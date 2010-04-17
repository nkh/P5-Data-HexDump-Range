
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

#use Graphics::ColorNames
#~ use List::Util qw(min) ;
#~ use List::MoreUtils qw(all) ;
#~ use Scalar::Util qw(looks_like_number) ;
#~ use Term::ANSIColor ;
#~ use Data::TreeDumper ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range::Format - Handles formating for Data::HexDump::Range

=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut

#-------------------------------------------------------------------------------

my $current_color_index = 0 ;

sub get_default_color
{

=head2 [P] get_default_color()

Returns a color to use with a range that has none

  my $default_color = $self->get_default_color() ;

I<Arguments> - None

I<Returns> - A string - a color according to the COLOR option and FORMAT

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $default_color ;

if($self->{COLOR} eq 'bw')
	{
	$default_color = $self->{COLORS}{$self->{FORMAT}}[0] ;
	}
else
	{
	$current_color_index++ ;
	$current_color_index = 0 if $current_color_index >= @{$self->{COLORS}{$self->{FORMAT}}} ;
	
	$default_color = $self->{COLORS}{$self->{FORMAT}}[$current_color_index] ;
	}
	
return $default_color ;
}

sub format
{
	
=head2 [P] format($line_data)

Transform the line data into ANSI, ASCII or HTML

I<Arguments> -

=over 2 

=item * \%line_data - See L<gather> 

=back

I<Returns> - A dump in ANSI, ASCII or HTML.

=cut

my ($self, $line_data) = @_ ;

#~ use Data::TreeDumper ;
#~ print DumpTree $line_data ;

my $formated = '' ;

my @fields = @{$self->{FIELDS_TO_DISPLAY}} ;
unshift @fields, 'INFORMATION', 'RULER' ;


for ($self->{FORMAT})
	{
	/ASCII/ || /ANSI/ and do
		{
		my $colorizer = /ASCII/ ? sub {$_[0]} : \&colored ;
		
		for my $line (@{$line_data})
			{
			for my $field (@fields)
				{
				if(exists $line->{$field})
					{
					for my $range (@{$line->{$field}})
						{
						my $user_color = (defined $self->{COLOR_NAMES} &&  defined $range->{"${field}_COLOR"})
										? $self->{COLOR_NAMES} {$self->{FORMAT}}{$range->{"${field}_COLOR"}}  ||  $range->{"${field}_COLOR"}
										: $range->{"${field}_COLOR"} ;
						
						if(defined $user_color && $user_color ne '')
							{
							$formated .= $colorizer->($range->{$field}, $user_color) ;
							}
						else
							{
							$formated .= $range->{$field} ;
							}
						}
						
					$formated .= ' '
					}
				}
				
			$formated .= "\n" if $line->{NEW_LINE} ;
			}
		} ;
		
	/HTML/ and do
		{
		$formated = <<'EOH' ;
<pre style ="font-family: monospace; background-color: #000 ;">

EOH
		for my $line (@{$line_data})
			{
			for my $field (@fields)
				{
				if(exists $line->{$field})
					{
					for my $range (@{$line->{$field}})
						{
						my $user_color = (defined $self->{COLOR_NAMES} &&  defined $range->{"${field}_COLOR"})
										? $self->{COLOR_NAMES} {$self->{FORMAT}}{$range->{"${field}_COLOR"}}  ||  $range->{"${field}_COLOR"}
										: $range->{"${field}_COLOR"} ;
						
						$user_color = "style='color:#fff;'" unless defined $user_color ;
						$formated .= "<span $user_color>" . $range->{$field} . "</span>" ;
						}
						
					$formated .= ' ' ;
					}
				}
				
			$formated .= "\n" if $line->{NEW_LINE} ;
			}
		
		$formated .= "\n</pre>\n" ;
		} ;
	}
	
return $formated ;
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
