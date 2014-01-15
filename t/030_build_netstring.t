#!perl

use strict;
use warnings;

use Test::More 0.88;
use t::Util qw[throws_ok];

use Net::SCGI::Protocol qw[build_netstring];

{
    my $str = 'Foo';
    my $exp = '3:Foo,';
    my $got = build_netstring($str);
    is($got, $exp, qq[build_netstring('$str')]);
}

{
    my $str = '';
    my $exp = '0:,';
    my $got = build_netstring($str);
    is($got, $exp, qq[build_netstring('$str')]);
}

{
    my $str = "\x{263A}";
    throws_ok {
        build_netstring($str);
    } qr/Wide character/, "Wide characters raises an exception";
}

done_testing;


