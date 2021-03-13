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
	/^=head1 EXAMPLES/ ... /^=head1/ or next;
	/^\h/ or next;
	chomp;

	my ($name) = /[\h(]*([^|]+)/;

	my $cmd = $_;
	while (my ($subcmd, $args) = each %CMDARGS) {
		$subcmd .= " \\K", $args .= ' ' unless $subcmd =~ m/\\K/;
		$cmd =~ s/\b$subcmd/$args/;
	}
	ok(qx($cmd), $name);
}

done_testing();
