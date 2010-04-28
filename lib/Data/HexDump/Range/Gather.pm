
package Data::HexDump::Range ; ## no critic (Modules::RequireFilenameMatchesPackage)

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

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DOCUMENTATION

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

my $used_data = $offset || 0 ;
$self->{INTERACTION}{DIE}("Error: Invalid negative offset at '$location'.\n") if($used_data < 0) ;

$size = defined $size ? min($size, length($data) - $used_data) : length($data) - $used_data ;
my $maximum_size = $size ;

my $skip_remaining_ranges = 0 ;
my $last_data = '' ;

my $range_provider = $self->create_range_provider($range_description);

while(my $range  = $range_provider->($self, $data, $used_data))
	{
	my ($range_name, $range_size_definition, $range_color, $range_user_information) = @{$range} ;
	my $range_size = $range_size_definition; 

	for my $range_field ($range_name, $range_size, $range_color, $range_user_information)
		{
		$range_field =  $range_field->($data, $used_data, $size, $range) if 'CODE' eq ref($range_field) ;
		}

	my ($is_comment, $is_bitfield, $is_skip, $unpack_format) ;

	# handle maximum_size
	if($EMPTY_STRING eq ref($range_size))
		{
		($is_comment, $is_bitfield, $is_skip, $range_size, undef) = $self->unpack_range_size($range_name, $range_size, $used_data) ;
		}
	elsif('CODE' eq ref($range_size))
		{
		($is_comment, $is_bitfield, $is_skip, $range_size, undef) = $self->unpack_range_size($range_name, $range_size->(), $used_data) ;
		}
	else
		{
		$self->{INTERACTION}{DIE}("Error: size '$range_size' doesn't look like a number or a code reference in range '$range_name' at '$location'.\n")
		}

	my $truncated_size ;
	if($maximum_size - $used_data < $range_size)
		{
		$range_size = $truncated_size = max($maximum_size - $used_data, 0) ;
		$skip_remaining_ranges++ ;
		}
	#third, get the unpack format with the justified size
	# note that we keep $is_comment and $is_bitfield from first run
	# as the those are extracted from the size field and we have modified it
	(undef, undef, undef, $range_size, $unpack_format) = $self->unpack_range_size($range_name, $range_size, $used_data) ;
	
	if($maximum_size == $used_data)
		{
		if($is_comment || $is_bitfield)
			{
			# display bitfields even for ranges that pass maximim_size (truncated ranges)
			}
		else
			{
			my $next_range  = $range_provider->($self, $data, $used_data) ;
			$self->{INTERACTION}{WARN}("Warning: More ranges to display but no more data.\n") if defined $next_range ;
			
			last ;
			}
		}
		
	if(! $is_comment && ! $is_bitfield)
		{
		if($range_size == 0 && $self->{DISPLAY_ZERO_SIZE_RANGE_WARNING}) 
			{
			$self->{INTERACTION}{WARN}("Warning: range '$range_name' requires zero bytes.\n") ;
			}
			
		if(defined $truncated_size)
			{
			$self->{INTERACTION}{WARN}("Warning: range '$range_name' size was reduced from $range_size_definition to $truncated_size due to size limit at '$location'.\n") ;
			$range_name = "$range_size_definition->$truncated_size:$range_name"  ;
			}
		else
			{
			if($self->{DISPLAY_RANGE_SIZE})
				{
				$range_name = "$range_size:$range_name" ;
				}
			}
			
		$last_data = unpack($unpack_format, $data) # get out data from the previous range for bitfield
		}
		
	my $chunk = 
		{
		NAME => $range_name, 
		COLOR => $range_color,
		OFFSET => $used_data,
		DATA =>  $is_comment ? undef : $last_data,
		IS_BITFIELD => $is_bitfield ? $range_size_definition : 0,
		IS_SKIP => $is_skip,
		IS_COMMENT => $is_comment,
		USER_INFORMATION => $range_user_information,
		} ;
	
	if(defined $self->{GATHERED_CHUNK})
		{
		my @chunks = $self->{GATHERED_CHUNK}($self, $chunk) ;
		push @{$collected_data}, @chunks ;	
		}
	else
		{
		push @{$collected_data}, $chunk ;	
		}
	
	# todo dump the stuff that the gathered callback returned
	
	if($self->{DUMP_RANGE_DESCRIPTION})
		{
		$self->{INTERACTION}{INFO}
				(
				DumpTree 
					{
					%{$chunk},
					'unpack format' => $is_bitfield ? $range_size_definition : $unpack_format,
					},
					$range_name,
					QUOTE_VALUES => 1, DISPLAY_ADDRESS => 0,
				) ;
		}

	$used_data += $range_size ;
	$size -= $range_size ;

	last if $skip_remaining_ranges ;
	}
	
return $collected_data, $used_data ;
}

#-------------------------------------------------------------------------------

sub create_range_provider
{

=head2 [P] create_range_provider($range_description)

Transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - An array reference or a subroutine reference

=back

I<Returns> - Array ference - ranges in internal format

I<Exceptions> - None

=cut

my ($self, $range_description) = @_ ;

my $range_provider ;

if('CODE' eq ref($range_description))
	{
	my $ranges ;
	
	$range_provider = 
		sub
		{
		my ($dumper, $data, $offset) = @_ ;
		
		if(! defined $ranges || ! @{$ranges})
			{
			my $generated_range_description = $range_description->($dumper, $data, $offset) ;
			
			return undef unless defined $generated_range_description ;
			
			my $created_ranges = $self->create_ranges($generated_range_description) ;
			
			push @{$ranges}, @{$created_ranges}, $range_description ;
			}
		
	RANGE:
		my $local_description = shift@{$ranges} ;
		
		if('CODE' eq  ref $local_description)
			{
			my $sub_range_description = $local_description->($dumper, $data, $offset) ; 
			
			if(defined $sub_range_description)
				{
				unshift @{$ranges}, $local_description ;
				
				if('CODE' eq  ref $sub_range_description )
					{
					unshift @{$ranges}, $sub_range_description ;
					}
				else
					{
					my $created_ranges = $self->create_ranges($sub_range_description) ; 
					unshift @{$ranges}, @{$created_ranges} ;
					}
				}
			#else
				# sub generating ranges is done
				
			goto RANGE ;
			}
		
		return $local_description ;
		}
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

return $range_provider ;
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

my ($is_comment, $is_bitfield, $is_skip, $range_size, $unpack_format) = (0, 0, 0, -1, '');

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
elsif($size =~ '^\s*x(\d+)\s*$')
	{
	$is_skip++ ;
	$range_size = $1 ;
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

return ($is_comment, $is_bitfield, $is_skip, $range_size, $unpack_format) ;
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

I<Returns> - Array ference - ranges in internal format

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

I<Returns> - Array ference - ranges in internal format

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

I<Returns> - I<Returns> - Array ference - ranges in internal format

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
				$description->[2] = undef if defined $description->[2] && $description->[2] eq $EMPTY_STRING ;
				}
			elsif(@{$description} == 4)
				{
				# make sure we get a default color
				$description->[2] = undef if defined $description->[2] && $description->[2] eq $EMPTY_STRING ;
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

=head1 COPYRIGHT AND LICENSE

Copyright Nadim Khemir 2010.

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
