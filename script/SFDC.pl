#!perl
package SFDC;
# ABSTRACT: Command tool for interacting with Salesforce.com

use strict;
use warnings;
use 5.10.0;

# VERSION

use App::SFDC;

sub usage {

    join "\n",
        "SFDC: Tools for interacting with Salesforce.com",
    @App::SFDC::commands
    ? (
        "Installed commands:",
        map {"\t$_"} @App::SFDC::commands,
        "\nFor more detail, run: SFDC <command> --usage"
    )
    : (
        "It doesn't look like you have any modules installed!",
        "Try searching CPAN for App::SFDC::Command"
    )
}

# The use of shift HAS SIDE EFFECTS. Note that child modules are invoked using
# Getopt::Long, which operates on @ARGV; when this program is invoked, we
# expect @ARGV to start with an operation which would be invalid as input to
# GetOptions, which is why we shift instead of using $_[0]

my $command = shift;
exit 1 unless do {
    if ($command and my ($correct_command) = grep {/^$command$/i} @App::SFDC::commands) {
        "App::SFDC::Command::$correct_command"->new_with_options->execute();
    } else {
        print usage;
    }
}

__END__

=head1 DESCRIPTION

This package provides a wrapper around certain common interactions with
Salesforce, with the aim of being sufficiently powerful and flexible for the enterprise, and to make 10k+ line ant XML packages unneccesary.

=head1 DEFAULT MODULES

By default, this application ships with

=head1 SHARED FUNCTIONALITY

All operations use L<App::SFDC::Role::Logging> and L<App::SFDC::Role::Credentials>
to provide shared functionality. Look in those modules to see specifics of the
options they provide.
