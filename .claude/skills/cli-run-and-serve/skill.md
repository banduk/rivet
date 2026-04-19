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
- `packages/cli/src/commands/run.ts` — loads project, runs graph once, prints JSON
- `packages/cli/src/commands/serve.ts` — Hono server; exposes graph as `POST /` (and optionally `POST /:graphId`)

## Command Module Pattern
Each command exports `makeCommand(y)` (adds options/positionals) + a handler. Registration in `cli.ts`:
```ts
.command('run <projectFile> [graphName]', '...', makeCommand, run)
```

## Key Abstractions (`@ironclad/rivet-node`)
- `loadProjectFromFile(path)` — parses `.rivet-project` YAML into `Project`
- `createProcessor(project, opts)` — returns `{ run(): Promise<Outputs>, processor, getSSEStream(filters) }`
- `LooseDataValue` — all graph inputs/outputs; `Record<string, LooseDataValue>` for inputs/context

## Input Parsing
- `--input key=value` / `--context key=value` — split on first `=`, values become `LooseDataValue`
- `--inputs-stdin` — reads entire JSON object from stdin instead; mutually exclusive with `--input`

## Streaming (serve)
- `--stream` enables SSE mode; `--stream-node <id|title>` filters to one node via `getSingleNodeStream()`
- Graph runs fire-and-forget once stream is set up; errors are logged, not thrown
- Normal mode: `runGraph()` awaits `processor.run()` and returns `Outputs` as JSON

## Critical Rules
- Graph lookup: always fall back to `project.metadata?.mainGraphId` if `graphName` is omitted; use `didyoumean2` for invalid name errors
- `--dev` flag in serve: reloads project file on **every request** — only call `loadProjectFromFile` inside the request handler when this flag is set
- `dotenv` (`configDotenv()`) is loaded once at serve startup — OpenAI keys fall through: CLI flag → env var → undefined
- Auto-discovery (`getProjectFile()`): errors if 0 or 2+ `.rivet-project` files found in cwd
- Process exits with code 1 on all errors; never throw unhandled in handlers

## References
- **Base conventions:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
