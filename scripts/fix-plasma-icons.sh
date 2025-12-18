# script that will repair KDE plasma icons after a flake update.
# Instead of referencing icons at the correct location /run/current-system/sw/share/applications, Freaking kde plasma just references the /nix/store directly for some reason.
# On NixOS (if you do not use home-manager) you should NEVER have files in your home directory that reference the /nix/store directly ever.
# Every time the NAR hashes of the store update, the imperatively created links will not update by default.
# This causes the icons on KDE plasma to disappear because they now reference a store path that doesn't exist.

for user in $(ls -A /home); do
	# fix icons on the taskbar
	sed -i 's/\/nix\/store\/[A-Za-z0-9]\+-system-path\/share\/applications/\/run\/current-system\/share\/applications/g' /home/$user/.config/plasma-org.kde.plasma.desktop-appletsrc

	# Fix symlinks in /home/user/Desktop
	DESKTOP_DIR="/home/$user/Desktop"
	for file in $(ls -A $DESKTOP_DIR); do
		if [[ $(echo $file | grep /nix/store) ]]; then
			rm $file
			ln -s $DESKTOP_DIR/$file /run/current-system/sw/share/applications/$file
		fi
	done
done
