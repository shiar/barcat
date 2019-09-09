#!/bin/sh

cd "${0%/*}" || exit 1

test_count=0

COLUMNS=40
diffcmd='diff --unchanged-line-format= --old-line-format=<%L --new-line-format=>%L'
regenerate=

for option in "$@"
do
	case "$option" in
	-G) regenerate=1 && shift;;
	-*) echo "Usage: $0 [-G] [<files>...]"; exit 64;;
	esac
done

for candidate in ${@:-t*.in}
do
	test_count=$((test_count+1))
	file="${candidate%.in}"
	test -r "$file.in" || continue

	name="$(echo ${file#*-} | tr _ \ )"
	cmd="barcat $file.in"
	case "$name" in *\ -*) cmd="$cmd -${name#* -}";; esac

	if test -n "$regenerate"
	then
		if test -e $file.out
		then
			echo "ok $test_count # skip existing $file.out"
			continue
		fi
		$cmd >$file.out 2>&1
	else
		$cmd 2>&1 | $diffcmd "$file.out" -
	fi

	test 0 = $? || printf 'not '
	echo "ok $test_count - $name"
done

echo "1..$test_count"
