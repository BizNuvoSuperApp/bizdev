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

__gitdir() { printf "%s/%s.sh\n" $GITDIR $1; }

_basic() { __gitdir 000-basic; }
_network() { __gitdir 010-network; }
_user() { __gitdir 020-user; }
_msmtp() { __gitdir 030-msmtp; }
_git() { __gitdir 040-git; }
_sshd() { __gitdir 050-sshd; }
_docker() { __gitdir 060-docker; }
_java() { __gitdir 070-java; }

_sshkeys() { __gitdir 100-sshkeys; }

_builder() { __gitdir 200-builder; }
_devdocs() { __gitdir 300-devdocs; }


case $respType in
A)  printf "# Processing Builder Only\n"
    sh -c "$(curl \
        $(_basic) $(_network) $(_user) $(_msmtp) $(_git) $(_sshd) \
        $(_java) $(_sshkeys) $(_builder) \
    )"
    ;;

B)  printf "# Processing Devdocs Only\n"
    sh -c "$(curl \
        $(_basic) $(_network) $(_user) $(_msmtp) $(_git) $(_sshd) \
        $(_docker) $(_devdocs) \
    )"
    ;;

C)  printf "# Processing Docker Only\n"
    sh -c "$(curl \
        $(_basic) $(_network) $(_user) $(_msmtp) $(_git) $(_sshd) \
        $(_docker) \
    )"
    ;;

*)  printf "# Processing Builder and Devdocs\n"
    sh -c "$(curl \
        $(_basic) $(_network) $(_user) $(_msmtp) $(_git) $(_sshd) \
        $(_java) $(_sshkeys) $(_builder) \
        $(_docker) $(_devdocs) \
    )"
    ;;
esac

chown -hR $SUDO_USER: $SUDO_USER_HOME

read -p "Press enter to reboot"
reboot
