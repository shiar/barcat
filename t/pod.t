#!/usr/bin/env perl
use 5.012;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => "Test::Pod required to test documentation" if $@;

plan tests => 1;
pod_file_ok('barcat', 'pod syntax');
