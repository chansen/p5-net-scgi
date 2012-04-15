#!perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('Net::SCGI');
    use_ok('Net::SCGI::IO');
    use_ok('Net::SCGI::Protocol');
}

diag("Net::SCGI $Net::SCGI::VERSION, Perl $], $^X");


