#!/bin/sh

# wrapper around nixos-rebuild, ensuring configurations are automaically logged and commited to git
# TODO add generation and maybe hash to commit log
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
		[ "$STATUS" = "Error" ] && _errormsg "$MSG"
	else
		[ "$STATUS" = "Error" ] && _errormsg "$MSG"
		printf "%s: %s\n" "$STATUS" "$MSG"
	fi
}

# main
[ "$1" ] || _errormsg "Unknown usage."
case "$1" in
"test")
	NEEDS_SUDO=1
	CAN_USE_NH_OS=1
	;;
"switch" | "boot")
	PERSISTENT=true
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
	_errormsg "no flake found $FLAKE_DIR"
fi

[ -d "$FLAKE_DIR/.git" ] && GIT_REPO_PRESENT=1

cd "$FLAKE_DIR" || _errormsg "Could not change working directory to $FLAKE_DIR"

_disable_git_sync() {
	y_or_n "Continue without git synchronization features?"

	case "$yn" in
	"Y" | "y") IGNORE_GIT_SYNCHRONIZATION=1 ;;
	"N" | "n") _errormsg "Aborted" ;;
	esac
}

if [ "$GIT_REPO_PRESENT" ]; then
	git ls-remote || {
		printf "Could not reach the remote repository, Maybe it is down or you do not have access rights?\n"
		_disable_git_sync
	}

	# dont stash if you have no local changes to commit
	git status | grep -q 'nothing to commit, working tree clean' && SKIP_STASH

	# ensure that your repo is synced with your remote in case you pushed from another host in your fleet
	if [ "$PERSISTENT" ] && [ ! ${IGNORE_GIT_SYNCHRONIZATION+x} ]; then
		if [ "$SKIP_STASH" ]; then
			git pull || _disable_git_sync
		else
			git stash || _disable_git_sync
			[ "$IGNORE_GIT_SYNCHRONIZATION" ] || git pull || _disable_git_sync
			[ "$IGNORE_GIT_SYNCHRONIZATION" ] || git stash apply >/dev/null || _errormsg "Could not apply git stash"
		fi
	fi

	# ensure all changes are staged so nix doesn't yell at you
	git add . || _errormsg "Could not stage changes. This is required by nix even without git synchronization from this script."
fi

if [ "$(whoami)" = "root" ]; then
	unset CAN_USE_NH_OS
	unset NEEDS_SUDO
fi

if ! command -v nh >/dev/null 2>&1 && [ ${CAN_USE_NH_OS+x} ]; then
	unset CAN_USE_NH_OS
fi

ERRORMSG="Rebuild failed or timeout reached."
if [ "$NEEDS_SUDO" ] && [ ! ${CAN_USE_NH_OS+x} ]; then
	sudo nixos-rebuild "$@" || _notify "Error" "$ERRORMSG"
elif [ ${CAN_USE_NH_OS+x} ]; then
	NH_OS_FLAKE="$(readlink -f "$FLAKE_DIR")" export NH_OS_FLAKE
	nh os "$@" || _notify "Error" "$ERRORMSG"
else
	nixos-rebuild "$@" || _notify "Error" "$ERRORMSG"
fi

if [ "$PERSISTENT" ]; then
	# keep a log file of your system updates
	UPDATE_LOG="$FLAKE_DIR/updates.log"
	HOSTNAME="$(cat /etc/hostname)"
	FLAKE_DIR_OWNER=$(stat -c '%U' -L "$FLAKE_DIR")
	if [ ! -e "$UPDATE_LOG" ]; then
		# sudo use should already be cached from nixos-rebuild or nh os
		touch "$UPDATE_LOG" >/dev/null 2>&1 || sudo touch "$UPDATE_LOG"
	fi

	NIXOS_GENERATION_INFO=$(nixos-rebuild list-generations | grep True | tr -s ' ' | cut -d' ' -f1-5)
	GENERATION=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f1)
	TIMESTAMP=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f2-3)
	KERNEL_VERSION=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f5)

	PREVIOUS_GENERATIION=$(cat $UPDATE_LOG | head --lines 3 | grep Generation | cut -d'-' -f2 | tr -d ' ')
	LOG=1
	[ "$GENERATION" = "$PREVIOUS_GENERATIION" ] && unset LOG

	if [ ${LOG+x} ]; then
		UPDATE_MSG="$(
			printf "%s\n%s
Generation - %s
Kernel - %s\n\n" \
				"$HOSTNAME" "$TIMESTAMP" "$GENERATION" "$KERNEL_VERSION"
		)"
		printf "%s\n\n" "$UPDATE_MSG" | cat - "$UPDATE_LOG" >/tmp/snowglobe-system-update.log
		if [ "$(whoami)" = "$FLAKE_DIR_OWNER" ]; then
			mv /tmp/snowglobe-system-update.log "$FLAKE_DIR/updates.log" || _errormsg "Could not move updates.log into place"
		else
			sudo mv /tmp/snowglobe-system-update.log "$FLAKE_DIR/updates.log" || _errormsg "Could not move updates.log into place"
		fi

		if [ ! ${IGNORE_GIT_SYNCHRONIZATION+x} ]; then
			printf "Successfully switched configuration. Now commit your changes.\n"
			# give a brief overview of what will be committed
			git status
			printf "Commit message: "
			read -r COMMIT_MSG
			git add . || _errormsg "could not stage changes"
			git commit -m "$COMMIT_MSG" || _errormsg "Could not commit to git"
			git push || _errormsg "Could not push to remote repository"
		fi
	fi
fi
