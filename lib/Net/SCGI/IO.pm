package Net::SCGI::IO;
use strict;
use warnings;
use warnings::register;

use Carp                qw[];
use Errno               qw[EINTR EPIPE];
use Net::SCGI::Protocol qw[build_headers build_netstring parse_headers];

BEGIN {
    our $VERSION   = '0.01';
    our @EXPORT_OK = qw[ read_headers
                         read_request
                         write_headers
                         write_request ];

    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    require Exporter;
    *import = \&Exporter::import;
}

sub MIN_HEADERS_LEN   () { 24 }
sub MIN_NETSTRING_LEN () { 28 }

sub read_headers {
    @_ == 1 || Carp::croak(q/Usage: read_headers(fh)/);
    my ($fh) = @_;

    my $len = MIN_NETSTRING_LEN;
    my $off = 0;
    my $buf;
    my $eol;

    while ($len) {
        my $r = sysread($fh, $buf, $len, $off);
        if (defined $r) {
            last unless $r;
            $len -= $r;
            $off += $r;
            if (!$len && $off == MIN_NETSTRING_LEN) {
                if ($buf !~ /\A (0 | [1-9][0-9]*) : /x) {
                    $! = EPIPE;
                    warnings::warn(q<SCGI: Could not read headers: Malformed netstring length>)
                      if warnings::enabled;
                    return;
                }
                if ($1 < MIN_HEADERS_LEN) {
                    $! = EPIPE;
                    warnings::warn(q<SCGI: Could not read headers: Insufficient number of octets in headers>)
                      if warnings::enabled;
                    return;
                }
                $eol = $+[0];
                $len = $1 - MIN_NETSTRING_LEN + 1 + $eol;
            }
        }
        elsif ($! != EINTR) {
            warnings::warn(qq<SCGI: Could not read headers: '$!'>)
              if warnings::enabled;
            return;
        }
    }
    if ($len) {
        $! = EPIPE;
        warnings::warn(qq<SCGI: Could not read headers: Unexpected end of stream>)
          if warnings::enabled;
        return;
    }
    if (chop($buf) ne ',') {
        $! = EPIPE;
        warnings::warn(q<SCGI: Could not read headers: Malformed netstring terminator>)
          if warnings::enabled;
        return;
    }
    substr($buf, 0, $eol, '');
    return parse_headers($buf);
}

sub read_request {
    @_ == 1 || Carp::croak(q/Usage: read_request(fh)/);
    my ($fh) = @_;

    my $headers = read_headers($fh)
      or return;

    my $len  = $headers->{CONTENT_LENGTH};
    my $off  = 0;
    my $body = '';

    while ($len) {
        my $r = sysread($fh, $body, $len, $off);
        if (defined $r) {
            last unless $r;
            $len -= $r;
            $off += $r;
        }
        elsif ($! != EINTR) {
            warnings::warn(qq<SCGI: Could not read body: '$!'>)
              if warnings::enabled;
            return;
        }
    }
    if ($len) {
        $! = EPIPE;
        warnings::warn(q<SCGI: Could not read body: Unexpected end of stream>)
          if warnings::enabled;
        return;
    }
    return ($headers, $body);
}

sub write_headers {
    @_ == 2 || @_ == 3 || Carp::croak(q/Usage: write_headers(fh, headers [, content_length])/);
    my ($fh, $headers, $content_length) = @_;

    my $buf = build_netstring(build_headers($headers, $content_length));
    my $len = length $buf;
    my $off = 0;

    while () {
        my $r = syswrite($fh, $buf, $len, $off);
        if (defined $r) {
            $len -= $r;
            $off += $r;
            last unless $len;
        }
        elsif ($! != EINTR) {
            warnings::warn(qq<SCGI: Could not write headers: '$!'>)
              if warnings::enabled;
            return;
        }
    }
    return $off;
}

sub write_request {
    @_ == 2 || @_ == 3 || Carp::croak(q/Usage: write_request(fh, headers [, content])/);
    my ($fh, $headers, $content) = @_;

    my $len = 0;
    my $off = 0;

    $content = ''
      unless defined $content;

    utf8::downgrade($content, 1)
      or Carp::croak(q/SCGI: Wide character in content/);
    $len = length $content;

    my $res = write_headers($fh, $headers, $len)
      or return;

    while () {
        my $r = syswrite($fh, $content, $len, $off);
        if (defined $r) {
            $len -= $r;
            $off += $r;
            last unless $len;
        }
        elsif ($! != EINTR) {
            warnings::warn(qq<SCGI: Could not write content: '$!'>)
              if warnings::enabled;
            return;
        }
    }
    return $res + $off;
}

1;

