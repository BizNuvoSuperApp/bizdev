printf "\n#### BEGIN CONFIG : Expanding HD\n\n"

# Make sure Fedora root is expanded
lvextend --extents +100%FREE /dev/mapper/fedora-root
xfs_growfs /dev/mapper/fedora-root

printf "\n#### FINISHED CONFIG : Expanding HD\n\n"

sleep 5


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Basic Software\n\n"

dnf -y -q upgrade
dnf -y -q copr enable lihaohong/yazi
dnf -y -q install pinentry vim stow git yazi msmtp

# https://discussion.fedoraproject.org/t/vim-default-editor-in-coreos/71356/4
dnf -y swap nano-default-editor vim-default-editor --allowerasing

printf "\n#### FINISHED CONFIG : Basic Software\n\n"

sleep 2


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Network\n\n"

read -p "?? Enter hostname: " hostname

if [[ -z $hostname ]]; then
    printf ".. No hostname set.  Not enabling MDNS."
else
    printf ".. Hostname set to %s\n" $hostname
    hostnamectl set-hostname $hostname

    # https://discussion.fedoraproject.org/t/correct-way-to-enable-mdns-on-fedora-server-34/34641/7
    printf "[Resolve]\nMulticastDNS=resolve\n" >> /etc/systemd/resolved.conf

    systemctl restart systemd-resolved

    firewall-cmd --add-service=mdns --permanent
fi

printf "\n#### FINISHED CONFIG : Network\n\n"

sleep 2


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : User setup\n\n"

# pull basic dot files for builder, stuff for bashrc and various commands
cd $SUDO_USER_HOME
sudo -u $SUDO_USER git clone https://github.com/BizNuvoSuperApp/bizdev-dotfiles.git .dotfiles


# get default cronfile and msmtprc file
curl -O "$GITDIR/scripts/{.msmtprc,cronfile}"
chmod 600 .msmtprc

sed -i 's/SUDO_USER/'$SUDO_USER'/g' cronfile


# use stow to create links to stuff in .dotfiles so .dotfiles can be a GIT repos
cd $SUDO_USER_HOME/.dotfiles
sudo -u $SUDO_USER stow --adopt --no-folding .
sudo -u $SUDO_USER git reset --hard


# install Oh-my-posh fancy prompt
curl -s https://ohmyposh.dev/install.sh | sudo -u $SUDO_USER bash -s

printf "\n#### FINISHED CONFIG : User setup\n\n"

sleep 2


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Git Starter\n\n"

# Create initial .gitconfig with some defaults for how to operate
printf "Creating $SUDO_USER_HOME/.gitconfig file\n"

git config --global init.defaultBranch main
git config --global core.autocrlf false
git config --global pull.rebase true

printf "\n#### FINISHED CONFIG : Git Starter\n\n"

sleep 2


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Github SSH Keys\n\n"

tempdir=$(mktemp -d)

sshkeystempfile=$(mktemp /tmp/tmp.dl.sshkeys.XXXXXXXXXX)
curl -sL -o $sshkeystempfile $GITDIR/biznuvo-deploy-keys.tar.gpg
gpg -d $sshkeystempfile | tar -xvf - -C $tempdir

# Create SSH setup
printf "\nCreating $SUDO_USER_HOME/.ssh/config\n\n"
mkdir -p $SUDO_USER_HOME/.ssh

cd $tempdir

# loop through all keys in the deploy file, creating SSH and GIT config entries to make fetching simple
# This basically makes GIT create an alias for the host for a specific repository, then SSH maps that
# alias to specific key and host to retrieve
for file in *.pub
do
    pkey=$(basename $file .pub)
    repo=$(printf $pkey | sed -e 's/^github-//' -e 's/-id_ed25519//')
    
    if ! grep -s -E "git@github-$repo" $SUDO_USER_HOME/.gitconfig
    then
        printf "Installing config entry for repository %s\n" $repo

        printf '
[url "git@github-%s:BizNuvoSuperApp/%s"]
    insteadOf = git@github.com:BizNuvoSuperApp/%s
' $repo $repo $repo >> $SUDO_USER_HOME/.gitconfig

        printf '
Host github-%s
    HostName ssh.github.com
    Port 443
    IdentityFile ~/.ssh/%s
' $repo $pkey >> $SUDO_USER_HOME/.ssh/config

    fi

    cp -v $pkey ${pkey}.pub $SUDO_USER_HOME/.ssh
    chmod go-rwx $SUDO_USER_HOME/.ssh/$pkey
done

rm -rf $tempdir

# Do a test connect to GIT to setup ssh keys
sudo -u $SUDO_USER ssh git@ssh.github.com

printf "\n#### FINISHED CONFIG : Github SSH Keys\n\n"

sleep 2
