#!/usr/bin/bash
# Copy home/ into a target directory (default $HOME), filling in the
# @PLACEHOLDERS@ left by scrub.sed. Values come from the environment or
# ~/.config/laptop-config.env:
#   GIT_NAME=...   GIT_EMAIL=...   WTTR_LOCATION=<zip or city>
# Usage: install.sh [--dry-run] [target-dir]
set -euo pipefail
cd "$(dirname "$0")"

dry=()
[[ ${1:-} == --dry-run ]] && { dry=(--dry-run); shift; }
target=${1:-$HOME}

env_file=~/.config/laptop-config.env
[[ -f $env_file ]] && . "$env_file"
: "${GIT_NAME:=$(id -un)}" "${GIT_EMAIL:=$(id -un)@localhost}" "${WTTR_LOCATION:=}"

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -a home/. "$stage/"
grep -rIl '' "$stage" | xargs -r -d '\n' sed -i \
    -e "s#@HOME@#$target#g" \
    -e "s#@USER@#$(id -un)#g" \
    -e "s#@GIT_NAME@#$GIT_NAME#g" \
    -e "s#@GIT_EMAIL@#$GIT_EMAIL#g" \
    -e "s#@WTTR_LOCATION@#$WTTR_LOCATION#g"

rsync -a --backup --suffix=.pre-install -v "${dry[@]}" "$stage/" "$target/"
