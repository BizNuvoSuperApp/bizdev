printf "\n#### BEGIN CONFIG : Docker\n\n"

cd $SUDO_USER_HOME

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | sudo -u $SUDO_USER bash

dnf -y -q install docker docker-compose

usermod -a -G docker $SUDO_USER

sudo -u $SUDO_USER mkdir docker

printf "\n#### FINISHED CONFIG : Docker\n\n"

sleep 2
