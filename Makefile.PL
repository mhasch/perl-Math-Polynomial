# Copyright (c) 2008-2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: Makefile.PL 43 2009-06-08 21:48:46Z demetri $

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Math::Polynomial',
    VERSION_FROM   => 'lib/Math/Polynomial.pm',
    PREREQ_PM      => {
        overload   => 0,
        Carp       => 0,
    },
    ABSTRACT_FROM  => 'lib/Math/Polynomial.pm',
    AUTHOR         => 'Martin Becker <becker-cpan-mp@cozap.com>',
    $ExtUtils::MakeMaker::VERSION >= 6.18? (
        SIGN       => 1,
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.31? (
        LICENSE    => 'perl',
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.46? (
        META_MERGE => {
            build_requires => {
                'Test'                => 0,
                'Math::Complex'       => 0,
                'File::Spec'          => 0,
                'File::Basename'      => 0,
                'FindBin'             => 0,
                'ExtUtils::MakeMaker' => 0,
            },
            recommends => {
                'Math::Complex'       => 0,
                'Math::BigRat'        => 0,
            },
        },
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.47? (
        MIN_PERL_VERSION => '5.006',
    ): (),
);
