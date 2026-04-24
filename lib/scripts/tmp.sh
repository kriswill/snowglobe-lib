#!/bin/sh

for file in $(find . -type f | grep -ve '.git' -e '.direnv' -e '.secrets'); do
	sed -i "s|Snowglobe-Lib's|Snowglobe-Lib's|g" "$file"
done
