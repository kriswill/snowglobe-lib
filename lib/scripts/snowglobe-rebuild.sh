#!/bin/sh

# wrapper around nixos-rebuild, ensuring configurations are automaically logged and commited to git
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

_errormsg() {
	MSG="$1"
	printf "Error: %s\n" "$MSG"
	exit 1
}

_notify() {
	STATUS=$1
	MSG=$2
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -a "snowglobe-rebuild" "$STATUS" "$MSG"
	else
		[ "$STATUS" = "Error" ] && _errormsg "$MSG"
		printf "%s: %s\n" "$STATUS" "$MSG"
	fi
}

# main
if [ ! "$1" ]; then
	_errormsg "Unknown usage."
fi

case "$1" in
"help" | "--help")
	printf "Wrapper around nixos-rebuild that provides some quality of life features for nixos-users.\n"
	printf "  --help - prints this menu\n"
	exit 0
	;;
"test")
	NEEDS_SUDO=1
	CAN_USE_NH_OS=1
	;;
"switch" | "boot")
	PERSISTENT_CONFIGURATION_CHANGE=true
	NEEDS_SUDO=1
	CAN_USE_NH_OS=1
	;;
"repl" | "info" | "rollback")
	CAN_USE_NH_OS=1
	;;
*) ;;
esac

ARG_IDX=1
for arg in "$@"; do
	NEXT_ARG=$(printf "%s " "$@" | cut -d' ' -f$((ARG_IDX + 1)))
	if [ "$arg" = "--flake" ]; then
		FLAKE_DIR="$(readlink -f "$(printf "%s" "$NEXT_ARG" | cut -d'#' -f1)")"
	fi
	ARG_IDX=$((ARG_IDX + 1))
done

if [ -z ${FLAKE_DIR+x} ]; then
	FLAKE_DIR="/etc/nixos"
fi

if [ ! -d "$FLAKE_DIR" ] || [ ! -e "$FLAKE_DIR/flake.nix" ]; then
	_errormsg "no flake found "$FLAKE_DIR""
fi
if [ -d "$FLAKE_DIR/.git" ]; then
	GIT_REPO_PRESENT=true
fi

cd "$FLAKE_DIR" || _errormsg "Could not change working directory to $FLAKE_DIR"

if [ "$GIT_REPO_PRESENT" ]; then
	git ls-remote || {
		printf "Could not reach the remote repository, Maybe it is down or you do not have access rights?\n"
		y_or_n "Continue without git synchronization features?"
		case "$yn" in
		"Y" | "y")
			IGNORE_GIT_SYNCHRONIZATION=1
			;;
		"N" | "n")
			_errormsg "Aborted"
			;;
		esac
	}

	# ensure all changes are staged so nix doesn't yell at you
	git add .

	# make sure that your module modifications are logged with a standalone commit
	if [ "$PERSISTENT_CONFIGURATION_CHANGE" ] && [ ! ${IGNORE_GIT_SYNCHRONIZATION+x} ]; then
		if ! git status | grep -q 'nothing to commit, working tree clean'; then
			git status
			printf "Detected these uncommitted changes in your repository, You should commit them now (Press Ctrl+C to abort)\n"
			printf "Commit Message: "
			read -r COMMIT_MSG
			git commit -m "$COMMIT_MSG"
		fi
		# TODO working auto conflict resolution?
		git pull || exit 1
	fi
fi

if [ "$(whoami)" = "root" ]; then
	IS_ROOT=1
	unset CAN_USE_NH_OS
fi

if ! command -v nh >/dev/null 2>&1 && [ ${CAN_USE_NH_OS+x} ]; then
	unset CAN_USE_NH_OS
fi

ERRORMSG="Rebuild failed or timeout reached."
if [ "$NEEDS_SUDO" ] && [ ! ${CAN_USE_NH_OS} ]; then
	sudo nixos-rebuild "$@" || _notify "Error" "$ERRORMSG"
elif [ ${CAN_USE_NH_OS+x} ]; then
	NH_OS_FLAKE="$(readlink -f "$FLAKE_DIR")" export NH_OS_FLAKE
	nh os "$@" || _notify "Error" "$ERRORMSG"
else
	nixos-rebuild "$@" || _notify "Error" "$ERRORMSG"
fi

if [ "$PERSISTENT_CONFIGURATION_CHANGE" ]; then
	# keep a log file of your system updates
	UPDATE_LOG="$CONFIG_DIR/updates.log"
	HOSTNAME="$(cat /etc/hostname)"
	if [ ! -e "$UPDATE_LOG" ]; then
		if [ "$IS_ROOT" ]; then
			touch "$UPDATE_LOG"
		else
			sudo touch "$UPDATE_LOG"
		fi
	fi

	UPDATE_MSG="$(printf "%s\nUpdated System - %s\n\n" "$(date)" "$HOSTNAME")"
	printf "%s\n\n" "$UPDATE_MSG" | cat - "$UPDATE_LOG" >/tmp/nixos-update.log && mv /tmp/nixos-update.log "$UPDATE_LOG"

	if [ "$GIT_REPO_PRESENT" ] && [ ! ${IGNORE_GIT_SYNCHRONIZATION+x} ]; then
		# commit the changes to the updates.log
		git add .
		git commit -m "Updated System - $HOSTNAME"
		git push || {
			printf "Failed to push to remote repository\n"
			exit 1
		}
	fi
fi
