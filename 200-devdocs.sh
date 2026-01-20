printf "\n#### BEGIN CONFIG : Software DevDocs\n\n"

dnf -y -q install docker docker-compose

cd $SUDO_USER_HOME

# Install lazydocker for nice UI about docker stuff
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | sudo -u $SUDO_USER bash

printf "\n#### FINISHED CONFIG : Software DevDocs\n\n"

sleep 2


# ------------------------------------------------------------


printf "\n#### BEGIN CONFIG : DevDocs\n\n"

printf "Creating Devdocs control files\n"

cd $SUDO_USER_HOME
sudo -u $SUDO_USER curl -O $GITDIR/scripts/.devdocsrc
chmod 600 .devdocsrc


usermod -a -G docker $SUDO_USER

sudo -u $SUDO_USER mkdir $SUDO_USER_HOME/docker
cd $SUDO_USER_HOME/docker

sudo -u $SUDO_USER git clone git@github.com:BizNuvoSuperApp/devdocs.git


printf "
*/3 * * * * $SUDO_USER_HOME/docker/devdocs/cron-build.sh >$SUDO_USER_HOME/devdocs.log 2>&1
" >> $SUDO_USER_HOME/cronfile

printf "\n#### END CONFIG : DevDocs\n\n"

sleep 2
