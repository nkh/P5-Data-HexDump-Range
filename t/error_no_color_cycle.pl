
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
my $hdr = Data::HexDump::Range->new() ;

my $range = [['field1', 10], ['field2', 10]] ;

print $hdr->dump([$range, $range, $range ], '0123456789' x 6) ;


