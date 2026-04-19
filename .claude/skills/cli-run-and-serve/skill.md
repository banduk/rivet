---
name: cli-run-and-serve
description: CLI run and serve commands — graph execution and Hono-based REST/SSE server
---

## Activation

This skill triggers when editing these files:
- `packages/cli/src/cli.ts`
- `packages/cli/src/commands/run.ts`
- `packages/cli/src/commands/serve.ts`

Keywords: rivet-node, createProcessor, loadProjectFromFile, serveHono, getSSEStream, LooseDataValue, rivet-project

---

You are working on the **Rivet CLI** — yargs-based commands for running graphs and serving them as a REST API.

## Key Files
- `packages/cli/src/cli.ts` — yargs entry; registers `run` and `serve` sub-commands
- `packages/cli/src/commands/run.ts` — loads project, runs graph once, prints JSON to stdout
- `packages/cli/src/commands/serve.ts` — Hono server; exposes graph as `POST /` (and optionally `POST /:graphId`)

## Command Module Pattern
Each command exports `makeCommand(y)` (adds options/positionals) + a named handler. Registration in `cli.ts`:
```ts
.command('run <projectFile> [graphName]', '...', (y) => makeRunCommand(y), (args) => run(args))
```

## Key Abstractions (`@ironclad/rivet-node`)
- `loadProjectFromFile(path)` — parses `.rivet-project` file into `Project`
- `createProcessor(project, opts)` — returns `{ run(): Promise<Outputs>, processor, getSSEStream(filters) }`
- `getSingleNodeStream(processor, nodeIdOrTitle)` — stream for one node's partial outputs
- `LooseDataValue` — type for all graph inputs/outputs; `Record<string, LooseDataValue>` for inputs/context

## Input Parsing
- `--input key=value` / `--context key=value` — split on first `=`, string values passed as `LooseDataValue`
- `--inputs-stdin` — reads entire JSON object from stdin; mutually exclusive with `--input`
- `serve` reads request body as raw text, parses JSON only if non-empty (empty body = no inputs)

## Streaming (serve only)
- `--stream` enables SSE mode; response headers: `Content-Type: text/event-stream`, `Cache-Control: no-cache`, `Connection: keep-alive`
- `--stream-node <id|title>` uses `getSingleNodeStream()`; without it, `getSSEStream()` sends nodeStart/nodeFinish/partialOutputs for all nodes
- `run()` is fire-and-forget after stream is returned; errors are logged, not propagated

## Critical Rules
- Graph lookup: match by `metadata.id` OR `metadata.name`; fall back to `project.metadata.mainGraphId` when graph arg omitted
- `throwIfInvalidGraph` uses `didyoumean2` for typo suggestions — preserve this for UX
- `serve` auto-discovers `.rivet-project` from CWD if `projectFile` omitted; errors if 0 or 2+ found
- `--dev` mode re-reads project file on every request (hot reload); production mode uses `initialProject` captured at startup
- `--allow-specifying-graph-id` adds `POST /:graphId` route — SSE streaming is NOT supported on this route
- `exposeCost`/`includeCost`: `delete outputs.cost` strips cost from response by default
- `configDotenv()` is called at serve startup — env vars from `.env` are available to graph runs

## References
- **Base conventions:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
