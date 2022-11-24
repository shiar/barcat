#!/bin/sh

cd "${0%/*}" || exit 1

test_count=0
fail_count=0

colorize=
test -t 1 && colorize=1
color () {
	test -n "$colorize" &&
	printf '\33[%sm' $@
}

for option in "$@"
do
	case "$option" in
	-*) echo "Usage: $0 [<files>...]"; exit 64;;
	esac
done

params="${@:-t*.out}"
color 0\;36
echo "1..$(echo $params | wc -w)"
color 0

for candidate in $params
do
	test_count=$((test_count+1))
	file="${candidate%.out}"
	name="$(echo ${file#*-} | tr _ \ )"

	if test -e "$file.out"
	then
		./cmddiff "$file.out"
	else
		color 33
		echo "not ok $test_count - $name # TODO"
		color 0
		continue
	fi

	if test 0 != $?
	then
		case "$name" in
		*' #TODO')
			color 33
			;;
		*)
			fail_count=$((fail_count+1))
			color 1\;31
		esac

		printf 'not '
	fi
	echo "ok $test_count - $name"
	color 0
done

if test $fail_count = 0
then
	color 32
	echo "# passed all $test_count test(s)"
else
	color 31
	echo "# failed $fail_count among $test_count test(s)"
	fail_count=1  # exit code
fi
color 0

exit $fail_count
