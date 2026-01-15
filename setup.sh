finish_setup() {
    read -p "Press enter to reboot"

    reboot
    exit
}

check_cond() {
    [[ "${1:0:1}" > "$2" || "${1:0:1}" = "$2" ]] || finish_setup
}


echo "
#
# Choose which setup you want to run:
#
#   A - Expand drive
#   B - Install software
#   C - Configure network
#   D - User config
#   E - Java
#   F - Github keys
#   G - SFTP
#   H - Build Automation
#   I - Misc
#   Z - all
#
"

read -p "?? Select setup type: " respType


GITDIR="https://raw.githubusercontent.com/BizNuvoSuperApp/bizdev/main"
SUDO_USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)


# ------------------------------------------------------------


check_cond "$respType" "A"

# Make sure Fedora root is expanded
lvextend --extents +100%FREE /dev/mapper/fedora-root
xfs_growfs /dev/mapper/fedora-root

sleep 5


# ------------------------------------------------------------


check_cond "$respType" "B"

printf "\n#### BEGIN CONFIG : Software\n\n"

dnf -y -q upgrade
dnf -y -q copr enable lihaohong/yazi
dnf -y -q install pinentry vim stow git yazi msmtp docker docker-compose

# https://discussion.fedoraproject.org/t/vim-default-editor-in-coreos/71356/4
dnf -y swap nano-default-editor vim-default-editor --allowerasing

printf "\n#### FINISHED CONFIG : Software\n\n"

sleep 2


# ------------------------------------------------------------


check_cond "$respType" "C"

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


check_cond "$respType" "D"

printf "\n#### BEGIN CONFIG : User setup\n\n"

# pull basic dot files for builder, stuff for bashrc and various commands
cd $SUDO_USER_HOME
sudo -u $SUDO_USER git clone https://github.com/BizNuvoSuperApp/bizdev-dotfiles.git .dotfiles

# use stow to create links to stuff in .dotfiles so .dotfiles can be a GIT repos
cd $SUDO_USER_HOME/.dotfiles
sudo -u $SUDO_USER stow --adopt --no-folding .
sudo -u $SUDO_USER git reset --hard

# install Oh-my-posh fancy prompt
curl -s https://ohmyposh.dev/install.sh | sudo -u $SUDO_USER bash -s

# allows wheel users to sudo without a password 
sed -i -e 's/^%wheel/# %wheel/' -e 's/^# %wheel/%wheel/' /etc/sudoers

printf "\n#### FINISHED CONFIG : User setup\n\n"

sleep 2


# ------------------------------------------------------------


check_cond "$respType" "E"

printf "\n#### BEGIN CONFIG : Java Multi\n\n"

mkdir $SUDO_USER_HOME/.local
cd $SUDO_USER_HOME/.local

# download jdk and untar it
curl -sL https://download.oracle.com/java/21/archive/jdk-21.0.8_linux-x64_bin.tar.gz | tar -xvzf -

# create link for 
ln -s jdk-21.0.8 jdk-21

printf "\n#### FINISHED CONFIG : Java\n\n"

sleep 2


# ------------------------------------------------------------


check_cond "$respType" "F"

printf "\n#### BEGIN CONFIG : Github SSH Keys\n\n"

printf "#- fetch ssh keys\n"

tempdir=$(mktemp -d)

sshkeystempfile=$(mktemp /tmp/tmp.dl.sshkeys.XXXXXXXXXX)
curl -sL -o $sshkeystempfile $GITDIR/biznuvo-deploy-keys.tar.gpg
gpg -d $sshkeystempfile | tar -xvf - -C $tempdir

printf "Creating $SUDO_USER_HOME/.gitconfig file\n"

# Create initial .gitconfig with some defaults for how to operate
cat <<EOF > $SUDO_USER_HOME/.gitconfig
[init]
defaultBranch = main

[core]
autocrlf = false

[pull]
rebase = true
EOF

printf "Creating $SUDO_USER_HOME/.ssh/config\n"
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


# ------------------------------------------------------------


check_cond "$respType" "G"

printf "\n#### BEGIN CONFIG : SFTP\n\n"

cd $SUDO_USER_HOME

printf "Adding biznuvo sftp user\n"
useradd -m -U -s /sbin/nologin biznuvo

printf "Adding biznuvo group to ${SUDO_USER}\n"
usermod -a -G biznuvo $SUDO_USER

mkdir /home/biznuvo/.ssh
touch /home/biznuvo/.ssh/authorized_keys
chown -R biznuvo: /home/biznuvo/.ssh
chmod go-rwx /home/biznuvo/.ssh/authorized_keys

printf "Creating downloads directory\n"
mkdir -p /var/sftp/biznuvo/downloads
chmod -R 755 /var/sftp
chown biznuvo: /var/sftp/biznuvo/downloads
chmod g+w /var/sftp/biznuvo/downloads

ln -s /var/sftp/biznuvo sftp


printf "Updating sshd with more restrictions for build server\n"

sed -i '/#PasswordAuthentication yes/a PasswordAuthentication no' /etc/ssh/sshd_config

echo "
Match User biznuvo
    ForceCommand internal-sftp -R
    ChrootDirectory /var/sftp/%u
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
" >> /etc/ssh/sshd_config

systemctl restart sshd

printf "\n#### END CONFIG : SFTP\n\n"

sleep 2


# ------------------------------------------------------------


check_cond "$respType" "H"

printf "\n#### BEGIN CONFIG : Build Automation\n\n"

printf "Creating msmtp control files\n"

cd $SUDO_USER_HOME
curl -O "$GITDIR/scripts/{.msmtprc,cronfile}"
chmod 600 .msmtprc

sed -i 's/SUDO_USER/'$SUDO_USER'/g' cronfile


printf "Creating automation control files\n"

mkdir $SUDO_USER_HOME/automation
cd $SUDO_USER_HOME/automation

curl -O "$GITDIR/scripts/automation/{build-if-changed.sh,build.sh,cron-build.sh,common.sh}"
chmod u+x build-if-changed.sh build.sh cron-build.sh

mkdir $SUDO_USER_HOME/.locks $SUDO_USER_HOME/repos $SUDO_USER_HOME/logs

printf "\n#### END CONFIG : Build Automation\n\n"

sleep 2


# ------------------------------------------------------------


check_cond "$respType" "I"

printf "\n#### BEGIN CONFIG : Misc\n\n"

cd $SUDO_USER_HOME

# Install lazydocker for nice UI about docker stuff
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | sudo -u $SUDO_USER bash

usermod -a -G docker $SUDO_USER

mkdir docker

printf "\n#### END CONFIG : Misc\n\n"

sleep 2


# ------------------------------------------------------------


chown -hR $SUDO_USER: $SUDO_USER_HOME


finish_setup