use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );
use Database::Server;

package Mock {
  
  our %uage;  
}

package Pod::Usage {

  use Carp qw( croak );
  use base qw( Exporter );
  our @EXPORT_OK = qw( pod2usage );

  sub pod2usage
  {
    croak "mock pod2usage only takes a hash argument (not hash ref)"
      if @_ % 2;
    my %args = @_;
    
    do { no warnings; %Mock::usage = %args };
    
    my $exit = delete $args{'-exitval'} // 2;
    
    exit $exit;
  }

}

package Database::Server::Foo {

  use Moose;
  use Carp qw( croak );
  use experimental qw( signatures postderef );
  use namespace::autoclean;

  with 'Database::Server::Role::Server';

  has foo => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
  );

  my %db = map { $_ => 1 } qw( foo template0 template1 );
  my $up   = 0;
  my $init = 0;
  
  sub create
  {
    my %config = ( foo => 'bar' );
    __PACKAGE__->new(%config)->init;
    \%config;
  }

  sub create_database ($self, $dbname)
  {
    croak "database is not up" unless $up;
    croak "database $dbname already exists" if $db{$dbname};
    $db{$dbname} = 1;
  }
  
  sub drop_database ($self, $dbname)
  {
    croak "database is not up" unless $up;
    croak "database no such database $dbname" unless $db{$dbname};
    delete $db{$dbname};
  }
  
  sub dsn 
  {
    croak "todo";
  }
  
  sub interactive_shell
  {
  }
  
  sub is_up
  {
    $up;
  }
  
  sub list_databases
  {
    sort keys %db;
  }
  
  sub shell
  {
    croak "todo";
  }
  
  sub start
  {
    $up = 1;
  }
  
  sub stop
  {
    $up = 0;
  }
  
  sub init
  {
    $init = 1;
  }

  __PACKAGE__->meta->make_immutable;
}

1;
