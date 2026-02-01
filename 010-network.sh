printf "\n#### BEGIN CONFIG : Network\n\n"

read -p "?? Enter hostname: " hostname

if [[ -z $hostname ]]; then
    printf ".. No hostname set.  Not enabling MDNS."
else
    printf ".. Hostname set to %s\n" $hostname
    hostnamectl set-hostname $hostname

    # https://discussion.fedoraproject.org/t/correct-way-to-enable-mdns-on-fedora-server-34/34641/7
    cat <<-EOT >>/etc/systemd/resolved.conf
	[Resolve]
	MulticastDNS=yes
EOT

    systemctl restart systemd-resolved

    firewall-cmd --add-service=mdns --permanent
fi

printf "\n#### FINISHED CONFIG : Network\n\n"

sleep 2
