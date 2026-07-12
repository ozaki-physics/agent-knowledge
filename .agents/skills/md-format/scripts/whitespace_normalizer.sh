#!/usr/bin/env sh
set -eu

usage() {
  cat <<-USAGE 1>&2
Usage: $0 INPUT_FILE OUTPUT_FILE

Replace full-width spaces (U+3000) with ASCII spaces in INPUT_FILE and
write the result to OUTPUT_FILE.
USAGE
}

if [ "$#" -ne 2 ]; then
  usage
  exit 2
fi

in="$1"
out="$2"

if [ ! -f "$in" ]; then
  echo "Input file not found: $in" >&2
  exit 3
fi

# Replace full-width space (Japanese ideographic space U+3000) with ASCII space
sed 's/　/ /g' "$in" > "$out"

exit 0
