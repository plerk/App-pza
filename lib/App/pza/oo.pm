use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );

package App::pza::attr {

  use Moose::Role;
  use namespace::autoclean;
  
  has short => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
  );
}

package App::pza::oo {

  # ABSTRACT: OO settings for Pizza

  # This is some crazy stuff.  I recommend
  # not duplicating it.  Like I have.
  # er.

  use Import::Into;
  use constant moose_class => 'Moose';
  
  sub import ($class, @modules)
  {
    my($caller, $caller_file) = caller;

    # fake out %INC
    my $pm = "$caller.pm";
    $pm =~ s{::}{/}g;
    $INC{$pm} //= $caller_file;
    
    # save warning bits to keep experimental
    no warnings 'uninitialized';
    my $old = ${^WARNING_BITS};

    # auto use modules
    unshift @modules, $class->moose_class;
    push @modules, 'App::pza::type';
    push @modules, 'MooseX::Types::Path::Class';
    push @modules, 'namespace::autoclean';
    while(@modules)
    {
      my $module = shift @modules;
      my $pm = "$module.pm";
      $pm =~ s{::}{/}g;
      require $pm;
      my @args = ref $modules[0] eq 'ARRAY' ? (shift @modules)->@* : ();
      $module->import::into($caller, @args);
    }
    ${^WARNING_BITS} = $old;
    
    return;
  }
}

1;
