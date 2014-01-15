#!perl

use strict;
use warnings;

use Test::More 0.88;
use Test::HexString;
use t::Util             qw[tmpfile warns_ok];

use Errno               qw[EPIPE];
use Net::SCGI::Protocol qw[build_headers build_netstring];
use Net::SCGI::IO       qw[read_headers];

{
    my $headers = build_netstring(build_headers({ Foo => 'Bar' }));
    my $fh      = tmpfile($headers);
    my $exp     = { CONTENT_LENGTH => 0, SCGI => 1, Foo => 'Bar' };
    my $got     = read_headers($fh);
    is_deeply($got, $exp, "read_headers()");
}

{
    my $fh  = tmpfile('');
    my $got;
    warns_ok {
        $got = read_headers($fh);
    } qr/Unexpected end of stream/, "read_headers(EOF)";

    is($got, undef, "read_headers(EOF) - returns undef");
    is($! + 0, EPIPE, "read_headers(EOF) - errno is set to EPIPE");
}

{
    my $buf = join "\x00", CONTENT_LENGTH => 0, SCGI => 1, '';
    my $fh  = tmpfile(sprintf '%d:%s-', length($buf), $buf);
    my $got;
    warns_ok {
        $got = read_headers($fh);
    } qr/ Malformed netstring terminator/, "read_headers(broken netsring)";

    is($got, undef, "read_headers(broken netsring) - returns undef");
    is($! + 0, EPIPE, "read_headers(broken netsring) - errno is set to EPIPE");
}

done_testing;

