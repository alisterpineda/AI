# Syntax pitfalls

The traps LLMs hit most often in Typst. Read this when you see compile errors mentioning "expected ...", or before writing non-trivial markup.

## Three modes: markup, code, math

Typst has three contexts, and the rules for `#`, `[]`, `()`, `{}` differ in each.

- **Markup mode** — top of a `.typ` file, inside content blocks `[...]`. Plain text by default; `#expr` switches to code temporarily.
- **Code mode** — inside `{...}`, after `#`, inside function arguments. Plain identifiers are variables; you use Typst's expression syntax.
- **Math mode** — inside `$...$`. Plain identifiers become symbols; `*`, `_`, `^` have math meanings.

Knowing which mode you're in tells you whether to use `#`, whether `*bold*` means bold or multiplication, and whether `(...)` is an array or grouping.

## Hash usage decision tree

- Function call in markup (top level or `[...]`)? → `#fn(...)` or `#fn[...]`
- Function call inside `{...}` or another function's arguments? → no `#`
- Reference a variable in markup? → `#name`
- Sub-expression inside markup? → `#(expr)`

```typst
#let n = 42
The answer is #n.                  // ✓
The answer is n.                   // ✗ — renders the letter n
The answer is #(n + 1).            // ✓ wrap sub-expressions in parens
#emph[The answer is #n.]           // ✓ markup inside content
{ let x = 1; x + 1 }               // ✗ — top-level needs leading #
#{ let x = 1; x + 1 }              // ✓
```

## Content `[]` vs code `{}` vs array `()`

- `[...]` — content block. Contains markup. Pass to functions that expect content.
- `{...}` — code block. Contains expressions. Returns the last expression's value.
- `(...)` — array, dictionary, or grouped expression depending on contents.

```typst
#let greeting = [Hello]            // content
#let n = { let x = 2; x * 3 }      // code; n = 6
#let xs = (1, 2, 3)                // array
#let d = (key: "value")            // dict
#let group = (1 + 2) * 3           // grouped expression
```

Array vs dict disambiguation: an empty `()` is an empty array; an empty dict is `(:)`.

## Show rules: transform vs configure

```typst
// Configure: apply a set rule only to matches
#show heading: set text(font: "Inter")

// Transform: take the element, return new content
#show heading: it => block(fill: aqua, inset: 6pt, it.body)
```

`#show selector: fn` applies `fn` to each match. `#show selector: set ...` is shorthand for "this set rule, but only for matches."

## Selectors

`.where(...)` narrows by field; combine with `or` if needed.

```typst
#show heading.where(level: 1): set text(size: 24pt)
#show heading.where(level: 2): set text(size: 18pt)
#show regex("[A-Z]{3,}"): set text(weight: "bold")   // 3+ capitals
#show "Typst": name => box(stroke: blue, name)        // literal string match
```

## Common error → cause map

| Error message contains | Likely cause |
|---|---|
| `expected expression, found ...` | Missing `#` in markup |
| `expected content, found ...` | Used code where content was needed; wrap in `[...]` or `#{...}` |
| `unknown variable: X` | Typo, or used `X` where `#X` was needed, or missing import |
| `unexpected ]` | Mismatched brackets, often after a content block |
| `expected closing brace` | Unclosed `{`, `[`, or `(` somewhere earlier |
| `unknown font family` | Font not installed; warning only, falls back automatically |
| `package not found` | Wrong name or version in `@preview/name:X.Y.Z` |
| `type X has no method Y` | Method name typo or wrong receiver type |

## Strings and raw

````typst
"plain string"                     // double quotes only; no single-quote strings
"line\nbreak"                      // escapes work
`inline raw`                       // raw inline, no interpolation
```text
multi-line raw block
```
````

## Function definitions

```typst
#let note(body, color: yellow) = {
  block(fill: color, inset: 8pt, radius: 4pt, body)
}

#note[A note in default yellow.]
#note(color: aqua)[A blue note.]
```

Trailing-content shorthand: `#fn[...]` passes `[...]` as the last positional argument.

## Labels and references

```typst
= Introduction <intro>             // label immediately after element

See @intro for context.            // reference; formatted per #set heading(numbering: ...)
```

Forgotten labels are the #1 cause of silent cross-reference failures. Put `<name>` directly after the labeled element with no blank line between them.

## Math mode gotchas

- Display math needs whitespace inside the `$...$`: `$ x^2 $` displays, `$x^2$` is inline.
- Multi-letter identifiers in math are functions/variables, not products of single letters. Use a space or `dot` for multiplication: `$a b$` shows `ab`, `$"ab"$` shows the string "ab".
- Numbers in math just work: `$2x + 3$`.
- Greek letters: `$alpha$`, `$Sigma$`. The `sym.` namespace has the full table; just typing the name usually works.
