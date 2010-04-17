
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

use Carp qw(carp croak confess) ;

#use Graphics::ColorNames
use List::Util qw(min) ;
use List::MoreUtils qw(all) ;
use Scalar::Util qw(looks_like_number) ;
use Term::ANSIColor ;
use Data::TreeDumper ;

use Data::HexDump::Range::Gather ;
use Data::HexDump::Range::Split ;
use Data::HexDump::Range::Format ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range - Hexadecial Range Dumper

=head1 SYNOPSIS

  my $hdr = Data::HexDump::Range->new() ;
  
  print $hdr->dump(['magic cookie', 12, 'red'], $data) ;
  
  $hdr->gather(['magic cookie', 12, 'red'], $data) ; 
  $hdr->gather(['image type', 2, 'green'], $other_data) ;
  
  print $hdr->dump_gathered() ;
  $hdr->reset() ;

=head1 DESCRIPTION

Creates a dump from binary data and user defined I<range> descriptions. The goal of this modules is
to create an easy to understand dump of binary data. This achieved through:

=over 2

=item * Highlighted (colors) dump that is easier to understand than a monochrome blob of hex data

=item * Multiple rendering modes with different output formats

=item * Bitfield rendering

=item * The possibility to describe complex structures

=back

=head1 DOCUMENTATION

The shortest perl dumper is C<perl -ne 'BEGIN{$/=\16} printf "%07x0: @{[unpack q{(H2)*}]}\n", $.-1'>, courtesy of a golfing session 
with Andrew Rodland <arodland@cpan.org> aka I<hobbs>. I<priodev>, I<tm604>, I<Khisanth> and other helped with the html output.

B<hexd> from libma L<http://www.ioplex.com/~miallen/libmba/> is nice tools that inspired me to write this module. It may be a better 
alternative If you need very fast dump generation.

B<Data::HexDump::Range> splits binary data according to user defined I<ranges> and rendered as a B<hex> or/and B<decimal> data dump.
The data dump can be rendered in ANSI, ASCII or HTML.

=head2 Rendered Columns

You can choose which columns are rendered by setting options when creating a Data::HexDump::Range object.
The default rendering corresponds to the object below:

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

If you decided that you wanted the binary data to be showed in decimal instead for hexadecimal, you' set B<DISPLAY_HEX_DUMP => 0> and B<DISPLAY_DEC_DUMP => 1>.
See L<new> for all the possible options. Most option are also available from the command line utility I<hdr>.

=head2 Orientation

Command I<hdr -r 'magic cookie,12:padding, 32:header,5:data, 20:extra data,#:header,5:data,40:footer,4' -col -o ver -display_ruler 1 lib/Data/HexDump/Range.pm>

=head3 Vertical

In this orientation mode, each range displayed on a separate line.

 RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP
                                    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345
 magic cookie     00000000 00000000 0a 70 61 63 6b 61 67 65 20 44 61 74              .package Dat
 padding          0000000c 00000000 61 3a 3a 48 65 78 44 75 6d 70 3a 3a 52 61 6e 67  a::HexDump::Rang
 padding          0000001c 00000010 65 20 3b 0a 0a 75 73 65 20 73 74 72 69 63 74 3b  e ;..use strict;
 header           0000002c 00000000 0a 75 73 65 20                                   .use
 data             00000031 00000000 77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20 43  warnings ;.use C
 data             00000041 00000010 61 72 70 20                                      arp
 "extra data"
 header           00000045 00000000 3b 0a 0a 42 45                                   ;..BE
 data             0000004a 00000000 47 49 4e 20 0a 7b 0a 0a 75 73 65 20 53 75 62 3a  GIN .{..use Sub:
 data             0000005a 00000010 3a 45 78 70 6f 72 74 65 72 20 2d 73 65 74 75 70  :Exporter -setup
 data             0000006a 00000020 20 3d 3e 20 0a 09 7b 0a                           => ..{.
 footer           00000072 00000000 09 65 78 70                                      .exp

In colors:

=begin html

<pre style ="font-family: monospace; background-color: #000 ;">

<span style='color:#fff;'>RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP       </span> 
<span style='color:#fff;'>                                   0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345 </span> 
<span style='color:#0f0;'>magic cookie    </span> <span style='color:#fff;'>00000000</span> <span style='color:#fff;'>00000000</span> <span style='color:#0f0;'>0a 70 61 63 6b 61 67 65 20 44 61 74             </span> <span style='color:#0f0;'>.package Dat    </span> 
<span style='color:#ff0;'>padding         </span> <span style='color:#fff;'>0000000c</span> <span style='color:#fff;'>00000000</span> <span style='color:#ff0;'>61 3a 3a 48 65 78 44 75 6d 70 3a 3a 52 61 6e 67 </span> <span style='color:#ff0;'>a::HexDump::Rang</span> 
<span style='color:#ff0;'>padding         </span> <span style='color:#fff;'>0000001c</span> <span style='color:#fff;'>00000010</span> <span style='color:#ff0;'>65 20 3b 0a 0a 75 73 65 20 73 74 72 69 63 74 3b </span> <span style='color:#ff0;'>e ;..use strict;</span> 
<span style='color:#f0f;'>header          </span> <span style='color:#fff;'>0000002c</span> <span style='color:#fff;'>00000000</span> <span style='color:#f0f;'>0a 75 73 65 20                                  </span> <span style='color:#f0f;'>.use            </span> 
<span style='color:#f00;'>data            </span> <span style='color:#fff;'>00000031</span> <span style='color:#fff;'>00000000</span> <span style='color:#f00;'>77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20 43 </span> <span style='color:#f00;'>warnings ;.use C</span> 
<span style='color:#f00;'>data            </span> <span style='color:#fff;'>00000041</span> <span style='color:#fff;'>00000010</span> <span style='color:#f00;'>61 72 70 20                                     </span> <span style='color:#f00;'>arp             </span> 
<span style='color:#fff;'>"extra data"</span> 
<span style='color:#0f0;'>header          </span> <span style='color:#fff;'>00000045</span> <span style='color:#fff;'>00000000</span> <span style='color:#0f0;'>3b 0a 0a 42 45                                  </span> <span style='color:#0f0;'>;..BE           </span> 
<span style='color:#ff0;'>data            </span> <span style='color:#fff;'>0000004a</span> <span style='color:#fff;'>00000000</span> <span style='color:#ff0;'>47 49 4e 20 0a 7b 0a 0a 75 73 65 20 53 75 62 3a </span> <span style='color:#ff0;'>GIN .{..use Sub:</span> 
<span style='color:#ff0;'>data            </span> <span style='color:#fff;'>0000005a</span> <span style='color:#fff;'>00000010</span> <span style='color:#ff0;'>3a 45 78 70 6f 72 74 65 72 20 2d 73 65 74 75 70 </span> <span style='color:#ff0;'>:Exporter -setup</span> 
<span style='color:#ff0;'>data            </span> <span style='color:#fff;'>0000006a</span> <span style='color:#fff;'>00000020</span> <span style='color:#ff0;'>20 3d 3e 20 0a 09 7b 0a                         </span> <span style='color:#ff0;'> => ..{.        </span> 
<span style='color:#f0f;'>footer          </span> <span style='color:#fff;'>00000072</span> <span style='color:#fff;'>00000000</span> <span style='color:#f0f;'>09 65 78 70                                     </span> <span style='color:#f0f;'>.exp            </span> 

</pre>

=end html

=head3 Horizontal

In this mode, the data are packed together in the dump

 OFFSET   HEX_DUMP                                         ASCII_DUMP       RANGE_NAME
          0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345
 00000000 0a 70 61 63 6b 61 67 65 20 44 61 74 61 3a 3a 48  .package Data::H magic cookie, padding,
 00000020 65 78 44 75 6d 70 3a 3a 52 61 6e 67 65 20 3b 0a  exDump::Range ;. padding,
 00000030 0a 75 73 65 20 73 74 72 69 63 74 3b 0a 75 73 65  .use strict;.use padding, header,
 00000050 20 77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20   warnings ;.use  header, data,
 00000070 43 61 72 70 20 3b 0a 0a 42 45 47 49 4e 20 0a 7b  Carp ;..BEGIN .{ data, "extra data", header, data,
 000000a0 0a 0a 75 73 65 20 53 75 62 3a 3a 45 78 70 6f 72  ..use Sub::Expor data,
 000000b0 74 65 72 20 2d 73 65 74 75 70 20 3d 3e 20 0a 09  ter -setup => .. data,
 000000c0 7b 0a 09 65 78 70                                {..exp           data, footer,

In colors:


=begin html

<pre style ="font-family: monospace; background-color: #000 ;">

<span style='color:#fff;'>OFFSET   HEX_DUMP                                         ASCII_DUMP       RANGE_NAME              </span> 
<span style='color:#fff;'>         0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345                         </span> 
<span style='color:#fff;'>00000000</span><span style='color:#fff;'></span> <span style='color:#0f0;'>0a 70 61 63 6b 61 67 65 20 44 61 74 </span><span style='color:#ff0;'>61 3a 3a 48 </span> <span style='color:#0f0;'>.package Dat</span><span style='color:#ff0;'>a::H</span> <span style='color:#0f0;'>magic cookie</span><span style='color:#fff;'>, </span><span style='color:#ff0;'>padding</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>00000020</span> <span style='color:#ff0;'>65 78 44 75 6d 70 3a 3a 52 61 6e 67 65 20 3b 0a </span> <span style='color:#ff0;'>exDump::Range ;.</span> <span style='color:#ff0;'>padding</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>00000030</span><span style='color:#fff;'></span> <span style='color:#ff0;'>0a 75 73 65 20 73 74 72 69 63 74 3b </span><span style='color:#f0f;'>0a 75 73 65 </span> <span style='color:#ff0;'>.use strict;</span><span style='color:#f0f;'>.use</span> <span style='color:#ff0;'>padding</span><span style='color:#fff;'>, </span><span style='color:#f0f;'>header</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>00000050</span><span style='color:#fff;'></span> <span style='color:#f0f;'>20 </span><span style='color:#f00;'>77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20 </span> <span style='color:#f0f;'> </span><span style='color:#f00;'>warnings ;.use </span> <span style='color:#f0f;'>header</span><span style='color:#fff;'>, </span><span style='color:#f00;'>data</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>00000070</span><span style='color:#fff;'></span><span style='color:#fff;'></span> <span style='color:#f00;'>43 61 72 70 20 </span><span style='color:#0f0;'>3b 0a 0a 42 45 </span><span style='color:#ff0;'>47 49 4e 20 0a 7b </span> <span style='color:#f00;'>Carp </span><span style='color:#0f0;'>;..BE</span><span style='color:#ff0;'>GIN .{</span> <span style='color:#f00;'>data</span><span style='color:#fff;'>, </span><span style='color:#fff;'>"extra data"</span><span style='color:#fff;'>, </span><span style='color:#0f0;'>header</span><span style='color:#fff;'>, </span><span style='color:#ff0;'>data</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>000000a0</span> <span style='color:#ff0;'>0a 0a 75 73 65 20 53 75 62 3a 3a 45 78 70 6f 72 </span> <span style='color:#ff0;'>..use Sub::Expor</span> <span style='color:#ff0;'>data</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>000000b0</span> <span style='color:#ff0;'>74 65 72 20 2d 73 65 74 75 70 20 3d 3e 20 0a 09 </span> <span style='color:#ff0;'>ter -setup => ..</span> <span style='color:#ff0;'>data</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>000000c0</span><span style='color:#fff;'></span> <span style='color:#ff0;'>7b 0a </span><span style='color:#f0f;'>09 65 78 70                               </span> <span style='color:#ff0;'>{.</span><span style='color:#f0f;'>.exp          </span> <span style='color:#ff0;'>data</span><span style='color:#fff;'>, </span><span style='color:#f0f;'>footer</span><span style='color:#fff;'>, </span> 

</pre>

=end html

=head2 Range definition

  my $simple_range = ['magic cookie', 12, 'red'] ;
  
Ranges are Array references containing four (4) elements:

=over 2

=item * name - a string

=item * size - an integer

=item * color - a string or undef

=item * user information - a very short string descibing  the range

=back

Any of the elements can be replaced by a subroutine reference. See L<Dynamic range definition> below.

You can also declare the ranges in a string. The string use the format used by the I<hdr> command line range dumper
that was installed by this module.

Example:

I<hdr --col -display_ruler -o ver lib/Data/HexDump/Range.pm -r 'header,12:name,10:magic,2:offset,4:BITMAP,4,bright_yellow:ff,x2b2:fx,b32:f0,b16:field,x8b8:field2, b17:footer,20'>
       
TODO: document string range format

=head3 Coloring

Ranges and ranges names are displayed according to the color field in the range definition. 

The color definition is one of:

=over 2

=item * A user defined color name found in B<COLOR_NAMES> (see L<new>)

=item * An ansi color definition - 'blue on_yellow'

=item * undef - will be repaced by a white color or picked from a cyclic color list (see B<COLOR> in L<new>).

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
	
=head4 Comment ranges

If the size of a range is the string '#', the whole range is considered a comment

  my $range_defintion_with_comments = 
	[
	  ['comment text', '#', 'optional color for meta range'],
	  ['magic cookie', 12, 'red'],
	  ['padding', 88, 'yellow'],
	    
	  [
	    ['another comment', '#'],
	    ['data header', 5, 'blue on_yellow'],
	    ['data', 100, 'blue'],
	  ],
	] ;

=head3 Bitfields

Bitfields can be up to 32 bits long and can overlap each other. Bitfields are applied on the previously defined range.

In the example below, bitfields I<ff, fx, f0> are extracted form the data defined by the I<MYDATA> range.

                 .------------.                      .--------------.
                 | data range |                      | data hexdump |
 .---.           '------------'                      '--------------'
 | b |                  |                                    |
 | i |     RANGE_NAME   |   OFFSET   CUMULATI HEX_DUMP       |                                 ASCII_DUMP     
 | t |     MYDATA  <----'   00000000 00000000 63 6f 6d 6d <--'                                 comm           
 | f |   ^ .ff              02 .. 03          -- -- -- 02 --10----------------------------     .bitfield: ---.
 | i |---> .fx              03 .. 19          -- 00 36 f6 ---00011011011110110------------     .bitfield: -.6?
 | e |   v .f0              07 .. 17          -- -- 05 bd -------10110111101--------------     .bitfield: --.?
 | l |                         ^                    ^                     ^                          ^
 | d |                         |                    |                     |                          |
 | s |             .----------------------.-------------------.----------------------.    .---------------------.
 '---'             | start bit .. end bit | bitfields hexdump | bitfield binary dump |    | bitfield ascci dump |
                   '----------------------'-------------------'----------------------'    '---------------------'

The the format definiton  is: an optional "x (for offset) + offset" + "b (for bits) + number of bits". Eg: I<x8b8> second byte in MYDATA.

An example output containing normal data and bifields dumps.

command: I<hdr --col -display_ruler -o ver -r 'header,12:name,10:magic, 2:offset,4:BITMAP,4,bright_yellow:ff,x2b2:fx,b32:f0,b16::footer,16' file_name

=begin html

<pre style ="font-family: monospace; background-color: #000 ;">

<span style='color:#fff;'>RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP       </span> 
<span style='color:#fff;'>                                   0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345 </span> 
<span style='color:#0f0;'>header          </span> <span style='color:#fff;'>00000000</span> <span style='color:#fff;'>00000000</span> <span style='color:#0f0;'>0a 70 61 63 6b 61 67 65 20 44 61 74             </span> <span style='color:#0f0;'>.package Dat    </span> 
<span style='color:#ff0;'>name            </span> <span style='color:#fff;'>0000000c</span> <span style='color:#fff;'>00000000</span> <span style='color:#ff0;'>61 3a 3a 48 65 78 44 75 6d 70                   </span> <span style='color:#ff0;'>a::HexDump      </span> 
<span style='color:#f0f;'>magic           </span> <span style='color:#fff;'>00000016</span> <span style='color:#fff;'>00000000</span> <span style='color:#f0f;'>3a 3a                                           </span> <span style='color:#f0f;'>::              </span> 
<span style='color:#f00;'>offset          </span> <span style='color:#fff;'>00000018</span> <span style='color:#fff;'>00000000</span> <span style='color:#f00;'>52 61 6e 67                                     </span> <span style='color:#f00;'>Rang            </span> 
<span style='color:#ff0;'>MYDATA          </span> <span style='color:#fff;'>0000001c</span> <span style='color:#fff;'>00000000</span> <span style='color:#ff0;'>65 20 3b 0a                                     </span> <span style='color:#ff0;'>e ;.            </span> 
<span style='color:#fff;'>.ff             </span> <span style='color:#fff;'>02 .. 03</span> <span style='color:#fff;'>        </span> <span style='color:#fff;'>-- -- -- 02 --10----------------------------    </span> <span style='color:#fff;'>.bitfield: ---. </span> 
<span style='color:#0f0;'>.fx             </span> <span style='color:#0f0;'>00 .. 31</span> <span style='color:#0f0;'>        </span> <span style='color:#0f0;'>65 20 3b 0a 01100101001000000011101100001010    </span> <span style='color:#0f0;'>.bitfield: e ;. </span> 
<span style='color:#ff0;'>.f0             </span> <span style='color:#ff0;'>00 .. 15</span> <span style='color:#ff0;'>        </span> <span style='color:#ff0;'>-- -- 65 20 0110010100100000----------------    </span> <span style='color:#ff0;'>.bitfield: --e  </span> 
<span style='color:#f0f;'>footer          </span> <span style='color:#fff;'>00000020</span> <span style='color:#fff;'>00000000</span> <span style='color:#f0f;'>0a 75 73 65 20 73 74 72 69 63 74 3b 0a 75 73 65 </span> <span style='color:#f0f;'>.use strict;.use</span> 

</pre>

=end html

B<NOTE!> This is under heavy developemnt. Complete error handling and indianess support are under way.

=head3 Dynamic range definition

The whole range can be replaced by a subroutine reference or elements of the range can be replaced by
a subroutine definition.

  my $dynamic_range =
	[
	  [\&name, \&size, \&color ],
	  [\&define_range] # returns a range definition
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

=head4 'range' sub ref

  sub whole_range(['whole range', 5, 'on_yellow']}
  
  $hdr->dump([\&whole_range], $data) ; #note this is very different from L<User defined range generator>

=head3  User defined range generator

A subroutine reference can be passed as a range definition. The cubroutine will be called repetitively
till the data is exhausted or the subroutine returns I<undef>.

  sub my_parser 
  	{
  	my ($data, $offset) = @_ ;
  	
  	my $first_byte = unpack ("x$offset C", $data) ;
  	
  	$offset < length($data)
  		?  $first_byte == ord(0)
  			? ['from odd', 5, 'blue on_yellow']
  			: ['from even', 3, 'green']
  		: undef ;
  	}
  
  my $hdr = Data::HexDump::Range->new() ;
  print $hdr->dump(\&my_parser, '01' x 50) ;

=head2 my_parser($data, $offset)

Returns a range description for the next range to dump

I<Arguments> - See L<gather>

=over 2

=item * $data - Binary string - the data passed to the I<dump> method

=item * $offset - Integer - current offset in $data

=back

I<Returns> - 

=over 2

=item * $range - An array reference containing a name, size and color

OR

=item * undef - Done parsing

=back

=cut

=head1 EXAMPLES

See L<hdr_user_manual>

=head1 OTHER IDEAS

- allow pack format as range size
	pack in array context returns the amount of fields processed
	fixed format can be found with a length of unpack

- hook with Convert::Binary::C to automatically create ranges

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
	DISPLAY_OFFSET DISPLAY_CUMULATIVE_OFFSET
	DISPLAY_ZERO_SIZE_RANGE_WARNING
	DISPLAY_ZERO_SIZE_RANGE 
	DISPLAY_RANGE_NAME
	MAXIMUM_RANGE_NAME_SIZE
	DISPLAY_RANGE_SIZE
	DISPLAY_ASCII_DUMP
	DISPLAY_HEX_DUMP
	DISPLAY_DEC_DUMP
	DISPLAY_USER_INFORMATION
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
		DISPLAY_COLUMN_NAMES => 0,
		DISPLAY_RULER => 0,
		DISPLAY_OFFSET  => 1 ,
		DISPLAY_CUMULATIVE_OFFSET  => 1 ,
		DISPLAY_ZERO_SIZE_RANGE_WARNING => 1,
		DISPLAY_ZERO_SIZE_RANGE => 1,
		DISPLAY_RANGE_SIZE => 1,
		DISPLAY_ASCII_DUMP => 1 ,
		DISPLAY_HEX_DUMP => 1,
		DISPLAY_DEC_DUMP => 1,
		COLOR_NAMES => {},
		ORIENTATION => 'horizontal',
		) ;

I<Arguments> - All arguments are optional. Default values are listed below.

=over 2 

=item * NAME - String - Name of the Data::HexDump::Range object, set to 'Anonymous' by default

=item * INTERACTION - Hash reference - Set of subs that are used to display information to the user

Useful if you use Data::HexDump::Range in an application without terminal.

=item * VERBOSE - Boolean - Display information about the creation of the object. Default is I<false>

=item * DUMP_RANGE_DESCRIPTION - Boolean - Diplays the range descritption. A debugging flag.

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

=item * MAXIMUM_RANGE_NAME_SIZE - Integer - maximum size of a range name (horizontal mode). Default size is 16.

=item * DISPLAY_COLUMN_NAMES - Boolean -  If set, the column names are displayed. Default I<false>

=item * DISPLAY_RULER - Boolean - if set, a ruler is displayed above the dump, Default is I<false>

=item * DISPLAY_OFFSET - Boolean - If set, the offset column is displayed. Default I<true>

=item * DISPLAY_CUMULATIVE_OFFSET - Boolean - If set, the cumulative offset column is displayed in 'vertical' rendering mode. Default is I<true>

=item * DISPLAY_ZERO_SIZE_RANGE - Boolean - if set, ranges that do not consume data are displayed. default is I<true> 

=item * DISPLAY_ZERO_SIZE_RANGE_WARNING - Boolean - if set, a warning is emitted if ranges that do not consume data. Default is I<true> 

=item * DISPLAY_RANGE_SIZE - Bolean - if set the range size is prepended to the name. Default I<false>

=item * DISPLAY_ASCII_DUMP - Boolean - If set, the ASCII representation of the binary data is displayed. Default is I<true>

=item * DISPLAY_HEX_DUMP - Boolean - If set, the hexadecimal dump column is displayed. Default is I<true>

=item * DISPLAY_DEC_DUMP - Boolean - If set, the decimall dump column is displayed. Default is I<false>

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
	DUMP_RANGE_DESCRIPTION => 0,
	
	FORMAT => 'ANSI',
	COLOR => 'bw',
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

	COLOR_NAMES => 
		{
		HTML =>
			{
			white => "style='color:#fff;'",
			green => "style='color:#0f0;'",
			bright_yellow => "style='color:#ff0;'",
			yellow => "style='color:#ff0;'",
			cyan => "style='color:#f0f;'",
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

$self->{FIELDS_TO_DISPLAY} =  $self->{ORIENTATION} =~ /^hor/
	? [qw(OFFSET HEX_DUMP DEC_DUMP ASCII_DUMP RANGE_NAME)]
	: [qw(RANGE_NAME OFFSET CUMULATIVE_OFFSET HEX_DUMP DEC_DUMP ASCII_DUMP USER_INFORMATION)] ;


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

=item * $range_description - See L<Range definition>
  
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

my $split_data = $self->split($self->{GATHERED}) ;

$self->add_information($split_data) ;

return $self->format($split_data) ;
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

my ($self, $range_description, $data, $offset, $size) = @_ ;

return unless defined wantarray ;

my ($gathered_data, $used_data) = $self->_gather(undef, $range_description, $data, $offset, $size) ;

my $split_data = $self->split($gathered_data) ;

$self->add_information($split_data) ;

return $self->format($split_data) ;
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
