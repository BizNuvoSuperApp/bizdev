EX_LOCK_CONFLICT=200
EX_NO_BUILD=201

githash() {
    git rev-parse --short HEAD
}

datelog() {
    date +%Y/%m/%d-%H:%M:%S
}

log() {
    printf "%s : %s\n" "$(datelog)" "${1}" >> ${LOGFILE}
}
