---
name: mcp-integration
description: MCP (Model Context Protocol) client nodes, provider interface, transport types, and server configuration in Rivet
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/MCP*.ts`
- `packages/core/src/integrations/mcp/*.ts`
- `packages/app/src/components/ProjectMCPConfiguration.tsx`

Keywords: MCPProvider, MCPBaseNodeData, mcpToolCall, mcpDiscovery, mcpGetPrompt, transportType, serverId, mcpProvider, loadMCPConfiguration

---

## Key Files
- `packages/core/src/integrations/mcp/MCPProvider.ts` — `MCP` namespace types, `MCPProvider` interface, `MCPError`/`MCPErrorType` — pure interface, no implementation
- `packages/core/src/integrations/mcp/MCPBase.ts` — `MCPBaseNodeData` and `getMCPBaseInputs()` shared by all MCP nodes
- `packages/core/src/integrations/mcp/MCPUtils.ts` — `loadMCPConfiguration`, `getServerOptions`, `getServerHelperMessage`
- `packages/core/src/model/nodes/MCPDiscoveryNode.ts` — discovers tools/prompts from server
- `packages/core/src/model/nodes/MCPToolCallNode.ts` — invokes a tool; supports `{{variable}}` interpolation in JSON args
- `packages/app/src/components/ProjectMCPConfiguration.tsx` — UI to edit `project.metadata.mcpServer` as JSON

## Key Concepts
- **Transport types:** `'http'` or `'stdio'`. HTTP nodes require the server URL to contain `/mcp`. STDIO nodes reference a `serverId` key from `project.metadata.mcpServer.mcpServers`.
- **MCP config source:** `context.project.metadata.mcpServer` (`MCP.Config`). Stored in the project file and edited via `ProjectMCPConfiguration`. `loadMCPConfiguration` throws `CONFIG_NOT_FOUND` if absent.
- **Provider injection:** `context.mcpProvider` (`MCPProvider` interface) is injected at runtime by the Node executor. The actual SDK implementation lives in `packages/node/`.
- **Discovery tools output type:** `gpt-function[]` — MCP tools are mapped to `GptFunction` shape (`name`, `description`, `parameters`, `strict: false`). Prompts output is `object[]`.
- **Tool argument interpolation:** When `useToolArgumentsInput` is false, input ports prefixed `input-` are interpolated into the JSON argument string using `interpolate()`.

## Critical Rules
- **Node executor only** — all MCP nodes throw if `context.executor === 'browser'`. Always check and surface this in `getBody()` with `(Requires Node Executor)`.
- **All MCP node data extends `MCPBaseNodeData`** — call `getMCPBaseInputs(this.data)` first in `getInputDefinitions()`.
- **HTTP URL must include `/mcp`** — validate and throw `MCPErrorType.SERVER_COMMUNICATION_FAILED` if missing.
- **`MCP.Prompt` has a typo in the SDK:** field is `arugments` (not `arguments`) — match it exactly when reading prompt arguments.
- **`getEditors()` is async** — uses `getServerOptions(context)` which reads live project config; always `await` it.

## References
- **Patterns:** `.claude/guidelines/mcp-integration/patterns.md`

---
**Last Updated:** 2026-04-19
