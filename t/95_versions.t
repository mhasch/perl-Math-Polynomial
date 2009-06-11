# Copyright (c) 2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 95_versions.t 59 2009-06-11 21:50:57Z demetri $

# Checking if $VERSION strings of updated perl modules have been updated.
# These are tests for the distribution maintainer.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/95_versions.t'

use 5.006;
use strict;
use warnings;
use Test;
use lib 't/lib';
use Test::MyUtils;

maintainer_only();

my %old_versions = (
    'lib/Math/Polynomial.pm' => {
        '1.000' => 'SHA1 f4978d7196e4be9e31e6725eda10ec9cb1191480',
        '1.001' => 'SHA1 13908cf12891248d7190c5ad6609a0c694b18a4d',

    },
    'lib/Math/Polynomial/Generic.pm' => {
        '0.001' => 'SHA1 7691df469a5bed1e9db51a602e5eb2b6575390dc',
    },
    't/lib/Test/MyUtils.pm' => {
        '0.003' => 'SHA1 ea029d964e2ce5ddf5ecc81a24d2dc2cd0d1fdf2',
    },
);
my %checksums = ();

my $manifest  = Test::MyUtils::slurp_or_bail('MANIFEST');
my @pm_files  = $manifest =~ /^(.+\.pm)$/mgi;

my $signature = Test::MyUtils::slurp_or_bail('SIGNATURE');

if (
    $signature =~ m{
        ^-----BEGIN\s+PGP\s+SIGNED\s+MESSAGE-----\n
        Hash:\s+(\S+)\n
        \n
        (.*)
        ^-----BEGIN\s+PGP\s+SIGNATURE-----\n
    }msx
) {
    my ($hash_type, $checksums) = ($1, $2);
    while ($checksums =~ m/^(\Q$hash_type\E [a-f\d]+)\s+(.*)$/mgo) {
        $checksums{$2} = $1;
    }
}
else {
    print "1..0 # SKIP cannot parse signature file\n";
    exit;
}

plan(tests => 1 + 6 * @pm_files);

ok(0 < @pm_files);
foreach my $file (@pm_files) {
    my $module = $file;
    $module =~ s{(?:t/)?lib/}{};
    $module =~ s{\.pm\z}{}i;
    $module =~ s{/}{::}g;
    print "# checking $module\n";

    my $version = eval "require $module; " . '$' . $module . '::VERSION';
    ok(defined $version);
    $version = '0' if !defined $version;

    my $sane = eval { use warnings FATAL => 'all'; 0 <= $version };
    if (!defined $sane) {
        my $err = $@;
        $err =~ s/\n.*//s;
        print "# strange version: $version: $err\n";
    }
    ok($sane);

    my $documented = '';
    if (open PM_FILE, '<', $file) {
        local $/ = \262144;
        my $content = <PM_FILE>;
        close PM_FILE;
        if (
            defined($content) &&
            $content =~ m{
                \n
                =head\d\s+VERSION\n
                \n
                [^\n]*\s[Vv]ersion\s+
                (\d\S*)\s
            }mx
        ) {
            $documented = $1;
            if ($version ne $documented) {
                print
                    '# $', $module, '::VERSION is ', $version,
                    ' while POD version is ', $documented, "\n";
            }
        }
    }
    skip($documented? 0: 'version not found in POD', $version eq $documented);

    my $checksum = exists($checksums{$file})? $checksums{$file}: '';
    ok(exists $checksums{$file});

    if (!exists $checksums{$file}) {
        foreach ('chronological', 'unchanged') {
            skip('checksum not known', 0);
        }
        next;
    }

    my $old_checksum = '';
    my $chronological = 1;
    if (
        !exists $old_versions{$file} or
        !exists $old_versions{$file}->{$version}
    ) {
        if ($sane && exists $old_versions{$file}) {
            my $mov = -1;
            foreach my $ov (keys %{$old_versions{$file}}) {
                if ($mov < $ov) {
                    $mov = $ov;
                }
            }
            if ($version <= $mov) {
                print "# $module $version <= latest known version $mov\n";
                $chronological = 0;
            }
        }
        if ($chronological) {
            print
                "# $module $version is new:\n",
                "# '$file' => {\n#     '$version' => '$checksum',\n# },\n";
        }
    }
    else {
        $old_checksum = $old_versions{$file}->{$version};
    }
    ok($chronological);

    if ($old_checksum && $old_checksum ne $checksum) {
        print
            "# $file has been changed without version update --\n",
            "# please increase ", '$', "$module", "::VERSION\n";
    }
    ok(!$old_checksum || $old_checksum eq $checksum);
}

__END__
