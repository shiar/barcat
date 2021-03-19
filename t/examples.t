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
	curl => '-sS',
	'cat \Klog/' => '/var/log/apache2/',
);

my $filename = 'barcat';
open my $input, '<', $filename
	or die "Cannot read documentation from $filename script\n";

local $/ = "\n\n";
while (readline $input) {
	# find code snippets in the appropriate section
	/^=head1 EXAMPLES/ ... /^=head1/ or next;
	/^\h/ or next;
	chomp;

	# compose an identifier from significant parts
	do {
		s/^\h+//;             # indentation
		s/\\\n\s*//g;         # line continuations
		s/^[(\h]+//;          # subshell
		s/^echo\ .*?\|\s*//;  # preceding input
		s/\|.*//;             # subsequent pipes
		s/^cat\ //;           # local file
		s/^curl\ // and do {  # remote url
			s/\ -.+//g;                 # download options
			s{//[^/\s]+/\K\S*(?=/)}{};  # subdirectories
			s{^https?://}{};            # http protocol
		};
	} for my $name = $_;

	# prepare shell command to execute
	my $cmd = $_;
	while (my ($subcmd, $args) = each %CMDARGS) {
		$subcmd .= " \\K", $args .= ' ' unless $subcmd =~ m/\\K/;
		$cmd =~ s/\b$subcmd/$args/;
	}
	my @cmd = (bash => -c => "set -o pipefail\n$cmd");

	# run and report unexpected results
	ok(eval {
		run(\@cmd, \undef, \my $output, \my $error);
		die("error message:\n    $error\n") if $error;
		$? == 0 or die "exit status ", $? >> 8, "\n";
		length $output or die "empty output\n";
		return 1;
	}, $name) or diag("Failed command\n@cmd\nfrom $filename line $.: $@");
}

done_testing();
