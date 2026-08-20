---
# ── Portable (agentskills.io spec) — read by Claude Code and GitHub Copilot ──
name: review
description: "Adversarial multi-perspective code review. Spawns independent reviewer agents (correctness, security, maintainability, tests), then puts every finding through a skeptic verification pass before reporting. Usage: /git-workflow:review [--fix] [--model <name>] [target]. Flags come before the target. With no target, reviews the staged changes — or all uncommitted changes if nothing is staged. User-invoked only — never invoke this skill on your own initiative."
compatibility: "Not fully portable — deliberately uses frontmatter extensions beyond the agentskills.io spec. On Claude Code, context: fork runs the whole skill in a forked subagent that orchestrates reviewer/verifier subagents, keeping the review out of the main conversation. VS Code Copilot Chat also honors context: fork (experimental, opt-in via github.copilot.chat.skillTool.enabled), forking into a generic subagent — the agent/background fields are Claude-only and ignored there. Hosts that ignore context: fork entirely (Copilot CLI, Codex) run the same workflow in the main conversation instead — still with parallel reviewers where a subagent tool exists; hosts with no subagent tool fall back to sequential passes. Hosts that ignore disable-model-invocation lose the user-only invocation guarantee."

# ── Non-spec extension, honored by Claude Code and GitHub Copilot (same field
# name in both). Blocks auto-invocation; only /git-workflow:review works.
disable-model-invocation: true

# ── Non-spec extensions (ignored by the agentskills.io spec) ──
# argument-hint is honored by both Claude Code and Copilot (slash-command hint).
# user-invocable: true is Copilot's default (keeps the slash command available);
# stated explicitly to document intent alongside disable-model-invocation.
user-invocable: true
argument-hint: "[--fix] [--model <name>] [target]"

# ── Fork extensions ──
# context: fork runs this skill's body in a forked subagent — the fork IS the
# review orchestrator, so the whole review (and --fix) stays out of the main
# conversation. The fork starts with a fresh context: everything it needs is in
# this file. Per-host support for these three fields is documented once, in the
# compatibility string above. background: false keeps the fork in the foreground — background forks get a
# narrower tool set that may exclude the Agent tool this workflow needs to
# spawn reviewers.
context: fork
agent: general-purpose
background: false
---

# Adversarial Code Review

Run a multi-perspective adversarial review of a diff. Several independent reviewers each attack the change from one angle, a skeptic then tries to refute every finding, and only findings that survive refutation reach the report. The point of this structure is signal-to-noise: isolated perspectives find more than one generalist pass, and the refutation stage kills the plausible-but-wrong findings that make reviews annoying to read.

You are the review orchestrator. Depending on the host, you are executing either as a forked subagent (Claude Code, via `context: fork`) or directly in the main conversation (hosts that ignore that field). The workflow is identical either way, but as a fork your context starts fresh and **only your final message reaches the user** — so the complete report (step 8) must be your final message, and nothing may be left implied by earlier conversation you don't have.

Report only by default. Never modify files unless the `--fix` flag was passed.

## 1. Parse arguments

Arguments arrive as a single string. Flags come first, target last:

```
/git-workflow:review [--fix] [--model <name>] [target]
```

Parse left to right:

- `--fix` — after composing the report, apply fixes for confirmed findings (see step 9).
- `--model <name>` — model to use for reviewer and verifier subagents (e.g. `haiku`, `sonnet`, `opus`, or a full model ID). The orchestration you are doing yourself always stays on the model you were started with; this flag only affects subagents you spawn. If the host's subagent tool doesn't accept the given value, note it in the report header and continue with the default model rather than failing.
- Anything after the flags is the **target**. Any unrecognized `--flag` — leading or trailing (e.g. `review src/ --fix` puts the flag after the target) — is an error: make your final message a one-line explanation that flags come before the target, and stop, rather than silently absorbing the token into the target.

ARGUMENTS: $ARGUMENTS

## 2. Resolve the target

- **No target**: if anything is staged (`git diff --cached --quiet` exits non-zero), review the staged changes only — `git diff --cached`. Otherwise review all uncommitted changes — unstaged and untracked files (`git status`, `git diff HEAD`, plus reading untracked files). The report title says which scope applied ("staged changes" vs "uncommitted changes") so a surprising staging state is visible. If the working tree is clean, make your final message a statement that there is nothing to review and that an explicit target (branch, commit range, or path) can be passed instead. Stop there.
- **Branch name**: review what the current branch adds relative to it — `git diff <branch>...HEAD` (three dots, so the comparison is from the merge base).
- **Commit range** (`A..B`): review that range's diff. A **single commit** means that commit's own change: `git show <commit>` (equivalently `git diff <commit>^..<commit>`) — never `git diff <commit>`, which would diff against the working tree instead.
- **Path**: review uncommitted changes limited to that path.

The resolved target appears in the report's title line (step 8), which is how the user catches a misinterpretation — state it there exactly as you resolved it, not as it was typed.

## 3. Scout the diff and snapshot it

Read the full diff and build a short map: which files changed, and what kind of change each is (logic, config, tests, docs, dependencies, generated code). This map drives perspective selection and gives reviewers a starting point. Do not start judging the code yourself — that is the reviewers' job, and pre-forming opinions here undermines their independence.

Then freeze what is being reviewed into a fresh snapshot directory that this run creates — a new uniquely-named subdirectory under wherever the host wants temporary files (e.g. inside a session scratchpad directory, if one is designated), or `mktemp -d` if the host designates nothing. Never use a host-designated directory itself as the snapshot: step 8 deletes the snapshot directory, and the delete must only ever hit a directory this run created.

Inside it:

- Write the exact diff output to `<snapshot>/diff.patch`.
- When untracked files are in scope, copy each one to `<snapshot>/untracked/<relative-path>` — copies, not a list of paths, so later edits to those files cannot leak into the review.

Every reviewer and verifier reads the change from the snapshot instead of re-running git commands. That saves repeated work, but the real point is consistency: all of them judge the same state even if the working tree changes while the review runs. The snapshot defines only what is under review — the live repository stays available to subagents for surrounding context. When the scope is staged-only, the live working tree can differ from the snapshot (a partially staged file has different content and line numbers): the snapshot is the authoritative state, and every `file:line` citation must be derived from `diff.patch`, not from the live tree.

## 4. Select perspectives

Each perspective has a charter file in this skill's `references/` directory (resolve paths from this skill's base directory). Select using these criteria:

| Perspective | Charter | Runs when |
|---|---|---|
| Correctness | `references/correctness.md` | Always. |
| Security | `references/security.md` | The diff touches input handling, auth, network calls, shell/process execution, file paths, serialization, SQL/queries, secrets, or dependency/config changes. |
| Tests | `references/tests.md` | Source logic changed (whether or not tests changed with it), or test files themselves changed. |
| Maintainability | `references/maintainability.md` | Any non-trivial code change — skip only for pure docs/config/generated-file diffs. |

Skipping is not silent: the report header lists which perspectives were skipped and why. When in doubt about a criterion, run the perspective — a wasted pass is cheaper than a missed vulnerability.

## 5. Run the reviewers

**If the host provides a subagent-spawning tool** (Claude Code's Agent/Task tool or equivalent): spawn all selected reviewers in parallel, one subagent per perspective, applying `--model` if given. Each subagent's prompt must contain:

1. The absolute path to its charter file, with the instruction to read it first and adopt that role completely.
2. The resolved target, and the absolute path to `<snapshot>/diff.patch` to read as the reviewed change — stating that the snapshot is the authoritative state and that `file:line` citations must come from it, since live files can differ when the scope is staged-only — — plus, when the scope includes untracked files (`git diff` never shows them), the absolute path of `<snapshot>/untracked/` with the instruction to read every file under it in full as part of the reviewed change.
3. That it has read access to the full repository for context, but must not modify anything.
4. That its final message must be only its findings in the charter's output format (or the charter's explicit "no findings" statement) — no preamble, no summary of its process.

If a spawned subagent fails, hangs, or never returns a result, do not drop its unit of work and do not stall the review waiting on it: perform that unit yourself inline, following the same charter file exactly, and continue.

**If no subagent mechanism is available**: run each selected charter as its own sequential pass. Complete one perspective fully — read the charter, re-examine the diff through only that lens, write down its findings — before starting the next. Do not let an earlier pass's findings steer a later pass; each charter deserves a fresh hunt. Note in the report header that the review ran sequentially, and that `--model` (if given) was ignored because there were no subagents to apply it to.

## 6. Deduplicate

Merge findings that share a root cause, even when different perspectives describe it differently (e.g. correctness flags a missing null check and security flags the same line as a crash vector). A merged finding keeps all its perspective tags and the strongest severity claimed. Keep findings **per code site**: two occurrences of the same mistake in different places stay separate findings (each is separately fixable), while a single cross-site pattern finding (e.g. "this anti-pattern appears in both functions") is split into one finding per site — each carrying the full defect, failure scenario, and suggested fix, and merged with any existing finding already at that site. Do not drop findings at this stage for seeming weak — that judgment belongs to the verifier. Reviewers' confidence ratings exist to inform the verifiers; they are dropped from the final report.

## 7. Verify every finding

Every deduplicated finding goes through refutation — no exceptions, including findings that look obviously right. The charter is `references/verifier.md`.

With subagents: spawn one verifier per finding, in parallel — in waves of at most 8 when findings are numerous, so a noisy review does not fan out into dozens of concurrent subagents — applying `--model` if given. Each verifier gets the charter path, the single finding it is judging (full text), and the same snapshot paths the reviewers got (`<snapshot>/diff.patch`, plus `<snapshot>/untracked/` when in scope). Fresh context per finding is the point — the verifier must re-derive the truth from the code, not inherit the reviewer's framing.

Without subagents: verify sequentially, one finding at a time. Before each one, re-read the relevant code from scratch and actively look for reasons the finding is wrong; you wrote these findings minutes ago, so bias toward refutation to compensate.

Findings verdict `CONFIRMED` go in the report. Findings verdict `REFUTED` go in the rejected appendix with the refutation reason. Apply any severity correction the verifier made.

## 8. Report

Assemble the report using this structure. Without `--fix`, output it as your final message. With `--fix`, hold it, complete step 9 first, and output the report with the fix summary appended as one final message — remember that as a fork, only that final message reaches the user. Just before sending that final message, delete the snapshot directory — exactly the directory this run created in step 3, never a host-designated parent (best effort — a failed cleanup is not worth mentioning in the report).

```
# Adversarial review: <target>

Perspectives run: <list>. Skipped: <perspective — reason, or "none">.
<If sequential fallback: note it here, including --model being ignored.>
<N> findings confirmed, <M> refuted.

## Confirmed findings

### 1. [CRITICAL|MAJOR|MINOR] <short title>
- **Perspective:** <tag(s)>
- **Location:** <file:line>
- **Defect:** <one sentence>
- **Failure scenario:** <concrete inputs/state → wrong outcome>
- **Suggested fix:** <one or two sentences>

<...ordered by severity, critical first>

## Considered and rejected
- <short title> (<perspective>) — <one-line refutation reason>
```

Where the verifier corrected a severity, append *(severity corrected from X by verifier)* to that finding's title so the adjustment is visible. If every finding was confirmed, the appendix is the single line `- None — all findings survived verification.` If nothing was confirmed, say so plainly and still show the rejected appendix — it is the evidence the review actually looked.

## 9. Fixes — only with `--fix`

Without the flag: the report is the end. Do not apply fixes, do not offer to.

With the flag: apply the suggested fix for each confirmed finding yourself, directly (not via subagents), making the smallest change that resolves the defect. Then run whatever cheap sanity check the project offers (build, lint, or the directly relevant tests) and append a `## Fixes applied` section to the report summarizing what was changed and what was verified. If a fix is too risky or ambiguous to apply mechanically, skip it and say why in that section instead of guessing.
