# ai

Personal marketplace of AI coding-agent customizations — skills, hooks, agents, and MCP config — packaged as plugins.

Built on the [Claude Code plugin format](https://code.claude.com/docs/en/plugins-reference.md), with skills authored to the vendor-neutral [Agent Skills](https://agentskills.io) standard. GitHub Copilot and OpenAI Codex read the Claude marketplace format natively, so the same repo installs into all three tools.

## Installing

### Claude Code

```
/plugin marketplace add alisterpineda/ai
/plugin install <plugin>@alisterpineda-ai
```

### GitHub Copilot (CLI / VS Code)

```
copilot plugin marketplace add alisterpineda/ai
copilot plugin install <plugin>@alisterpineda-ai
```

In VS Code, add `alisterpineda/ai` to the `chat.plugins.marketplaces` setting, or use **Chat: Install Plugin From Source** with the repo URL.

### OpenAI Codex

Codex CLI (≥ 0.146.0) supports Claude Code plugin marketplaces — use `/plugins` in the CLI to add this repo as a marketplace and install from it.

## Plugins

### git-workflow

Git-related skills.

| Skill | Invocation | What it does |
|---|---|---|
| `commit-message` | model-invoked | Commit staging discipline and message format conventions. |
| `pr-description` | model-invoked | Generates PR titles and descriptions from a branch diff. |
| `review` | **user-only**: `/git-workflow:review [--fix] [--model <name>] [target]` | Adversarial multi-perspective code review — parallel reviewer subagents (correctness, security, maintainability, tests, performance) plus a skeptic verification pass on every finding. Defaults to uncommitted changes; report-only unless `--fix` is passed. |

### publishing

Document production skills.

| Skill | Invocation | What it does |
|---|---|---|
| `typst` | model-invoked | Writes and iterates on Typst documents with a compile → render → inspect loop. Ships a neutral `base.typ`, conservative design principles, and `render.sh` / `probe.sh` scripts for deterministic verification. Requires the `typst` CLI. |

## Repo structure

See [CLAUDE.md](CLAUDE.md) for the plugin skeleton and authoring conventions.

## License

[MIT](LICENSE)
