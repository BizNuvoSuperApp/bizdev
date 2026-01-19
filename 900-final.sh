printf "\n#### BEGIN CONFIG : System Stuff\n\n"

# allows wheel users to sudo without a password 
sed -i -e 's/^%wheel/# %wheel/' -e 's/^# %wheel/%wheel/' /etc/sudoers

# Updating sshd with more restrictions for build server
sed -i '/#PasswordAuthentication yes/a PasswordAuthentication no' /etc/ssh/sshd_config

systemctl restart sshd

printf "\n#### END CONFIG : System Stuff\n\n"


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : Misc Final Stuff\n\n"

chown -hR $SUDO_USER: $SUDO_USER_HOME

printf "\n#### END CONFIG : Misc Final Stuff\n\n"
