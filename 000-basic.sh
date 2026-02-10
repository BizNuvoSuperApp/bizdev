printf "\n#### BEGIN CONFIG : Expanding HD\n\n"

# Make sure Fedora root is expanded
lvextend --extents +100%FREE /dev/mapper/fedora*-root
xfs_growfs /dev/mapper/fedora*-root

printf "\n#### FINISHED CONFIG : Expanding HD\n\n"


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Basic Software\n\n"

dnf -y -q upgrade
dnf -y -q copr enable lihaohong/yazi
dnf -y -q install pinentry vim stow git yazi msmtp gum

# https://discussion.fedoraproject.org/t/vim-default-editor-in-coreos/71356/4
dnf -y swap nano-default-editor vim-default-editor --allowerasing

printf "\n#### FINISHED CONFIG : Basic Software\n\n"

sleep 2
