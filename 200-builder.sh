printf "\n#### BEGIN CONFIG : Build Automation\n\n"

printf "Creating build control files\n"

cd $SUDO_USER_HOME

sudo -u $SUDO_USER curl -O $GITDIR/scripts/.builderrc
chmod 600 .builderrc


printf "Getting automation control files\n"

sudo -u $SUDO_USER git clone https://github.com/BizNuvoSuperApp/bizdev-automation.git automation

sudo -u $SUDO_USER mkdir $SUDO_USER_HOME/.locks $SUDO_USER_HOME/repos $SUDO_USER_HOME/logs


printf "Updating cronfile\n"

printf "PATH=/usr/local/bin:/usr/bin:$SUDO_USER_HOME/.local/jdk-21/bin
JAVA_HOME=$SUDO_USER_HOME/.local/jdk-21

0 1 * * * /home/bn/automation/cleanup.py >$SUDO_USER_HOME/cleanup.log 2>&1
" >> $SUDO_USER_HOME/cronfile


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

sudo -u $SUDO_USER ln -s /var/sftp/$SFTP_USER $SUDO_USER_HOME/sftp

echo "
Match User $SFTP_USER
    ForceCommand internal-sftp -R
    ChrootDirectory /var/sftp/%u
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
" >> /etc/ssh/sshd_config


chown -hR $SUDO_USER: $SUDO_USER_HOME

printf "\n#### END CONFIG : Build Automation\n\n"

sleep 2
