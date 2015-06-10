package App::SFDC;

use strict;
use warnings;
use 5.12.0;

sub import {
  my $class = shift;

  require "App/SFDC/$_.pm"
    for @_ || qw'Retrieve Deploy'

}

1;


__END__
