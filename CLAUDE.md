# AI Customizations Repo

Personal plugin marketplace for AI coding-agent customizations (skills, hooks, agents, MCP config). Primary consumer is Claude Code; the Claude plugin/marketplace format is also read natively by GitHub Copilot (CLI + VS Code) and OpenAI Codex, so this repo serves all three without any sync scripts.

## Repo layout

- `.claude-plugin/marketplace.json` — marketplace manifest (`alisterpineda-ai`). Every plugin must be listed here with `name` + `source` (relative path under `./plugins`).
- `plugins/<plugin-name>/` — one directory per plugin.
- `README.md` — install instructions per tool.

## Plugin skeleton

When creating a new plugin, use this structure. Only `.claude-plugin/plugin.json` is required; add the other pieces as needed.

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json          # required: {"name": "<plugin-name>", "version": "0.1.0", "description": "..."}
├── plugin.json              # optional: Agent Plugins 1.0 manifest for strict spec conformance
│                            #   {"$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json", "name": "<plugin-name>"}
├── skills/                  # portable layer — read by Claude Code, Copilot, Codex, Cursor
│   └── <skill-name>/
│       ├── SKILL.md         # YAML frontmatter + instructions
│       ├── references/      # docs loaded on demand
│       └── scripts/         # executables the skill invokes
├── hooks/
│   ├── hooks.json           # Claude Code hook wiring
│   └── scripts/             # standalone hook scripts (keep logic here, wiring thin)
├── agents/                  # Claude Code subagents (one .md per agent, YAML frontmatter)
├── commands/                # Claude Code slash commands — prefer skills instead
├── .mcp.json                # MCP servers (Claude Code format; Copilot reads it too)
└── com.github.copilot/      # Copilot-specific files (agents/hooks), only if ever needed
```

After adding a plugin: register it in `.claude-plugin/marketplace.json` and run `claude plugin validate ./plugins/<plugin-name>`.

## Conventions

- **Claude Code is the source of truth.** Design skills, agents, and hooks for Claude Code first; anything created for another harness (Copilot, Codex) is a derivative of the Claude Code version and must not fork behavior — when they drift, the Claude Code version wins and the derivative is regenerated from it.
- **Skills are the portable unit.** Prefer a skill over a slash command or per-vendor prompt file for anything reusable.
- **Portable skills** stick to the vendor-neutral Agent Skills frontmatter fields (agentskills.io): `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Claude-only extensions (`context: fork`, `model`, `hooks`, dynamic `` !`cmd` `` injection, etc.) are allowed only in skills deliberately marked Claude-only — note it in the skill's `description` or `compatibility`. (One partial exception: VS Code Copilot Chat honors `context: fork` experimentally behind `github.copilot.chat.skillTool.enabled`; Copilot CLI ignores it and loads the skill inline.)
- **Hooks are not portable.** Claude Code, Copilot, and Codex each have different hook config formats and event sets. Keep hook logic in standalone scripts under `hooks/scripts/` so the per-vendor wiring stays a thin wrapper. Use `${CLAUDE_PLUGIN_ROOT}` for paths in `hooks.json`.
- **Version discipline:** bump `version` in `.claude-plugin/plugin.json` in any commit that changes files under `plugins/<name>/` — all consumers (Claude Code, Copilot, Codex) cache installed plugins and only refetch when the version string changes. Changes outside plugin directories (README, CLAUDE.md, marketplace.json) never need a bump. One bump per commit; a commit touching two plugins bumps each.
  - **Major:** a consumer-visible break — removing or renaming a skill/command/agent (renames change the `<plugin>:<skill>` namespace), removing a hook, or restructuring how the plugin is invoked.
  - **Minor:** additions and behavior changes — a new skill/agent/hook, a new workflow step, or any edit that changes what a skill does or when it triggers (`description` edits that alter triggering are minor; triggering is the skill's interface).
  - **Patch:** no observable behavior change — typo/wording fixes, script bugfixes, formatting, tightening instructions without changing the outcome.
  - Minor-vs-patch tiebreaker for prose edits: if you'd want the change to stand out in version history when debugging why a skill started acting differently, it's minor.
  - Plugins stay pre-1.0 but follow the same semantics (no "0.x means anything goes"); cut 1.0 when a plugin is stable enough that a rename would be annoying.
- **Naming:** kebab-case for plugin and skill names. Skill names become namespaced as `<plugin-name>:<skill-name>` in Claude Code.
