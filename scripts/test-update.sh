#!/usr/bin/env bash
# This script is used to verify all host configurations for the registered repositories
# It ensures that all configurations that depend on the module set do not have failing builds after a flake update.
# additionally it will ensure all packages are cached, preventing local builds for these hosts.

REPOSITORIES=(
	"https://git.earthgman.dev/earthgman/nixos-hosts"
	# "https://git.earthgman.dev/thunderbean/nixos-hosts"
	"https://git.earthgman.dev/pumpkinking/nixos"
)

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
	PROJECT_DIR="/home/g/src/git/earthgman/nix-modules"
	if [[ $(git branch --show-current) != "dev" ]]; then
		git checkout dev
	fi
	nix flake update
	git -C $PROJECT_DIR add $PROJECT_DIR
	git commit -m "update flake"
	git push -u origin dev
}

check_configs() {
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
			popd >/dev/null
		fi

		if [[ ! -e $REPO_DIR/flake.nix ]]; then
			echo "no flake.nix found in $REPO_DIR"
			continue
		fi

		pushd $REPO_DIR >/dev/null

		# edit the flake.nix to point to the testing branch
		# TODO ill learn this without looking too scuffed eventually
		sed -i "s/\/EarthGman\/nix-modules/\/EarthGman\/nix-modules?ref=dev/g" $REPO_DIR/flake.nix

		nix flake update gman

		HOSTS=($(nix eval $REPO_DIR'#'nixosConfigurations --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"'))

		for host in ${HOSTS[@]}; do
			nixos-rebuild build --flake .#$host
			if [[ $? != 0 ]]; then
				echo "build for $host from repo: $REPO_OWNER/$REPO_NAME has failed"
				sed -i "s/\/EarthGman\/nix-modules?ref=dev/\/EarthGman\/nix-modules/g" $REPO_DIR/flake.nix
				popd >/dev/null
				exit 1
			fi
		done
		# return the flake to its original state
		sed -i "s/\/EarthGman\/nix-modules?ref=dev/\/EarthGman\/nix-modules/g" $REPO_DIR/flake.nix
		popd >/dev/null
	done
}

main() {
	y_or_n "Update flake?" && update_flake
	check_configs

	y_or_n "Configuration checks successful, merge into main?"
	if [[ $yn == [Yy] ]]; then
		git checkout main
		git merge dev
		git push -u origin main
	fi
	exit 0
}

main
