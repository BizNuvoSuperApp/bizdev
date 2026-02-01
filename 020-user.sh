printf "\n#### BEGIN CONFIG : User setup\n\n"

cd $SUDO_USER_HOME

# install Oh-my-posh fancy prompt
curl -s https://ohmyposh.dev/install.sh | sudo -u $SUDO_USER bash -s

# pull basic dot files for builder, stuff for bashrc and various commands
sudo -u $SUDO_USER git clone https://github.com/BizNuvoSuperApp/bizdev-dotfiles.git .dotfiles

# use stow to create links to stuff in .dotfiles so .dotfiles can be a GIT repos
cd $SUDO_USER_HOME/.dotfiles
sudo -u $SUDO_USER stow --adopt --no-folding .
sudo -u $SUDO_USER git reset --hard

chown -hR $SUDO_USER: $SUDO_USER_HOME

printf "\n#### FINISHED CONFIG : User setup\n\n"

sleep 2
