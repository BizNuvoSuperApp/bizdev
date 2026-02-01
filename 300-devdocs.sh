printf "\n#### BEGIN CONFIG : DevDocs\n\n"

cd $SUDO_USER_HOME

printf "Creating Devdocs control files\n"

sudo -u $SUDO_USER curl -O $GITDIR/scripts/.devdocsrc
chmod 600 .devdocsrc

sudo -u $SUDO_USER git clone git@github.com:BizNuvoSuperApp/devdocs.git

printf "
*/3 * * * * $SUDO_USER_HOME/docker/devdocs/cron-build.sh >$SUDO_USER_HOME/devdocs.log 2>&1
" >> $SUDO_USER_HOME/cronfile

sudo -u $SUDO_USER mkdir $SUDO_USER_HOME/.locks $SUDO_USER_HOME/logs

chown -hR $SUDO_USER: $SUDO_USER_HOME

printf "\n#### END CONFIG : DevDocs\n\n"

sleep 2
