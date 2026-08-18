---
name: pr-description
description: Generates a pull-request title and description based on the diff between a source and target branch. Use this skill whenever the user asks to create, write, draft, or generate a PR title, PR description, pull request message, or pull-request summary — even if they phrase it casually like "write me a PR" or "what should the PR say". This is the go-to skill for any PR content generation task.
---

# PR Description Generator

Generate a pull-request title and formatted description by analyzing the full diff between a source and target branch. The goal is to communicate the **end result** of the changes clearly — not a play-by-play of individual commits.

## Step 1: Determine the branches

- **Source branch**: Use the current branch (HEAD) unless the user specifies otherwise
- **Target branch**: Use the branch the user specifies. If they don't, default to `main` — if `main` doesn't exist, fall back to `master`

Confirm which branches you're comparing if there's any ambiguity.

## Step 2: Gather the full context

Run these git commands to understand the complete picture:

```bash
# The cumulative diff — this is your primary source of truth
git diff <target>...<source>

# Commit history for narrative context
git log --oneline <target>...<source>

# See which files changed and how much
git diff --stat <target>...<source>
```

Read the diff carefully. When the diff is large, also read the key changed files directly to understand the broader context (what the file does, what surrounds the changed code).

**Focus on the end result, not the journey.** If a function was added in one commit and renamed in a later commit, describe only the final state. If a file was modified back and forth across commits, describe only the net change. The PR description should reflect the state of the world after merging — not the sequence of events that got there.

## Step 3: Write the title

Follow the same style as a good commit message title:

- **Present-tense imperative mood** ("Add", "Fix", "Remove" — not "Added", "Fixes")
- Keep it under 60 characters when possible
- **Plain language** — describe the change at a human level, avoid code references in the title (write "user authentication" not "`AuthService.ts`")
- Hint at the **why** when it adds clarity
- No conventional commit prefixes (`feat:`, `fix:`, etc.)
- No trailing period
- Sentence case

## Step 4: Write the description

Structure the description as a markdown codeblock with two sections:

### Summary

A short paragraph (2-4 sentences) that explains what this PR does and why. This is the "elevator pitch" — someone skimming PRs should understand the motivation and scope from this alone.

### Changes

A grouped, hierarchical bullet list of what changed. The structure is:

- **Top-level bullets** are logical groupings (by feature area, component, concern, etc.)
  - **Nested bullets** are the specific changes within that group, with enough technical detail to be useful during code review

Grouping guidelines:
- Group by logical theme, not by file. Multiple file changes that serve the same purpose go under one group.
- If there's only one logical group, still use the two-level structure — the top-level bullet names the area, nested bullets list the specifics.
- Order groups by importance or logical flow, not alphabetically.
- Use present-tense imperative mood for each bullet, matching the title style.

## Output format

Present the result as:

1. The **title** on its own line
2. A **markdown codeblock** containing the formatted description

Like this:

```
<the PR title>
```

````markdown
## Summary

<2-4 sentence summary of what and why>

## Changes

- <Group 1 name or theme>
  - <Specific change>
  - <Specific change with why, if the reason isn't obvious>
- <Group 2 name or theme>
  - <Specific change>
  - <Specific change>
````

## Examples

**Example 1** — Feature addition:

```
Add cursor-based pagination to the user list API
```

````markdown
## Summary

Replaces the unbounded query in the user list endpoint with cursor-based pagination. The previous implementation loaded all users into memory, causing OOM errors for organizations with large datasets.

## Changes

- User list endpoint pagination
  - Accept `cursor` and `limit` query parameters with a default limit of 50
  - Return `next_cursor` in the response body for client-side iteration
  - Replace unbounded SELECT with a keyset pagination query
- Database indexing
  - Add index on `users.created_at` to support cursor ordering without a full table scan
- Client SDK updates
  - Update `listUsers()` to accept pagination options and auto-paginate by default
  - Add `iterateUsers()` async generator for streaming large result sets
````

**Example 2** — Bug fix:

```
Fix dark mode toggle not persisting across page reloads
```

````markdown
## Summary

The dark mode toggle was resetting to light mode on every page reload because the component always initialized with the default value instead of reading the stored preference. This also adds cross-tab synchronization so changing the theme in one tab reflects immediately in others.

## Changes

- Theme persistence
  - Read saved preference from localStorage on component mount instead of hardcoding the default
  - Fall back to the system `prefers-color-scheme` value when no saved preference exists
- Cross-tab synchronization
  - Add a `storage` event listener to sync toggle state when the preference changes in another tab
- Theme tokens
  - Replace scattered hardcoded hex values with light/dark color tokens defined in theme config
````

**Example 3** — Refactor spanning multiple areas:

```
Extract shared validation logic into a reusable middleware
```

````markdown
## Summary

Consolidates duplicated request validation logic from five route handlers into a single middleware. This reduces code duplication and ensures consistent error response formatting across all API endpoints.

## Changes

- Validation middleware
  - Create `validateRequest` middleware that accepts a schema and returns 400 with structured errors on failure
  - Support both body and query parameter validation via a `source` option
- Route handler cleanup
  - Remove inline validation from user, project, team, billing, and settings route handlers
  - Wire each route to the shared middleware with its specific schema
- Error response format
  - Standardize all validation errors to return `{ errors: [{ field, message }] }` instead of the inconsistent formats each handler used previously
````

## What to leave out

- No emoji in the title or description
- Don't list every file that changed — group by logical concern
- Don't describe intermediate states or back-and-forth changes — only the net result
- Don't include commit hashes or refer to specific commits
- Don't add boilerplate like "This PR..." at the start of the summary — just state what it does directly
