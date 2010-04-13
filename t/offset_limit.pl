
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
my $hdr = Data::HexDump::Range->new() ;

print $hdr->dump([ ['field1', 10, 'red'], ['field2', 10] ], '0123456789' x 2, undef, 18) ;

my $data = '01234X6789' ;

print $hdr->dump(['offset', 1], $data, 5) ;
print $hdr->dump(['limit3', 3], $data, 7, 3) ;
print $hdr->dump(['limit3', 3], $data, 0, 3) ;
print $hdr->dump(['limit3', 5], $data, 0, 3) ;
print $hdr->dump(['limit2', 5], $data, 8, 3) ;

print $hdr->dump([ ['field1', 5], ['field2', 5] ], $data, 0, 8) ;

print $hdr->dump([ ['field1', 5], ['field2', 5] ], $data, -1, 8) ;

