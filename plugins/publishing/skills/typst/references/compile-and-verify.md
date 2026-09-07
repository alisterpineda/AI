# Compile and verify

The compile → render → inspect loop, the scripts that make it deterministic, and the raw commands behind them for hosts without a shell.

## The loop

1. Edit the `.typ` file.
2. `scripts/render.sh file.typ` — compiles, snapshots every page to PNG, prints the snapshot directory, page count, file list, and warnings.
3. If it printed `COMPILE FAILED`, read the diagnostic, fix at the exact `file:line:col`, go to 2.
4. View every PNG it listed with your image-reading capability. Check layout against intent and against `design.md`'s checklist. If anything is off, go to 1.
5. When the render is right, `scripts/render.sh file.typ --pdf [PATH] --strict` to write the deliverable from the same compile that produced the verified render.

Exit codes from `render.sh`: `0` success, `1` compile error or bad usage, `2` warnings under `--strict`.

## render.sh

```
scripts/render.sh FILE.typ [--ppi N] [--pages SPEC] [--strict] [--embedded-fonts-only] [--pdf [PATH]] [--root DIR] [--snapshots DIR]
```

- `--ppi 144` is the default and right for layout review. `--ppi 200`+ for small text, kerning, math details. Higher PPI costs more context per image.
- `--pages 1` or `--pages 1,3-5` renders a subset. Use it on long documents when only some pages are in scope; the report then says `(subset: ...)` so you know the count isn't the total.
- `--strict` turns warnings into a failing exit. Run it once before delivering: a font-fallback or unresolved-reference warning means the PDF isn't what you think it is.
- `--embedded-fonts-only` passes `--ignore-system-fonts`, proving the document renders with only the fonts bundled in Typst. Use it when reproducibility across machines matters.
- `--pdf` writes the deliverable next to the source (or at `PATH`) in the same run. Prefer this over a separate `typst compile` so the PDF can never lag behind the render you inspected.
- `--root DIR` is passed through to Typst when the document reads or includes files outside its own directory.
- `--snapshots DIR` sets the snapshot root for this call (see below).

### Where snapshots go

`<root>/<stem>/<timestamp>/page-NN.png`, where the root is the first of `--snapshots DIR`, `$TYPST_SNAPSHOT_DIR`, or `$TMPDIR/typst-render`. Each render lands in its own timestamped directory, so earlier snapshots survive for before/after comparison and nothing pollutes the working tree or `git status`.

No agent harness (Claude Code, Copilot, Codex) exposes its session scratchpad to scripts through an environment variable, but the harness usually tells *you* the path in its instructions. When it does, pass it: `--snapshots "<scratchpad>/typst-render"`, or export `TYPST_SNAPSHOT_DIR` once so every call in the session uses it. When it doesn't, the temp-dir default is fine.

Only deliverables (the PDF the user asked for) belong in the working tree.

### Raw equivalents

For a host without Bash, the script is these commands:

```bash
typst compile file.typ "out/page-{0p}.png" --ppi 144 [--pages 1,3-5]   # snapshot
typst compile file.typ [out.pdf]                                        # deliverable
typst compile file.typ --ignore-system-fonts                            # embedded fonts only
```

Always keep `{p}` or `{0p}` in a PNG output path: a one-page document can spill to two after an edit, and a plain `out.png` then fails with "cannot export multiple images without a page number template."

## Reading diagnostics

```
error: expected content, found function
  ┌─ paper.typ:14:3
   │
14 │   #figure(#image("plot.png"))
   │           ^^^^^^^^^^^^^^^^^^^
```

- The `^^^` span and `line:col` are exact. Fix there.
- "Expected X, found Y" almost always means a mode mix-up: add or remove `#`, wrap in `[...]`, or switch `()`/`[]`. See `syntax-pitfalls.md`.
- Warnings don't fail the build but print to stderr. Font fallback is usually cosmetic and still worth fixing (it breaks reproducibility); an unresolved reference (`@label`) means a broken link in the PDF.

## probe.sh

Answer "what does Typst do with this expression?" without scratch files:

```
scripts/probe.sh 'EXPR' [--prelude 'CODE'] [--in FILE.typ]
```

```bash
scripts/probe.sh '(1, 2, 3).map(x => x * 2)'                        # → [2,4,6]
scripts/probe.sh 'type((a: 1))'                                     # → "dictionary"
scripts/probe.sh 'range(1, 5).fold(0, (a, b) => a + b)'             # → 10
scripts/probe.sh '"ok"' --prelude 'import "@preview/cetz:0.4.2"'    # import resolves? (else a compile error)
scripts/probe.sh 'x + 1' --prelude 'let x = 41'                     # bindings via prelude (code mode, `;`-separated)
scripts/probe.sh 'query(heading).map(h => h.body)' --in report.typ  # introspect a document (0.15+)
```

Output is the value as JSON. Probe values (numbers, strings, arrays, dictionaries, booleans), not content: content serializes as a syntax tree. Layout questions are answered by rendering.

The script uses `typst eval` (Typst 0.15+) and falls back to the `typst query` metadata trick on older versions, which 0.15 deprecates:

```bash
typst eval 'EXPR'                                                         # 0.15+
printf '#metadata(EXPR) <p>\n' | typst query - "<p>" --field value --one  # ≤ 0.14
```

## Introspecting a compiled document

Label elements and read them back without parsing the source:

```typst
The total is #metadata(42) <total>.
```

```bash
scripts/probe.sh 'query(<total>).first().value' --in file.typ    # → 42
typst query file.typ "<total>" --field value --one               # ≤ 0.14 equivalent
```

## Watch mode

When a human is iterating live with the PDF open, `typst watch file.typ` recompiles on save. Not useful for headless agent iteration; use the render script.
