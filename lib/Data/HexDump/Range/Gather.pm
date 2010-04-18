
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
$VERSION     = '0.01';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

Readonly my $RANGE_DEFINITON_FIELDS => 4 ;

use Carp qw(carp croak confess) ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range::Gather - Handles gathering of binary data  for Data::HexDump::Range

=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut

#-------------------------------------------------------------------------------

sub _gather
{

=head2 [P] _gather($range_description, $data, $offset, $size)

Creates an internal data structure from the data to dump.

  $hdr->_gather($container, $range_description, $data, $size)

I<Arguments> - See L<gather>

=over 2 

=item * $container - an array reference or undef - where the gathered data 

=item * $range_description - See L<gather> 

=item * $data - See L<gather>

=item * $offset - See L<gather>

=item * $size - See L<gather>

=back

I<Returns> - 

=over 2 

=item * $container - the gathered data 

=item * $used_data - integer - the location in the data where the dumping ended

=back

I<Exceptions> dies if passed invalid parameters

=cut

my ($self, $collected_data, $range_description, $data, $offset, $size) = @_ ;

my $location = "$self->{FILE}:$self->{LINE}" ;
my $range_provider ;

if('CODE' eq ref($range_description))
	{
	$range_provider = $range_description ;
	}
else
	{
	my $ranges = $self->create_ranges($range_description) ;
	
	$range_provider = 
		sub
		{
		while(@{$ranges})
			{
			return shift @{$ranges} ;
			}
		}
	}

my $used_data = $offset || 0 ;

if($used_data < 0)
	{
	$self->{INTERACTION}{DIE}("Warning: Invalid negative offset at '$location'.\n")
	}

$size = defined $size ? min($size, length($data) - $used_data) : length($data) - $used_data ;

my $skip_remaining_ranges = 0 ;
my $last_data = '' ;

while(my $range  = $range_provider->($self, $data, $used_data))
	{
	my ($range_name, $range_size, $range_color, $range_user_information) = @{$range} ;
	my $range_size_definition = $range_size ; # needed for comment and bitfield

	for my $range_field ($range_name, $range_size, $range_color, $range_user_information)
		{
		$range_field =  $range_field->($data, $used_data, $size, $range) if 'CODE' eq ref($range_field) ;
		}

	my ($is_comment, $is_bitfield, $unpack_format) ;

	if('' eq ref($range_size))
		{
		($is_comment, $is_bitfield, $range_size, $unpack_format) = $self->unpack_range_size($range_name, $range_size, $used_data) ;
		}
	elsif('CODE' eq ref($range_size))
		{
		($is_comment, $is_bitfield, $range_size, $unpack_format) = $self->unpack_range_size($range_name, $range_size->(), $used_data) ;
		}
	else
		{
		$self->{INTERACTION}{DIE}("Error: size '$range_size' doesn't look like a number or a code reference in range '$range_name' at '$location'.\n")
		}
		
	if($self->{DUMP_RANGE_DESCRIPTION})
		{
		$self->{INTERACTION}{INFO}
				(
				DumpTree 
					{
					size => $range_size,
					color => $range_color,
					'unpack format' => $is_bitfield ? $range_size_definition : $unpack_format,
					'user information' => $range_user_information,
					type => $is_bitfield ? 'bitfield' : $is_comment ? 'comment' : 'data',
					},
					$range_name,
					QUOTE_VALUES => 1, DISPLAY_ADDRESS => 0,
				) ;
		}

	if(! $is_comment && ! $is_bitfield)
		{
		if($range_size == 0 && $self->{DISPLAY_ZERO_SIZE_RANGE_WARNING}) 
			{
			$self->{INTERACTION}{WARN}("Warning: range '$range_name' requires zero bytes.\n") ;
			}
			
		if($self->{DISPLAY_RANGE_SIZE})
			{
			$range_name = $range_size . ':' . $range_name ;
			}
		}

	if($range_size > $size)
		{
		$self->{INTERACTION}{WARN}("Warning: not enough data for range '$range_name', $range_size needed but only $size available.\n") ;
		
		$range_name = '-' . ($range_size - $size)  . ':' . $range_name ;
		
		$range_size = $size;
		$skip_remaining_ranges++ ;
		}

	$last_data = unpack($unpack_format, $data) unless $unpack_format eq '#' ; # get out data from the previous range for bitfield

	push @{$collected_data}, 		
		{
		NAME => $range_name, 
		COLOR => $range_color,
		OFFSET => $used_data,
		DATA =>  $is_comment ? undef : $last_data,
		IS_BITFIELD => $is_bitfield ? $range_size_definition : 0,
		USER_INFORMATION => $range_user_information,
		} ;
	
	$used_data += $range_size ;
	$size -= $range_size ;
	
	last if $skip_remaining_ranges ;
	}

return $collected_data, $used_data ;
}

#-------------------------------------------------------------------------------

sub unpack_range_size
{

=head2 [P] unpack_range_size($self, $range_name, $size, $used_data)

Verifies the size field from a range descritpion and generates unpack format

I<Arguments> - 

=over 2 

=item * $self

=item * $range_name

=item * $size

=item * $used_data

=back

I<Returns> - A list 

=over 2 

=item * $is_comment - Boolean -

=item * $is_bitfield - Boolean -

=item * $range_size - Integer

=item * $unpack_format -  A String - formated according to I<pack>.

=back
I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my ($self, $range_name, $size, $used_data) = @_ ;

my ($is_comment, $is_bitfield, $range_size, $unpack_format) = (0, 0, -1, '');

if('#' eq  $size)
	{
	$is_comment++ ;
	$range_size = 0 ;
	$unpack_format = '#' ;
	}
elsif($size =~ '^\s*(x\d*)?\s*b\d*\s*$')
	{
	$is_bitfield++ ;
	$range_size = 0 ;
	$unpack_format = '#' ;
	}
elsif(looks_like_number($size))
	{
	$unpack_format = "x$used_data a$size"  ;
	$range_size = $size ;
	}
else
	{
	my $location = "$self->{FILE}:$self->{LINE}" ;

	$self->{INTERACTION}{DIE}("Error: size '$size' doesn't look valid in range '$range_name' at '$location'.\n")
	}

return ($is_comment, $is_bitfield, $range_size, $unpack_format) ;
}

#-------------------------------------------------------------------------------

sub create_ranges
{

=head2 [P] create_ranges($range_description)

Transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - See L<gather> 

=back

I<Returns> - Nothing

I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my ($self, $range_description) = @_ ;

return $self->create_ranges_from_array_ref($range_description) if 'ARRAY' eq ref($range_description) ;
return $self->create_ranges_from_string($range_description) if '' eq ref($range_description) ;

}

#-------------------------------------------------------------------------------

sub create_ranges_from_string
{

=head2 [P] create_ranges_from_string($range_description)

Transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - A string - See L<gather> 

=back

I<Returns> - Nothing

I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my ($self, $range_description) = @_ ;

# 'comment,#:name,size,color:name,size:name,size,color'

my @ranges = 
	map
	{
		[ map {s/^\s+// ; s/\s+$//; $_} split /,/ ] ;
	} split /:/, $range_description ;

my @flattened = $self->flatten(\@ranges) ;
@ranges = () ;

while(@flattened)
	{
	push @ranges, [splice(@flattened, 0, $RANGE_DEFINITON_FIELDS)] ;
	}

return \@ranges ;
}


sub create_ranges_from_array_ref
{

=head2 [P] create_ranges_from_array_ref($range_description)

transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - An array reference - See L<gather> 

=back

I<Returns> - Nothing

I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my ($self, $range_description) = @_ ;

my @flattened = $self->flatten($range_description) ;

my @ranges ;

while(@flattened)
	{
	push @ranges, [splice(@flattened, 0, $RANGE_DEFINITON_FIELDS)] ;
	}
	
return \@ranges ;
}

#-------------------------------------------------------------------------------

sub flatten 
{ 
	
=head2 [P] flatten($range_description)

transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - See L<gather> 

=back

I<Returns> - Nothing

I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my $self = shift ;

map 
	{
	my  $description = $_ ;
	
	if(ref($description) eq 'ARRAY')
		{
		if(all {'' eq ref($_) || 'CODE' eq ref($_) } @{$description} )
			{
			my $location = "$self->{FILE}:$self->{LINE}" ;
			
			if(@{$description} == 0)
				{
				$self->{INTERACTION}{DIE}->
					(
					"Error: too few elements in range description [" 
					. join(', ', map {defined $_ ? $_ : 'undef'} @{$description})  
					. "] at '$location'." 
					) ;
				}
			elsif(@{$description} == 1)
				{
				if('' eq ref($description->[0]))
					{
					$self->{INTERACTION}{DIE}->
						(
						"Error: too few elements in range description [" 
						. join(', ', map {defined $_ ? $_ : 'undef'} @{$description})  
						. "] at '$location'." 
						) ;
					}
				else
					{
					@{$description} = $description->[0]() ;
					
					$self->{INTERACTION}{DIE}->
						(
						"Error: single sub range definition returned ["
						. join(', ', map {defined $_ ? $_ : 'undef'}@{$description})  
						. "] at '$location'." 
						) 
						unless (@{$description} == 4) ;
					}
				}
			elsif(@{$description} == 2)
		        	{
				push @{$description}, undef, undef ;
				}
			elsif(@{$description} == 3)
				{
				push @{$description}, undef ;
				# make sure we get a default color
				$description->[2] = undef if $description->[2] eq $EMPTY_STRING ;
				}
			elsif(@{$description} == 4)
				{
				# make sure we get a default color
				$description->[2] = undef if $description->[2] eq $EMPTY_STRING ;
				}
			elsif(@{$description} > $RANGE_DEFINITON_FIELDS)
				{
				$self->{INTERACTION}{DIE}->
					(
					"Error: too many elements in range description [" 
					. join(', ', map {defined $_ ? $_ : 'undef'} @{$description}) 
					. "] at '$location'." 
					) ;
				}
				
			@{$description} ;
			}
		else
			{
			$self->flatten(@{$description}) ;
			}
		}
	else
		{
		$description
		}
	} @_ 
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

L<Data::HexDump::Range>

=cut
