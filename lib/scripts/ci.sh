#!/bin/sh
# This script is used to verify all host configurations for the registered repositories
# It ensures that all configurations that depend on the module set do not have failing builds after a flake update.
# additionally it will ensure all packages are cached, preventing local builds for these hosts.

_errormsg() {
	printf "Error: %s\n" "$1"
	exit 1
}

y_or_n() {
	while :; do
		printf "%s: [y/n] " "$1"
		read -r yn

		case "$yn" in
		"Y" | "y") return 0 ;;
		"N" | "n") return 1 ;;
		*) printf "Not a valid response\n" ;;
		esac
	done
}

_end_sequence() {
	notify-send -a "snowglobe-CI" "ci.sh" "Configuration Checks complete"
	if systemctl is-active nix-post-build-hook-queue >/dev/null; then
		y_or_n "disable post-build-hook-queue?" && _disable_nix_uploader
	fi
	exit 0
}

_enable_nix_uploader() {
	if ! systemctl is-active nix-post-build-hook-queue.socket >/dev/null; then
		printf "Build hook queue is not enabled Authenticate to enable the service.\n"
		printf "Starting nix-post-build-hook-queue\n"
		sudo systemctl start nix-post-build-hook-queue.socket || _errormsg "Could not start post-build-hook-queue.sock"
		sudo systemctl start nix-post-build-hook-queue || _errormsg "Could not start post-build-hook-queue.service"
	fi
}

_disable_nix_uploader() {
	if systemctl is-active nix-post-build-hook-queue >/dev/null 2>&1; then
		printf "nix-post-build-hook-queue is enabled. Authenticate to disable.\n"
		sudo systemctl stop nix-post-build-hook-queue.socket || return 1
		sudo systemctl stop nix-post-build-hook-queue || return 1
	fi
}

# TODO build custom packages and package overlays
_build_packages() {
	SYSTEM_ARCH="$(lscpu | grep Arch | tr -d " " | cut -d: -f2)""-linux"
	_enable_nix_uploader
	for package in $(nix eval .\#packages."$SYSTEM_ARCH" --apply builtins.attrNames | tr -d '[]'); do
		nom build .#"$package" || _errormsg "Failed to build $package"
	done
	_end_sequence
}

# auto builds, signs, and uploads all installer images to the cache website
_build_installers() {
	WEBSITE_IP="192.168.25.69"
	UPLOAD_DIR="/tmp"

	ping -c 1 $WEBSITE_IP || _errormsg "Unable to reach webserver at: $WEBSITE_IP"

	INSTALLERS=$(
		for configuration in $(nix eval ".#nixosConfigurations" --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"'); do
			printf "%s\n" "$configuration"
		done | grep 'snowglobe-installer'
	)

	CACHE_DIR="$XDG_CACHE_HOME/snowglobe-CI/installers-hashes"
	mkdir -p "$CACHE_DIR" || exit 1

	ssh earthgman@$WEBSITE_IP 'mkdir -p /tmp/snowglobe-installers' || exit 1

	for image in $INSTALLERS; do
		# store isos so they can be shared between hosts
		ISO_DEST_PATH=~/Archive/isos/$image.iso
		HASH_DEST_PATH="$CACHE_DIR/$image.iso.sha256"
		nixos-rebuild build-image --image-variant iso-installer --flake .\#"$image" || {
			printf "Could not build the installer image: %s" "$image"
			exit 1
		}

		[ -e "$ISO_DEST_PATH" ] && rm -f "$ISO_DEST_PATH"

		cp result/iso/* "$ISO_DEST_PATH" || _errormsg "Could not copy image to $ISO_DEST_PATH"

		sha256sum "$ISO_DEST_PATH" | cut -d ' ' -f1 >"$HASH_DEST_PATH"
		gpg --sign --default-key 'EarthGman@protonmail.com' "$HASH_DEST_PATH" || _errormsg "Failed to sign iso image hash for $image"

		scp "$ISO_DEST_PATH" "$HASH_DEST_PATH"".gpg" "earthgman@$WEBSITE_IP:$UPLOAD_DIR/snowglobe-installers" || _errormsg "Could not copy image to the server."
	done

	rm -r "$CACHE_DIR"
}

[ "$XDG_CACHE_HOME" ] || XDG_CACHE_HOME="/tmp"
MODE="$(printf "build testmonkey
check repo flakes
build registered repos
build installers
build packages
unstable -> main" | fzf)"

case "$MODE" in
"build testmonkey") ;;
"check repo flakes")
	CHECK_ONLY=1
	BUILD_REGISTERED_REPOS=1
	;;
"build registered repos")
	BUILD_REGISTERED_REPOS=1
	;;
"unstable -> main")
	git checkout main
	git merge unstable || ERROR=1
	[ -z "$ERROR" ] && git push
	git checkout unstable
	[ "$ERROR" ] && exit 1
	exit 0
	;;
"build packages")
	_build_packages || exit 1
	exit 0
	;;
"build installers")
	_build_installers || exit 1
	exit 0
	;;
*) _errormsg "Nothing selected" ;;
esac

if [ ! -e .secrets/repo-urls.txt ] && [ "$BUILD_REGISTERED_REPOS" ]; then
	_errormsg "repo-urls were not found or you are not in the project root."
fi
[ -d nixosConfigurations/testmonkey ] || _errormsg "testmonkey config missing or not in project root"

if [ -z "$CHECK_ONLY" ]; then
	if command -v nh >/dev/null 2>&1; then
		nh os build .#testmonkey
	else
		nixos-rebuild build --flake .#testmonkey
	fi
fi

# early escape if no repo checks are being done
[ "$BUILD_REGISTERED_REPOS" ] || _end_sequence

GIT_BRANCH="$(git branch | grep '\*' | cut -d' ' -f2)"

REPOSITORIES=$(cat ".secrets/repo-urls.txt")
[ "$REPOSITORIES" ] || _errormsg "no repositories found in repo urls"
PROJECT_ROOT="$PWD"

[ ! "$CHECK_ONLY" ] && _enable_nix_uploader
for repo in $REPOSITORIES; do
	REPO_DOMAIN=$(printf "%s" "$repo" | cut -d/ -f3)
	REPO_OWNER=$(printf "%s" "$repo" | rev | cut -d/ -f2 | rev)
	REPO_NAME=$(printf "%s" "$repo" | rev | cut -d/ -f1 | rev)

	REPO_DIR="$XDG_CACHE_HOME/snowglobe-CI/repos/$REPO_DOMAIN/$REPO_OWNER/$REPO_NAME"

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
	# TODO allow arbitrary branches
	if [ "$(cat "$REPO_DIR/flake.nix" | grep 'earthgman/snowglobe-lib' | grep "ref=$GIT_BRANCH")" ]; then
		# do nothing
		printf "already on branch\n"
	else
		sed -i "s|/earthgman/snowglobe-lib.*|/earthgman/snowglobe-lib?ref=$GIT_BRANCH\";|" "$REPO_DIR/flake.nix"
	fi

	nix flake update snowglobe-lib || {
		mv -f flake.nix.bak flake.nix
		_errormsg "failed to update snowglobe-lib input for $repo"
	}

	if [ "$CHECK_ONLY" ]; then
		nix flake check || exit 1
		continue
	fi

	HOSTS=$(nix eval "$REPO_DIR#nixosConfigurations" --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"')

	for host in $HOSTS; do
		nh os build ".#nixosConfigurations.$host" || {
			msg="build for $host from repo: $REPO_OWNER/$REPO_NAME has failed"
			printf "%s\n" "$msg"
			notify-send -a "snowglobe-CI" "ci.sh" "Error: $msg"
			mv -f flake.nix.bak flake.nix
			exit 1
		}
	done
	# return the flake to its original state
	mv flake.nix.bak flake.nix
done

cd "$PROJECT_ROOT" || exit 1
_end_sequence
