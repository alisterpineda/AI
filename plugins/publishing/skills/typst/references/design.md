# Design principles

Conservative defaults that make any document look deliberate: a resume, a letter, a report, a memo, a handout. `assets/base.typ` encodes these; this file explains them so you can adapt rather than copy. Read once before writing a document, then apply.

The governing idea: **restraint reads as quality.** Nearly every amateur document fails by adding, not by omitting. Fewer sizes, fewer colours, fewer rules, more whitespace.

## Type

- **Body size 10–11pt** for letter/A4. 10pt for dense one-pagers (resume, cheat sheet), 11pt for prose people read at length. Never below 9pt, even to fit a page (see *Fitting to a page*).
- **Leading 0.55–0.65em** (`set par(leading: 0.6em)`). Tighter for short lines, looser for long ones.
- **Paragraph spacing ≈ 1 line** (`set par(spacing: 1.1em)`) with no first-line indent, or a first-line indent with no extra spacing. Not both.
- **One typeface for text, one for code.** Two families maximum. A single family with weight and size variation is enough for almost everything.

## Fonts

Default to the fonts bundled inside the Typst binary, so output is identical on every machine and needs no installation:

| Role | Face |
|---|---|
| Body, headings | Libertinus Serif |
| Alternative body (LaTeX-like) | New Computer Modern |
| Math | New Computer Modern Math (used automatically) |
| Code | DejaVu Sans Mono |

Use a system font only when the user asks for one, and then:

- Always give a fallback list: `set text(font: ("Helvetica Neue", "Libertinus Serif"))`.
- Say in your close-out that the document depends on an installed font.
- Verify with `scripts/render.sh file.typ --embedded-fonts-only` that the document at least still compiles without it (a font warning is the signal).

`typst fonts` lists what's available; `typst fonts --ignore-system-fonts` lists only the bundled ones.

## Measure and margins

- Aim for **60–90 characters per line** of body text. Long-form prose is most readable near 65; reference-style documents tolerate 90.
- **Margins of 1in** on letter/A4 for prose. Dense one-pagers can go to 0.6–0.75in. Below 0.5in looks cramped and many printers clip it.
- Prefer widening margins or raising the type size over stretching lines across the page. A 6.5in line at 10pt is already ~95 characters.
- Two columns only for genuinely list-like content (cheat sheets, glossaries). Body prose in columns needs a smaller measure and careful balancing; avoid unless asked.

## Hierarchy

- Express hierarchy with **size and weight**, not colour, not underlines, not all-caps by default.
- **Three heading levels** are the practical maximum. Each step about 1.2× the previous: body 1em, H3 1em bold, H2 1.2em, H1 1.44em, title ~2em.
- More space **above** a heading than below it (`set block(above: 1.6em, below: 0.7em)` for H1), so headings attach to the text they introduce.
- Numbering only for documents people will cite by section (specs, long reports). Off by default.
- Small caps or tracked uppercase for a section label are fine as a *single* device (resumes use it well). Not on every level.

## Spacing rhythm

- Set spacing once with `set par`, `set block`, `set list`, and heading show-set rules. Then **don't sprinkle `#v()`**. Manual spacers are for the one or two places a rule can't express (a title block, a signature line).
- Keep vertical spacing on a scale derived from the line: 0.5em, 1em, 1.5em, 2em. Arbitrary values like `7pt` and `13pt` produce visible unevenness.
- Lists tight: `set list(indent: 0.6em, body-indent: 0.5em, spacing: 0.55em)`. Loose lists only when items are multi-sentence.

## Colour

- **Black text on white.** Body text is never coloured.
- **At most one accent colour**, used for structure only: headings, rules, link underlines. Muted and dark (navy, oxblood, forest green) prints and photocopies better than saturated hues.
- Grey (`luma(90)`–`luma(140)`) for secondary information: dates, captions, page numbers, metadata lines.
- Filled boxes and tinted backgrounds are strong devices; one kind per document (e.g. a single callout style), or none.

## Rules, boxes, and whitespace

- Whitespace separates first. A rule is a second resort. A box is a last resort.
- One horizontal rule under the top-level heading is a classic device; rules under *every* heading are noise.
- Rules are thin: 0.5–0.8pt. Never full-width 2pt bars.
- For a thematic break in prose, use `#divider()` (Typst 0.15+) and style it once with `show divider: set line(stroke: ...)`; keep `line()` for drawing inside layouts like headers and title blocks.
- If you find yourself drawing a box to make something stand out, try a heading or bold lead-in first.

## Tables

- `stroke: none` as the baseline, then a rule under the header row and one at the bottom. No vertical rules, no full grid.
- `inset: (x: 6pt, y: 5pt)`. Header row bold.
- Right-align numbers, left-align text: `align: (left, right, right)`. Keep the same unit and precision down a column.
- Column widths: `auto` for short labels, `1fr` for the column that should absorb space. Don't let a table exceed the text width; wrap it in `figure` when it needs a caption or a reference.

## Alignment

- **Left-aligned, ragged right** by default. Justify only wide prose measures (≥ 75 characters), and turn hyphenation on when you do (`set par(justify: true)`; Typst hyphenates automatically when justifying with `lang` set).
- Centre only titles and, sparingly, short standalone lines. Never centre body text or lists.
- Vertical alignment tricks (`#h(1fr)` to push a date to the right margin) are the right way to do two-sided lines in resumes and letters.

## Page furniture

- **Page numbers** on any document longer than one page. Centred or outer-margin, small, grey. `base.typ` does this automatically.
- Running headers only for long documents (reports > ~8 pages) where the reader needs orientation; keep them to the document title or section, small and grey.
- No decorative footers. A confidentiality line or a version stamp is content, not decoration, and belongs in the footer when required.

## Fitting to a page

When a document must fit a fixed length (a one-page resume, a two-page brief) and doesn't:

1. **Cut content.** This is almost always the right answer and produces the better document.
2. Tighten leading (to 0.55em) and paragraph spacing (to 0.9em).
3. Reduce margins, not below 0.6in.
4. Reduce body size, not below 9pt.

Never go straight to step 4. Text that shrank to fit reads as exactly that.

## Notes by document kind

These are starting parameters for `doc.with(...)`, not templates.

| Kind | Size | Margins | Notes |
|---|---|---|---|
| Resume, one-pager | 10pt | 0.6–0.75in | Section labels as small tracked uppercase; `#h(1fr)` for right-aligned dates; page-numbers: false |
| Letter, memo | 11pt | 1in | Address block and date at top; generous space before the signature; no headings beyond one level |
| Report, proposal | 10.5–11pt | 1in | Title block, page numbers; numbered headings if it will be cited; outline (`#outline()`) only past ~8 pages |
| Handout, cheat sheet | 9–10pt | 0.5–0.6in | Two columns acceptable; one callout style; keep every item scannable |
| Slides, posters | — | — | Different medium; use a Universe package (see `packages.md`) rather than page tricks |

## Verification checklist for appearance

After every render, look at the pages and ask:

- Is there a clear visual order: title, sections, body, in that priority?
- Does anything overflow or crowd a margin? Are there orphan headings at the bottom of a page? (`set block(sticky: true)` on headings or `pagebreak(weak: true)` fixes them.)
- Is spacing even? Two headings at the same level should have identical space around them.
- Is there more than one accent colour, or more than two typefaces? Remove one.
- Are numbers in tables aligned on the right? Are units consistent?
- Would the page survive a black-and-white photocopy?
