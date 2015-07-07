package App::SFDC;

use strict;
use warnings;
use 5.12.0;

# VERSION

sub import {
  my $class = shift;

  require "App/SFDC/$_.pm" ## no critic
    for @_ || qw'Retrieve Deploy'

}

1;


__END__
