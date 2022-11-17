#!/usr/bin/env perl
use 5.014;
use warnings;
use re '/ms';
use IPC::Run 'run';

use Test::More;
{ # silence fail diagnostics because of single caller
	no warnings 'redefine';
	sub Test::Builder::_ok_debug {}
}

my %CMDARGS = (
	ping => '-c 1',
	'cat \Khttpd/' => '/var/log/apache2/',
);

my $filename = 'barcat';
open my $input, '<', $filename
	or die "Cannot read documentation from $filename script\n";

local $/ = "\n\n";
while (readline $input) {
	# find scriptlets in the appropriate section
	/^=head1 EXAMPLES/ ... /^=head1/ or next;
	/^\h/ or next;  # indented code snippet
	/\A\h*>/ and next;  # psql prompt
	chomp;
	my $cmd = $_;
	my $ref = "$filename line $.";

	# store curl downloads
	s{\bcurl (\S*)(?<param>[^|]*)}{
		my $url = $1;
		my @params = split ' ', $+{param};
		my $ext = (
			$cmd =~ /\bxml/     ? 'xml'  :
			$cmd =~ / jq /      ? 'json' :
			$cmd =~ /[=.]csv\b/ ? 'csv'  :
			                      'txt'
		);
		my ($domain, $path) = $url =~ m{//([^/]+) .*/ ([^/]*) \z}x;
		$path =~ s/\.$ext\z//;
		my $cache = join '.', $path =~ tr/./_/r, $domain, $ext;
		$cache = "sample/data/$cache";
		SKIP: {
			-e $cache and skip($url, 1);
			ok(defined runres(['curl', '-sS', $url, '-o', $cache, @params]), $url)
				or diag("download at $ref: $@");
		}
		"cat $cache"
	}e;

	# compose an identifier from significant parts
	do {
		s/^\h+//;             # indentation
		s/\\\n\s*//g;         # line continuations
		s/^[(\h]+//;          # subshell
		s/^echo\ .*?\|\s*//;  # preceding input
		s/'(\S+)[^']*'/$1/g;  # quoted arguments
		s/\h*\|.*//;          # subsequent pipes
		s/^cat\ (?:\S+\/)?//; # local file
	} for my $name = $cmd;

	# prepare shell command to execute
	while (my ($subcmd, $args) = each %CMDARGS) {
		$subcmd .= " \\K", $args .= ' ' unless $subcmd =~ m/\\K/;
		$cmd =~ s/\b$subcmd/$args/;
	}

	# run and report unexpected results
	my $output = runres($cmd);
	ok(!!$output, $name)
		or diag("command at $ref\n$cmd\n" . ($@ || 'empty output'));
	defined $output or next;

	# record output for review
	my $numprefix = sprintf '%02d', Test::More->builder->current_test;
	if (open my $record, '>', "sample/out/t$numprefix-$name.txt") {
		print {$record} $output;
	}
}

sub runres {
	my ($cmd) = @_;
	ref $cmd eq 'ARRAY'
		or $cmd = [bash => -c => "set -o pipefail\n$cmd"];
	eval {
		run($cmd, \undef, \my $output, \my $error);
		die("error message:\n".($error =~ s/^/    /gr)."\n") if $error;
		$? == 0 or die "exit status ", $? >> 8, "\n";
		return $output;
	};
}

done_testing();
