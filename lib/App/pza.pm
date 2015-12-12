use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );

package App::pza {

  # ABSTRACT: Command line for Database::Server
  use File::HomeDir ();
  use Path::Class qw( file );
  use MooseX::Types::Path::Class qw( File Dir );
  use YAML::XS ();
  use App::pza::oo;

  has db_class => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
  );
  
  has db_config_file => (
    is      => 'ro',
    isa     => File,
    lazy    => 1,
    coerce  => 1,
    default => sub {
      my($self) = @_;
      my $file = file( File::HomeDir->my_home, '.pizza', 'etc', lc($self->db_class).'.yml');
      $file->parent->mkpath(0,0700) unless -d $file->parent;
      $file;
    },
  );
  
  has db_config => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      my $file = $self->db_config_file;
      -f $file 
        ? YAML::XS::Load("$file")
        : do {
          my $config = $self->db_class->create($file->parent->parent);
          YAML::XS::Dump("$file", $config);
          $config;
        };
    },
  );

  has db => (
    is      => 'ro',
    isa     => 'Database::Server::Role::Server',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      $self->db_class->new($self->db_config);
    },
  );
  
  sub start_unless_up ($self)
  {
    $self->db->is_up || $self->start;
    $self;
  }

  __PACKAGE__->meta->make_immutable;
}

package App::pza::list {

  use App::pza::oo;
  extends 'App::pza';

  sub run ($self)
  {
    say for 
      $self
        ->start_unless_up
        ->list_databases
        ->@*;
  }

  __PACKAGE__->meta->make_immutable;
}

package App::pza::main {

  use Getopt::Long qw( GetOptionsFromArray );
  use Pod::Usage   qw( pod2usage           );
  use Module::Load qw( load                );

  sub App::pza::main ($, @args)
  {
    if(!defined $args[0] || $args[0] =~ /^-/)
    {
      GetOptionsFromArray(\@args, 
        'help|h'       => sub { pod2usage({ -verbose => 2}) },
        'version'      => sub {
          say 'App::pza version ', (App::pza->VERSION // 'dev');
          exit;
        },
      );
      pod2usage(1);
    }
    
    my %dbs = (
      my         => 'MySQL',
      mysql      => 'MySQL',
      pg         => 'PostgreSQL',
      postgres   => 'PostgreSQL',
      postgresql => 'PostgreSQL',
      lt         => 'SQLite',
      sqlite     => 'SQLite',
    );
    
    my $dbs_class = $dbs{shift @args//''};
    pod2usage(-message  => 'unknown database specified', 
              -exitval  => 1, 
              -verbose  => 99,
              -sections => ['SYNOPSIS', 'DESCRIPTION/Databases']) unless $dbs_class;
    $dbs_class = "Database::Server::$dbs_class";
    
    my $class = shift @args;
    pod2usage(-message => 'no command specified', -exitval => 1)
      unless $class;
    
    $class = "App::pza::$class";
    pod2usage(-message => 'no such command', -exitval => 1)
      unless $class->can('new');

    eval qq{ load $dbs_class };
    if($@)
    {
      say STDERR "Install $dbs_class";
      exit 2;
    }
    
    exit $class
      ->new(db_class => $dbs_class, args => \@args)
      ->run;
  }
}

1;

