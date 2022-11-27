#!/usr/bin/env perl
use 5.014;
use warnings;
use re '/ms';
use Getopt::Long qw(2.32 :config gnu_getopt);
use Test::More;
use File::Basename;

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
	my $name = basename($candidate, '.out');
	$name =~ tr/_/ /;
	my $todo = $name =~ s/ #TODO$//;
	local $TODO = $todo ? ' ' : undef;

	if (!-e $candidate) {
		local $TODO = 'missing output';
		fail($name);
		next;
	}

	open my $fh, '<', $candidate or die "missing $candidate: $!\n";
	!!(my $spec = readline $fh)
		or die "input lacks a script on the first line\n";

	my $script = $spec;
	chomp $script;
	my $wantexit = $script =~ s/\h+[?](\d+)\z// ? $1 : 0;
	my $wantwarn = $script !~ s/[?]\z//;
	my $shell = $script;
	if ($script =~ /\|/) {
		# explicit shell wrapper to capture all warnings
		$script =~ s/'/'\\''/g;
		$shell = "sh -c '$shell'";
	}
	$shell .= ' 2>' . ($wantwarn ? '&1' : '/dev/null');

	open my $cmd, '-|', $shell or do {
		fail($name);
		diag("open failure: $!");
		diag("command: $script");
		next;
	};
	my @lines = readline $cmd;
	close $cmd;
	my $error = $? >> 8;

	if ($opt{regenerate}) {
		#TODO: error
		open my $rewrite, '>', $candidate;
		print {$rewrite} $_ for $spec, @lines;
	}

	if ($error != $wantexit) {
		fail($name);
		diag("unexpected exit status $error");
		diag("command: $script");
		next;
	}

	my @diff;
	my @wanted = readline $fh;

	while (@lines or @wanted) {
		my $was = shift @wanted;
		my $is  = shift @lines;
		next if defined $was and defined $is and $was eq $is;
		push @diff, color(32) . "< " . color(0) . $_ for $was // ();
		push @diff, color(31) . "> " . color(0) . $_ for $is  // ();
	}

	ok(!@diff, $name) or do {
		diag(@diff);
		diag("command: $script");
	};
}

done_testing();

sub color {
	return !$ENV{NOCOLOR} && "\e[@{_}m";
}
