printf "\n#### BEGIN CONFIG : Java JDK\n\n"

mkdir $SUDO_USER_HOME/.local
cd $SUDO_USER_HOME/.local

# download jdk and untar it
curl -sL https://download.oracle.com/java/21/archive/jdk-21.0.8_linux-x64_bin.tar.gz | tar -xvzf -

# create link for 
ln -s jdk-21.0.8 jdk-21

printf "\n#### FINISHED CONFIG : Java JDK\n\n"

sleep 2


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : SFTP\n\n"

cd $SUDO_USER_HOME

printf "Adding $SFTP_USER sftp user\n"
useradd -m -U -s /sbin/nologin $SFTP_USER

printf "Adding $SFTP_USER group to ${SUDO_USER}\n"
usermod -a -G $SFTP_USER $SUDO_USER

mkdir /home/$SFTP_USER/.ssh
touch /home/$SFTP_USER/.ssh/authorized_keys
chown -R $SFTP_USER: /home/$SFTP_USER/.ssh
chmod go-rwx /home/$SFTP_USER/.ssh/authorized_keys

printf "Creating downloads directory\n"
mkdir -p /var/sftp/$SFTP_USER/downloads
chmod -R 755 /var/sftp
chown $SFTP_USER: /var/sftp/$SFTP_USER/downloads
chmod g+w /var/sftp/$SFTP_USER/downloads

ln -s /var/sftp/$SFTP_USER sftp

echo <<EOT >>/etc/ssh/sshd_config
Match User $SFTP_USER
    ForceCommand internal-sftp -R
    ChrootDirectory /var/sftp/%u
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
EOT

printf "\n#### END CONFIG : SFTP\n\n"

sleep 2


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Build Automation\n\n"

printf "Creating build control files\n"

cd $SUDO_USER_HOME
curl -O "$GITDIR/scripts/.builderrc"
chmod 600 .builderrc


printf "Getting automation control files\n"

git clone https://github.com/BizNuvoSuperApp/bizdev-automation.git automation

mkdir $SUDO_USER_HOME/.locks $SUDO_USER_HOME/repos $SUDO_USER_HOME/logs

printf "\n#### END CONFIG : Build Automation\n\n"

sleep 2
