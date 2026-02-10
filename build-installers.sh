#!/bin/sh
# script which auto builds, signs, and uploads all installer images to the cache website

WEBSITE_IP="192.168.25.85"

if ! ping -c 1 $WEBSITE_IP; then
	printf "Unable to reach cache server at: %s\n" "$WEBSITE_IP"
	exit 1
fi

type nixos-generate || {
	echo "nixos-generate not installed, You can install it through the nix package \"nixos-generators\""
	exit 1
}

INSTALLERS=$(
	for configuration in $(nix eval "$REPO_DIR#nixosConfigurations" --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"'); do
		printf "%s\n" "$configuration"
	done | grep 'installer'
)

for image in $INSTALLERS; do
	# store isos so they can be shared between hosts
	ISO_DEST_PATH=~/src/isos/$image.iso
	HASH_DEST_PATH="$XDG_CACHE_HOME/nix-modules-CI/installers/$image.iso.sha256"
	nixos-generate --flake .\#"$image" -f iso -o result || {
		echo "Could not build the installer image"
		exit 1
	}

	if [ -e "$ISO_DEST_PATH" ]; then
		rm -f "$ISO_DEST_PATH"
	fi

	cp result/iso/* "$ISO_DEST_PATH"

	sha256sum "$ISO_DEST_PATH" | cut -d ' ' -f1 >"$HASH_DEST_PATH"
	gpg --sign --default-key 'EarthGman@protonmail.com' "$HASH_DEST_PATH"

	scp "$ISO_DEST_PATH" "$HASH_DEST_PATH"".gpg" "root@$WEBSITE_IP:/srv/binaries"
	rm "$HASH_DEST_PATH"
done
