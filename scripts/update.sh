#!/usr/bin/env bash

if [[ ! -d /etc/nixos ]]; then
	echo "/etc/nixos does not exist. You should create the directory or move the configuration there first."
	exit 1
fi

pushd /etc/nixos >/dev/null
nix flake update gman
popd >/dev/null

if [[ $(type nh) ]]; then
	nh os switch /etc/nixos
else
	nixos-rebuild switch --flake /etc/nixos
fi
