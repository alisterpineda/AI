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

None yet.

## Repo structure

See [CLAUDE.md](CLAUDE.md) for the plugin skeleton and authoring conventions.

## License

[MIT](LICENSE)
