
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
$VERSION     = '0.02_1';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;

#use Graphics::ColorNames
use List::Util qw(min) ;
use List::MoreUtils qw(all) ;
use Scalar::Util qw(looks_like_number) ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range - Hexadecial Range Dumper

=head1 SYNOPSIS

  my $hdr = Data::HexDump::Range->new() ;
  
  print $hdr->dump(['magic cookie', 12, 'red'], $data) ;
  
  $hdr->gather(['magic cookie', 12, 'red'], $data) ; 
  $hdr->gather(['image type', 2, 'green'], $other_data) ;
  $hdr->gather(['image data ...', 100, 'yellow'], $more_data, 0, CONSUME_ALL_DATA) ;
  
  print $hdr->dump_gathered() ;
  
  $hdr->reset() ;

=head1 HEADS UP!

This is the first release . The API is unlikely to change but you never know. 
The documentation shows more what I want the module to do than what is implemented.

Still, this is module as well as the I<hdr> script are functional enough to be useful.

=head1 DESCRIPTION

Creates a dump from binary data and user defined I<range> descriptions. The goal of this modules is
to create an easy to understand dump of binary data. This achieved through:

=over 2

=item * Highlighted (colors) dump that is easier to understand than a monochrome blob of hex data

=item * Multiple rendering modes with different output formats

=item * The possibility to describe complex structures

=back

=head1 DOCUMENTATION

This module was inspired by the B<hexd> command from libma L<http://www.ioplex.com/~miallen/libmba/>.

Binary data is split according to user defined I<ranges> and rendered as a B<hex> or/and B<decimal> data dump.
The data dump can be rendered in ANSI, ASCII or HTML.

=head2 Orientation

The examples below show the hypothetic ranges:

  my $data_range = # definition to re-use
	[
	  ['data header', 5, 'blue on_cyan'],
	  ['data', 20, 'blue on_bright_yellow'],
	] ;

  my $structured_range = 
	[
	  [
	    ['magic cookie', 12, 'red'],
	    ['padding', 32, 'yellow'],
	    $data_range, 
	  ],
		
	  [
	    ['extra data', 12, undef],
	      [
	      $data_range, 
	      ['footer', 4, 'bright_yellow on_red'],
	    ]
	  ],
	] ;
	
Applied to the source code of this module.

=head3 Vertical

In this orientation mode, each range displayed separately starting with the range name
followed by the binary data dump. 

  magic cookie     00000000 00000000 0a 70 61 63 6b 61 67 65 20 44 61 74               .package Dat
  padding          0000000c 00000000 61 3a 3a 48 65 78 44 75 6d 70 3a 3a 52 61 6e 67   a::HexDump::Rang
  padding          0000001c 00000010 65 20 3b 0a 0a 75 73 65 20 73 74 72 69 63 74 3b   e ;..use strict;
  data header      0000002c 00000000 0a 75 73 65 20                                    .use
  data             00000031 00000000 77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20 43   warnings ;.use C
  data             00000041 00000010 61 72 70 20                                       arp
  extra data       00000045 00000000 3b 0a 0a 42 45 47 49 4e 20 0a 7b 0a               ;..BEGIN .{.
  data header      00000051 00000000 0a 75 73 65 20                                    .use
  data             00000056 00000000 53 75 62 3a 3a 45 78 70 6f 72 74 65 72 20 2d 73   Sub::Exporter -s
  data             00000066 00000010 65 74 75 70                                       etup
  footer           0000006a 00000000 20 3d 3e 20                                        =>

=head3 Horizontal

In this mode, the data are packed together in the dump

  00000000 0a 70 61 63 6b 61 67 65 20 44 61 74 61 3a 3a 48   .package Data::H magic cookie, padding,
  00000010 65 78 44 75 6d 70 3a 3a 52 61 6e 67 65 20 3b 0a   exDump::Range ;. padding,
  00000020 0a 75 73 65 20 73 74 72 69 63 74 3b 0a 75 73 65   .use strict;.use padding, data header,
  00000030 20 77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20    warnings ;.use  data header, data,
  00000040 43 61 72 70 20 3b 0a 0a 42 45 47 49 4e 20 0a 7b   Carp ;..BEGIN .{ data, extra data,
  00000050 0a 0a 75 73 65 20 53 75 62 3a 3a 45 78 70 6f 72   ..use Sub::Expor extra data, data header, data,
  00000060 74 65 72 20 2d 73 65 74 75 70 20 3d 3e 20         ter -setup =>    data, footer,

=head2 Rendered fields

You can choose which fields are rendered by setting options when creating a Data::HexDump::Range object.
The default rendering corresponds to the following object construction:

  Data::HexDump::Range->new
	(
	FORMAT => 'ANSI',
	COLOR => 'cycle',
	
	ORIENTATION => 'horizontal',
	
	DISPLAY_RANGE_NAME => 1 ,
	
	DISPLAY_OFFSET  => 1 ,
	OFFSET_FORMAT => 'hex',
	
	DISPLAY_HEX_DUMP => 1,
	DISPLAY_ASCII_DUMP => 1,
	
	DATA_WIDTH => 16,
	) ;

See L<new>.

=head2 Range definition

  my $simple_range = ['magic cookie', 12, 'red'] ;
  
Ranges are Array references containing three (3) elements:

=over 2

=item * name - a string

=item * size - an integer

=item * color - a string or undef

=back

Any of the three first elements can be replaced by a subroutine reference. See L<Dynamic range definition> below.

=head3 Coloring

Ranges and ranges names are displayed according to the color field in the range definition. 

The color definition is one of:

=over 2

=item * A user defined color name found in B<COLOR_NAMES> (see L<new>)

=item * An ansi color definition - 'blue on_yellow'

=item * A html color definition - eg todo: add example
 
=item * An RGB color definition - eg: todo: add example

=item * undef - will be repaced by a white color or pickec from a cyclic color list (see B<COLOR> in L<new>).

=back

=head3 Linear ranges

For simple data formats, your can put all the your range descriptions in a array:

  my $image_ranges =
	[
	  ['magic cookie', 12, 'red'],
	  ['size', 10, 'yellow'],
	  ['data', 10, 'blue on_yellow'],
	  ['timestamp', 5, 'green'],
	] ;

=head3 Structured Ranges

  my $data_range = # definition to re-use
	[
	  ['data header', 5, 'blue on_yellow'],
	  ['data', 100, 'blue'],
	] ;
			
  my $structured_range = 
	[
	  [
	    ['magic cookie', 12, 'red'],
	    ['padding', 88, 'yellow'],
	    $data_range, 
	  ],
		
	  [
	    ['extra data', 12, undef],
	      [
	      $data_range, 
	      ['footer', 4, 'yellow on_red'],
	    ]
	  ],
	]
	
=head4 Meta Ranges

Meta Ranges are defined by their sub ranges. They do not consume any data but describe their contants

Meta range names start witht the '<<' sequence.

  my $meta_range_defintion = 
	[
	  [
	  '<< header and data meta range', 'color for meta range'
	  
	    ['magic cookie', 12, 'red']
	    ['padding', 88, 'yellow']
	    
	      [
	      '<< data', undef, # undef => module picks a color for the data meta range
	      
	        ['data header', 5, 'blue on_yellow']
		['data', 100, 'blue']
	      ]
	  ],
	] ;

=head3 Dynamic range definition

The whole range can be replaced by a subroutine reference or elements of the range can be replaced by
a subroutine definition.

  my $dynamic_range =
	[
	  [\&name, \&size, \&color ],
	
	  [\&define_range] # returns a sub range definition
	] ;

=head4 'name' sub ref

  sub cloth_size
  {
  my ($data, $offset, $size) = @_ ;
  my %types = (O => 'S', 1 => 'M', 2 => 'L',) ;
  return 'size:' . ($types{$data} // '?') ;
  }
  
  $hdr->dump([\&cloth_size, 1, 'yellow'], $data) ;
  
=head4 'size' sub ref

  sub cloth_size
  {
  my ($data, $offset, $size) = @_ ;
  return unpack "a", $data ;
  }
  
  $hdr->dump(['data', \&get_size, 'yellow'], $data) ;
  
=head4 'color' sub ref

  my $flip_flop = 1 ;
  my @colors = ('green', 'red') ;
  
  sub alternate_color {$flip_flop ^= 1 ; return $colors[$flip_flop] }
  
  $hdr->dump(['data', 100, \&alternate_color], $data) ;

=head4 whole range definition as a subroutine reference

This allows you to define a parser. 

TODO: give an example

TODO: give an alternative solution using L<gather>

=head1 OTHER IDEAS

- allow pack format as range size

- hook with Convert::Binary::C to automatically create ranges

=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut


#-------------------------------------------------------------------------------

Readonly my $NEW_ARGUMENTS => 	
	[
	qw(
	NAME INTERACTION VERBOSE
	
	FORMAT 
	COLOR 
	OFFSET_FORMAT 
	DATA_WIDTH 
	DISPLAY_OFFSET DISPLAY_CUMULATIVE_OFFSET
	DISPLAY_ZERO_SIZE_RANGE_WARNING
	DISPLAY_ZERO_SIZE_RANGE 
	DISPLAY_RANGE_NAME
	MAXIMUM_RANGE_NAME_SIZE
	DISPLAY_ASCII_DUMP
	DISPLAY_HEX_DUMP
	DISPLAY_DEC_DUMP 
	COLOR_NAMES 
	ORIENTATION 
	)] ;

sub new
{

=head2 new(NAMED_ARGUMENTS)

Create a Data::HexDump::Range object.

  my $hdr = Data::HexDump::Range->new() ; # use default setup
  
  my $hdr = Data::HexDump::Range->new
		(
		FORMAT => 'ANSI'|'ASCII'|'HTML',
		COLOR => 'bw' | 'cycle',
		OFFSET_FORMAT => 'hex' | 'dec',
		DATA_WIDTH => 16 | 20 | ... ,
		DISPLAY_RANGE_NAME => 1 ,
		MAXIMUM_RANGE_NAME_SIZE => 16,
		DISPLAY_OFFSET  => 1 ,
		DISPLAY_CUMULATIVE_OFFSET  => 1 ,
		DISPLAY_ZERO_SIZE_RANGE_WARNING => 1,
		DISPLAY_ZERO_SIZE_RANGE => 1,
		DISPLAY_ASCII_DUMP => 1 ,
		DISPLAY_HEX_DUMP => 1,
		DISPLAY_DEC_DUMP => 1,
		COLOR_NAMES => {},
		ORIENTATION => 'horizontal',
		) ;

I<Arguments> - A list of named arguments

All arguments are optional. Settings get a default value if not passed by user. Default values are listed below.

=over 2 

=item * NAME - String - Name of the Data::HexDump::Range object, set to 'Anonymous' by default

=item * INTERACTION - Hash reference - Set of subs that are used to display information to the user

Useful if you use Data::HexDump::Range in an application without terminal.

=item * VERBOSE - Boolean - Display information about the creation of the object. Default is I<false>

=item * FORMAT - String - format of the dump string generated by Data::HexDump::Range.

Default is B<ANSI> which allows for colors. Other formats are 'ASCII' and 'HTML'.

=item * COLOR - String 'bw' or 'cycle'.

Ranges for which no color has been defined, in 'ANSI' or 'HTML' format mode, will be rendered in
black and white or with a color picked from a cyclic color list. Default is 'bw'.

=item * OFFSET_FORMAT - String - 'hex' or 'dec'

If set to 'hex', the offset will be displayed in base 16. When set to 'dec' the offset is displayed
in base 10. Default is 'hex'.

=item * DATA_WIDTH - Integer - Number of elements displayed per line. Default is 16.

=item * DISPLAY_RANGE_NAME - Boolean - If set, range names are displayed in the dump.

=item * MAXIMUM_RANGE_NAME_SIZE - Integer - maximum size of a range name (in horizontal mode)

Default size is 16.

=item * DISPLAY_OFFSET - Boolean - If set, the offset columnis displayed in the dump.

=item * DISPLAY_CUMULATIVE_OFFSET - Boolean - If set, the cumulative offset column is displayed in 'vertical' rendering mode

=item * DISPLAY_ZERO_SIZE_RANGE - Boolean - if set, ranges that do not consume data are displayed. default is I<true> 

=item * DISPLAY_ZERO_SIZE_RANGE_WARNING - Boolean - if set, a warning is emitted if ranges that do not consume data. default is I<true> 

=item * DISPLAY_ASCII_DUMP - Boolean - If set, the ASCII representation of the binary data is displayed

=item * DISPLAY_HEX_DUMP - Boolean - If set, the hexadecimal dump column is displayed

=item * DISPLAY_DEC_DUMP - Boolean - If set, the decimall dump column is displayed

=item * COLOR_NAMES - A hash reference

  {
  ANSI =>
	{
	header => 'yellow on_blue',
	data => 'yellow on_black',
	},
	
  HTML =>
	{
	header => 'FFFF00 0000FF',
	data => 'FFFF00 000000',
	},
  }


=item * ORIENTATION - String - 'vertical' or 'horizontal' (the default).

=back

I<Returns> - Nothing

I<Exceptions> - Dies if an unsupported option is passed.

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {} ;

my ($package, $file_name, $line) = caller() ;
bless $object, $class ;

$object->Setup($package, $file_name, $line, @setup_data) ;

return($object) ;
}

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

	FORMAT => 'ANSI',
	COLOR => 'bw',
	COLORS =>
		{
		ASCII => [],
		ANSI => ['white', 'green'],
		HTML => ['?', '?'],
		},
		
	OFFSET_FORMAT => 'hex',
	DATA_WIDTH => 16,
	
	DISPLAY_ZERO_SIZE_RANGE_WARNING => 1,
	DISPLAY_ZERO_SIZE_RANGE => 1,
	
	DISPLAY_RANGE_NAME => 1,
	MAXIMUM_RANGE_NAME_SIZE => 16,
	DISPLAY_OFFSET => 1,
	DISPLAY_CUMULATIVE_OFFSET => 1,
	DISPLAY_HEX_DUMP => 1,
	DISPLAY_DEC_DUMP => 0,
	DISPLAY_ASCII_DUMP => 1,
	
	COLOR_NAMES => undef,

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

#todo: check all the options values

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
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'!")  ;
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

sub gather
{

=head2 gather($range_description, $data, $offset, $size)

Dump the data, up to $size, according to the description. The data dump is kept in the object so you can
merge multiple gathered dumps and get a single rendering.

  $hdr->gather($range_description, $data, $offset, $size)
  $hdr->gather($range_description, $more_data)
  
  print $hdr->dump_gathered() ;

I<Arguments>

=over 2 

=item * $range_description - See L<Range definiton>
  
=item * $data - A string - binary data to dump

=item * $offset - dump data from offset

=over 2

=item * undef - start from first byte

=back

=item * $size - amount of data to dump

=over 2

=item * undef - use range description

=item * CONSUME_ALL_DATA - apply range descritption till all data is consumed

=back

=back

I<Returns> - An integer - the number of processed bytes

I<Exceptions> - See L<_gather>

=cut

my ($self, $range, $data, $offset, $size) = @_ ;

my ($gathered_data, $used_data) = $self->_gather($self->{GATHERED}, $range, $data, $offset, $size) ;

return $used_data ;
}

#-------------------------------------------------------------------------------

sub dump_gathered
{

=head2 dump_gathered()

Returns the dump string for the gathered data.

  $hdr->gather($range_description, $data, $size)
  $hdr->gather($range_description, $data, $size)
  
  print $hdr->dump_gathered() ;

I<Arguments> - None

I<Returns> - A string - the binary data formated according to the rnage descriptions

I<Exceptions> - None

=cut

my ($self) = @_ ;

return $self->format($self->split($self->{GATHERED})) ;
}

#-------------------------------------------------------------------------------


sub dump
{

=head2 dump($range_description, $data, $offset, $size)

Dump the data, up to $size, according to the description

I<Arguments> - See L<gather>

I<Returns> - A string -  the formated dump

I<Exceptions> - dies if the range description is invalid

=cut

my ($self) = shift ;

return unless defined wantarray ;

my ($gathered_data, $used_data) = $self->_gather(undef, @_) ;

return $self->format($self->split($gathered_data)) ;
}

#-------------------------------------------------------------------------------

sub get_dump_and_consumed_data_size
{

=head2 get_dump_and_consumed_data_size($range_description, $data, $offset, $size)

Dump the data, from $offset up to $size, according to the $range_description

I<Arguments> - See L<gather>

I<Returns> - 

=over 2

=item *  A string -  the formated dump

=item * An integer - the number of bytes consumed by the range specification

=back 

I<Exceptions> - dies if the range description is invalid

=cut

my ($self) = shift ;

return unless defined wantarray ;

my ($gathered_data, $used_data) = $self->_gather(undef, @_) ;

my $dump =$self->format($self->split($gathered_data)) ;

return  $dump, $used_data ;
}

#-------------------------------------------------------------------------------

sub reset
{

=head2 reset()

Clear the gathered dump 

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self) = @_ ;

$self->{GATHERED} = [] ;

return ;
}

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

my $ranges = $self->create_ranges($range_description) ;

my $used_data = $offset || 0 ;

if($used_data < 0)
	{
	my $location = "$self->{FILE}:$self->{LINE}" ;
	$self->{INTERACTION}{DIE}("Warning: Invalid negative offset at '$location'.\n")
	}

$size = defined $size ? min($size, length($data) - $used_data) : length($data) - $used_data ;

my $location = "$self->{FILE}:$self->{LINE}" ;
my $skip_ranges = 0 ;

for my $range (@{$ranges})
	{
	my ($range_name, $range_size, $range_color) = @{$range} ;
	
	$self->{INTERACTION}{DIE}("Error: size '$range_size' doesn't look like a number in range '$range_name' at '$location'.\n")
		if('' eq ref($range_size) && ! looks_like_number($range_size)) ;
		
	my @sub_or_scalar ;
	
	push @sub_or_scalar, ref($range_name) eq 'CODE' ? $range_name->($data, $used_data, $size)  : $range_name ;
	push @sub_or_scalar, ref($range_size) eq 'CODE' ? $range_size->($data, $used_data, $size)  : $range_size ;
	push @sub_or_scalar, ref($range_color) eq 'CODE' ? $range_color->($data, $used_data, $size)  : $range_color;
	
	($range_name, $range_size, $range_color) = @sub_or_scalar ;
	
	$self->{INTERACTION}{WARN}("Warning: range '$range_name' requires zero bytes.\n")
		if($range_size == 0 && $self->{DISPLAY_ZERO_SIZE_RANGE_WARNING}) ;
		
	if($range_size > $size)
		{
		my $location = "$self->{FILE}:$self->{LINE}" ;
		$self->{INTERACTION}{WARN}("Warning: not enough data for range '$range_name', $range_size needed but only $size available.\n") ;
		
		$range_size = $size;
		$skip_ranges++ ;
		}
			
	push @{$collected_data}, 		
		{
		NAME => $range_name, 
		COLOR => $range_color,
		OFFSET => $used_data,
		DATA => unpack("x$used_data a$range_size", $data)
		} ;
	
	$used_data += $range_size ;
	$size -= $range_size ;
	
	last if $skip_ranges ;
	}

return $collected_data, $used_data ;
}

#-------------------------------------------------------------------------------

sub create_ranges
{

=head2 [P] create_ranges($range_description)

transforms the user supplied ranges into an internal format

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

transforms the user supplied ranges into an internal format

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
	push @ranges, [splice(@flattened, 0, 3)] ;
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
	push @ranges, [splice(@flattened, 0, 3)] ;
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
		if(all {'' eq ref($_) || 'CODE' eq ref($_) } @{$description} ) # todo: handle code refs
			{
			my $location = "$self->{FILE}:$self->{LINE}" ;
			
			# a simple  range description, color is  optional
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
						unless (@{$description} == 3) ;
					}
				}
			elsif(@{$description}  == 2)
				{
				push @{$description}, undef ;
				}
			elsif(@{$description} > 3)
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

my $room_left = $self->{DATA_WIDTH} ;
my $total_dumped_data = 0 ;
my $name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;

for my $data (@{$collected_data})
	{
	if($self->{ORIENTATION} =~ /^hor/)
		{
		my $last_data = $data == $collected_data->[-1] ? 1 : 0 ;
		my $dumped_data = 0 ;
		
		if(0 == length($data->{DATA}) && $self->{DISPLAY_ZERO_SIZE_RANGE})
			{
			my $name_size_quoted = $name_size - 2 ;
			$name_size_quoted =  2 if $name_size_quoted <= 2 ;
			
			push @{$line->{RANGE_NAME}},
				{
				'RANGE_NAME_COLOR' => $data->{COLOR},
				'RANGE_NAME' => '<' . sprintf("%-${name_size_quoted}.${name_size_quoted}s", $data->{NAME}) . '>',
				},
				{
				'RANGE_NAME_COLOR' => undef,
				'RANGE_NAME' => ', ',
				} ;
			}
		
		while ($dumped_data < length($data->{DATA}))
			{
			my $size_to_dump = min($room_left, length($data->{DATA}) - $dumped_data) ;
			$room_left -= $size_to_dump ;
			
			for my  $field_type 
				(
				['OFFSET', sub {@{$line->{OFFSET}} ? '' : sprintf $self->{OFFSET_FORMAT}, $self->{DATA_WIDTH} * @lines}, undef],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @_}, $data->{COLOR}, 3],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @_}, $data->{COLOR}, 4],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @_}, $data->{COLOR}, 1],
				['RANGE_NAME',sub {sprintf "%.${name_size}s", $data->{NAME} ; }, $data->{COLOR}],
				['RANGE_NAME', sub {', '}],
				)
				{
				my ($field_name, $field_data_formater, $color, $pad_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					my $pad = $last_data 
							? $pad_size 
								? ' ' x ($room_left * $pad_size) 
								: '' 
							: '' ;
					
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name => $field_data_formater->(unpack("x$dumped_data C$size_to_dump", $data->{DATA})) . $pad,
						} ;
					}
				}
				
			$dumped_data += $size_to_dump ;
			
			if($room_left == 0 || $last_data)
				{
				$line->{NEW_LINE}++ ;
				push @lines, $line ;
				
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
		
		if(0 == length($data->{DATA}) && $self->{DISPLAY_ZERO_SIZE_RANGE})
			{
			push @{$line->{RANGE_NAME}},
				{
				'RANGE_NAME_COLOR' => $data->{COLOR},
				'RANGE_NAME' => "<$data->{NAME}>",
				} ;
				
			$line->{NEW_LINE} ++ ;
			push @lines, $line ;
			$line = {};
			}
			
		while ($dumped_data < length($data->{DATA}))
			{
			my $size_to_dump = min($self->{DATA_WIDTH}, length($data->{DATA}) - $dumped_data) ;
			
			for my  $field_type 
				(
				['RANGE_NAME',  sub {sprintf "%-${name_size}.${name_size}s", $data->{NAME} ; }, $data->{COLOR}] ,
				['OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $total_dumped_data ;}, undef],
				['CUMULATIVE_OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $dumped_data}, undef],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @_}, $data->{COLOR}, 3],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @_}, $data->{COLOR}, 4],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @_}, $data->{COLOR}, 1],
				)
				{
				my ($field_name, $field_data_formater, $color, $pad_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					my $pad = $pad_size ? ' ' x (($self->{DATA_WIDTH} - $size_to_dump) * $pad_size) : '' ;
					
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name => $field_data_formater->(unpack("x$dumped_data C$size_to_dump", $data->{DATA})) . $pad
						} ;
					}
				}
				
			$dumped_data += $size_to_dump ;
			$total_dumped_data += $size_to_dump ;
			
			$line->{NEW_LINE} ++ ;
			push @lines, $line ;
			$line = {};
			}
		}
	}

return \@lines ;
}

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

for ($self->{FORMAT})
	{
	/ASCII/ || /ANSI/ and do
		{
		use Term::ANSIColor ;
	
		my $colorizer = /ASCII/ ? sub {$_[0]} : \&colored ;
		
		my @fields = 
			$self->{ORIENTATION} =~ /^hor/
				? qw(OFFSET HEX_DUMP DEC_DUMP ASCII_DUMP RANGE_NAME)
				: qw( RANGE_NAME OFFSET CUMULATIVE_OFFSET HEX_DUMP DEC_DUMP ASCII_DUMP) ;

		for my $line (@{$line_data})
			{
			my $default_color = $self->get_default_color() ;
			
			for my $field (@fields)
				{
				if(exists $line->{$field})
					{
					for my $range (@{$line->{$field}})
						{
						my $user_color = defined $self->{COLOR_NAMES} &&  defined $range->{"${field}_COLOR"}
										? $self->{COLOR_NAMES} {$self->{FORMAT}}{$range->{"${field}_COLOR"}}  ||  $range->{"${field}_COLOR"}
										: $range->{"${field}_COLOR"} ;
						
						$formated .= $colorizer->($range->{$field}, $user_color || $default_color) ;
						}
					}
					
				$formated .= ' '
				}
				
			$formated .= "\n" if $line->{NEW_LINE} ;
			}
		} ;
		
	/HTML/ and do
		{
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

L<Data::Hexdumper>

=cut
