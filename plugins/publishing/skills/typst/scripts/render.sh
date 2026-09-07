#!/usr/bin/env bash
# render.sh — compile a Typst document, snapshot its pages as PNG, and report.
#
# Usage:
#   render.sh FILE.typ [--ppi N] [--pages SPEC] [--strict] [--embedded-fonts-only]
#                      [--pdf [PATH]] [--root DIR] [--snapshots DIR]
#
#   --ppi N               PNG resolution (default 144; 200+ for fine detail)
#   --pages SPEC          render only these pages, e.g. "1" or "1,3-5"
#   --strict              exit 2 if the compile produced warnings
#   --embedded-fonts-only compile with --ignore-system-fonts to prove the document
#                         needs nothing beyond the fonts bundled with Typst
#   --pdf [PATH]          also write the PDF deliverable (default: next to FILE)
#   --root DIR            project root passed through to typst (for read()/#include)
#   --snapshots DIR       where to put snapshots; overrides $TYPST_SNAPSHOT_DIR
#
# Snapshots go to <snapshot root>/<stem>/<timestamp>/page-NN.png, so earlier
# renders survive for comparison. The root is, in order: --snapshots,
# $TYPST_SNAPSHOT_DIR, then $TMPDIR/typst-render. Agent harnesses that give the
# session a scratchpad directory don't expose it to scripts, so pass it here.
#
# Exit codes: 0 ok, 1 compile error or bad usage, 2 warnings under --strict.
set -uo pipefail

usage() { awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 1; }

file="" ppi=144 pages="" strict=0 pdf="" want_pdf=0 root="" snap_root=""
extra=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ppi) ppi="$2"; shift 2 ;;
    --pages) pages="$2"; shift 2 ;;
    --strict) strict=1; shift ;;
    --embedded-fonts-only) extra+=(--ignore-system-fonts); shift ;;
    --root) root="$2"; shift 2 ;;
    --snapshots) snap_root="$2"; shift 2 ;;
    --pdf)
      want_pdf=1; shift
      if [[ $# -gt 0 && "$1" != --* ]]; then pdf="$1"; shift; fi ;;
    -h|--help) usage ;;
    --*) echo "unknown flag: $1" >&2; usage ;;
    *) if [[ -z "$file" ]]; then file="$1"; shift; else echo "unexpected argument: $1" >&2; usage; fi ;;
  esac
done

[[ -n "$file" ]] || usage
[[ -f "$file" ]] || { echo "error: no such file: $file" >&2; exit 1; }
command -v typst >/dev/null || { echo "error: typst not found on PATH" >&2; exit 1; }
[[ -n "$root" ]] && extra+=(--root "$root")

stem="$(basename "${file%.typ}")"
[[ -n "$snap_root" ]] || snap_root="${TYPST_SNAPSHOT_DIR:-${TMPDIR:-/tmp}/typst-render}"
snap="$snap_root/$stem/$(date +%Y%m%d-%H%M%S)"
n=1; while [[ -e "$snap" ]]; do snap="$snap_root/$stem/$(date +%Y%m%d-%H%M%S)-$n"; n=$((n+1)); done
mkdir -p "$snap"

page_args=()
[[ -n "$pages" ]] && page_args+=(--pages "$pages")

# Compile PNG snapshot. Diagnostics go to a file so they can be reported whole.
diag="$snap/diagnostics.txt"
typst compile "$file" "$snap/page-{0p}.png" --ppi "$ppi" ${page_args[@]+"${page_args[@]}"} ${extra[@]+"${extra[@]}"} \
  --diagnostic-format human 2>"$diag"
rc=$?

if [[ $rc -ne 0 ]]; then
  echo "COMPILE FAILED ($file)"
  cat "$diag"
  exit 1
fi

count=$(ls "$snap"/page-*.png 2>/dev/null | wc -l | tr -d ' ')
warnings=$(grep -c '^warning:' "$diag" || true)

echo "Snapshot: $snap"
if [[ -n "$pages" ]]; then
  echo "Pages rendered: $count (subset: $pages)"
else
  echo "Pages: $count"
fi
for p in "$snap"/page-*.png; do echo "  $p"; done

if [[ $want_pdf -eq 1 ]]; then
  [[ -n "$pdf" ]] || pdf="${file%.typ}.pdf"
  if typst compile "$file" "$pdf" ${extra[@]+"${extra[@]}"} 2>>"$diag"; then
    echo "PDF: $pdf"
  else
    echo "PDF COMPILE FAILED ($pdf)"; cat "$diag"; exit 1
  fi
fi

if [[ "$warnings" -gt 0 ]]; then
  echo "Warnings: $warnings"
  cat "$diag"
  [[ $strict -eq 1 ]] && exit 2
else
  echo "Warnings: 0"
fi
exit 0
