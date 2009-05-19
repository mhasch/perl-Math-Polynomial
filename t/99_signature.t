# Copyright (c) 2008-2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 99_signature.t 30 2009-05-19 13:48:07Z demetri $

# Verify signature file.  This is a test for the distribution maintainer.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/99_signature.t'

use strict;
use lib 't/lib';
use Test::MyUtils;

BEGIN {
    maintainer_only();

    use_or_bail('Test::More',        '0.47');
    use_or_bail('Module::Signature', '0.22');
    use_or_bail('Test::Signature',   '1.04');
}

plan(tests => 1);

signature_ok();
