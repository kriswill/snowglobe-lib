#!/bin/sh
# This script is used to verify all host configurations for the registered repositories
# It ensures that all configurations that depend on the module set do not have failing builds after a flake update.
# additionally it will ensure all packages are cached, preventing local builds for these hosts.
y_or_n() {
	printf "%s: [y/n] " "$1"
	read -r yn

	if [ -z "$yn" ]; then
		return 1
	fi

	case "$yn" in
	"Y" | "y")
		return 0
		;;

	"N" | "n")
		return 1
		;;
	*)
		printf "Not a valid response\n"
		;;
	esac
}

_end_sequence() {
	notify-send -a "snowglobe-CI" "ci.sh" "Configuration Checks successful\!"
	if systemctl is-active nix-post-build-hook-queue >/dev/null; then
		y_or_n "disable post-build-hook-queue?" && sudo systemctl stop nix-post-build-hook-queue
	fi
	exit 0
}

for arg in "$@"; do
	ARG_NAME=$(printf "%s" "$arg" | cut -d= -f1)
	ARG_VAL=$(printf "%s" "$arg" | cut -d= -f2)
	case "$ARG_NAME" in
	"--check-only")
		CHECK_ONLY=1
		;;
	"--clear-cache")
		rm -rf "$XDG_CACHE_HOME/snowglobe-CI"
		;;
	"--check-registered-repos")
		CHECK_REGISTERED_REPOS=1
		;;
	esac
done

if [ ! -e .secrets/repo-urls.txt ] && [ "$CHECK_REGISTERED_REPOS" ]; then
	printf "Error: repo-urls were not found or you are not in the project root.\n"
	exit 1
fi

if [ ! -d nixosConfigurations/testmonkey ]; then
	printf "testmonkey config missing or not in project root\n"
	exit 1
fi

# use nix-post-build-hook-queue to push modified packages to nix-store.earthgman.dev
if [ -z "$CHECK_ONLY" ] && ! systemctl is-active nix-post-build-hook-queue >/dev/null; then
	printf "Build hook queue is not enabled Authenticate to enable the service.\n"
	if ! systemctl is-active nix-post-build-hook-queue.socket >/dev/null; then
		sudo systemctl start nix-post-build-hook-queue.socket
	fi
	sudo systemctl start nix-post-build-hook-queue
fi

if [ "$CHECK_ONLY" ]; then
	nix flake check
else
	nixos-rebuild build --flake .#testmonkey
fi

# early escape if no repo checks are being done
if [ ! ${CHECK_REGISTERED_REPOS+x} ]; then
	_end_sequence
fi

GIT_BRANCH="$(git branch | grep '\*' | cut -d' ' -f2)"

REPOSITORIES=$(cat ".secrets/repo-urls.txt")
PROJECT_ROOT="$PWD"

y_or_n() {
	while true; do
		printf "%s [y/n]: " "$@"
		read -r yn
		case $yn in
		[Yy]) return 0 ;;
		[Nn]) return 1 ;;
		*) printf "Not a valid response\n" ;;
		esac
	done
}

for repo in $REPOSITORIES; do
	REPO_OWNER=$(echo "$repo" | rev | cut -d "/" -f2 | rev)
	REPO_NAME=$(echo "$repo" | rev | cut -d "/" -f1 | rev)
	if [ -z "$XDG_CACHE_HOME" ]; then
		REPO_DIR="/tmp/snowglobe-CI/repos/$REPO_OWNER/$REPO_NAME"
	else
		REPO_DIR="$XDG_CACHE_HOME/snowglobe-CI/repos/$REPO_OWNER/$REPO_NAME"
	fi

	if [ ! -d "$REPO_DIR/.git" ]; then
		mkdir -p "$REPO_DIR"
		git clone "$repo" --depth 1 "$REPO_DIR" || exit 1
	else
		cd "$REPO_DIR" || exit 1
		git stash
		git config pull.rebase true
		git pull || exit 1
	fi

	if [ ! -e "$REPO_DIR/flake.nix" ]; then
		printf "no flake.nix found in %s\n" "$REPO_DIR"
		continue
	fi

	cd "$REPO_DIR" || exit 1
	cp flake.nix flake.nix.bak

	# edit the flake.nix to point to the development branch
	if [ "$(cat "$REPO_DIR/flake.nix" | grep 'earthgman/snowglobe-lib' | grep 'ref=unstable')" ]; then
		# do nothing
		printf "already on dev branch\n"
	else
		sed -i 's|/earthgman/snowglobe-lib|/earthgman/snowglobe-lib?ref=unstable|' "$REPO_DIR/flake.nix"
	fi

	nix flake update snowglobe-lib

	if [ "$CHECK_ONLY" ]; then
		nix flake check || exit 1
		continue
	fi

	HOSTS=$(nix eval "$REPO_DIR#nixosConfigurations" --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"')

	for host in $HOSTS; do
		nh os build ".#nixosConfigurations.$host" || {
			msg="build for $host from repo: $REPO_OWNER/$REPO_NAME has failed"
			echo "$msg"
			notify-send -a "snowglobe-CI" "ci.sh" "$msg"
			mv flake.nix.bak flake.nix
			exit 1
		}
	done
	# return the flake to its original state
	mv flake.nix.bak flake.nix
done

cd "$PROJECT_ROOT" || exit 1
_end_sequence
