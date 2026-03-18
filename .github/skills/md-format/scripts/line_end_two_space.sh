#!/usr/bin/env sh
set -eu

usage() {
  cat <<-USAGE 1>&2
Usage: $0 INPUT_FILE OUTPUT_FILE

For each line in INPUT_FILE, normalize trailing spaces (full-width or half-width)
so that the resulting line ends with exactly two ASCII spaces, then write to
OUTPUT_FILE.
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

# Replace any trailing sequence of ASCII spaces and/or full-width spaces (U+3000)
# with exactly two ASCII spaces. The bracket contains an ASCII space and a
# literal full-width space character.
sed 's/[ 　]*$/  /' "$in" > "$out"

exit 0
