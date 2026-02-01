printf "\n#### BEGIN CONFIG : Java JDK\n\n"

cd $SUDO_USER_HOME

mkdir .local
cd .local

# download jdk and untar it
curl -sL https://download.oracle.com/java/21/archive/jdk-21.0.8_linux-x64_bin.tar.gz | tar -xvzf -

# create link for 
ln -s jdk-21.0.8 jdk-21

# Make sure everything owned by SUDO_USER
chown -hR $SUDO_USER: $SUDO_USER_HOME

printf "\n#### FINISHED CONFIG : Java JDK\n\n"

sleep 2
