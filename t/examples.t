#!/usr/bin/env perl
use 5.014;
use warnings;
use Test::More;

my $filename = 'barcat';
open my $input, '<', $filename
	or die "Cannot read documentation from $filename script\n";

local $/ = "\n\n";
while (readline $input) {
	/^=head1 EXAMPLES/ ... /^=head1/ or next;
	/^\h/ or next;
	chomp;

	my ($name) = /[\h(]*([^|]+)/;
	ok(qx($_), $name);
}

done_testing();
