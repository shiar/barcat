#!/usr/bin/env perl
use 5.014;
use warnings;
use re '/ms';

use Test::More;
{ # silence fail diagnostics because of single caller
	no warnings 'redefine';
	sub Test::Builder::_ok_debug {}
}

eval q(use IPC::Run 'run');
plan skip_all => "IPC::Run required to test commands" if $@;

my %CMDARGS = (
	ping => '-c 1 ',
	' \Khttpd/' => 'sample/data/',
	' \K\*(?=\h*\|)' => 'sample/media/*.*',
	find => 'sample/media -name \*.\* ',
);

my $filename = 'barcat';
open my $input, '<', $filename
	or die "Cannot read documentation from $filename script\n";

local $/ = "\n\n";
while (readline $input) {
SKIP: {
	# find scriptlets in the appropriate section
	/^=head1 EXAMPLES/ ... /^=head1/ or next;
	/^\h/ or next;  # indented code snippet
	/\A\h*>/ and next;  # psql prompt
	chomp;
	my $cmd = $_;
	my $ref = "$filename line $.";

	# store curl downloads
	$cmd =~ s{\bcurl (\S*)([^|]*)}{
		my ($url, $params) = ($1, $2);
		my $cache = 'sample/data/';
		-w $cache or skip($url, 2);
		my $ext = (
			$cmd =~ /\bxml/     ? 'xml'  :
			$cmd =~ / jq /      ? 'json' :
			$cmd =~ /[=.]csv\b/ ? 'csv'  :
			                      'txt'
		);
		my ($domain, $path) = $url =~ m{//([^/]+) .*/ ([^/]*) \z}x;
		$path =~ s/\.$ext\z//;
		$cache .= join '.', $path =~ tr/./_/r, $domain, $ext;
		my $cached = -e $cache;
		SKIP: {
			# download to file
			skip($url, 1) if $cached;
			$cached = defined runres("curl -sSf $url$params -o $cache");
			ok($cached, $url) or diag("download at $ref: $@");
		}
		$cached or skip($url, 1);
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
		s/\S*\///g;           # preceding paths
	} for my $name = $cmd;

	# prepare shell command to execute
	while (my ($subcmd, $args) = each %CMDARGS) {
		$subcmd .= " \\K" unless $subcmd =~ m/\\K/;
		$cmd =~ s/$subcmd/$args/;
	}

	for my $param ($cmd =~ m{^[(\h]* (\w\S*)}gx) {
		$param eq 'cat' or
		runres(['which', $param])
			or diag("dependency $param missing at $ref\n$cmd"), skip($name, 1);
	}

	# run and report unexpected results
	my $output = runres($cmd);
	ok(!!$output, $name)
		or diag("command at $ref\n$cmd\n" . ($@ || 'empty output'));
	defined $output or next;

	# record output for review
	my $outname = "sample/out/";
	-w $outname or next;
	my $numprefix = sprintf '%02d', Test::More->builder->current_test;
	$outname .= "t$numprefix-$name.txt";
	open my $record, '>', $outname
		or diag("output not saved in $outname: $!"), next;
	print {$record} $output;
}}

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
