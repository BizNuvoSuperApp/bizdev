printf "\n#### BEGIN CONFIG : Github SSH Keys\n\n"

cd $SUDO_USER_HOME

tempdir=$(mktemp -d)

sshkeystempfile=$(mktemp /tmp/tmp.dl.sshkeys.XXXXXXXXXX)
curl -sL -o $sshkeystempfile $GITDIR/biznuvo-deploy-keys.tar.gpg
gpg -d $sshkeystempfile | tar -xvf - -C $tempdir

# Create SSH setup
printf "\nCreating $SUDO_USER_HOME/.ssh/config\n\n"
mkdir -p .ssh

cd $tempdir

# loop through all keys in the deploy file, creating SSH and GIT config entries to make fetching simple
# This basically makes GIT create an alias for the host for a specific repository, then SSH maps that
# alias to specific key and host to retrieve
for file in *.pub
do
    pkey=$(basename $file .pub)
    repo=$(printf $pkey | sed -e 's/^github-//' -e 's/-id_ed25519//')
    
    if ! grep -s -E "git@github-$repo" .gitconfig
    then
        printf "Installing config entry for repository %s\n" $repo

        printf '
[url "git@github-%s:BizNuvoSuperApp/%s"]
    insteadOf = git@github.com:BizNuvoSuperApp/%s
' $repo $repo $repo >> .gitconfig

        printf '
Host github-%s
    HostName ssh.github.com
    Port 443
    IdentityFile ~/.ssh/%s
' $repo $pkey >> .ssh/config
    fi

    cp -v $pkey ${pkey}.pub .ssh
    chmod go-rwx .ssh/$pkey
done

rm -rf $tempdir

printf "\n\nTest ssh connection to Github\n"
# Do a test connect to GIT to setup ssh keys
sudo -u $SUDO_USER ssh git@ssh.github.com

# Make sure everything owned by SUDO_USER
chown -hR $SUDO_USER: $SUDO_USER_HOME

printf "\n#### FINISHED CONFIG : Github SSH Keys\n\n"

sleep 2
