package Text::CSV::Simple;

$VERSION = '0.10';

use strict;

use Text::CSV_XS;
use File::Slurp ();

=head1 NAME

Text::CSV::Simple - Simpler parsing of CSV files

=head1 SYNOPSIS

	my $parser = Text::CSV::Simple->new;
	my @data = $parser->read_file($datafile);
	print @$_ foreach @data;

	# Only want certain fields?
	my $parser = Text::CSV::Simple->new;
	$parser->want_fields(1, 2, 4, 8);
	my @data = $parser->read_file($datafile);

	# Map the fields to a hash?
	my $parser = Text::CSV::Simple->new;
	$parser->field_map(qw/id name null town/);
	my @data = $parser->read_file($datafile);

=head1 DESCRIPTION

Parsing CSV files is nasty. It seems so simple, but it usually isn't.
Thankfully Text::CSV_XS takes care of most of that nastiness for us.

Like many modules which have to deal with all manner of nastiness and
edge cases, however, it can be clumsy to work with in the simple case.

Thus this module.

We simply provide a little wrapper around Text::CSV_XS to streamline the
common case scenario. (Or at least B<my> common case scenario; feel free
to write your own wrapper if this one doesn't do what you want).

=head1 METHODS

=head2 new

	my $parser = Text::CSV::Simple->new(\%options);

Construct a new parser. This takes all the same options as Text::CSV_XS.

=head2 read_file

	my @data = $parser->read_file($filename);

Read the data in the given file, parse it, and return it as a list of
data.

Each entry in the returned list will be a listref of parsed CSV data.

=head2 want_fields

	$parser->want_fields(1, 2, 4, 8);

If you only want to extract certain fields from the CSV, you can set up
the list of fields you want, and, hey presto, those are the only ones
that will be returned in each listref. The fields, as with Perl arrays,
are zero based (i.e. the above example returns the second, third, fifth
and ninth entries for each line)

=head2 field_map

	$parser->field_map(qw/id name null town null postcode/);

Rather than getting back a listref for each entry in your CSV file, you
often want a hash of data with meaningful names. If you set up a field_map
giving the name you'd like for each field, then we do the right thing
for you! Fields named 'null' vanish into the ether.

=head1 Error Handling

Currenly, for each line that we can't parse, we emit a warning, and move
on. If this isn't what you want, feel free to subclass and override
_failed().

=cut

sub new {
	my $class = shift;
	return bless { _parser => Text::CSV_XS->new(@_), } => $class;
}

sub _parser { shift->{_parser} }

sub _file {
	my $self = shift;
	$self->{_file} = shift if @_;
	return $self->{_file};
}

sub _contents {
	my $self  = shift;
	my @lines = File::Slurp::read_file($self->_file)
		or die "Can't read " . $self->_file;
	return @lines;
}

sub want_fields {
	my $self = shift;
	if (@_) {
		$self->{_wanted} = [@_];
	}
	return @{ $self->{_wanted} || [] };
}

sub field_map {
	my $self = shift;
	if (@_) {
		$self->{_map} = [@_];
	}
	return @{ $self->{_map} || [] };
}

sub _failed {
	my ($self, $line) = @_;
	warn "Failed on $line\n";
}

sub read_file {
	my ($self, $file) = @_;
	$self->_file($file);
	my @lines = $self->_contents;
	my @return;
	my $csv = $self->_parser;
	foreach (@lines) {
		next unless $_;
		unless ($csv->parse($_)) {
			$self->_failed($csv->error_input);
			next;
		}
		my @fields = $csv->fields;
		if (my @wanted = $self->want_fields) {
			@fields = @fields[ $self->want_fields ];
		}
		if (my @map = $self->field_map) {
			my $hash = { map { $_ => shift @fields } @map };
			delete $hash->{null};
			push @return, $hash;
		} else {
			push @return, [@fields];
		}
	}
	return @return;
}

=head1 AUTHOR

Tony Bowden, <cpan@tmtm.com>

=head1 SEE ALSO

Text::CSV_XS

=head1 COPYRIGHT

Copyright (C) 2004 Tony Bowden. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself

=cut

