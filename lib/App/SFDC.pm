package App::SFDC;
# ABSTRACT: Implements the SFDC command-line application

use strict;
use warnings;
use 5.12.0;

# VERSION

use File::Find 'find';

our @commands;

sub import {
    my $class = shift;

    @commands = @_
        or find
            {
                wanted => sub {push @commands, $1 if m'App/SFDC/Command/(\w*)\.pm'},
                no_chdir => 1
            },
            grep {-e} map {$_.'/App/SFDC'} @INC;

    # Deduplication:
    my %commands = map {$_ => 1} @commands;
    @commands = sort keys %commands;

    require "App/SFDC/Command/$_.pm" for @commands; ## no critic
}

1;

__END__

#head1 SYNOPSIS

    # require all available modules
    use App::SFDC;

    # require only specified modules
    use App::SFDC qw'Deploy Retrieve';

    my @availableCommands = @App::SFDC::commands;

    # Read options from @ARGV
    "App::SFDC::$command"->new_with_options->execute();

    # Use these options
    "App::SFDC::$command"->new(%options)->execute();

#head1 USER DOCUMENTATION

For more information on the SFDC application, read L<SFDC>. For more on a
specific module's options and functionality, visit that module's page.

#head1 WRITING A MODULE

App::SFDC modules consume the L<WWW::SFDC> API wrapper in order to perform
useful tasks on the Salesforce platform. To contribute your own module,
you should create a new module in the App::SFDC namespace, using Moo and
MooX::Options. You should then consume App::SFDC::Role::Credentials and
App::SFDC::Role::Logging, and provide an execute() method, which returns a
truthy value on success and a falsey value on failure.
