package Net::SCGI::Protocol::PP;
use strict;
use warnings;

use Carp qw[];

BEGIN {
    our $VERSION   = '0.01';
    our @EXPORT_OK = qw[ build_headers build_netstring parse_headers ];

    require Exporter;
    *import = \&Exporter::import;
}

sub MIN_HEADERS_LEN () { 24 }

sub parse_headers {
    @_ == 1 || Carp::croak(q/Usage: parse_headers(octets)/);
    my ($octets) = @_;

    utf8::downgrade($octets, 1)
      or Carp::croak(q/SCGI: Wide character in octet string/);

    (length($octets) >= MIN_HEADERS_LEN)
      or Carp::croak(q/SCGI: Insufficient number of octets to parse headers/);

    (substr($octets, 0, 15) eq "CONTENT_LENGTH\x00")
      or Carp::croak(q/SCGI: Malformed headers/);

    my %headers = ();
    while ($octets =~ /\G ([^\x00]*) \x00 ([^\x00]*) \x00/xgc) {
        (length $1)
          or Carp::croak(qq/SCGI: Malformed header name/);
        (!exists $headers{$1})
          or Carp::croak(qq/SCGI: Duplicate header name: '$1'/);
        $headers{$1} = $2;
    }
    ($octets =~ /\G \z /xgc)
      or Carp::croak(q/SCGI: Truncated headers/);
    return \%headers;
}

sub build_headers {
    @_ == 1 || @_ == 2 || Carp::croak(q/Usage: build_headers(headers [, content_length])/);
    my ($headers, $content_length) = @_;

    $content_length = $headers->{CONTENT_LENGTH} || 0
      unless defined $content_length;

    my $v = $headers->{SCGI} || 1;
    my $r = "CONTENT_LENGTH\x00${content_length}\x00SCGI\x00${v}\x00";
    while (my ($k, $v) = each(%$headers)) {
        next if $k eq 'CONTENT_LENGTH'
             or $k eq 'SCGI';
        no warnings 'uninitialized';
        $r .= "$k\x00$v\x00";
    }

    utf8::downgrade($r, 1)
      or Carp::croak(q/SCGI: Wide character in headers/);

    return $r;
}

sub build_netstring {
    @_ == 1 || Carp::croak(q/Usage: build_netstring(octets)/);
    my ($octets) = @_;

    utf8::downgrade($octets, 1)
      or Carp::croak(q/SCGI: Wide character in octet string/);

    substr($octets, 0, 0, length($octets) . ':');
           $octets .= ',';
    return $octets;
}

1;

