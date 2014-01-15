#!perl

use strict;
use warnings;

use Test::More 0.88;
use Test::HexString;
use t::Util qw[throws_ok];

use Net::SCGI::Protocol qw[build_headers];

{
    my $headers = {};
    my $exp     = join "\x00", CONTENT_LENGTH => 0, SCGI => 1, '';
    my $got     = build_headers($headers);
    is_hexstr($got, $exp, "build_headers({})");
}

{
    my $headers = { CONTENT_LENGTH => 10, SCGI => 2 };
    my $exp     = join "\x00", CONTENT_LENGTH => 10, SCGI => 2, '';
    my $got     = build_headers($headers);
    is_hexstr($got, $exp, "build_headers({CONTENT_LENGTH => 10, SCGI => 2})");
}

{
    my $headers = { Foo => 'Bar' };
    my $exp     = join "\x00", CONTENT_LENGTH => 20, SCGI => 1, Foo => 'Bar', '';
    my $got     = build_headers($headers, 20);
    is_hexstr($got, $exp, "build_headers({Foo => 'Bar'}, 20)");
}

{
    my $headers = { Foo => "\x{263A}" };
    throws_ok {
        build_headers($headers);
    } qr/Wide character/, "Wide characters raises an exception";
}

done_testing;

