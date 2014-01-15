#!perl

use strict;
use warnings;

use Test::More 0.88;
use t::Util qw[throws_ok];

use Net::SCGI::Protocol qw[parse_headers];

{
    my $headers = join "\x00", CONTENT_LENGTH => 0, SCGI => 1, '';
    my $exp     = { CONTENT_LENGTH => 0, SCGI => 1 };
    my $got     = parse_headers($headers);
    is_deeply($got, $exp, "parse_headers()");
}

{
    my $headers = join "\x00", CONTENT_LENGTH => 0, SCGI => 1, Foo => "\x{263A}", '';
    throws_ok {
        parse_headers($headers);
    } qr/Wide character/, "Wide characters raises an exception";
}

{
    my $headers = '';
    throws_ok {
        parse_headers($headers);
    } qr/Insufficient number of octets/, "at least 24 octets is required to represent a well-formed SCGI header";
}

{
    my $headers = join "\x00", SCGI => 1, CONTENT_LENGTH => 0, '';
    throws_ok {
        parse_headers($headers);
    } qr/Malformed headers/, "The first header must have the name CONTENT_LENGTH";
}

{
    my $headers = join "\x00", CONTENT_LENGTH => 0, SCGI => 1, SCGI => 1, '';
    throws_ok {
        parse_headers($headers);
    } qr/Duplicate header/, "Duplicate header names are not allowed";
}

{
    my $headers = join "\x00", CONTENT_LENGTH => 0, SCGI => 1, '' => '', '';
    throws_ok {
        parse_headers($headers);
    } qr/Malformed header name/, "Zero length header names are not allowed";
}

{
    my $headers = join "\x00", CONTENT_LENGTH => 0, SCGI => 1, 'Foo';
    throws_ok {
        parse_headers($headers);
    } qr/Truncated headers/, "Truncated headers";
}

done_testing;

