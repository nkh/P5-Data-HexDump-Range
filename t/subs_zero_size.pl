
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
sub generate_user_info {my ($self, $data, $used_data, $size, $range) = @_ ;  "offset:$used_data left:$size"} ;

my $range = # definition to re-use
	[
	  [sub{'generated name'}, 5, 'blue on_cyan',  \&generate_user_info ],
	  ['size_zero', sub {0}, 'green', \&generate_user_info ],
	  ['generated_color', 20, sub{'red'}, \&generate_user_info ],
	  [sub{ ['generated', sub {5}, 'red on_bright_yellow', \&generate_user_info]} ],
	  ['end', 4],
	] ;
			
my $hdr = Data::HexDump::Range->new
			(
			DISPLAY_ZERO_SIZE_RANGE => 10, DISPLAY_ZERO_SIZE_RANGE_WARNING => 10,
			DISPLAY_USER_INFORMATION => 1,
			ORIENTATION => 'vertical',
			DUMP_RANGE_DESCRIPTION => 1,
			) ;

my $data = 'A' . chr(5) . ('0123456789' x  100 ) ;

$hdr->gather($range, $data) ;

print $hdr->dump_gathered() ;

