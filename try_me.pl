
use strict ;
use warnings ;

use lib qw(lib) ;
use Data::TreeDumper ;

use Data::HexDump::Range  qw() ;
 
sub my_parser 
	{
	my ($dumper, $data, $offset) = @_ ;
	
	my $first_byte = unpack ("x$offset C", $data) ;
	
	$offset < length($data)
		?  $first_byte == ord(0)
			? ['from odd', 5, 'blue on_yellow']
			: ['from even', 3, 'green']
		: undef ;
	}

my $data = '01' x 50 ;
#~ my $hdr = Data::HexDump::Range->new(ORIENTATION => 'vertical') ;
my $hdr = Data::HexDump::Range->new() ;

print $hdr->dump(\&my_parser, $data) ;

