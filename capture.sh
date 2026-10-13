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
grep -rIl '' home/ | xargs -r -d '\n' sed -i -f scrub.sed

./pii-check.sh
