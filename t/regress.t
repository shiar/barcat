#!/bin/sh

cd "${0%/*}" || exit 1

test_count=0
fail_count=0

COLUMNS=40
colorize=
test -t 1 && colorize=1
color () {
	test -n "$colorize" &&
	printf '\e[%sm' $@
}
regenerate=
diffcmd () {
	comm --nocheck-order --output-delimiter=::: -3 $@ |
	perl -pe"END{exit !!\$.} s/^:::/$(color 31)>/ || s/^/$(color 32)</"
}

for option in "$@"
do
	case "$option" in
	-G) regenerate=1 && shift;;
	-*) echo "Usage: $0 [-G] [<files>...]"; exit 64;;
	esac
done

for candidate in ${@:-t*.out}
do
	test_count=$((test_count+1))
	file="${candidate%.out}"
	input="${file%%_-*}.in"
	name="$(echo ${file#*-} | tr _ \ )"

	set -- barcat
	[ -r "$input" ] && set -- "$@" "$input"
	case "$name" in *\ -*) set -- "$@" -"${name#* -}";; esac
	case "$name" in
		*' |'*) set -- sh -c "\$0 \$1 | ${name#* |}" "$@";;
		*)      set -- "$1" $2 $3
	esac

	if test -n "$regenerate"
	then
		if test -e $file.sh
		then
			echo "ok $test_count # skip $file.out"
			continue
		fi
		"$@" >$file.out 2>&1
	elif test -e "$file.out"
	then
		"$@" 2>&1 | diffcmd "$file.out" -
	else
		color 33
		echo "not ok $test_count - $name # TODO"
		color 0
		continue
	fi

	if test 0 != $?
	then
		fail_count=$((fail_count+1))
		color 1\;31
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

color 0\;36
echo "1..$test_count"
color 0
exit $fail_count
