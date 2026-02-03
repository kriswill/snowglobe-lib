#!/bin/sh

# update flakes of various projects to ensure that all inputs are in sync with this repository.
PROJECTS_DIR=~/src/git
PROJECT_DIRS="$PROJECTS_DIR/earthgman.dev/earthgman/nix-modules
$PROJECTS_DIR/earthgman.dev/earthgman/nixos-hosts
$PROJECTS_DIR/earthgman.dev/earthgman/dotfiles"

for project in $PROJECT_DIRS; do
	cd "$project" || exit 1
	pwd
	nix flake update
done
