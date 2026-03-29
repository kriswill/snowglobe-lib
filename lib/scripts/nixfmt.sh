#!/bin/sh
PROJECT_ROOT=$1

echo "formatting nix files in $PROJECT_ROOT"
# exclude all hidden files to prevent massive computational overhead
for i in $(find $PROJECT_ROOT -type f -not -path '*/.*'); do
	case "$i" in
	*".nix")
		printf "formatting nix file %s\n" "$i"
		nixfmt "$i"
		;;
	*)
		continue
		;;
	esac
done
