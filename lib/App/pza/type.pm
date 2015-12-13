use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );

package App::pza::type {

  # ABSTRACT: types for Pizza
  
  use Moose::Util::TypeConstraints;
  use namespace::autoclean;

  my @types = (
    subtype('App::pza::OptStr'  => as 'Maybe[Str]'),
    subtype('App::pza::OptFlag' => as 'Maybe[Bool]'),
    map { Moose::Util::TypeConstraints::get_type_constraint_registry->get_type_constraint($_) } qw(
      Int
      Str
      Bool
    ),
  );
  
  sub import
  {
    my $caller = caller;
    foreach my $type (@types)
    {
      constant->import::into($caller, ($type->name =~ s{^.*::}{}r) => $type);
    }
  }

}

1;
