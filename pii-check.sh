#!/usr/bin/bash
# Fails if anything identifying or secret-looking is left in home/.
# Extra private terms (real name, email, city, ...) can be listed one per line
# in ~/.config/laptop-config.pii (never committed).
set -uo pipefail
cd "$(dirname "$0")"

patterns=(
    'oshox'
    '[A-Za-z0-9._%+-]+@(gmail|yahoo|outlook|hotmail|proton)\.[a-z]+'
    '(ghp|gho|github_pat)_[A-Za-z0-9_]{20,}'
    'sk-[A-Za-z0-9-]{20,}'
    'AKIA[0-9A-Z]{16}'
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
    '"password": *"[^"]+"'
    '\b(192\.168|10\.[0-9]+)\.[0-9]+\.[0-9]+\b'
)
extra=~/.config/laptop-config.pii
[[ -f $extra ]] && mapfile -t -O "${#patterns[@]}" patterns < <(grep -v '^\s*$' "$extra")

status=0
for p in "${patterns[@]}"; do
    if grep -rInEi -- "$p" home/ ; then status=1; fi
done

while IFS= read -r -d '' img; do
    if exiv2 -q -pa "$img" 2>/dev/null | grep -q . || exiv2 -q -px "$img" 2>/dev/null | grep -q .; then
        echo "metadata in $img (run: exiv2 rm '$img')"; status=1
    fi
done < <(find home -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)

if (( status )); then echo "pii-check: FAILED" >&2; else echo "pii-check: ok"; fi
exit $status
