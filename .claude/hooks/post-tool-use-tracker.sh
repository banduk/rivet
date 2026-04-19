#!/bin/bash
# Note: Removed set -e to prevent hook failures from blocking edits

# IMPORTANT: All output MUST go to stderr (>&2), not stdout.
# stdout from PostToolUse hooks is injected into Claude's context.

# Post-tool-use hook that tracks edited files and their repos
# This runs after Edit, MultiEdit, or Write tools complete successfully

# Require jq for JSON parsing
if ! command -v jq &> /dev/null; then
    exit 0
fi

get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir
        dir="$(cd -P "$(dirname "$source")" && pwd)" || return 1
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

SCRIPT_DIR="$(get_script_dir)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Exit early if neither CLAUDE_PROJECT_DIR nor PROJECT_DIR is set
if [[ -z "$CLAUDE_PROJECT_DIR" ]] && [[ -z "$PROJECT_DIR" ]]; then
    exit 0
fi

# Read tool information from stdin
tool_info=$(cat)


# Extract relevant data
tool_name=$(echo "$tool_info" | jq -r '.tool_name // empty')
file_path=$(echo "$tool_info" | jq -r '.tool_input.file_path // empty')
session_id=$(echo "$tool_info" | jq -r '.session_id // empty')


# Skip if not an edit tool or no file path
if [[ ! "$tool_name" =~ ^(Edit|MultiEdit|Write)$ ]] || [[ -z "$file_path" ]]; then
    exit 0  # Exit 0 for skip conditions
fi

# Skip markdown files
if [[ "$file_path" =~ \.(md|markdown)$ ]]; then
    exit 0  # Exit 0 for skip conditions
fi

# Create cache directory in project
cache_dir="$PROJECT_DIR/.claude/tsc-cache/${session_id:-default}"
mkdir -p "$cache_dir"

# Function to detect repo from file path
detect_repo() {
    local file="$1"
    local project_root="$PROJECT_DIR"

    # Remove project root from path
    local relative_path="${file#$project_root/}"

    # Extract first directory component
    local repo
    repo=$(echo "$relative_path" | cut -d'/' -f1)

    # Common project directory patterns
    case "$repo" in
        # Frontend variations
        frontend|client|web|app|ui)
            echo "$repo"
            ;;
        # Backend variations
        backend|server|api|src|services)
            echo "$repo"
            ;;
        # Database
        database|prisma|migrations)
            echo "$repo"
            ;;
        # Package/monorepo structure
        packages)
            # For monorepos, get the package name
            local package=$(echo "$relative_path" | cut -d'/' -f2)
            if [[ -n "$package" ]]; then
                echo "packages/$package"
            else
                echo "$repo"
            fi
            ;;
        # Examples directory
        examples)
            local example=$(echo "$relative_path" | cut -d'/' -f2)
            if [[ -n "$example" ]]; then
                echo "examples/$example"
            else
                echo "$repo"
            fi
            ;;
        *)
            # Check if it's a source file in root
            if [[ ! "$relative_path" =~ / ]]; then
                echo "root"
            else
                echo "unknown"
            fi
            ;;
    esac
}

# Function to get build command for repo
get_build_command() {
    local repo="$1"
    local project_root="$PROJECT_DIR"

    # Map special repo names to actual paths
    local repo_path
    if [[ "$repo" == "root" ]] || [[ "$repo" == "src" ]] || [[ "$repo" == "unknown" ]]; then
        repo_path="$project_root"
    else
        repo_path="$project_root/$repo"
    fi

    # Check if package.json exists and has a build script
    if [[ -f "$repo_path/package.json" ]]; then
        if grep -q '"build"' "$repo_path/package.json" 2>/dev/null; then
            # Detect package manager (prefer pnpm, then npm, then yarn)
            if [[ -f "$repo_path/pnpm-lock.yaml" ]]; then
                echo "cd $repo_path && pnpm build"
            elif [[ -f "$repo_path/package-lock.json" ]]; then
                echo "cd $repo_path && npm run build"
            elif [[ -f "$repo_path/yarn.lock" ]]; then
                echo "cd $repo_path && yarn build"
            else
                echo "cd $repo_path && npm run build"
            fi
            return
        fi
    fi

    # Special case for database with Prisma
    if [[ "$repo" == "database" ]] || [[ "$repo" =~ prisma ]]; then
        if [[ -f "$repo_path/schema.prisma" ]] || [[ -f "$repo_path/prisma/schema.prisma" ]]; then
            echo "cd $repo_path && npx prisma generate"
            return
        fi
    fi

    # No build command found
    echo ""
}

# Function to get TSC command for repo
get_tsc_command() {
    local repo="$1"
    local project_root="$PROJECT_DIR"

    # Map special repo names to actual paths
    local repo_path
    if [[ "$repo" == "root" ]] || [[ "$repo" == "src" ]] || [[ "$repo" == "unknown" ]]; then
        repo_path="$project_root"
    else
        repo_path="$project_root/$repo"
    fi

    # Check if tsconfig.json exists
    if [[ -f "$repo_path/tsconfig.json" ]]; then
        # Check for Vite/React-specific tsconfig
        if [[ -f "$repo_path/tsconfig.app.json" ]]; then
            echo "cd $repo_path && npx tsc --project tsconfig.app.json --noEmit"
        else
            echo "cd $repo_path && npx tsc --noEmit"
        fi
        return
    fi

    # No TypeScript config found
    echo ""
}

# Detect repo
repo=$(detect_repo "$file_path")

# Skip if unknown repo
if [[ "$repo" == "unknown" ]] || [[ -z "$repo" ]]; then
    exit 0  # Exit 0 for skip conditions
fi

# Log edited file
echo "$(date +%s):$file_path:$repo" >> "$cache_dir/edited-files.log"

# Update affected repos list
if ! grep -q "^$repo$" "$cache_dir/affected-repos.txt" 2>/dev/null; then
    echo "$repo" >> "$cache_dir/affected-repos.txt"
fi

# Store build commands
build_cmd=$(get_build_command "$repo")
tsc_cmd=$(get_tsc_command "$repo")

if [[ -n "$build_cmd" ]]; then
    echo "$repo:build:$build_cmd" >> "$cache_dir/commands.txt.tmp"
fi

if [[ -n "$tsc_cmd" ]]; then
    echo "$repo:tsc:$tsc_cmd" >> "$cache_dir/commands.txt.tmp"
fi

# Remove duplicates from commands
if [[ -f "$cache_dir/commands.txt.tmp" ]]; then
    sort -u "$cache_dir/commands.txt.tmp" > "$cache_dir/commands.txt"
    rm -f "$cache_dir/commands.txt.tmp"
fi

# ============================================
# SESSION-STICKY SKILLS TRACKING
# ============================================
# Detect which domain skill should be activated based on file path
# and persist it in session state for sticky behavior

# BEGIN detect_skill_domain
detect_skill_domain() {
    local file="$1"
    local detected_skills=""

    # Generated by aspens from skill-rules.json filePatterns
    if [[ "$file" =~ /custom/ ]] || [[ "$file" =~ /useAiGraphBuilder ]] || [[ "$file" =~ /components/ ]]; then
        detected_skills="ai-assisted-node-editing"
    elif [[ "$file" =~ /useAiGraphBuilder ]] || [[ "$file" =~ /components/ ]] || [[ "$file" =~ /graph-creator.rivet-project ]] || [[ "$file" =~ /graph-creator.rivet-data ]]; then
        detected_skills="ai-graph-builder"
    elif [[ "$file" =~ /executor ]] || [[ "$file" =~ /build-executor ]] || [[ "$file" =~ /debugger ]] || [[ "$file" =~ /api ]] || [[ "$file" =~ /useExecutorSidecar ]] || [[ "$file" =~ /useRemoteExecutor ]]; then
        detected_skills="app-executor-sidecar"
    elif [[ "$file" =~ /useAutoLayoutGraph ]] || [[ "$file" =~ /NodeCanvas ]] || [[ "$file" =~ /useGraphBuilderContextMenuHandler ]] || [[ "$file" =~ /useContextMenuConfiguration ]]; then
        detected_skills="auto-layout"
    elif [[ "$file" =~ /cli ]] || [[ "$file" =~ /run ]] || [[ "$file" =~ /serve ]]; then
        detected_skills="cli-run-and-serve"
    elif [[ "$file" =~ /CodeNode ]] || [[ "$file" =~ /CodeRunner ]] || [[ "$file" =~ /CodeNodeAIAssistEditor ]]; then
        detected_skills="code-execution-node"
    elif [[ "$file" =~ /community/ ]] || [[ "$file" =~ /hooks/ ]] || [[ "$file" =~ /useNewProjectFromTemplate ]] || [[ "$file" =~ /communityApi ]]; then
        detected_skills="community-template-platform"
    elif [[ "$file" =~ /IfElseNode ]] || [[ "$file" =~ /IfNode ]] || [[ "$file" =~ /LoopControllerNode ]] || [[ "$file" =~ /LoopUntilNode ]] || [[ "$file" =~ /RaceInputsNode ]] || [[ "$file" =~ /AbortGraphNode ]]; then
        detected_skills="control-flow"
    elif [[ "$file" =~ /nodes/ ]] || [[ "$file" =~ /FilterNode ]] || [[ "$file" =~ /ChunkNode ]] || [[ "$file" =~ /SplitNode ]] || [[ "$file" =~ /SliceNode ]]; then
        detected_skills="data-extraction-and-transform"
    elif [[ "$file" =~ /nodes/ ]] || [[ "$file" =~ /DatasetNearestNeigborsNode ]] || [[ "$file" =~ /GetDatasetRowNode ]] || [[ "$file" =~ /GetAllDatasetsNode ]] || [[ "$file" =~ /ReplaceDatasetNode ]] || [[ "$file" =~ /DatasetProvider ]] || [[ "$file" =~ /dataStudio ]] || [[ "$file" =~ /dataStudio/ ]]; then
        detected_skills="dataset-management"
    elif [[ "$file" =~ /RaiseEventNode ]] || [[ "$file" =~ /WaitForEventNode ]]; then
        detected_skills="event-system"
    elif [[ "$file" =~ /ExecutionRecorder ]] || [[ "$file" =~ /RecordedEvents ]] || [[ "$file" =~ /useLoadRecording ]] || [[ "$file" =~ /useSaveRecording ]] || [[ "$file" =~ /execution ]]; then
        detected_skills="execution-recording-and-playback"
    elif [[ "$file" =~ /useFactorIntoSubgraph ]] || [[ "$file" =~ /useContextMenuConfiguration ]] || [[ "$file" =~ /useGraphBuilderContextMenuHandler ]]; then
        detected_skills="factor-into-subgraph"
    elif [[ "$file" =~ /ReadFileNode ]] || [[ "$file" =~ /ReadDirectoryNode ]] || [[ "$file" =~ /AudioNode ]] || [[ "$file" =~ /PlayAudioNode ]] || [[ "$file" =~ /TauriBrowserAudioProvider ]]; then
        detected_skills="file-and-audio-io"
    elif [[ "$file" =~ /GetGlobalNode ]] || [[ "$file" =~ /SetGlobalNode ]]; then
        detected_skills="global-variables"
    elif [[ "$file" =~ /GraphProcessor ]] || [[ "$file" =~ /ProcessContext ]] || [[ "$file" =~ /NodeImpl ]] || [[ "$file" =~ /NodeRegistration ]] || [[ "$file" =~ /Nodes ]]; then
        detected_skills="graph-execution-engine"
    elif [[ "$file" =~ /dataFlow ]] || [[ "$file" =~ /execution ]] || [[ "$file" =~ /useGraphExecutor ]] || [[ "$file" =~ /useLocalExecutor ]] || [[ "$file" =~ /useRemoteExecutor ]] || [[ "$file" =~ /useCurrentExecution ]] || [[ "$file" =~ /ActionBar ]] || [[ "$file" =~ /NodeOutput ]] || [[ "$file" =~ /GraphExecutionSelectorBar ]] || [[ "$file" =~ /VisualNode ]]; then
        detected_skills="graph-execution-ui"
    elif [[ "$file" =~ /commands/ ]] || [[ "$file" =~ /useGraphRevisions ]] || [[ "$file" =~ /useGraphHistoryNavigation ]] || [[ "$file" =~ /useChooseHistoricalGraph ]] || [[ "$file" =~ /useHistoricalNodeChangeInfo ]] || [[ "$file" =~ /ProjectRevisionCalculator ]] || [[ "$file" =~ /GraphRevisionList ]] || [[ "$file" =~ /NodeChangesModal ]]; then
        detected_skills="graph-history-and-versioning"
    elif [[ "$file" =~ /useSearchGraph ]] || [[ "$file" =~ /useSearchProject ]] || [[ "$file" =~ /useFuseSearch ]] || [[ "$file" =~ /NavigationBar ]]; then
        detected_skills="graph-search"
    elif [[ "$file" =~ /HttpCallNode ]]; then
        detected_skills="http-client-node"
    elif [[ "$file" =~ /ChatNode ]] || [[ "$file" =~ /ChatLoopNode ]] || [[ "$file" =~ /ChatNodeBase ]] || [[ "$file" =~ /AssemblePromptNode ]] || [[ "$file" =~ /AssembleMessageNode ]] || [[ "$file" =~ /TrimChatMessagesNode ]]; then
        detected_skills="llm-chat-nodes"
    elif [[ "$file" =~ /plugin.ts/ ]] || [[ "$file" =~ /nodes/ ]] || [[ "$file" =~ /index.ts/ ]] || [[ "$file" =~ /plugins ]]; then
        detected_skills="llm-provider-plugins"
    elif [[ "$file" =~ /nodes/ ]] || [[ "$file" =~ /mcp/ ]] || [[ "$file" =~ /ProjectMCPConfiguration ]]; then
        detected_skills="mcp-integration"
    elif [[ "$file" =~ /clipboard ]] || [[ "$file" =~ /useCopyNodes ]] || [[ "$file" =~ /usePasteNodes ]] || [[ "$file" =~ /useCopyNodesHotkeys ]] || [[ "$file" =~ /useGraphBuilderContextMenuHandler ]]; then
        detected_skills="node-clipboard-copy-paste"
    elif [[ "$file" =~ /editors/ ]] || [[ "$file" =~ /EditorDefinition ]]; then
        detected_skills="node-property-editors"
    elif [[ "$file" =~ /node/ ]] || [[ "$file" =~ /bin/ ]] || [[ "$file" =~ /app-executor/ ]]; then
        detected_skills="nodejs-runtime"
    elif [[ "$file" =~ /nodes/ ]] || [[ "$file" =~ /NodeImpl ]] || [[ "$file" =~ /DataValue ]] || [[ "$file" =~ /commands/ ]] || [[ "$file" =~ /state/ ]] || [[ "$file" =~ /bundle.esbuild ]]; then
        detected_skills="packages"
    elif [[ "$file" =~ /plugins/ ]] || [[ "$file" =~ /RivetPlugin ]] || [[ "$file" =~ /NodeDefinition ]] || [[ "$file" =~ /NodeImpl ]] || [[ "$file" =~ /NodeRegistration ]] || [[ "$file" =~ /useProjectPlugins ]] || [[ "$file" =~ /plugins ]]; then
        detected_skills="plugin-system"
    elif [[ "$file" =~ /savedGraphs ]] || [[ "$file" =~ /useLoadProject ]] || [[ "$file" =~ /useSaveProject ]] || [[ "$file" =~ /useNewProject ]] || [[ "$file" =~ /useLoadProjectWithFileBrowser ]] || [[ "$file" =~ /Project ]] || [[ "$file" =~ /serialization/ ]]; then
        detected_skills="project-management"
    elif [[ "$file" =~ /PromptDesigner ]] || [[ "$file" =~ /promptDesigner ]] || [[ "$file" =~ /useGetAdHocInternalProcessContext ]]; then
        detected_skills="prompt-designer"
    elif [[ "$file" =~ /debugger ]] || [[ "$file" =~ /useRemoteDebugger ]] || [[ "$file" =~ /useRemoteExecutor ]] || [[ "$file" =~ /DebuggerConnectPanel ]] || [[ "$file" =~ /execution ]]; then
        detected_skills="remote-debugger"
    elif [[ "$file" =~ /settings ]] || [[ "$file" =~ /storage ]] || [[ "$file" =~ /SettingsModal ]] || [[ "$file" =~ /tauri ]] || [[ "$file" =~ /Settings ]] || [[ "$file" =~ /getPluginConfig ]] || [[ "$file" =~ /api ]]; then
        detected_skills="settings-and-api-keys"
    elif [[ "$file" =~ /useCheckForUpdate ]] || [[ "$file" =~ /useMonitorUpdateStatus ]] || [[ "$file" =~ /UpdateModal ]]; then
        detected_skills="software-update-notifications"
    elif [[ "$file" =~ /SubGraphNode ]] || [[ "$file" =~ /CallGraphNode ]] || [[ "$file" =~ /GraphInputNode ]] || [[ "$file" =~ /GraphOutputNode ]] || [[ "$file" =~ /GraphReferenceNode ]]; then
        detected_skills="subgraph-composition"
    elif [[ "$file" =~ /trivet/ ]] || [[ "$file" =~ /trivet ]] || [[ "$file" =~ /useTestSuite ]]; then
        detected_skills="trivet-testing-framework"
    elif [[ "$file" =~ /commands/ ]]; then
        detected_skills="undo-redo-command-system"
    elif [[ "$file" =~ /UserInputNode ]] || [[ "$file" =~ /UserInputModal ]] || [[ "$file" =~ /userInput ]]; then
        detected_skills="user-input-node"
    elif [[ "$file" =~ /VectorStoreNode ]] || [[ "$file" =~ /VectorNearestNeighborsNode ]] || [[ "$file" =~ /GetEmbeddingNode ]] || [[ "$file" =~ /EmbeddingGenerator ]] || [[ "$file" =~ /VectorDatabase ]] || [[ "$file" =~ /integrations ]]; then
        detected_skills="vector-search-and-embeddings"
    elif [[ "$file" =~ /NodeCanvas ]] || [[ "$file" =~ /VisualNode ]] || [[ "$file" =~ /WireLayer ]] || [[ "$file" =~ /Wire ]] || [[ "$file" =~ /Port ]] || [[ "$file" =~ /DraggableNode ]] || [[ "$file" =~ /useCanvasPositioning ]] || [[ "$file" =~ /useNodePortPositions ]] || [[ "$file" =~ /useDraggingNode ]] || [[ "$file" =~ /useDraggingWire ]]; then
        detected_skills="visual-graph-canvas"
    fi

    echo "$detected_skills"
}
# END detect_skill_domain

# Create session file path based on project directory hash
get_session_file() {
    local project_dir="$1"
    local hash=$(echo -n "$project_dir" | md5 2>/dev/null || echo -n "$project_dir" | md5sum | cut -d' ' -f1)
    echo "${TMPDIR:-/tmp}/claude-skills-${hash}.json"
}

# Add skill to session state
add_skill_to_session() {
    local skill="$1"
    local session_file="$2"
    local repo="$3"

    if [[ -z "$skill" ]]; then
        return
    fi

    # Create or update session file (jq required — checked at script entry)
    if [[ -f "$session_file" ]]; then
        jq --arg skill "$skill" --arg time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '.active_skills = ((.active_skills + [$skill]) | unique) | .last_updated = $time' \
            "$session_file" > "${session_file}.tmp" 2>/dev/null && \
            mv "${session_file}.tmp" "$session_file"
    else
        # Create new session file
        echo "{\"repo\":\"$repo\",\"active_skills\":[\"$skill\"],\"last_updated\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$session_file"
    fi
}

# Track skill domain(s) for session-sticky behavior
skill_domains=$(detect_skill_domain "$file_path")
if [[ -n "$skill_domains" ]]; then
    session_file=$(get_session_file "$PROJECT_DIR")
    for skill in $skill_domains; do
        add_skill_to_session "$skill" "$session_file" "$repo"
    done
fi

# Exit cleanly
exit 0
