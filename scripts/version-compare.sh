#!/usr/bin/env bash
# Dotted-version comparison, sourced by install.sh.

# version_lt <a> <b>: success when a is strictly older than b (numeric, dot-separated).
# Non-numeric suffixes (e.g. 5.6.2-beta) are ignored; missing parts count as 0.
version_lt() {
  local -a a b
  local i x y
  IFS=. read -r -a a <<< "${1%%[-+]*}"
  IFS=. read -r -a b <<< "${2%%[-+]*}"
  for i in 0 1 2; do
    x="${a[i]:-0}"; y="${b[i]:-0}"
    [[ "$x" =~ ^[0-9]+$ && "$y" =~ ^[0-9]+$ ]] || return 1
    if (( 10#$x < 10#$y )); then return 0; fi
    if (( 10#$x > 10#$y )); then return 1; fi
  done
  return 1
}
