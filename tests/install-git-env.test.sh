#!/usr/bin/env bash
#
# install-git-env.test.sh — install.sh must act on its own checkout even when
# the caller's environment points git at another repository.
# `bash tests/install-git-env.test.sh`
#
# Git exports GIT_INDEX_FILE to commit hooks (an absolute path under
# `git commit -a`) and GIT_DIR as well in a linked worktree; a shell kept on a
# bare dotfiles repo exports GIT_DIR and GIT_WORK_TREE. install.sh unsets the
# variables that choose the repository, work tree, index and object store
# (git(1), "The Git Repository"), so:
#   1. GIT_INDEX_FILE naming this checkout's own index: the clone fallback's
#      checkout does not stage the upstream's files in it.
#   2. GIT_DIR, GIT_WORK_TREE and GIT_INDEX_FILE naming another repository: the
#      recorded commits and HEAD come from this checkout, and the other
#      repository is untouched.
#   3. GIT_OBJECT_DIRECTORY, GIT_ALTERNATE_OBJECT_DIRECTORIES and GIT_COMMON_DIR
#      naming another repository: nothing is written there.
#
# Runs install.sh in the shared sandbox (tests/lib/install-sandbox.sh): a
# throwaway HOME, TMPDIR and npm prefix, shimmed installers, local git only.
set -uo pipefail
. "$(dirname "$0")/lib/install-sandbox.sh"

# upstream/omc as its remote holds it: a pinned package.json and one agent.
OMC_REMOTE="$SANDBOX/omc-remote"
mkdir -p "$OMC_REMOTE/agents"
printf '{ "name": "oh-my-claude-sisyphus", "version": "1.2.3" }\n' > "$OMC_REMOTE/package.json"
printf -- '---\nname: omc-env-agent\n---\n' > "$OMC_REMOTE/agents/omc-env-agent.md"
tgit init -q "$OMC_REMOTE"
OMC_SHA="$(commit_all "$OMC_REMOTE" "omc at the pin")"
redirect "https://github.com/Yeachan-Heo/oh-my-claudecode" "$OMC_REMOTE"

# A checkout that records that commit for upstream/omc but never initialized
# it and has no .gitmodules: init_upstream takes its clone fallback, whose git
# calls write an index, objects and refs. One per scenario.
new_checkout() {  # new_checkout <dir>
  make_repo "$1"
  rm -f "$1/.gitmodules"
  mkdir -p "$1/upstream/omc"
  record "$1" "$OMC_SHA" upstream/omc
  tgit -C "$1" commit -qm "record the pins"
}

# The user's own repository, which the environment points git at.
DECOY="$SANDBOX/decoy"
mkdir -p "$DECOY"
echo mine > "$DECOY/mine.txt"
tgit init -q "$DECOY"
commit_all "$DECOY" "the user's own repository" > /dev/null

# Every file under <dir> with its checksum: nothing may be added, changed or removed.
snapshot() { ( cd "$1" && find . -type f -exec cksum {} + | sort ); }
DECOY_SNAPSHOT="$(snapshot "$DECOY")"

if [ -z "$OMC_SHA" ] || [ -z "$DECOY_SNAPSHOT" ]; then
  echo "FAIL  fixture setup"
  exit 1
fi

FLAGS=(--skip-ecc --skip-gstack --skip-superpowers --skip-archify --skip-tools)
agent_installed() { [ -f "$1/.claude/agents/omc-env-agent.md" ]; }
index_only_pins() { [ "$(tgit -C "$1" ls-files -s)" = "$(printf '160000 %s 0\tupstream/omc' "$OMC_SHA")" ]; }
installed_sha_is_head() {  # installed_sha_is_head <home> <checkout>
  [ "$(cat "$1/.claude/.my-claude-installed-sha" 2>/dev/null)" = "$(tgit -C "$2" rev-parse --short=12 HEAD)" ]
}

echo "[1/3] GIT_INDEX_FILE names this checkout's own index (a commit hook here)"
C="$SANDBOX/repo-index"; new_checkout "$C"
H="$SANDBOX/home-index"; mkdir -p "$H"
RUN_ENV=("GIT_INDEX_FILE=$C/.git/index")
run_install "$H" "$C" "${FLAGS[@]}"
check "this checkout's index still holds only its pins"   "$(yes_if index_only_pins "$C")"
check "OMC agent installed from the recorded commit"      "$(yes_if agent_installed "$H")"

echo "[2/3] GIT_DIR, GIT_WORK_TREE and GIT_INDEX_FILE name another repository"
C="$SANDBOX/repo-dir"; new_checkout "$C"
H="$SANDBOX/home-dir"; mkdir -p "$H"
RUN_ENV=("GIT_DIR=$DECOY/.git" "GIT_WORK_TREE=$DECOY" "GIT_INDEX_FILE=$DECOY/.git/index")
run_install "$H" "$C" "${FLAGS[@]}"
check "the other repository is untouched"                 "$(yes_if [ "$(snapshot "$DECOY")" = "$DECOY_SNAPSHOT" ])"
check "no 'no commit is recorded' warning for upstream/omc" "$(yes_if not in_log "$H" "no commit is recorded for upstream/omc")"
check "OMC agent installed from the recorded commit"      "$(yes_if agent_installed "$H")"
check "installed commit recorded is this checkout's HEAD" "$(yes_if installed_sha_is_head "$H" "$C")"

echo "[3/3] GIT_OBJECT_DIRECTORY, GIT_ALTERNATE_OBJECT_DIRECTORIES and GIT_COMMON_DIR name another repository"
C="$SANDBOX/repo-objects"; new_checkout "$C"
H="$SANDBOX/home-objects"; mkdir -p "$H"
RUN_ENV=("GIT_OBJECT_DIRECTORY=$DECOY/.git/objects" "GIT_ALTERNATE_OBJECT_DIRECTORIES=$DECOY/.git/objects" "GIT_COMMON_DIR=$DECOY/.git")
run_install "$H" "$C" "${FLAGS[@]}"
check "the other repository is untouched"                 "$(yes_if [ "$(snapshot "$DECOY")" = "$DECOY_SNAPSHOT" ])"
check "OMC agent installed from the recorded commit"      "$(yes_if agent_installed "$H")"

finish
