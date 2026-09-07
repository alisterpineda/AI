---
name: typst
description: Produce polished, print-ready PDF documents with Typst — resumes, letters, memos, reports, one-pagers, handouts — through a compile → render → inspect loop with conservative design defaults. Use whenever the user asks to create, edit, style, debug, render, or compile a Typst document or any .typ file, or wants a well-typeset PDF of something, even phrased casually ("make me a PDF", "typeset this", "fix this .typ", "make it look nicer"). Ships a neutral base document, design principles, and scripts that make rendering and probing deterministic.
compatibility: Requires the typst CLI on PATH (0.15 or newer preferred; 0.13+ works via the scripts' fallbacks). Helper scripts are Bash (macOS/Linux); references/compile-and-verify.md lists the raw commands for hosts without a shell.
---

# Typst Documents

Goal: a document that is verified correct *and* looks deliberate — not Typst that merely compiles. The compiler is ground truth for correctness; your own eyes on the rendered pages are ground truth for appearance.

Typst is young and moves fast; training data is stale. **Trust `typst compile`, the scripts, and the current docs at https://typst.app/docs over memory.** When unsure, probe.

Paths below are relative to this skill's directory.

## Step 1: Confirm the toolchain

```bash
typst --version
```

If `typst` isn't installed, stop and tell the user — there is no useful iteration without a compiler. Note the version; features differ across releases.

## Step 2: Start from the base

For a new document, copy `assets/base.typ` beside it and open the document with:

```typst
#import "base.typ": doc, title-block
#show: doc.with(paper: "us-letter", size: 10.5pt)
```

`doc` sets page, text, paragraph, heading, list, table, link, code, and figure defaults according to `references/design.md`. Its parameters: `paper`, `margin`, `size`, `font`, `mono`, `accent` (none by default), `page-numbers` (auto: only past one page), `justify`, `lang`. Override anything afterwards with ordinary `set`/`show` rules in the document. Leave `base.typ` itself unmodified so it can be refreshed from the skill.

When editing an existing document, or when the project already has its own styling, respect what's there rather than importing the base.

Read `references/design.md` once before writing. The principles in brief:

- Hierarchy by size and weight; three heading levels at most, each ~1.2× the last.
- Body 10–11pt, leading ~0.6em, margins ~1in, 60–90 characters per line.
- Black text, at most one muted accent colour for structure, grey for secondary detail.
- Fonts bundled with Typst (Libertinus Serif, DejaVu Sans Mono) unless the user asks otherwise, so output is identical everywhere.
- Spacing from `set` rules on a consistent scale, not scattered `#v()`. Whitespace before rules, rules before boxes.
- Tables: header rule and bottom rule only; numbers right-aligned.
- To fit a page: cut content first, never shrink below 9pt.

## Step 3: Write, then render — every time

After any edit:

```bash
scripts/render.sh file.typ            # add --ppi 200 for fine detail, --pages 1,3 for a subset
```

It compiles, snapshots every page to PNG in a timestamped directory outside the working tree, and prints the paths, page count, and warnings. If it prints `COMPILE FAILED`, fix at the exact `file:line:col` it shows and rerun. **Do not claim success without a clean render.**

Then **view every PNG it listed** with your image-reading capability and check:

- Visual order is clear: title, sections, body.
- Nothing overflows or crowds a margin; no heading orphaned at a page bottom.
- Spacing is even; same-level headings have identical space around them.
- Tables fit, numbers align right, units are consistent.
- Fonts are the intended ones (no missing-glyph boxes, no fallback faces).
- The page would survive a black-and-white photocopy.

Loop until the render matches intent. On documents longer than a few pages, render everything on the first pass and again before finalizing; in between, pass `--pages` for the pages you changed (plus their neighbours, since edits reflow) rather than re-viewing every page. Snapshots land in a timestamped directory under the temp dir by default. If your harness gave you a session scratchpad directory, use it instead: pass `--snapshots "<scratchpad>/typst-render"` or export `TYPST_SNAPSHOT_DIR` once. Scripts can't discover the scratchpad on their own; only you know the path.

Defer to the user only when the question is genuinely subjective (colour, font feel, copy), they asked to review, the document is too long to sample usefully, or you cannot ingest images.

## Step 4: Finalize the deliverable

```bash
scripts/render.sh file.typ --pdf --strict      # --pdf out.pdf to choose where it goes
```

This renders the full document once more and writes the PDF in the same run, so it can never be stale, and under `--strict` withholds the PDF when the compile produced warnings (e.g. font fallback) that would silently degrade it. `--pdf` cannot be combined with `--pages`. Add `--embedded-fonts-only` when the document must render identically on other machines. Report the PDF path and page count. Leave no PNGs in the working tree.

## Step 5: Probe when uncertain about runtime behaviour

Don't write scratch files to test an expression:

```bash
scripts/probe.sh '(1, 2, 3).sum()'                                   # → 6
scripts/probe.sh '"ok"' --prelude 'import "@preview/cetz:0.4.2"'      # does the import resolve?
scripts/probe.sh 'query(heading).len()' --in file.typ                  # introspect a compiled document
```

## The four traps you will hit

### 1. `#` invokes code inside markup, never inside code

```typst
This is #emph[important].                  // ✓ markup → code needs #
#image("logo.png", width: 50%)             // ✓ args are already code: no #
#figure(image("photo.jpg"))                // ✓
#figure(#image("photo.jpg"))               // ✗ extra # inside code
```

### 2. Arrays use parentheses; brackets are content

```typst
#let xs = (1, 2, 3)        // ✓ array        #let xs = [1, 2, 3]   // ✗ content
#let one = (1,)            // ✓ singleton needs the trailing comma
xs.at(0)                   // ✓ index        xs[0]                 // ✗ content block
```

### 3. `set` configures, `show` transforms

```typst
#set heading(numbering: "1.")                        // defaults for every heading
#show heading.where(level: 1): set text(size: 24pt)  // narrowed set rule
#show "Typst": name => box(stroke: blue, name)       // replace matches
```

### 4. No LaTeX

No `\section`, `\textbf`, `\begin{tabular}`. `= Heading`, `*bold*`, `_emph_`, `#table(...)`, `#figure(...)`. A backslash command is a sign to look up the Typst equivalent.

Special characters in prose need escaping: `\~` (bare `~` is a non-breaking space), `\#`, `\$`, `\@`, `\*`, `\_`. Text in backticks is raw and needs none.

## References

- Appearance decisions, per-document-kind parameters, the visual checklist → `references/design.md`
- Compile errors about hash, brackets, "expected ..." → `references/syntax-pitfalls.md`
- Script flags, raw commands, reading diagnostics, probing, querying → `references/compile-and-verify.md`
- Importing from Typst Universe (`@preview/...`) → `references/packages.md`

For anything else (advanced math, CeTZ drawings, Touying slides) consult the current docs at https://typst.app/docs or https://typst.app/universe; don't answer from memory.

## Formatting (optional)

If `typstyle` is installed, `typstyle -i file.typ` after edits. Don't reformat files you didn't touch.

## What to leave out

- Don't claim a document is done without a clean render you looked at.
- Don't invent layout devices the design reference argues against (extra colours, boxes everywhere, shrunken type) to solve a fit problem.
- Don't write `@preview` package usage from memory; versions and APIs drift.
- Don't create files just to test an expression; probe instead.
- Don't leave render artifacts in the working tree.
