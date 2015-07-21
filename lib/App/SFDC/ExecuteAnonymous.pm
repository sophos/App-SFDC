package App::SFDC::ExecuteAnonymous;
# ABSTRACT: Use the apex API to execute anonymous apex code

use strict;
use warnings;

use Log::Log4perl ':easy';
use Data::Dumper;

use Moo;
use MooX::Options;
with 'App::SFDC::Role::Logging',
    'App::SFDC::Role::Credentials';

option 'expression',
    is => 'ro',
    format => 's',
    short => 'E',
    lazy => 1,
    builder => sub {
        my $self = shift;
        local $/;
        if ($self->file) {
            INFO "Reading apex code from ".$self->file;
            open my $FH, '<', $self->file;
            return <$FH>;
        } else {
            INFO "Reading apex code from STDIN";
            return <STDIN>;
        }
    };

option 'file',
    is => 'ro',
    format => 's',
    short => 'f',
    isa => sub {
        LOGDIE "The given file, $_[0], does not exist!" unless -e $_[0];
    };

has '_result',
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        DEBUG "Expression:\t".$self->expression;
        $self->_session->Apex->executeAnonymous(
            $self->expression,
            debug => 1
        )
    };

=method execute()

Executes the anonymous code against the target sandbox, printing the debug log
to STDOUT and returning truth or falsehood depending on whether the code
executed successfully.

=cut

sub execute {
    my $self = shift;

    print $self->_result->log;
    return $self->_result->success;
}

1;
