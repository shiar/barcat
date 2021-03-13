#!/usr/bin/env perl
use 5.014;
use warnings;
use Test::More;

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

	my ($name) = /[\h(]*([^|]+)/;

	# prepare shell command to execute
	my $cmd = $_;
	while (my ($subcmd, $args) = each %CMDARGS) {
		$subcmd .= " \\K", $args .= ' ' unless $subcmd =~ m/\\K/;
		$cmd =~ s/\b$subcmd/$args/;
	}
	$cmd =~ s/'/'\\''/g, $cmd = "bash -c 'set -o pipefail\n$cmd'";

	# run and report unexpected results
	ok(eval {
		qx($cmd) or return;
		return $? == 0;
	}, $name);
}

done_testing();
