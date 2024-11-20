#!/bin/sh
#
# Copyright 2024 sbwml <admin@cooluc.com>
# Licensed to the public under the GNU General Public License v3.0.
#

sys_user=$(awk -F: '{print $1}' /etc/passwd)
uci_smbuser=$(uci -q show smbuser | grep -vE "=smbuser|password=" | sed -n "s/.*@smbuser\[\([0-9]\+\)\].*/\1/p")
smb_user=$(pdbedit -L | awk -F: '{print $1}')

for smbuser in $smb_user; do
	pdbedit -x "$smbuser"
done

if [ -z "$uci_smbuser" ]; then
	/etc/init.d/samba4 restart
else
	for uci_smbuser_id in $uci_smbuser; do
		uci_username=$(uci -q get smbuser.@smbuser["$uci_smbuser_id"].username)
		for user in $uci_username; do
			if ! echo -e "$sys_user" | grep -qw "$user"; then
				groupadd "$user" >/dev/null 2>&1
				useradd -c "$user" -g "$user" -d /var/run/"$user" -s /bin/false "$user"
			fi
		done
	done

	for uci_smbuser_id in $uci_smbuser; do
		uci_username=$(uci -q get smbuser.@smbuser["$uci_smbuser_id"].username)
		uci_password=$(uci -q get smbuser.@smbuser["$uci_smbuser_id"].password)
		echo -e "$uci_password\n$uci_password" | pdbedit -a "$uci_username"
	done
	/etc/init.d/samba4 restart
fi
