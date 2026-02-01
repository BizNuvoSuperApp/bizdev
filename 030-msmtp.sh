printf "\n#### BEGIN CONFIG : MSMTP\n\n"

cd $SUDO_USER_HOME

# get default msmtprc file
sudo -u $SUDO_USER curl -O $GITDIR/scripts/.msmtprc
chmod 600 .msmtprc

printf "\n#### FINISHED CONFIG : MSMTP\n\n"

sleep 2
