printf "\n#### BEGIN CONFIG : Docker\n\n"

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | sudo -u $SUDO_USER bash

dnf -y -q install docker docker-compose

usermod -a -G docker $SUDO_USER

sudo -u $SUDO_USER mkdir $SUDO_USER_HOME/docker
cd $SUDO_USER_HOME/docker

printf "\n#### FINISHED CONFIG : Docker\n\n"

sleep 2
