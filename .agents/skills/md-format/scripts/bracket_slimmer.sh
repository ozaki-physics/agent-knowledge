#!/usr/bin/env sh
set -eu

usage() {
	cat <<-USAGE 1>&2
Usage: $0 INPUT_FILE OUTPUT_FILE

Replaces full-width parentheses （ and ） with half-width ( and ).
Each input line is processed and written to OUTPUT_FILE.
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

# Process the file line-by-line and replace various full-width brackets with half-width.
# Mapping included:
#  （ ） -> ( )
#  ｛ ｝ -> { }
#  ［ ］ -> [ ]
#  【 】 -> [ ]
#  〈 〉 -> < >
#  《 》 -> < >
#  ＜ ＞ -> < >
#  ｢ ｣ and 「 」 -> " " (double quotes)
#  『 』 -> (leave unchanged)
sed '
	s/（/(/g;
	s/）/)/g;
	s/｛/{/g;
	s/｝/}/g;
	s/［/[/g;
	s/］/]/g;
	s/【/[/g;
	s/】/]/g;
	s/〈/</g;
	s/〉/>/g;
	s/《/</g;
	s/》/>/g;
	s/＜/</g;
	s/＞/>/g;
	s/｢/"/g;
	s/｣/"/g;
	s/「/"/g;
	s/」/"/g
' "$in" > "$out"

exit 0
