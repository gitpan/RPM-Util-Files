#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RPM::Util::Files::Entry' );
}

diag( "Testing RPM::Util::Files::Entry $RPM::Util::Files::Entry::VERSION, Perl $], $^X" );
