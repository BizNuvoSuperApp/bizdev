printf "\n#### BEGIN CONFIG : Git Starter\n\n"

# Create initial .gitconfig with some defaults for how to operate
printf "Creating $SUDO_USER_HOME/.gitconfig file\n"

sudo -u $SUDO_USER git config --global init.defaultBranch main
sudo -u $SUDO_USER git config --global core.autocrlf false
sudo -u $SUDO_USER git config --global pull.rebase true

printf "\n#### FINISHED CONFIG : Git Starter\n\n"

sleep 2
