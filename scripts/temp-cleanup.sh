#!/usr/bin/env bash
# Temp paths for install.sh, sourced from it (like skill-allowlists.sh).
#
# A temp file or directory is created with make_temp, which also registers it,
# and a single EXIT trap running cleanup_temp_paths removes everything that is
# registered. One trap per path does not work: a second `trap ... EXIT` replaces
# the first, so only the last path set was ever cleaned up and every install left
# its clone directories behind in $TMPDIR. install.sh therefore sets exactly one
# EXIT trap, and the one other place that changes it (the tools menu, which has
# to restore the terminal on exit) runs cleanup_temp_paths too and puts the
# plain trap back when it is done. tests/temp-cleanup.test.sh enforces both.

_MY_CLAUDE_TEMP_PATHS=()

# make_temp <var> [mktemp flags]: create a temp file (a directory with -d) under
# $TMPDIR, register it for removal, and store its path in <var>.
#
# Call it as a command, never as $(make_temp ...): a subshell would lose the
# registration. BSD/macOS mktemp ignores $TMPDIR when it is given no template,
# so one is spelled out; if that fails (an unusable $TMPDIR) the plain mktemp
# default is used instead.
make_temp() {
  local _var="$1" _dir _made
  shift
  _dir="${TMPDIR:-/tmp}"
  _made=$(mktemp "$@" "${_dir%/}/my-claude.XXXXXX" 2>/dev/null || mktemp "$@") || return 1
  _MY_CLAUDE_TEMP_PATHS+=("$_made")
  printf -v "$_var" '%s' "$_made"
}

# Remove every registered path. It runs from the EXIT trap, so it never fails
# and it is safe to run more than once. (${arr[@]+"${arr[@]}"} keeps an empty
# list from tripping `set -u` on bash 3.2, the macOS system bash.)
cleanup_temp_paths() {
  local _path
  for _path in ${_MY_CLAUDE_TEMP_PATHS[@]+"${_MY_CLAUDE_TEMP_PATHS[@]}"}; do
    rm -rf -- "$_path" 2>/dev/null || true
  done
}
