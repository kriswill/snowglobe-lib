#!/bin/sh
# wrapper around nixos-rebuild, ensuring configuration switches are automaically logged and commited to git

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

_notify() {
	STATUS=$1
	MSG=$2
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -a "snowglobe-rebuild" "$STATUS" "$MSG" || printf "%s\n" "$MSG"
	else
		printf "%s: %s\n" "$STATUS" "$MSG"
	fi
	[ "$STATUS" = "Error" ] && exit 1
}

# main
case "$1" in
"help" | "--help")
	printf "  --help - prints this menu\n"
	printf "\n  Arg 1:\n"
	printf "  ------\n"
	printf "  switch - Switch configuration. Log and commit to your bootloader and git repository (if present)\n"
	printf "  test - Switch configuration temporarily. Changes will be reverted after boot\n"
	printf "  boot - Identical to switch except the configuration is only applied when the system is rebooted.\n"
	printf "  build - Build the targeted configuration\n"
	printf "\n  Optional Flags:\n"
	printf "  ------\n"
	printf "  --config-dir=path - the root location of your NixOS configuration flake. Defaults to /etc/nixos.\n"
	printf "  --update-inputs=input1,input2 - comma seperated list of flake inputs to update. Defaults to 'snowglobe-lib'\n"
	exit 0
	;;

"switch" | "boot")
	PERSISTENT_UPDATE=true
	;;
"test" | "build")
	# do nothing
	;;
*)
	printf "Unsupported usage. Use --help for a list of commands\n"
	exit 1
	;;
esac

for arg in "$@"; do
	ARG_NAME="$(printf "%s" "$arg" | cut -d= -f1)"
	ARG_VAL="$(printf "%s" "$arg" | cut -d= -f2)"
	case "$ARG_NAME" in
	# ignore first argument
	"$1")
		continue
		;;

	"--update-inputs")
		INPUTS_TO_UPDATE=$(printf "%s" "$ARG_VAL" | tr ',' ' ')
		;;
	"--config-dir")
		if [ -z "$ARG_VAL" ]; then
			printf "Error: No directory provided to --config-dir\n"
			exit 1
		fi
		CONFIG_DIR="$ARG_VAL"
		if [ ! -d "$CONFIG_DIR" ]; then
			printf "Error: specified directory for --config-dir was not found.\n"
			exit 1
		fi
		;;
	esac
done

if [ -z "$CONFIG_DIR" ]; then
	CONFIG_DIR="/etc/nixos"
fi
CONFIG_DIR="$(readlink -f "$CONFIG_DIR")"

if [ ! -e "$CONFIG_DIR/flake.nix" ]; then
	printf "Error: no flake.nix was found in the specified configuration directory: %s\n" "$CONFIG_DIR"
	exit 1
fi

if [ -d "$CONFIG_DIR/.git" ]; then
	GIT_REPO_PRESENT=true
fi

cd "$CONFIG_DIR" || printf "Error: could not change working directory to %s" "$CONFIG_DIR"

if [ "$INPUTS_TO_UPDATE" ]; then
	for input in $INPUTS_TO_UPDATE; do
		nix flake update "$input"
	done
fi

if [ "$GIT_REPO_PRESENT" ]; then
	git ls-remote || {
		printf "Could not reach the remote repository, Maybe it is down or you do not have access rights?\n"
		exit 1
	}

	# ensure all changes are staged so nix doesn't yell at you
	git add .

	# make sure that your module modifications are logged with a standalone commit
	if [ "$PERSISTENT_UPDATE" ]; then
		if ! git status | grep -q 'nothing to commit, working tree clean'; then
			git status
			printf "Detected these uncommitted changes in your repository, You should commit them now (Press Ctrl+C to abort)\n"
			printf "Commit Message: "
			read -r COMMIT_MSG
			git commit -m "$COMMIT_MSG"
		fi
		# TODO working auto conflict resolving
		git pull || exit 1
	fi
fi

# use _notify so a desktop notification is sent when the rebuild fails or succeeds.
ERRORMSG="Rebuild failed or sudo timed out."
# nh complains if you run it as root
if type nh >/dev/null && [ "$(whoami)" != "root" ] >/dev/null; then
	nh os "$1" "$CONFIG_DIR" || _notify "Error" "$ERRORMSG"
else
	# TODO build functionality
	nixos-rebuild "$1" --flake "$CONFIG_DIR" || _notify "Error" "$ERRORMSG"
fi

if [ "$PERSISTENT_UPDATE" ]; then
	# keep a log file of your system updates
	# TODO cannot create if owned by root
	UPDATE_LOG="/etc/nixos/updates.log"
	HOSTNAME="$(cat /etc/hostname)"
	if [ ! -e "$UPDATE_LOG" ]; then
		touch "$UPDATE_LOG"
	fi
	UPDATE_MSG="$(printf "%s\nUpdated System - %s\n\n" "$(date)" "$HOSTNAME")"
	printf "%s\n\n" "$UPDATE_MSG" | cat - "$UPDATE_LOG" >/tmp/nixos-update.log && mv /tmp/nixos-update.log "$UPDATE_LOG"

	if [ "$GIT_REPO_PRESENT" ]; then
		# commit the changes to the updates.log
		git add .
		git commit -m "Updated System - $HOSTNAME"
		git push || {
			printf "Failed to push to remote repository\n"
			exit 1
		}
	fi
fi
