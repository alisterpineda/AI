# Packages (Typst Universe)

Typst's package ecosystem lives at https://typst.app/universe. Packages are imported by name and pinned version.

## Why this needs care

Package APIs change between versions, and your training data is stale. The most common failure mode is calling a function with the signature from a version other than the one you imported.

**Rule: every time you use a `@preview/...` package, verify the import line works and the function signatures match the version you pinned. Do not write package code from memory.**

## Import syntax

```typst
#import "@preview/package-name:0.1.0"           // import as a module
#import "@preview/package-name:0.1.0": fn1, fn2 // selective
#import "@preview/package-name:0.1.0" as pkg    // namespaced
```

The version is required. There is no `@latest`; pin to a specific release.

## Workflow when adding a package

1. **Find the package on Typst Universe.** Search at https://typst.app/universe or web-search "typst <thing> package".
2. **Note the current version** from the package page. Use that exact version in the import.
3. **Read the package's own README or manual.** Most packages ship a `manual.pdf` or README on their Typst Universe page or GitHub. Don't write usage from memory.
4. **Verify the import compiles** before writing the rest of your code:

   ```bash
   scripts/probe.sh '"ok"' --prelude 'import "@preview/cetz:0.4.2"'
   ```

   (Raw equivalent on Typst 0.15+: `typst eval '{ import "@preview/cetz:0.4.2"; "ok" }'`.)

   If this fails with "package not found," the name or version is wrong.

5. **Use the smallest example from the package docs first.** Get one example rendering before adding your own logic on top.

## Frequently-needed packages

These are common asks. **Always check Typst Universe for the current version** — entries below are pointers, not pinned recommendations.

| Need | Package |
|---|---|
| Diagrams, plots, TikZ-style drawing | `@preview/cetz` |
| Slide presentations | `@preview/touying` |
| Code blocks with line numbers, highlights | `@preview/codly` |
| Algorithms / pseudocode | `@preview/algorithmic` or `@preview/algo` |
| Resume / CV templates | many; search Universe for the look you want |
| Chemistry notation | `@preview/alchemist` |
| Glossary / acronyms | `@preview/glossarium` |

For each, the API and version drift. Do not write calls like `cetz.draw(...)` from memory if you haven't verified the version supports that signature.

## Local imports (project-local files)

For project-local files without Typst Universe:

```typst
#import "./mylib.typ": helper
#include "./chapters/intro.typ"
```

Plain relative imports — no `@preview/` prefix. Useful for splitting large documents across files. `#import` brings in named bindings; `#include` inlines content.

## Caching

Typst caches downloaded packages under `$XDG_DATA_HOME/typst/packages/preview/` (or the platform equivalent). First import downloads; later compiles are offline. If a download fails, check the network and try again — there's no separate install step.

## When the import fails

- `package not found` → wrong name or version. Check Typst Universe.
- `failed to download` → network or stale cache. Retry; clear cache if it persists.
- `error in package` → version mismatch with current Typst (e.g. package built for 0.13 features missing in 0.12, or the reverse).

If you suspect version skew, ask the user which Typst version they're on (`typst --version`) and check the package page for a compatibility note.
