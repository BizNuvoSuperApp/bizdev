#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. ${SCRIPT_DIR}/setup.sh

# ----

UPSTREAM=${1:-'@{u}'}

log "Fetching remote repository..."

git fetch

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ "${LOCAL}" = "${REMOTE}" ]; then
    log "No changes detected in git"
    exit ${EX_NO_BUILD}
elif [ "${LOCAL}" = "${BASE}" ]; then
    log "Changes detected, building new version: $(git rev-parse HEAD)"
    ${SCRIPT_DIR}/build.sh
elif [ "${REMOTE}" = "${BASE}" ]; then
    output "Local changes detected, stashing"
    git stash
    ${SCRIPT_DIR}/build.sh
else
    output "Git is diverged, this is unexpected.  Possible force push"
    exit 1
fi
