#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. ${SCRIPT_DIR}/setup.sh

# ----

export BRANCH=${1}

export BRANCH_SIMPLE=$(echo ${BRANCH} | tr '/' '-')
export LOGFILE="${HOME}/logs/${BRANCH_SIMPLE}.log"

LOCKFILE="${HOME}/.locks/${BRANCH_SIMPLE}.lock"
DESTDIR=/var/sftp/biznuvo/downloads

mkdir -p ${HOME}/build-repos
cd ${HOME}/build-repos

if [ ! -d "${BRANCH}" ]; then
    git clone git@github.com:BizNuvoSuperApp/biznuvo-server-v2.git --quiet --branch ${BRANCH} --single-branch ${BRANCH} 2>&1 >/dev/null
    newbuild=true
fi

if [ ! -d "${BRANCH}" ]; then
    log "Invalid build branch ${BRANCH}"
    exit 64
fi

cd ${BRANCH}

BUILD_LOGFILE=$(mktemp --tmpdir cblog.$(date +%Y%m%d-%H%M%S).XXXXXXXX)

if [ "${newbuild}" = true ]; then
    flock -E ${EX_LOCK_CONFLICT} -n ${LOCKFILE} ${SCRIPT_DIR}/build.sh > ${BUILD_LOGFILE}
else
    flock -E ${EX_LOCK_CONFLICT} -n ${LOCKFILE} ${SCRIPT_DIR}/build-if-changed.sh > ${BUILD_LOGFILE}
fi

case ${?} in
${EX_LOCK_CONFLICT}|${EX_NO_BUILD})
    exit
    ;;

0)
    BUILD_VERSION=$(githash)
    LATEST_BUILD_PKG=$(find build -name 'biznuvo-install-*' -printf "%T@ %p\n" | sort -nr | head -1 | cut -d\  -f2)
    BUILD_DATE=$(basename ${LATEST_BUILD_PKG} | sed -e 's/biznuvo-install-//' -e 's/.tgz//')
    BUILD_LOCATION="biznuvo-${BRANCH_SIMPLE}-${BUILD_DATE}-${BUILD_VERSION}.tgz"

    mv ${LATEST_BUILD_PKG} ${DESTDIR}/${BUILD_LOCATION}

    (
        . ${SCRIPT_DIR}/build-email-aliases

        echo "\
            To: ${mailnotify}
            Cc: ${mailother}
            Reply-To: do-not-reply@biznuvo.com
            Subject: Auto Build ${BRANCH} :: SUCCESS

            BUILD SUCCESS

            Branch: ${BRANCH}
            Commit: ${BUILD_VERSION}

            Archive: sftp://something/downloads/${BUILD_LOCATION}

        " | sed 's/^[[:space:]]*//'

        if [ "${newbuild}" != true ]; then
            sed -n '/==== BUILD LOG ====/q;p' ${BUILD_LOGFILE}
        fi

        # cat ${BUILD_LOGFILE}
    ) | msmtp --read-recipients

    ;;

*)
    BUILD_VERSION=$(githash)

    (
        . ${SCRIPT_DIR}/build-email-aliases

        echo "\
            To: ${mailnotify}
            Cc: ${mailother}
            Reply-To: do-not-reply@biznuvo.com
            Subject: Auto Build ${BRANCH} :: FAILURE

            BUILD FAILURE

            Branch: ${BRANCH}
            Commit: ${BUILD_VERSION}

        " | sed 's/^[[:space:]]*//'

        cat ${BUILD_LOGFILE}
    ) | msmtp --read-recipients

    ;;
esac

rm ${BUILD_LOGFILE}

log "----"
