# This script parses the fish_history file in a very crud way and generates the
# equivalent ZSH history in the extended format.
# Ideally, we'd use something like `yq` to process the fish history file with
# `jq`, but `yq` fails to parse `cmd` values that contain a column character.

FISH_HISTORY_FILE=${1:-~/.local/share/fish/fish_history}

while mapfile -t -n 2 ary && ((${#ary[@]}))
do
  cmd=$(echo "${ary[0]}" | sed 's/^- cmd: \(.*\)/\1/')
  timestamp=$(echo "${ary[1]}" | sed 's/^  when: \(.*\)/\1/')
  echo ": $timestamp:0;$cmd"
done < <(sed '/^    -/d;/  paths:/d' $FISH_HISTORY_FILE)
