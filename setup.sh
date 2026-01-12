GITDIR="https://raw.githubusercontent.com/BizNuvoSuperApp/bizdev/main"
export GITDIR

SUDO_USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
export SUDO_USER_HOME


# Make sure Fedora root is expanded
lvextend --extents +100%FREE /dev/mapper/fedora-root
xfs_growfs /dev/mapper/fedora-root

sleep 5


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Software\n\n"

dnf -y -q upgrade
dnf -y -q copr enable lihaohong/yazi
dnf -y -q install vim stow git yazi podman msmtp

# https://discussion.fedoraproject.org/t/vim-default-editor-in-coreos/71356/4
dnf -y swap nano-default-editor vim-default-editor --allowerasing

touch /tmp/doreboot

printf "\n#### FINISHED CONFIG : Software\n\n"


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


# ------------------------------------------------------------


cd $SUDO_USER_HOME
sudo -u bn git clone https://github.com/BizNuvoSuperApp/bizdev-dotfiles.git .dotfiles

cd $SUDO_USER_HOME/.dotfiles
sudo -u bn stow --adopt .
sudo -u bn git reset --hard

curl -s https://ohmyposh.dev/install.sh | sudo -u bn bash -s

# allows wheel users to sudo without a password 
sed -i -e 's/^%wheel/# %wheel/' -e 's/^# %wheel/%wheel/' /etc/sudoers


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Java Multi\n\n"

curl -o /tmp/jdk.tar.gz https://download.oracle.com/java/21/archive/jdk-21.0.8_linux-x64_bin.tar.gz

sudo tar -C .local -xvf /tmp/jdk.tar.gz
(cd .local && ln -s jdk-21.0.8 jdk-21 && chown $SUDO_USER: .local/jdk-21)

printf "\n#### FINISHED CONFIG : Java\n\n"


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Github SSH Keys\n\n"

printf "#- fetch ssh keys\n"

mkdir -p $SUDO_USER_HOME/.ssh

sshkeystempfile=$(mktemp /tmp/tmp.dl.sshkeys.XXXXXXXXXX)
curl -sL -o $sshkeystempfile $GITDIR/biznuvo-server-keys.tar.xz.gpg
gpg -d $sshkeystempfile | tar -J -xvf - -C $SUDO_USER_HOME/.ssh

printf "#- configure ssh config\n"

printf "
Host github.com
    Hostname ssh.github.com
    Port 443
    IdentityFile=~/.ssh/biznuvo-server-v2-id_ed25519
" >> $SUDO_USER_HOME/.ssh/config

chown -R $SUDO_USER: $SUDO_USER_HOME/.ssh

printf "\n#### FINISHED CONFIG : Github SSH Keys\n\n"


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : SFTP\n\n"

printf "Adding biznuvo sftp user\n"
useradd -m -U -s /sbin/nologin biznuvo


printf "Adding biznuvo group to ${SUDO_USER}\n"
usermod -a -G biznuvo $SUDO_USER


printf "Creating downloads directory\n"
mkdir -p /var/sftp/biznuvo/downloads
chmod -R 755 /var/sftp
chown biznuvo: /var/sftp/biznuvo/downloads
chmod g+w /var/sftp/biznuvo/downloads


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


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Build Automation\n\n"

printf "Creating msmtp control files\n"

cd $SUDO_USER_HOME
curl $GITDIR/scripts/.msmtprc | sed "s#aliases #aliases ${SUDO_USER_HOME}/#" > .msmtprc

chown -R ${SUDO_USER}: .msmtprc
chmod 600 .msmtprc


printf "Creating automation control files\n"

mkdir $SUDO_USER_HOME/build-automation
cd $SUDO_USER_HOME/build-automation

printf "mailnotify=DEST1\nmailother=\n" > build-email-aliases

curl -O "$GITDIR/scripts/{build-if-changed.sh,build.sh,cron-build.sh,setup.sh}"
chown -R $SUDO_USER: $SUDO_USER_HOME/build-automation
chmod u+x $SUDO_USER_HOME/build-automation/*.sh

mkdir $SUDO_USER_HOME/.locks $SUDO_USER_HOME/build-repos $SUDO_USER_HOME/logs
chown $SUDO_USER: $SUDO_USER_HOME/.locks $SUDO_USER_HOME/build-repos $SUDO_USER_HOME/logs

printf "\n#### END CONFIG : Build Automation\n\n"


# ------------------------------------------------------------

read -p "Press enter to reboot"

reboot
