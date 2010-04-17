
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

use Carp qw(carp croak confess) ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range::Split - Handles formating for Data::HexDump::Range


=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut

#-------------------------------------------------------------------------------

sub split
{

=head2 [P] split($collected_data)

Split the collected data into lines

I<Arguments> - 

=over 2 

=item * $container - Collected data

=back

I<Returns> - Nothing

I<Exceptions>

=cut

my ($self, $collected_data) = @_ ;

#~ use Data::TreeDumper ;
#~ print DumpTree $collected_data ;

my @lines ;
my $line = {} ;
my $current_offset = 0 ;

my $room_left = $self->{DATA_WIDTH} ;
my $total_dumped_data = 0 ;
my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;

my @found_bitfields ;

for my $data (@{$collected_data})
	{
	my $data_length = defined $data->{DATA} ? length($data->{DATA}) : 0 ;
	my $is_comment = ! defined $data->{DATA} ;
	my ($start_quote, $end_quote) = $is_comment ? ('"', '"') : ('<', '>') ;
	
	$data->{COLOR} = $self->get_default_color()  unless defined $data->{COLOR} ;
	
	if($self->{ORIENTATION} =~ /^hor/)
		{
		my $last_data = $data == $collected_data->[-1] ? 1 : 0 ;
		my $dumped_data = 0 ;
		my $data_length = defined $data->{DATA} ? length($data->{DATA}) : 0 ;
		
		if(0 == $data_length && $self->{DISPLAY_ZERO_SIZE_RANGE} && $self->{DISPLAY_RANGE_NAME})
			{
			my $name_size_quoted = $max_range_name_size - 2 ;
			$name_size_quoted =  2 if $name_size_quoted < 2 ;
			
			push @{$line->{RANGE_NAME}},
				{
				'RANGE_NAME' => $start_quote . sprintf("%.${name_size_quoted}s", $data->{NAME}) . $end_quote,
				'RANGE_NAME_COLOR' => $data->{COLOR},
				},
				{
				'RANGE_NAME_COLOR' => undef,
				'RANGE_NAME' => ', ',
				} ;
			}
		
		while ($dumped_data < $data_length)
			{
			my $size_to_dump = min($room_left, length($data->{DATA}) - $dumped_data) ;
			$room_left -= $size_to_dump ;
			
			for my  $field_type 
				(
				['OFFSET', sub {exists $line->{OFFSET} ? '' : sprintf $self->{OFFSET_FORMAT}, $current_offset}, undef, 0],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @_}, $data->{COLOR}, 3],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @_}, $data->{COLOR}, 4],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @_}, $data->{COLOR}, 1],
				['RANGE_NAME',sub {sprintf "%.${max_range_name_size}s", $data->{NAME}}, $data->{COLOR}, 0],
				['RANGE_NAME', sub {', '}, undef, 0],
				)
				{
				my ($field_name, $field_data_formater, $color, $pad_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					#todo: move unpack out of the loop
					#todo: pass object as argument to sub
					my $field_text = $field_data_formater->(unpack("x$dumped_data C$size_to_dump", $data->{DATA})) ;
					
					my $pad = $last_data 
							? $pad_size 
								? ' ' x ($room_left * $pad_size) 
								: '' 
							: '' ;
							
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name => $field_text . $pad,
						} ;
					}
				}
				
			$dumped_data += $size_to_dump ;
			$current_offset += $self->{DATA_WIDTH} ;
			
			if($data->{IS_BITFIELD} && ! $data->{BITFIELD_DISPLAYED})
				{
				push @found_bitfields, $self->get_bitfield_lines($data) ;
				$data->{BITFIELD_DISPLAYED}++ ;
				}
			
			if($room_left == 0 || $last_data)
				{
				$line->{NEW_LINE}++ ;
				push @lines, $line ;
				
				if(@found_bitfields)
					{
					push @lines, {NEW_LINE => 1}, @found_bitfields, {NEW_LINE => 1} ;
					@found_bitfields = () ;
					}
					
				$line = {} ;
				$room_left = $self->{DATA_WIDTH} ;
				}
			}
		}
	else
		{ 
		# vertical mode
			
		$line = {} ;

		my $dumped_data = 0 ;
		my $current_range = '' ;
		
		if(0 == $data_length && $self->{DISPLAY_ZERO_SIZE_RANGE} && $self->{DISPLAY_RANGE_NAME})
			{
			push @{$line->{RANGE_NAME}},
				{
				'RANGE_NAME_COLOR' => $data->{COLOR},
				'RANGE_NAME' => "$start_quote$data->{NAME}$end_quote",
				} ;
				
			$line->{NEW_LINE} ++ ;
			push @lines, $line ;
			$line = {};
			}
			
		while ($dumped_data < $data_length)
			{ 
			last if($data->{IS_BITFIELD}) ;

			my $size_to_dump = min($self->{DATA_WIDTH}, length($data->{DATA}) - $dumped_data) ;
			my @range_data = unpack("x$dumped_data C$size_to_dump", $data->{DATA}) ;
			
			for my  $field_type 
				(
				['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", $data->{NAME} ; }, $data->{COLOR}, $max_range_name_size] ,
				['OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $total_dumped_data ;}, undef, 8],
				['CUMULATIVE_OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $dumped_data}, undef, 8],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @{$_[0]}}, $data->{COLOR}, 3 * $self->{DATA_WIDTH}],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @{ $_[0] }}, $data->{COLOR}, 4 * $self->{DATA_WIDTH}],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @{$_[0]}}, $data->{COLOR}, $self->{DATA_WIDTH}],
                                ['USER_INFORMATION', sub { sprintf '%-20.20s', $data->{USER_INFORMATION} || ''}, $data->{COLOR}, 20],
				)
				{
				
				my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					my $field_text = $field_data_formater->(\@range_data) ;
					my $pad = ' ' x ($field_text_size -  length($field_text)) ;
					
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name =>  $field_text .  $pad,
						} ;
					}
				}
				
			$dumped_data += $size_to_dump ;
			$total_dumped_data += $size_to_dump ;
			
			$line->{NEW_LINE} ++ ;
			push @lines, $line ;
			$line = {};
			}
			
		push @lines, $self->get_bitfield_lines($data) if($data->{IS_BITFIELD}) ;
		}
	}

return \@lines ;
}

sub get_bitfield_lines
{

my ($self, $data) = @_ ;

my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;

my @lines ;

for my $bitfield_description ($data)
	{
	#todo: handle 'x' outside of string in unpack
	#todo: handle bitfield without data
	
	#~ my @bitfield_data = unpack("$bitfield_description->{IS_BITFIELD}", $bitfield_description->{DATA}) ;

	my ($offset, $size) = $bitfield_description->{IS_BITFIELD} =~ m/x?(.*)b(.*)/ ;

	$offset ||= 0 ;
	$size ||= 1 ;

	my $line = {};

	for my  $field_type 
		(
		['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", '.' . $_[0]->{NAME} ; }, undef, $max_range_name_size ] ,
		['OFFSET', sub {sprintf '%02u .. %02u', $offset, ($offset + $size) - 1}, undef, 8],
		['CUMULATIVE_OFFSET', sub {''}, undef, 8],
		['HEX_DUMP', 
			sub 
			{
			my @binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			my $binary = join('', @binary) ;
			
			my $value = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));

			my $binary_dashed = '-' x $offset . $binary . '-' x (32 - ($size + $offset)) ;
			my $bytes = $size > 24 ? 4 : $size > 16 ? 3 : $size > 8 ? 2 : 1 ;
			
			my @bytes = unpack("(H2)*", pack("B32", substr("0" x 32 . $binary, -32)));
			
			my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
			splice @bytes, 0 , (4 - $number_of_bytes), map {'--'} 1 .. (4 - $number_of_bytes) ;
			
			join(' ', @bytes) . ' ' . $binary_dashed;
			},
			
			undef, 3 * $self->{DATA_WIDTH}],
		['DEC_DUMP', 
			sub 
			{
			my @binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			my $binary = join('', @binary) ;
			my $value = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));
			
			my @values = map {sprintf '%03u', $_} unpack("W*", pack("B32", substr("0" x 32 . $binary, -32)));
			
			my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
			splice @values, 0 , (4 - $number_of_bytes), map {'---'} 1 .. (4 - $number_of_bytes) ;
			
			join(' ',  @values) . ' ' . "value: $value"  ;
			},
			
			$bitfield_description->{COLOR}, 4 * $self->{DATA_WIDTH}],
			
		['ASCII_DUMP',
			sub 
			{
			my @binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			my $binary = join('', @binary) ;
			
			my @chars = map{$_ < 30 ? '.' : chr($_) } unpack("C*", pack("B32", substr("0" x 32 . $binary, -32)));
			
			my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
			splice @chars, 0 , (4 - $number_of_bytes), map {'-'} 1 .. (4 - $number_of_bytes) ;
			
			'.bitfield: '.  join('',  @chars) 
			},

			undef, $self->{DATA_WIDTH}],
		)
		{
		my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
		
		$color = $bitfield_description->{COLOR} ;
		
		if($self->{"DISPLAY_$field_name"})
			{
			my $field_text = $field_data_formater->($bitfield_description) ;
			my $pad_size = $field_text_size -  length($field_text) ;
			
			push @{$line->{$field_name}},
				{
				$field_name . '_COLOR' => $color,
				$field_name =>  $field_text . ' ' x $pad_size,
				} ;
				
			}
		}
	
	$line->{NEW_LINE} ++ ;
	push @lines, $line ;
	}
	
return @lines ;
}

#-------------------------------------------------------------------------------

sub add_information
{

=head2 [P] add_information($split_data)

Add information, according to the options passed to the constructor, to the internal data.

I<Arguments> - See L<gather>

=over 2

=item * $split_data - data returned by _gather()

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self, $split_data) = @_ ;

my @information ;

if($self->{DISPLAY_COLUMN_NAMES})
	{
	my $information = '' ;
	
	for my $field_name (@{$self->{FIELDS_TO_DISPLAY}})
		{
		if(exists $split_data->[0]{$field_name})
			{
			my $length = 0 ;
			
			for (@{$split_data->[0]{$field_name}})
				{
				$length += length($_->{$field_name}) ;
				}
				
			$information .= sprintf "%-${length}.${length}s ", $field_name
			}
		}
		
	push @information,
		{
		INFORMATION => [ {INFORMATION => $information} ], 
		NEW_LINE => 1,
		} ;
	}

if($self->{DISPLAY_RULER})
	{
	my $information = '' ;
	
	for my $field_name (@{$self->{FIELDS_TO_DISPLAY}})
		{
		if(exists $split_data->[0]{$field_name})
			{
			my $length = 0 ;
			
			for (@{$split_data->[0]{$field_name}})
				{
				$length += length($_->{$field_name}) ;
				}
				
			for ($field_name)
				{
				/HEX_DUMP/ and do
					{
					$information .= join '', map {sprintf '%x  ' , $ _ % 16} (0 .. $self->{DATA_WIDTH} - 1) ;
					$information .= ' ' ;
					last ;
					} ;
					
				/DEC_DUMP/ and do
					{
					$information .= join '', map {sprintf '%d   ' , $ _ % 10} (0 .. $self->{DATA_WIDTH} - 1) ;
					$information .= ' ' ;
					last ;
					} ;
					
				/ASCII_DUMP/ and do
					{
					$information .= join '', map {$ _ % 10} (0 .. $self->{DATA_WIDTH} - 1) ;
					$information .= ' ' ;
					last ;
					} ;
					
				$information .= ' ' x $length  . ' ' ;
				}
			}
		}
		
	push @information,
		{
		RULER => [ {RULER=> $information} ], 
		NEW_LINE => 1,
		} ;
	}
	
unshift @{$split_data}, @information ;

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
