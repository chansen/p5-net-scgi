package t::Util;

use strict;
use warnings;

use IO::File    qw[SEEK_SET SEEK_END];
use Test::Fatal qw[exception];

BEGIN {
    our @EXPORT_OK = qw(
        tmpfile
        slurp
        rewind
        throws_ok
        warns_ok
    );

    require Exporter;
    *import = \&Exporter::import;
}

sub rewind(*) {
    seek($_[0], 0, SEEK_SET)
      || die(qq/Couldn't rewind file handle: '$!'/);
}

sub tmpfile {
    my $fh = IO::File->new_tmpfile
      || die(qq/Couldn't create a new temporary file: '$!'/);

    binmode($fh)
      || die(qq/Couldn't binmode temporary file handle: '$!'/);

    if (@_) {
        print({$fh} @_)
          || die(qq/Couldn't write to temporary file handle: '$!'/);

        seek($fh, 0, SEEK_SET)
          || die(qq/Couldn't rewind temporary file handle: '$!'/);
    }

    return $fh;
}

sub slurp (*) {
    my ($fh) = @_;

    seek($fh, 0, SEEK_END)
      || die(qq/Couldn't navigate to EOF on file handle: '$!'/);

    my $exp = tell($fh);

    rewind($fh);

    binmode($fh)
      || die(qq/Couldn't binmode file handle: '$!'/);

    my $buf = do { local $/; <$fh> };
    my $got = length $buf;

    ($exp == $got)
      || die(qq[I/O read mismatch (expexted: $exp got: $got)]);

    return $buf;
}

my $Tester;
sub throws_ok (&$;$) {
    my ($code, $regexp, $name) = @_;

    require Test::Builder;
    $Tester ||= Test::Builder->new;

    my $e  = exception(\&$code);
    my $ok = ($e && $e =~ m/$regexp/);

    $Tester->ok($ok, $name);

    unless ($ok) {
        if ($e) {
            $Tester->diag("expecting: " . $regexp);
            $Tester->diag("found: " . $e);
        }
        else {
            $Tester->diag("expected an exception but none was raised");
        }
    }
}

sub warns_ok (&$;$) {
    my ($code, $regexp, $name) = @_;

    require Test::Builder;
    $Tester ||= Test::Builder->new;

    my @warnings = ();
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $e  = exception(\&$code);
    my $ok = (!$e && @warnings == 1 && $warnings[0] =~ m/$regexp/);

    $Tester->ok($ok, $name);

    unless ($ok) {
        if ($e) {
            $Tester->diag("expected a warning but an exception was raised");
            $Tester->diag("exception: " . $e);
        }
        elsif (@warnings == 0) {
            $Tester->diag("expected a warning but none were issued");
        }
        elsif (@warnings >= 2) {
            $Tester->diag("expected a warning but several were issued");
            $Tester->diag("warnings: " . join '', @warnings);
        }
        else {
            $Tester->diag("expecting: " . $regexp);
            $Tester->diag("found: " . $warnings[0]);
        }
    }
}

1;

