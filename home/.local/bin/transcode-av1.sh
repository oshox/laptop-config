#!/usr/bin/env bash
set -uo pipefail

ROOT="@HOME@/Downloads"
STATE="$HOME/.local/state/transcode-av1"
mkdir -p "$STATE"
LOG="$STATE/run.log"
DONE="$STATE/done.tsv"          # status <TAB> oldsize <TAB> newsize <TAB> path
touch "$DONE"

PRESET=7
CRF=30
MIN_SAVING=15                   # percent; user's rule
MIN_FREE_GIB=10                 # abort below this

log(){ printf '%s %s\n' "$(date '+%F %T')" "$*" | tee -a "$LOG"; }

# ---- Build work list: only inefficient codecs, skip anything already handled.
# Ordered by estimated bytes saved (descending) so space is reclaimed fastest.
build_manifest(){
  find "$ROOT" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' \
       -o -iname '*.wmv' -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.ts' \
       -o -iname '*.flv' -o -iname '*.mpg' -o -iname '*.mpeg' \) -print0 |
  while IFS= read -r -d '' f; do
    grep -Fq "	$f" "$DONE" && continue
    codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
            -of csv=p=0 "$f" 2>/dev/null)
    # hevc/av1/vp9 are already efficient -> cannot clear 15%; proven by measurement.
    case "$codec" in h264|mpeg4|mpeg2video|vp8|wmv3|vc1|msmpeg4v3) ;; *) continue ;; esac
    dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null)
    sz=$(stat -c%s "$f")
    awk -v s="$sz" -v d="${dur:-0}" -v p="$f" \
      'BEGIN{ est=s-(d*1.63e6/8); printf "%d\t%d\t%s\n", est, s, p }'
  done | sort -rn | cut -f2-
}

verify(){                       # $1=source $2=candidate
  local src="$1" out="$2" errs sd od
  errs=$(ffmpeg -nostdin -v error -i "$out" -f null - 2>&1 | head -3)
  [ -n "$errs" ] && { log "    decode errors: $errs"; return 1; }
  sd=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$src")
  od=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out")
  awk -v a="$sd" -v b="$od" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d<=1.5 || (a>0 && d/a<=0.01))}' \
    || { log "    duration mismatch: $sd vs $od"; return 1; }
  return 0
}

log "=== starting; $(build_manifest | wc -l) candidates ==="

build_manifest | while IFS=$'\t' read -r oldsz f; do
  free=$(df --output=avail -BG "$ROOT" | tail -1 | tr -dc '0-9')
  if [ "${free:-0}" -lt "$MIN_FREE_GIB" ]; then
    log "ABORT: only ${free}G free (floor ${MIN_FREE_GIB}G)"; exit 1
  fi

  base="${f%.*}"; ext="${f##*.}"
  case "${ext,,}" in mkv) oext=mkv ;; *) oext=mp4 ;; esac
  tmp="$(dirname "$f")/.$(basename "$base").av1tmp.$oext"
  rm -f "$tmp"

  log "[$(numfmt --to=iec "$oldsz")] $(basename "$f")"

  mp4flags=(); [ "$oext" = mp4 ] && mp4flags=(-movflags +faststart)
  if ! nice -n 10 ionice -c3 ffmpeg -nostdin -y -v error -i "$f" \
        -map 0:v:0 -map 0:a:0\? -map 0:s\? \
        -c:v libsvtav1 -preset "$PRESET" -crf "$CRF" -pix_fmt yuv420p \
        -c:a libopus -b:a 128k \
        -c:s copy -map_metadata 0 "${mp4flags[@]}" "$tmp" 2>>"$LOG"; then
    log "    ENCODE FAILED -> keeping original"
    rm -f "$tmp"
    printf 'ENCFAIL\t%s\t0\t%s\n' "$oldsz" "$f" >> "$DONE"
    continue
  fi

  newsz=$(stat -c%s "$tmp" 2>/dev/null || echo 0)
  pct=$(( newsz > 0 ? 100 - newsz*100/oldsz : 0 ))

  if [ "$pct" -ge "$MIN_SAVING" ] && verify "$f" "$tmp"; then
    touch -r "$f" "$tmp"
    chmod --reference="$f" "$tmp"
    mv -f "$tmp" "$base.$oext"
    [ "$base.$oext" != "$f" ] && rm -f "$f"      # container changed (e.g. .avi -> .mp4)
    log "    REPLACED  -${pct}%  $(numfmt --to=iec "$newsz")"
    printf 'REPLACED\t%s\t%s\t%s\n' "$oldsz" "$newsz" "$f" >> "$DONE"
  else
    rm -f "$tmp"
    log "    SKIPPED (only -${pct}%, under ${MIN_SAVING}% or failed verify)"
    printf 'SKIPPED\t%s\t%s\t%s\n' "$oldsz" "$newsz" "$f" >> "$DONE"
  fi
done

log "=== finished ==="
awk -F'\t' '$1=="REPLACED"{n++; s+=$2-$3} END{
  printf "replaced %d files, reclaimed %.2f GiB\n", n, s/1073741824 }' "$DONE" | tee -a "$LOG"
