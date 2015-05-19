package App::SFDC::Role::Logging;
# ABSTRACT: Handle logging customisation on the command line

use strict;
use warnings;
use 5.8.8;

use Log::Log4perl ':easy';
use Moo::Role;
use MooX::Options;

Log::Log4perl->easy_init({
    level   => $INFO,
    layout => "%d %p: %m%n",
});

has 'logger',
    is => 'rw',
    lazy => 1,
    default => sub {Log::Log4perl->get_logger("")};

option 'debug',
    is => 'ro',
    short => 'd',
    trigger => sub {
        $_[0]->logger->level($DEBUG)
    };

option 'trace',
    is => 'ro',
    trigger => sub {
        $_[0]->logger->level($TRACE)
    };

option 'log',
    format => 's',
    is => 'ro',
    trigger => sub {
       $_[0]->logger->add_appender(
            Log::Log4perl::Appender->new(
                "Log::Log4perl::Appender::File",
                name      => "$_[1]logger",
                filename  => $_[1]
            )
        )
    };

1;

__END__
