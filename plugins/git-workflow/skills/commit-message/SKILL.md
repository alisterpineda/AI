---
name: commit-message
description: Defines how git commits should be handled — what to stage and how to format the message. Use this skill whenever the user asks to commit changes, make a commit, or write a commit message — even if they don't mention formatting or staging. This ensures commits only include relevant changes and follow the user's preferred message style.
---

# Commit Workflow

## What to stage

The working tree often contains changes unrelated to the current task — manual tweaks for local development (e.g. hardcoding a localhost URL), dependency file changes from `npm install`, editor configs, or experiments the user hasn't mentioned. Committing these by accident can break shared repos or pollute the history, and reversing a bad commit on a shared branch is painful. Being selective about staging is worth the extra few seconds.

- **Stage files by name, not by wildcard.** Don't use `git add .`, `git add -A`, or `git add --all`. These sweep up everything, including changes you didn't make and shouldn't commit.
- **Only stage files you changed** as part of the current task. If you didn't create or modify a file during this conversation, don't stage it — even if `git status` shows it as modified or untracked. Those changes belong to the user's other work.
- **Review diffs before staging.** Run `git diff <file>` for each file you plan to stage. If a file contains a mix of your task-related changes and unrelated edits (e.g. the user manually tweaked a config value in the same file you refactored), don't stage the whole file. Instead, tell the user what you found and let them decide — they may want to split the commit or revert their local tweak first.
- **Don't assume pre-staged changes are intentional.** If files are already staged when you begin, review them with `git diff --cached`. They may be leftovers the user staged earlier for a different purpose.
- **When in doubt, ask.** Under-staging is easy to fix (`git add` one more file). Over-staging can mean an unwanted change lands on a shared branch and causes problems downstream.

## Commit message format

When writing git commit messages, follow this structure and style exactly.

## Title line

- Write in **present-tense imperative mood** ("Add", "Fix", "Remove" — not "Added", "Fixes", "Removed")
- Keep it concise — aim for under 60 characters
- Use **plain language** that describes the change at a human level. Avoid code-like references in the title (write "user list endpoint" not "`/api/users`", write "settings page" not "`SettingsPage.tsx`")
- When it adds clarity, hint at the **why** — not just what changed but what problem it solves (e.g. "Paginate user list to fix memory issues on large datasets")
- No conventional commit prefixes (`feat:`, `fix:`, `chore:`, etc.)
- No trailing period
- Sentence case (capitalize the first word only, unless a proper noun follows)

## Message body

- Separate the body from the title with a blank line
- Use **bullet points** (` - ` prefix), one idea per bullet
- Include **technical detail** — mention specific implementations, parameters, data structures, queries, etc.
- When it adds value, explain **why** a change was made, not just what. This is preferred but not mandatory for every bullet — use judgment. If the reason is obvious, just state the what.
- Wrap lines at ~72 characters for readability in terminals

## What to leave out

- No emoji

## Examples

**Example 1** — Refactoring with a why-oriented title:
```
Paginate user list endpoint to fix memory issues on large datasets

- Replace unbounded SELECT query with cursor-based pagination
  to prevent OOM on large datasets
- Accept `cursor` and `limit` query params, default limit to 50
- Return `next_cursor` in response body for client iteration
- Add index on `created_at` to support cursor ordering efficiently
```

**Example 2** — Bug fix with technical body:
```
Fix toggle state not persisting across page reloads

- Read saved theme preference from localStorage on component mount
  instead of defaulting to light mode every time
- Add useEffect hook to sync toggle state when preference changes
  in another tab via the storage event
- Fall back to system preference via prefers-color-scheme when
  no saved preference exists
```

**Example 3** — New feature with balanced what/why bullets:
```
Add dark mode support and fix settings persistence

- Add dark mode toggle with system preference detection so users
  get a sensible default without manual configuration
- Define light/dark color tokens in theme config to replace
  hardcoded hex values scattered across components
- Persist preference in localStorage so it survives page reloads
```
