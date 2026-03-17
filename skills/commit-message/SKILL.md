---
name: commit-message
description: Defines how git commit messages should be formatted. Use this skill whenever the user asks to commit changes, make a commit, or write a commit message — even if they don't mention formatting. This ensures all commits follow the user's preferred style.
---

# Commit Message Format

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
