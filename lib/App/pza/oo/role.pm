use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );

package App::pza::oo::role {

  # ABSTRACT: Roles for Pizza
  
  use constant moose_class => 'Moose::Role';
  require App::pza::oo;
  
  sub import
  {
    goto &App::pza::oo::import;
  }
}

1;
