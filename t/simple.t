#!/usr/bin/perl -w

use strict;
use Text::CSV::Simple;
use Test::More tests => 12;

my $datafile = "data/test.csv";

{
	my $parser = Text::CSV::Simple->new;
	my @data = $parser->read_file($datafile);
	is @data, 3, "Got 3 rows";
	is @{$data[0]}, 3, "and 3 cols";
	is $data[0]->[0], 1, "1:1";
	is $data[1]->[1], "bar, baz", "2:2";
	is $data[2]->[2], 103, "3:3";
}

{
	my $parser = Text::CSV::Simple->new;
	$parser->want_fields(1, 2);
	my @data = $parser->read_file($datafile);
	is @data, 3, "Got 3 rows";
	is @{$data[0]}, 2, "but only 2 rows";
	is $data[0]->[0], "foo Bar", "start at 2nd row";
}

{
	my $parser = Text::CSV::Simple->new;
	$parser->field_map(qw/id value null/);
	my @data = $parser->read_file($datafile);
	is @data, 3, "Got 3 rows";
	my %hash = %{ $data[0] };
	is $hash{id}, 1, "Hash id";
	is $hash{value}, "foo Bar", "Hash value";
	is $hash{null}, undef, "nothing in null";
}

