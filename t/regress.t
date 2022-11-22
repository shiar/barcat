#!/usr/bin/env perl
use 5.014;
use warnings;
use re '/ms';
use Getopt::Long qw(2.32 :config gnu_getopt);
use Test::More;
use File::Basename;
use IPC::Run 'run';
use Data::Dump 'pp';

chdir dirname($0) or exit 1;

GetOptions(\my %opt,
	'regenerate|G!',
) or do {
	say "Usage: $0 [-G] [<files>...]";
	exit 64;  # EX_USAGE
};

local $ENV{COLUMNS} = 40;

my @params = @ARGV ? @ARGV : glob 't*.out';
plan(tests => int @params);

for my $candidate (@params) {
	my $file = basename($candidate, '.out');
	(my $name = $file =~ s/^[^-]*-//r) =~ tr/_/ /;
	my $todo = $name =~ s/ #TODO$//;

	my $diff;
	if ($opt{regenerate}) {
		if (-e "$file.sh") {
			skip("$file.out", 1);
			next;
		}
		#run(\@run, '>&', "$file.out");
	}
	elsif (!-e "$file.out") {
		local $TODO = 'missing output';
		fail($name);
		next;
	}
	else {
		run(['./cmddiff', "$file.out"], '>', \$diff);
	}

	local $TODO = $todo ? ' ' : undef;
	is($? >> 8, 0, $name) or do {
		#diag('command: ', pp(@run));
		diag($diff);  #TODO native
	};
}

done_testing();
