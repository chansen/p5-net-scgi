package Net::SCGI::Protocol;

use Carp qw[];

BEGIN {
    our $VERSION   = '0.01';
    our @EXPORT_OK = qw[ build_headers build_netstring parse_headers ];

    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    my $use_pp = $ENV{NET_SCGI_PP} || $ENV{NET_SCGI_PROTOCOL_PP};

    if (!$use_pp) {
        eval { 
            require Net::SCGI::Protocol::XS;
        };
        $use_pp = !!$@;
    }

    if ($use_pp) {
        require Net::SCGI::Protocol::PP;
        Net::SCGI::Protocol::PP->import(@EXPORT_OK);
    }
    else {
        Net::SCGI::Protocol::XS->import(@EXPORT_OK);
    }

    require Exporter;
    *import = \&Exporter::import;
}

1;

