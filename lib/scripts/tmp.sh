#!/bin/sh

for file in $(ls -A "$1"); do
	sed -i 's|earthgman|snowglobe-core|g' "$file"
	sed -i 's|EarthGman|Snowglobe-Core|g' "$file"
done
