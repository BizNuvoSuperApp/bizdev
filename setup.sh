export SUDO_USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
export SFTP_USER=biznuvo
export GITDIR="https://raw.githubusercontent.com/BizNuvoSuperApp/bizdev/main"


cat <<EOT

#
# Choose which setup you want to run:
#
#   A - Builder Only
#   B - DevDocs Only
#   C - Docker Only
#   * - All (default if enter)
#

EOT

read -p "?? Select setup type: " respType

[[ -z "$respType" ]] && respType=Z

respType="${respType:0:1}"
respType="${respType^^}"


_basic() {
    printf "%s/000-basic.sh\n" $GITDIR
}

_builder() {
    printf "%s/100-builder.sh\n" $GITDIR
}

_docker() {
    printf "%s/150-docker.sh\n" $GITDIR
}

_devdocs() {
    printf "%s/200-devdocs.sh\n" $GITDIR
}

_final() {
    printf "%s/900-final.sh" $GITDIR
}

case $respType in
A)  printf "# Processing Builder Only\n"
    sh -c "$(curl $(_basic) $(_builder) $(_final))"
    ;;

B)  printf "# Processing Devdocs Only\n"
    sh -c "$(curl $(_basic) $(_docker) $(_devdocs) $(_final))"
    ;;

C)  printf "# Processing Docker Only\n"
    sh -c "$(curl $(_basic) $(_docker) $(_final))"
    ;;

*)  printf "# Processing Builder and Devdocs Only\n"
    sh -c "$(curl $(_basic) $(_builder) $(_docker) $(_devdocs) $(_final))"
    ;;
esac

read -p "Press enter to reboot"
reboot
