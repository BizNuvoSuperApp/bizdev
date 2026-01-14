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

cd $SUDO_USER_HOME
sudo -u bn git clone https://github.com/BizNuvoSuperApp/bizdev-dotfiles.git .dotfiles

cd $SUDO_USER_HOME/.dotfiles
sudo -u bn stow --adopt --no-folding .
sudo -u bn git reset --hard

curl -s https://ohmyposh.dev/install.sh | sudo -u bn bash -s

# allows wheel users to sudo without a password 
sed -i -e 's/^%wheel/# %wheel/' -e 's/^# %wheel/%wheel/' /etc/sudoers

printf "\n#### FINISHED CONFIG : User setup\n\n"

sleep 2


# ------------------------------------------------------------


check_cond "$respType" "E"

printf "\n#### BEGIN CONFIG : Java Multi\n\n"

cd $SUDO_USER_HOME/.local

curl -sL https://download.oracle.com/java/21/archive/jdk-21.0.8_linux-x64_bin.tar.gz | tar -xvzf -

ln -s jdk-21.0.8 jdk-21

chown -R $SUDO_USER: $SUDO_USER_HOME/.local/jdk*

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

echo "[init]
defaultBranch = main

[core]
autocrlf = false

[pull]
rebase = true

" > $SUDO_USER_HOME/.gitconfig

printf "Creating $SUDO_USER_HOME/.ssh/config\n"
mkdir -p $SUDO_USER_HOME/.ssh

cd $tempdir

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

chown -R $SUDO_USER: $SUDO_USER_HOME/.gitconfig $SUDO_USER_HOME/.ssh

sudo -u bn ssh -T git@github.com

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


printf "Creating downloads directory\n"
mkdir -p /var/sftp/biznuvo/downloads
chmod -R 755 /var/sftp
chown biznuvo: /var/sftp/biznuvo/downloads
chmod g+w /var/sftp/biznuvo/downloads

ln -s /var/sftp/biznuvo sftp
chown $SUDO_USER: sftp


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
curl $GITDIR/scripts/.msmtprc | sed "s#aliases #aliases ${SUDO_USER_HOME}/#" > .msmtprc

chown -R ${SUDO_USER}: .msmtprc
chmod 600 .msmtprc


printf "Creating automation control files\n"

mkdir $SUDO_USER_HOME/automation
cd $SUDO_USER_HOME/automation

printf "mailnotify=DEST1\nmailother=\n" > build-email-aliases

curl -O "$GITDIR/scripts/{build-if-changed.sh,build.sh,cron-build.sh,setup.sh}"
chown -R $SUDO_USER: $SUDO_USER_HOME/automation
chmod u+x $SUDO_USER_HOME/automation/*.sh

mkdir $SUDO_USER_HOME/.locks $SUDO_USER_HOME/repos $SUDO_USER_HOME/logs
chown $SUDO_USER: $SUDO_USER_HOME/.locks $SUDO_USER_HOME/repos $SUDO_USER_HOME/logs


echo "JAVA_HOME=/home/bn/.local/jdk-21
PATH=/usr/local/bin:/usr/bin:/home/bn/.local/jdk-21/bin
CB_MAIL_TO=dmcclure@biznuvo.com
CB_MAIL_CC=

0 0 * * * find /var/sftp/biznuvo/downloads -type f -mtime +21 -delete > $HOME/cleanup.log

# Template for build automation
# */3 * * * * /home/bn/automation/cron-build.sh main 2>&1 >/home/bn/logs/main.debug
" > $SUDO_USER_HOME/cronfile

chown $SUDO_USER: $SUDO_USER_HOME/cronfile

printf "\n#### END CONFIG : Build Automation\n\n"

sleep 2


# ------------------------------------------------------------


check_cond "$respType" "I"

printf "\n#### BEGIN CONFIG : Misc\n\n"

cd $SUDO_USER_HOME

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | sudo -u bn bash

usermod -a -G docker $SUDO_USER

mkdir docker
chown $SUDO_USER: docker

printf "\n#### END CONFIG : Misc\n\n"

sleep 2


# ------------------------------------------------------------


finish_setup