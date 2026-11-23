#!/bin/sh
printf '\033c\033]0;%s\a' UltimateDCCFighting
base_path="$(dirname "$(realpath "$0")")"
"$base_path/ultimate_dcc_fighting.x86_64" "$@"
