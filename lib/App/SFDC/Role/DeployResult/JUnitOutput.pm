package App::SFDC::Role::DeployResult::JUnitOutput;
# ABSTRACT: Provides JUnit output functionality to DeployResults

use strict;
use warnings;

use Log::Log4perl ':easy';

# VERSION

use Moo::Role;

sub _printTestSuccesses {
    my ($self, $FH) = @_;
    return
        unless $self->result->{runTestsEnabled} eq 'true'
        and $self->complete
        and exists $self->result->{details}->{runTestResult}->{successes};
    print $FH $_ for map {
        my $time = $$_{time}/1000;
        "   <testcase
                name='$$_{methodName}'
                classname='$$_{name}'
                time='$time'>
            </testcase>
        "} (
            ref $self->result->{details}->{runTestResult}->{successes} eq 'ARRAY'
                ? @{$self->result->{details}->{runTestResult}->{successes}}
                : $self->result->{details}->{runTestResult}->{successes}
        );
}

sub _printTestFailures {
    my ($self, $FH) = @_;
    return
        unless $self->result->{runTestsEnabled} eq 'true';
    print $FH $_ for map {
        my $time = $$_{time}/1000;
        "   <testcase
                name='$$_{methodName}'
                classname='$$_{name}'
                time='$time'>
                <failure>
                    <![CDATA[$$_{stackTrace}\n$$_{message}]]>
                </failure>
            </testcase>
        "} @{
            $self->testFailures
        };
}

=method printToJUnit

Accepts a filename and prints JUnit-formatted test results to that file.

=cut

sub printToJUnit {
  my ($self, $fileName) = @_;
  INFO "Writing test results to $fileName";
  open my $FH, '>', $fileName
    or ERROR "Couldn't open $fileName for writing: $!";
  print $FH '<?xml version="1.0" encoding="UTF-8"?>';
  print $FH '<testsuite name="SFDC Unit Tests">';
  $self->_printTestSuccesses($FH);
  $self->_printTestFailures($FH);
  print $FH '</testsuite>';
}

1;

__END__

=head1 SYNOPSIS

    my $deployResult = WWW::SFDC::Metadata::DeployResult->new(%args);
    Role::Tiny->apply_roles_to_object($deployResult, 'App::SFDC::Role::DeployResult::JUnitOutput');
    $deployResult->printToJUnit($fileName);

=cut
