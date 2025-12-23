#!/usr/bin/env bash
y_or_n() {
	while true; do
		read -p "$* [y/n]: " yn
		case $yn in
		[Yy]) return 0 ;;
		[Nn]) return 1 ;;
		esac
	done
}

main() {
	if [[ $(whoami) != "root" ]]; then
		echo "You must be root."
		exit 1
	fi

	if [[ $(systemctl status nix-daemon | grep "inactive") ]]; then
		echo "The nix daemon is not running. Starting it now."
		systemctl start nix-daemon
	fi

	while [[ ! $(curl -s ifconfig.me) ]]; do
		y_or_n "No internet connection detected. Connect Now?" && nmtui || exit 0
	done

	printf "\nIf you have used this installer before, you might have an existing configuration for this host.\n"
	printf "You should also read access to your remote repositry. If not you will need to authenticate with your git provider first.\n"
	printf "In this case, you can skip directly to the installation phase.\n"
	y_or_n "Install an existing configuration?" && install_existing_config

	printf "\nIf you have used this installer before, you should have an exiting configuration repository.\n"
	printf "The installer allows you to seamlessly integrate your new configuration with the rest of your NixOS hosts.\n"
	y_or_n "Append to an existiing repository?" && {
		pull_repo
		INSTALLATION_METHOD="append"
	} || INSTALLATION_METHOD="new"
}

pull_repo() {
	REPO_DIR=/tmp/repository

	if [[ $(ls -A $REPO_DIR) ]]; then
		printf "\nAn existing repository was found at $REPO_DIR."
		y_or_n "Remove it and pull your repository again?" || return 0
	fi

	while :; do
		read -p "Enter the url for your repository: " REPO_URL
		git ls-remote $REPO_URL || {
			echo "Could not pull repository, Maybe the url provided is invalid?"
			continue
		}
		break
	done

	git clone $REPO_URL --depth 1 $REPO_DIR || {
		printf "\nSomething went wrong while pulling the repository\n"
		exit 1
	}
}

install_existing_config() {
	exit 0
}

main
