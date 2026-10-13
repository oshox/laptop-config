#!/usr/bin/bash
# Copy the paths in include.txt from $HOME into home/, scrubbing personal
# identifiers (scrub.sed), then run pii-check.sh.
set -euo pipefail
cd "$(dirname "$0")"

rsync -a -r --delete-excluded \
    --files-from=<(grep -vE '^\s*(#|$)' include.txt) \
    --exclude-from=<(grep -vE '^\s*(#|$)' exclude.txt) \
    "$HOME/" home/

# Strip EXIF from images, then scrub text files.
find home -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
    -exec exiv2 -q rm {} +
# Absolute symlinks into $HOME (e.g. systemd .wants links) -> relative.
while IFS= read -r -d '' link; do
    ln -sfr "home/$(readlink "$link" | sed "s#^$HOME/##")" "$link"
done < <(find home -type l -lname "$HOME/*" -print0)
grep -rIl '' home/ | xargs -r -d '\n' sed -i -f scrub.sed

./pii-check.sh
