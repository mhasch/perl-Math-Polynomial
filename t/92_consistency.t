# Copyright (c) 2008-2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 92_consistency.t 50 2009-06-10 19:31:06Z demetri $

# Checking package consistency (version numbers, file names, ...).
# These are tests for the distribution maintainer.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/92_consistency.t'

use 5.006;
use strict;
use warnings;
use lib 't/lib';
use Test::MyUtils;
use File::Spec;
use File::Basename;
use FindBin;
use Math::Polynomial 1.000;

my $test_count = 0;

sub plan {
    my ($n) = @_;
    print "1..$n\n";
}

sub test {
    my ($ok, $comment) = @_;
    ++$test_count;
    print
        !$ok && 'not ', "ok $test_count",
        defined($comment) && " - $comment", "\n";
}

sub skip {
    my ($tests, $reason) = @_;
    while (0 < $tests) {
        ++$test_count;
        --$tests;
        print "ok $test_count # SKIP $reason\n";
    }
}

$| = 1;
undef $/;

maintainer_only();

plan 27;

my $README   = 'README';
my $META_YML = 'META.yml';
my $MANIFEST = 'MANIFEST';
my $CHANGES  = 'Changes';
my $modname  = 'Math::Polynomial';
my $distname = $modname;
$distname =~ s/::/-/g;

my %pattern = (
    'binary_file'      => qr{\.(?i:png|jpg|gif)\z},
    'perl_code'        => qr{\.(?i:pm|pl|t)\z},
    'ignore_copyright' => qr{^(?:Changes|MANIFEST|META\.yml|SIGNATURE)\z},
    'copyright_info'   => qr{\bCopyright \(c\) (?:\d{4}-)?(\d{4})?\b},
    'revision_id'      => qr{^\s*#\s+\$Id[\:\$]},
    'revision_info'    =>
        qr{
            ^\s*\#\s+
            \$ Id \:\s+         # keyword
            (\S+)\s+            # filename into $1
            \S+\s+              # version/patch number
            (\d{4})             # year into $2
            -\d\d-\d\d\s+       # month/day
            \S+\s+              # time
            \S+\s+              # user name
            \$
        }x,
    'script_ref'       =>
        qr{
            ^\s*\#[^\n]*\b
            After\s+\`make\s+install\'\s+it\s+should\s+work\s+as\s+
            \`perl\s+t/
            ([\-\w]+\.t)
            \'
        }mx,
);

# part 1: names and version numbers in various places

my $mod_version =
    defined($Math::Polynomial::VERSION)?
        "$Math::Polynomial::VERSION":
        'undef';

print "# dist name is $distname\n";
print "# module version is $mod_version\n";
test $mod_version =~ qr/^\d+\.\d+\z/, 'sane version number';

my $distroot = '.' eq $FindBin::Bin? '..': dirname($FindBin::Bin);
if ($distroot =~ /\b\Q$distname\E-(\d+\.\d+)(?:-\w+)?\z/) {
    test $1 eq $mod_version, 'numbered distro dir matches version';
}
else {
    skip 1, "not running in numbered distro dir";
}

if (open FILE, '<', $README) {
    my $readme = <FILE>;
    close FILE;
    my $found = $readme =~ /^(\S+)\s+version\s+(\d+\.\d+)\n/i;
    test $found, "$README contains distro name and version number";
    if ($found) {
        my ($readme_distname, $readme_version) = ($1, $2);
        print "# $README refers to $readme_distname version $readme_version\n";
        test $readme_distname eq $distname || $readme_distname eq $modname;
        test $readme_version eq $mod_version;
    }
    else {
        skip 2, "unknown $README version";
    }
}
else {
    skip 3, "cannot open $README file";
}

if (open FILE, '<', $META_YML) {
    my $metayml = <FILE>;
    close FILE;
    my $found_dist = $metayml =~ /^name:\s+(\S+)$/mi;
    test $found_dist;
    if ($found_dist) {
        test $1 eq $distname, "$META_YML has matching distro name";
    }
    else {
        skip 1, "unknown $META_YML dist name";
    }
    my $found_vers = $metayml =~ /^version:\s+(\S+)$/mi;
    test $found_vers;
    if ($found_dist) {
        test $1 eq $mod_version, "$META_YML has matching version";
    }
    else {
        skip 1, "unknown $META_YML dist name";
    }
}
else {
    skip 4, "cannot open $META_YML file";
}

my $changes_version = undef;
if (open FILE, '<', $CHANGES) {
    local $/ = "\n";
    $changes_version = '';
    while (<FILE>) {
        if (/^\s*\Q$modname\E\s+(?:[Vv]ersion\s+)?(\d\S*)\s*$/) {
            $changes_version = $1;
            print "# topmost version in $CHANGES is $changes_version\n";
            last;
        }
    }
    close FILE;
}
test defined($changes_version), "$CHANGES file is present";
if (defined $changes_version) {
    test '' ne $changes_version, "$CHANGES file has version numbers";
    test $mod_version eq $changes_version, "$CHANGES file is up to date";
}
else {
    skip 2, "cannot open $CHANGES file";
}

# part 2: references to filenames

my $files_count       = 0;
my @unreadable_files  = ();
my @missing_filenames = ();
my @wrong_filenames   = ();
foreach my $script_path (glob File::Spec->catfile('t', '*.t')) {
    ++$files_count;
    my $script_name = basename($script_path);
    if (open FILE, '<', $script_path) {
        my $script = <FILE>;
        close FILE;
        if ($script =~ /$pattern{'script_ref'}/o) {
            my $referenced_name = $1;
            if ($referenced_name ne $script_name) {
                push @wrong_filenames, "$referenced_name vs. $script_name";
            }
        }
        else {
            push @missing_filenames, $script_name;
        }
    }
    else {
        push @unreadable_files, $script_name;
    }
}
print "# found $files_count test script(s)\n";
test $files_count, 'found test scripts';
print "# unreadable: @unreadable_files\n" if @unreadable_files;
test !@unreadable_files, 'test scripts readable';
print "# w/o file names: @missing_filenames\n" if @missing_filenames;
test !@missing_filenames, 'script filenames referenced';
print "# wrong filename referenced: $_\n" foreach @wrong_filenames;
test !@wrong_filenames, 'referenced filenames match script names';

# part 3: code maturity

$/ = "\n";

my @missing_distfiles   = ();
my @fixme_distfiles     = ();
my @todo_distfiles      = ();
my @debug_distfiles     = ();
my @badchar_distfiles   = ();
my @hardtab_distfiles   = ();
my @lacking_copyright   = ();
my @lacking_revision_id = ();
my @stale_copyright     = ();
my @uncommited_files    = ();
my @all_distfiles       = ();
my $manifest_open = open MANIFEST, '<', $MANIFEST;
test $manifest_open, "$MANIFEST is present";
if ($manifest_open) {
    while (<MANIFEST>) {
        chomp;
        s/\s\s.*//s;
        push @all_distfiles, $_;
    }
    close MANIFEST;
    foreach my $file (@all_distfiles) {
        if (open FILE, '<', $file) {
            if ($file !~ /$pattern{'binary_file'}/o) {
                my $seen_copyright   = 0;
                my $seen_revision_id = 0;
                my $seen_fixme       = 0;
                my $seen_todo        = 0;
                my $seen_debug       = 0;
                my $seen_badchar     = 0;
                my $seen_hardtab     = 0;
                my $in_signature     = 0;
                my $copyright_year   = undef;
                my $checkin_filename = undef;
                my $checkin_year     = undef;
                while (<FILE>) {
                    if (/$pattern{'copyright_info'}/o) {
                        ++$seen_copyright;
                        $copyright_year = $1;
                    }
                    if (/$pattern{'revision_id'}/o) {
                        ++$seen_revision_id;
                        if (/$pattern{'revision_info'}/o) {
                            ($checkin_filename, $checkin_year) = ($1, $2);
                        }
                    }
                    if (!$in_signature && /FI[X]ME/) {
                        ++$seen_fixme;
                    }
                    if (!$in_signature && /TO[D]O/) {
                        ++$seen_todo;
                    }
                    if (!$in_signature && /DE[B]UG/) {
                        ++$seen_debug;
                    }
                    if (/[^\t\n\x20-\x7e]/) {
                        ++$seen_badchar;
                    }
                    if (/\t/) {
                        ++$seen_hardtab;
                    }
                    if (/-----(BEGIN|END) PGP SIGNATURE-----/) {
                        $in_signature = 'BEGIN' eq $1;
                    }
                }
                if (
                    !$seen_copyright &&
                    $file !~ /$pattern{'ignore_copyright'}/
                ) {
                    push @lacking_copyright, $file;
                }
                if (!$seen_revision_id && $file =~ /$pattern{'perl_code'}/) {
                    push @lacking_revision_id, $file;
                }
                if ($seen_fixme) {
                    push @fixme_distfiles, $file;
                }
                if ($seen_todo) {
                    push @todo_distfiles, $file;
                }
                if ($seen_debug) {
                    push @debug_distfiles, $file;
                }
                if ($seen_badchar) {
                    push @badchar_distfiles, $file;
                }
                elsif ($seen_hardtab) {
                    push @hardtab_distfiles, $file;
                }
                if ($seen_revision_id) {
                    if (!defined $checkin_year) {
                        push @uncommited_files, $file;
                    }
                    else {
                        if (
                            defined($copyright_year) &&
                            $copyright_year ne $checkin_year
                        ) {
                            push @stale_copyright, $file;
                        }
                        if ($checkin_filename ne basename($file)) {
                            push @uncommited_files, $file;
                        }
                    }
                }
            }
            close FILE;
        }
        else {
            push @missing_distfiles, $file;
        }
    }
    foreach my $file (@missing_distfiles) {
        print "# missing file: $file\n";
    }
    test !@missing_distfiles, 'distribution complete';
    foreach my $file (@fixme_distfiles) {
        print "# file with FIX", "ME tag: $file\n";
    }
    test !@fixme_distfiles, 'no files flagged as needing fix';
    foreach my $file (@todo_distfiles) {
        print "# file with TO", "DO tag: $file\n";
    }
    test !@todo_distfiles, 'no files flagged as needing more work';
    foreach my $file (@debug_distfiles) {
        print "# file with DE", "BUG tag: $file\n";
    }
    test !@debug_distfiles, 'no files with temporary debugging aids';
    foreach my $file (@badchar_distfiles) {
        print "# file with strange characters: $file\n";
    }
    test !@badchar_distfiles, 'no text files with strange characters';
    foreach my $file (@hardtab_distfiles) {
        print "# file with hardtab characters: $file\n";
    }
    test !@hardtab_distfiles, 'no text files with hardtab characters';
    foreach my $file (@lacking_copyright) {
        print "# file lacking copyright notice: $file\n";
    }
    test !@lacking_copyright, 'copyright notice present where appropriate';
    foreach my $file (@stale_copyright) {
        print "# copyright year != checkin year: $file\n";
    }
    test !@stale_copyright, 'copyright years match checkin dates';
    foreach my $file (@lacking_revision_id) {
        print "# file lacking revision ID: $file\n";
    }
    test !@lacking_revision_id, 'revision ID present in perl source code';
    foreach my $file (@uncommited_files) {
        print "# file probably not yet commited: $file\n";
    }
    test !@uncommited_files, 'revision IDs have date and match filenames';
}
else {
    skip 8, "cannot open $MANIFEST file";
}

__END__
