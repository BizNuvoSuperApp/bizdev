#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. ${SCRIPT_DIR}/setup.sh

# ----

log "Building ${BRANCH}"

printf "==== GIT NEW COMMITS ====\n\n" \
&& git log @..@{u} \
&& printf "\n\n==== GIT PULL ====\n\n" \
&& git pull \
&& printf "\n\n==== BUILD LOG ====\n\n" \
&& ./create-archives.sh pkg 2>&1
