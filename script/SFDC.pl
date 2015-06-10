#!perl
package SFDC;
# ABSTRACT: Command tool for interacting with Salesforce.com

use strict;
use warnings;
use 5.10.0;
use experimental qw(smartmatch);
use App::SFDC;


sub usage {"
    SFDC: Tools for interacting with Salesforce.com

    Valid commands:

        retrieve - Retrieve metadata from SFDC

        deploy   - Deploy metadata to SFDC

    For more detail, run: SFDC <command> --usage
"}

# The use of shift HAS SIDE EFFECTS. Note that child modules are invoked using
# Getopt::Long, which operates on @ARGV; when this program is invoked, we
# expect @ARGV to start with an operation which would be invalid as input to
# GetOptions, which is why we shift instead of using $_[0]

given (shift) {
    when (/retrieve/i) {
        App::SFDC::Retrieve->new_with_options->execute();
    }
    when (/deploy/i) {
        App::SFDC::Deploy->new_with_options->execute();
    }
    default {
        print usage;
    }
}

1;

__END__

=head1 DESCRIPTION

This package provides a wrapper around certain common interactions with Salesforce,
with the aim of being sufficiently powerful and flexible for the enterprise, and to
make 10k+ line ant XML packages unneccesary.

=head1 SHARED FUNCTIONALITY

All operations use L<App::SFDC::Role::Logging> and L<App::SFDC::Role::Credentials>
to provide shared functionality. Look in those modules to see specifics of the
options they provide.
