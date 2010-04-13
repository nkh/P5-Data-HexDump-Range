
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
my $range = # definition to re-use
	[
	  [sub{'generated name'}, 5, 'blue on_cyan'],
	  ['size_zero', sub {0}, 'green'],
	  ['generated_color', 20, sub{'red'}],
	  [sub{ 'generated', sub {5}, 'red on_yellow'}],
	] ;
			
my $hdr = Data::HexDump::Range->new(DISPLAY_ZERO_SIZE_RANGE => 10, DISPLAY_ZERO_SIZE_RANGE_WARNING => 10) ;

my $data = 'A' . chr(5) . ('0123456789' x  100 ) ;

$hdr->gather($range, $data) ;

print $hdr->dump_gathered() ;

