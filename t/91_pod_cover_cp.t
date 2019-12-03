# Copyright (c) 2007-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Check for POD coverage.
# This is a test for the distribution maintainer.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/91_pod_cover_cp.t'

use strict;
use warnings;
use lib 't/lib';
use Test::MyUtils;

BEGIN {
    maintainer_only();
    use_or_bail('Test::Pod::Coverage', '1.07');
    require Test::Pod::Coverage;        # redundant, but clue for CPANTS
}

all_pod_coverage_ok( { coverage_class => 'Pod::Coverage::CountParents' } );

__END__
