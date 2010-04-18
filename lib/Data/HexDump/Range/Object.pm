
package Data::HexDump::Range ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{

use Sub::Exporter -setup => 
	{
	exports => [ qw() ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.06';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range::Object - Hexadecial Range Dumper object creation support methods

=head1 SYNOPSIS

=head1 DESCRIPTION

The main goal of this module is to remove non public APIs from the module documentation

=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut


#-------------------------------------------------------------------------------

Readonly my $NEW_ARGUMENTS => 	
	[
	qw(
	NAME INTERACTION VERBOSE
	
	DUMP_RANGE_DESCRIPTION
	
	FORMAT 
	COLOR 
	OFFSET_FORMAT 
	DATA_WIDTH 
	DISPLAY_COLUMN_NAMES
	DISPLAY_RULER
	DISPLAY_OFFSET 
	DISPLAY_CUMULATIVE_OFFSET
	DISPLAY_ZERO_SIZE_RANGE_WARNING
	DISPLAY_ZERO_SIZE_RANGE 
	DISPLAY_RANGE_NAME
	MAXIMUM_RANGE_NAME_SIZE
	DISPLAY_RANGE_SIZE
	DISPLAY_ASCII_DUMP
	DISPLAY_HEX_DUMP
	DISPLAY_DEC_DUMP
	DISPLAY_USER_INFORMATION
	DISPLAY_BITFIELDS
	DISPLAY_BITFIELD_SOURCE
	COLOR_NAMES 
	ORIENTATION 
	)] ;

#-------------------------------------------------------------------------------

sub Setup
{

=head2 [P] Setup(...)

Helper sub called by new. This is a private sub.

=cut

my ($self, $package, $file_name, $line, @setup_data) = @_ ;

if (@setup_data % 2)
	{
	croak "Invalid number of argument '$file_name, $line'!" ;
	}

$self->{INTERACTION}{INFO} ||= sub {print @_} ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::croak ;
$self->{NAME} = 'Anonymous';
$self->{FILE} = $file_name ;
$self->{LINE} = $line ;

$self->CheckOptionNames($NEW_ARGUMENTS, @setup_data) ;

%{$self} = 
	(
	%{$self},
	
	VERBOSE => 0,
	DUMP_RANGE_DESCRIPTION => 0,
	
	FORMAT => 'ANSI',
	COLOR => 'cycle',
	COLORS =>
		{
		ASCII => [],
		ANSI => ['white', 'green', 'bright_yellow','cyan', 'red' ],
		HTML => ['white', 'green', 'bright_yellow','cyan', 'red' ],
		},
		
	OFFSET_FORMAT => 'hex',
	DATA_WIDTH => 16,
	
	DISPLAY_ZERO_SIZE_RANGE_WARNING => 1,
	DISPLAY_ZERO_SIZE_RANGE => 1,
	
	DISPLAY_RANGE_NAME => 1,
	MAXIMUM_RANGE_NAME_SIZE => 16,
	DISPLAY_RANGE_SIZE => 1,
	
	DISPLAY_COLUMN_NAMES  => 0 ,
	DISPLAY_RULER => 0,
	
	DISPLAY_OFFSET => 1,
	DISPLAY_CUMULATIVE_OFFSET => 1,
	DISPLAY_HEX_DUMP => 1,
	DISPLAY_DEC_DUMP => 0,
	DISPLAY_ASCII_DUMP => 1,
	DISPLAY_USER_INFORMATION => 0,

	DISPLAY_BITFIELDS => 1,
	DISPLAY_BITFIELD_SOURCE => 1,
	
	COLOR_NAMES => 
		{
		HTML =>
			{
			white => "style='color:#fff;'",
			green => "style='color:#0f0;'",
			bright_yellow => "style='color:#ff0;'",
			yellow => "style='color:#ff0;'",
			cyan => "style='color:#0ff;'",
			red => "style='color:#f00;'",
			},
		},

	ORIENTATION => 'horizontal',
	
	GATHERED => [],
	@setup_data,
	) ;

my $location = "$self->{FILE}:$self->{LINE}" ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}('Creating ' . ref($self) . " '$self->{NAME}' at $location.\n") ;
	}

$self->{OFFSET_FORMAT} = $self->{OFFSET_FORMAT} =~ /^hex/ ? "%08x" : "%010d" ;
$self->{MAXIMUM_RANGE_NAME_SIZE} = 2 if$self->{MAXIMUM_RANGE_NAME_SIZE} <= 2 ;

if($self->{ORIENTATION} =~ /^hor/)
	{
	my @fields = qw(OFFSET) ;
	push @fields, 'BITFIELD_SOURCE' if $self->{DISPLAY_BITFIELD_SOURCE} ;
	push @fields, qw( HEX_DUMP DEC_DUMP ASCII_DUMP RANGE_NAME) ;
	
	$self->{FIELDS_TO_DISPLAY} =  \@fields ;
	}
else
	{
	$self->{FIELDS_TO_DISPLAY} =  
		 [qw(RANGE_NAME OFFSET CUMULATIVE_OFFSET HEX_DUMP DEC_DUMP ASCII_DUMP USER_INFORMATION)] ;
	}

my (undef, undef, $colorizer) = get_colorizer_data($self->{FORMAT}) ; # verify validity
$self->{INTERACTION}{DIE}("Error: Invalid output format '$self->{FORMAT}'.\n") unless defined $colorizer ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub CheckOptionNames
{

=head2 [P] CheckOptionNames(...)

Verifies the named options passed to the members of this class. Calls B<{INTERACTION}{DIE}> in case
of error. 

=cut

my ($self, $valid_options, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

if('HASH' eq ref $valid_options)
	{
	# OK
	}
elsif('ARRAY' eq ref $valid_options)
	{
	$valid_options = { map{$_ => 1} @{$valid_options} } ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("Invalid argument '$valid_options'!") ;
	}

my %options = @options ;

for my $option_name (keys %options)
	{
	unless(exists $valid_options->{$option_name})
		{
		$self->{INTERACTION}{DIE}->
				(
				"$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'\nValid options:\n\t"
				.  join("\n\t", sort keys %{$valid_options}) . "\n"
				);
		}
	}

if
	(
	   (defined $options{FILE} && ! defined $options{LINE})
	|| (!defined $options{FILE} && defined $options{LINE})
	)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Incomplete option FILE::LINE!") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NKH
	mailto: nadim@cpan.org

=head1 COPYRIGHT & LICENSE

Copyright 2010 Nadim Khemir.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::HexDump::Range

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-HexDump-Range>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-data-hexdump-range@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Data-HexDump-Range>

=back

=head1 SEE ALSO

L<Data::Hexdumper>, L<Data::ParseBinary>, L<Convert::Binary::C>, L<Parse::Binary>

=cut
