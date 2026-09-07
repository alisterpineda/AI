#!/usr/bin/env bash
# probe.sh — evaluate a Typst expression without creating scratch files.
#
# Usage:
#   probe.sh 'EXPR' [--prelude 'CODE'] [--in FILE.typ]
#
#   EXPR       a Typst code-mode expression, e.g. '(1, 2, 3).sum()'
#   --prelude  code-mode statements evaluated before EXPR, separated by ';'
#              e.g. 'import "@preview/cetz:0.4.2"' or 'let x = 41'
#   --in FILE  evaluate in the context of a compiled document so EXPR can
#              introspect it, e.g. 'query(heading).map(h => h.body)'
#              (Typst 0.15+ only)
#
# Prints the value as JSON. Probe values (numbers, strings, arrays, dicts,
# booleans), not layout: content serializes as a syntax tree, not a picture.
# For "does this look right?" questions, render instead.
#
# Uses `typst eval` (Typst 0.15+) and falls back to the `typst query`
# metadata trick on older versions.
#
# Examples:
#   probe.sh '(1, 2, 3).map(x => x * 2)'
#   probe.sh 'type((a: 1))'
#   probe.sh '"ok"' --prelude 'import "@preview/cetz:0.4.2"'   # does the import resolve?
#   probe.sh 'x + 1' --prelude 'let x = 41'
#   probe.sh 'query(heading).len()' --in report.typ
set -uo pipefail

usage() { awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 1; }

expr="" prelude="" infile=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prelude) prelude="$2"; shift 2 ;;
    --in) infile="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) if [[ -z "$expr" ]]; then expr="$1"; shift; else expr="$expr $1"; shift; fi ;;
  esac
done
[[ -n "$expr" ]] || usage
command -v typst >/dev/null || { echo "error: typst not found on PATH" >&2; exit 1; }

# Wrap prelude + expression in one code block so both paths share semantics.
if [[ -n "$prelude" ]]; then code="{ $prelude; $expr }"; else code="$expr"; fi

if typst eval --help >/dev/null 2>&1; then
  if [[ -n "$infile" ]]; then
    typst eval --in "$infile" "$code"
  else
    typst eval "$code"
  fi
else
  [[ -n "$infile" ]] && { echo "error: --in requires Typst 0.15 or newer (typst eval)" >&2; exit 1; }
  printf '#metadata(%s) <probe>\n' "$code" | typst query - "<probe>" --field value --one
fi
