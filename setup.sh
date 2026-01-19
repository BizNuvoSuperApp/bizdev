SUDO_USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
SFTP_USER=biznuvo

GITDIR="https://raw.githubusercontent.com/BizNuvoSuperApp/bizdev/main"


echo "
#
# Choose which setup you want to run:
#
#   A - Builder Only
#   B - DevDocs Only
#   Z - Both (default if enter)
#
"

read -p "?? Select setup type: [abZ] " respType

[[ -z "$respType" ]] && respType=Z

respType="${respType:0:1}"
respType="${respType^^}"


_basic() {
    printf "%s/000-basic.sh\n" $GITDIR
}

_builder() {
    printf "%s/100-builder.sh\n" $GITDIR
}

_devdocs() {
    printf "%s/200-devdocs.sh\n" $GITDIR
}

if [ -n "$respType" ]; then
	case $respType in
    A)  printf "# Processing Builder Only\n"
        sh -c "$(curl $(_basic) $(_builder))"
        ;;

    A)  printf "# Processing Devdocs Only\n"
        sh -c "$(curl $(_basic) $(_devdocs))"
        ;;

    Z)  printf "# Processing Builder and Devdocs Only\n"
        sh -c "$(curl $(_basic) $(_builder) $(_devdocs))"
        ;;
    esac
fi

read -p "Press enter to reboot"

reboot
