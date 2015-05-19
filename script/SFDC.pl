#!perl
package SFDC;
# ABSTRACT: Command tool for interacting with Salesforce.com

use strict;
use warnings;
use 5.10.0;
use experimental qw(smartmatch);


sub usage {"
    SFDC: Tools for interacting with Salesforce.com
"}

# The use of shift HAS SIDE EFFECTS. Note that child modules are invoked using
# Getopt::Long, which operates on @ARGV; when this program is invoked, we
# expect @ARGV to start with an operation which would be invalid as input to
# GetOptions, which is why we shift instead of using $_[0]

given (shift) {
    when ('retrieve') {
        require App::SFDC::Retrieve;
        App::SFDC::Retrieve->new_with_options
            ->execute();
    }
    when ('deploy') {
        require App::SFDC::Deploy;
        App::SFDC::deploy->new_with_options
            ->execute();
    }
    default {
        print usage;
    }
}

1;

__END__
