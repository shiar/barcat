#!/bin/sh

cd "${0%/*}" || exit 1

test_count=0

COLUMNS=40
diffcmd='diff --unchanged-line-format= --old-line-format=<%L --new-line-format=>%L'

for candidate in ${@:-t*.in}
do
	test_count=$((test_count+1))
	name="${candidate%.out}"
	barcat <"$name.in" | $diffcmd "$name.out" - || printf 'not '
	echo "ok $test_count - $name"
done

echo "1..$test_count"
