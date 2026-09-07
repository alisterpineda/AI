// base.typ — neutral document defaults for any kind of document.
//
// Usage (copy this file beside your document, then at the top of it):
//
//   #import "base.typ": doc, title-block
//   #show: doc.with(paper: "us-letter", size: 10.5pt)
//
// Every default below is overridable with an ordinary set/show rule placed
// after the `#show: doc` line. Keep this file unmodified so it can be
// refreshed from the skill; put document-specific styling in the document.
//
// Fonts default to the faces bundled inside the Typst binary, so the output
// renders identically on every machine with no font installation.

// Greys shared by `doc` and `title-block`, so secondary text stays one colour.
#let faint = luma(120)   // page numbers, captions, metadata lines
#let muted = luma(90)    // subtitles

#let doc(
  paper: "us-letter",        // "us-letter" | "a4" | any Typst paper name
  margin: 1in,               // length, or a dictionary like (x: 0.8in, y: 1in)
  size: 10.5pt,              // body text size; everything else scales from it
  font: "Libertinus Serif",  // bundled with Typst
  mono: "DejaVu Sans Mono",  // bundled with Typst
  accent: none,              // colour for headings, rules, links; none = black
  page-numbers: auto,        // auto = only when the document exceeds one page
                             // true = always, false = never
  justify: false,            // ragged right by default; justify wide prose only
  lang: "en",
  body,
) = {
  let ink = if accent == none { black } else { accent }

  set page(
    paper: paper,
    margin: margin,
    footer: context {
      let total = counter(page).final().first()
      let show-number = page-numbers == true or (page-numbers == auto and total > 1)
      if show-number {
        // Honour a `set page(numbering: ...)` placed after `#show: doc`. As in
        // Typst's own footer, "current of total" is shown only when the
        // pattern has two counting symbols, e.g. "1 of 1".
        let fmt = page.numbering
        let num = if fmt == none { counter(page).display("1") }
          else if type(fmt) == str { counter(page).display(fmt, both: fmt.matches(regex("[1aAiI*]")).len() >= 2) }
          else { counter(page).display(fmt) }
        align(center, text(size: 0.85em, fill: faint, num))
      }
    },
  )

  set text(font: font, size: size, lang: lang)
  set par(leading: 0.6em, spacing: 1.1em, justify: justify)

  // Headings: hierarchy by size and weight, three usable levels.
  set heading(numbering: none)
  show heading: set text(fill: ink, weight: "bold")
  show heading.where(level: 1): set text(size: 1.44em)
  show heading.where(level: 1): set block(above: 1.6em, below: 0.7em)
  show heading.where(level: 2): set text(size: 1.2em)
  show heading.where(level: 2): set block(above: 1.4em, below: 0.6em)
  show heading.where(level: 3): set text(size: 1em)
  show heading.where(level: 3): set block(above: 1.2em, below: 0.5em)

  // Lists: tight, modest indent.
  set list(indent: 0.6em, body-indent: 0.5em, spacing: 0.55em)
  set enum(indent: 0.6em, body-indent: 0.5em, spacing: 0.55em)

  // Tables: a rule under the header and a rule at the bottom, nothing else.
  set table(
    inset: (x: 6pt, y: 5pt),
    stroke: (x, y) => if y == 0 { (bottom: 0.6pt + ink) } else { none },
  )
  // The bottom rule is a non-repeating footer row: a stroked wrapper block or
  // a trailing table.hline would repeat the rule at every page break. Tables
  // that bring their own footer or end with their own hline are left alone.
  show table: it => {
    let fields = it.fields()
    let children = fields.remove("children")
    let has-footer = children.any(c => c.func() == table.footer)
    let ends-with-line = children.len() > 0 and children.last().func() == table.hline
    if has-footer or ends-with-line { it } else {
      let cols = it.columns
      let n = if type(cols) == int { cols } else if type(cols) == array { cols.len() } else { 1 }
      let rule = table.footer(repeat: false, table.cell(colspan: n, inset: 0pt, stroke: (top: 0.6pt + ink), []))
      table(..fields, ..children, rule)
    }
  }
  show table.cell.where(y: 0): set text(weight: "bold")

  // Links: subtle underline, same ink as text unless an accent is set.
  show link: it => underline(offset: 1.5pt, stroke: 0.5pt + luma(150), text(fill: ink, it))

  // Code: monospace, slightly smaller; blocks get a quiet background.
  show raw: set text(font: mono, size: 0.9em)
  show raw.where(block: true): block.with(
    fill: luma(246), inset: 8pt, radius: 2pt, width: 100%,
  )

  // Figures and quotes.
  set figure(gap: 0.6em)
  show figure.caption: set text(size: 0.9em, fill: faint)
  set quote(block: true)
  show quote.where(block: true): set pad(left: 1.2em)

  body
}

// Title block: left-aligned title, optional subtitle and a metadata line
// (author, date, version). Use once, at the top of the document. Pass the
// same `accent` as `doc` to colour the title like the headings.
#let title-block(title, subtitle: none, meta: none, accent: none) = {
  block(below: 1.4em)[
    #text(size: 2em, weight: "bold", fill: if accent == none { black } else { accent })[#title]
    #if subtitle != none [
      #v(-0.6em)
      #text(size: 1.15em, fill: muted)[#subtitle]
    ]
    #if meta != none [
      #v(0.1em)
      #text(size: 0.9em, fill: faint)[#meta]
    ]
  ]
}
