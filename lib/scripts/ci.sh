#!/bin/sh
# This script is used to verify all host configurations for the registered repositories
# It ensures that all configurations that depend on the module set do not have failing builds after a flake update.
# additionally it will ensure all packages are cached, preventing local builds for these hosts.

# conceal identities of those enrolled for the checks
if [ ! -e .secrets/repo-urls.txt ]; then
	printf "Error: repo-urls were not found or you are not in the project root.\n"
	exit 1
fi

if [ "$1" = "--check-only" ]; then
	CHECK_ONLY=1
fi

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

if [ $(git branch | grep '*' | cut -d' ' -f2) != 'dev' ]; then
	printf "You are not on the development branch, Aborting."
	exit 1
fi

if ! git status | grep -q 'nothing to commit, working tree clean'; then
	y_or_n "Detected uncommitted changes, commit them now?" && {
		printf "Commit Message: "
		read -r COMMIT_MSG
		git add .
		git commit -m "$COMMIT_MSG"
		git push -u origin dev
	}
fi

nix flake check

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

	# edit the flake.nix to point to the development branch
	if [ "$(cat "$REPO_DIR/flake.nix" | grep 'earthgman/snowglobe-lib' | grep 'testing')" ]; then
		# if the repo is on the testing branch
		sed -i 's|/earthgman/snowglobe-lib?ref=testing|/earthgman/snowglobe-lib?ref=dev|' "$REPO_DIR/flake.nix"
	else
		sed -i 's|/earthgman/snowglobe-lib|/earthgman/snowglobe-lib?ref=dev|' "$REPO_DIR/flake.nix"
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
			sed -i 's|/EarthGman/snowglobe-lib?ref=dev|/EarthGman/snowglobe-lib?ref=testing|' "$REPO_DIR/flake.nix"
			exit 1
		}
	done
	# return the flake to its original state
	sed -i 's|/EarthGman/snowglobe-lib?ref=dev|/EarthGman/snowglobe-lib?ref=testing|' "$REPO_DIR/flake.nix"
done

cd "$PROJECT_ROOT" || exit 1

notify-send -a "snowglobe-CI" "ci.sh" "Configuration Checks successful\!"

y_or_n "Configuration checks successful, merge into testing?" && {
	git checkout testing
	git merge dev
	git push -u origin testing
	git checkout dev
}

exit 0
