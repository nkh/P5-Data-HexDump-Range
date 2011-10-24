
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
sub generate_user_info {my ($data, $used_data, $size, $range) = @_ ;  "offset:$used_data left:$size"} ;

my $range = 'a,b4   :b,b3   :data,1 :c,b9  :d,b3  :e,x4b5    :the end,10' ;
			
my $hdr = Data::HexDump::Range->new
			(
			DISPLAY_ZERO_SIZE_RANGE => 10, DISPLAY_ZERO_SIZE_RANGE_WARNING => 10,
			DISPLAY_USER_INFORMATION => 1,
			ORIENTATION => 'vertical',
			DISPLAY_COLUMN_NAMES => 1,
			#~ DUMP_RANGE_DESCRIPTION => 1,
			) ;

my $data = 'A' . chr(5) . ('0123456789' x  100 ) ;

$hdr->gather($range, $data) ;

print $hdr->dump_gathered() ;

