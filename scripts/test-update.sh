#!/usr/bin/env bash
# This script is used to verify all host configurations for the registered repositories
# It ensures that all configurations do not have failing builds.
# additionally it will ensure all packages are cached, preventing local builds

y_or_n() {
	while true; do
		read -p "$* [y/n]: " yn
		case $yn in
		[Yy]*) return 0 ;;
		[Nn]*)
			return 1
			;;
		esac
	done
}

update_flake() {
	git checkout dev
	nix flake update
	git commit -m "update flake"
	git push -u origin dev
}

pull_repositories() {
	# enroll repositories via links here
	REPOSITORIES=(
		"https://git.earthgman.dev/thunderbean/nixos-hosts"
		"https://git.earthgman.dev/pumpkinking/nixos"
	)

	for repo in ${REPOSITORIES[@]}; do
		REPO_OWNER=$(echo $repo | rev | cut -d "/" -f2 | rev)
		REPO_NAME=$(echo $repo | rev | cut -d "/" -f1 | rev)
		REPO_DIR="/tmp/nixos-update-check/$REPO_OWNER/$REPO_NAME"

		if [[ ! -d $REPO_DIR ]]; then
			mkdir -p $REPO_DIR
			git clone $repo --depth 1 $REPO_DIR
		else
			pushd $REPO_DIR >/dev/null
			git pull
		fi

		if [[ ! -e $REPO_DIR/flake.nix ]]; then
			echo "no flake.nix found in $REPO_DIR"
			continue
		fi

		pushd $REPO_DIR >/dev/null

		# edit the flake.nix to point to the testing branch
		# TODO ill learn this without looking too scuffed eventually
		sed -i "s/\/EarthGman\/nix-modules/\/EarthGman\/nix-modules?ref=dev/g" $REPO_DIR/flake.nix

		HOSTS=($(nix eval $REPO_DIR'#'nixosConfigurations --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"'))

		for host in ${HOSTS[@]}; do
			nixos-rebuild build --flake .#$host
			if [[ $? != 0 ]]; then
				echo "build for $host from repo: $REPO_OWNER/$REPO_NAME has failed"
				popd >/dev/null
				exit 1
			fi
		done
		popd >/dev/null
	done
}

main() {
	y_or_n "Update flake?" && update_flake
	pull_repositories
}

main
