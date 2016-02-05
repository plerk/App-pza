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
  use Getopt::Long    qw( GetOptionsFromArray );
  use Pod::Usage      qw( pod2usage           );
  use App::pza::oo;

  has dbs_class => (
    is       => 'ro',
    isa      => Str,
    required => 1,
  );
  
  has dbs_config_file => (
    is      => 'ro',
    isa     => File,
    lazy    => 1,
    coerce  => 1,
    default => sub ($self) {
      my $file = file( File::HomeDir->my_home, '.pizza', 'etc', lc($self->dbs_class =~ s/^.*:://r).'.yml');
      $file->parent->mkpath(0,0700) unless -d $file->parent;
      $file;
    },
  );
  
  has dbs_config => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    default => sub ($self) {
      my $file = $self->dbs_config_file;
      -f $file 
        ? YAML::XS::LoadFile("$file")
        : do {
          my $config = $self->dbs_class->create($file->parent->parent);
          YAML::XS::DumpFile("$file", $config);
          $config;
        };
    },
  );

  has dbs => (
    is      => 'ro',
    does    => 'Database::Server::Role::Server',
    lazy    => 1,
    default => sub ($self) {
      $self->dbs_class->new($self->dbs_config);
    },
  );
  
  sub get_dbs ($, $class)
  {
    $class = "Database::Server::$class" unless $class =~ /::/;
    __PACKAGE__->new(dbs_class => $class)->dbs;
  }
  
  has exit_value => (
    is      => 'rw',
    isa     => Int,
    default => 0,
  );
  
  has args => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
  );

  sub start_unless_up ($self)
  {
    $self->dbs->is_up || $self->dbs->start;
    $self;
  }
  
  sub BUILDARGS ($class, %args)
  {
    my @options = (
      'help|h'       => sub { pod2usage({ -verbose => 1}) },
      'version'      => sub {
          say 'App::pza version ', (App::pza->VERSION // 'dev');
          exit;
        },
    );
  
    foreach my $attr ($class->meta->get_all_attributes)
    {
      my $constraint = $attr->type_constraint;
      next unless $constraint;
      my $name = $attr->name;
      $name .= '|' . $attr->short if $attr->does('App::pza::attr') && $attr->short;
      if($constraint->name eq 'App::pza::OptStr')
      {
        push @options, $name . '=s' => \$args{$attr->name},
      }
      elsif($constraint->name eq 'App::pza::OptFlag')
      {
        push @options, $name  => \$args{$attr->name},
      }
    }
    $args{args} //= [];
    $args{args} = [@{ $args{args} }];
    GetOptionsFromArray($args{args}, @options) || pod2usage({ -exitval => 1 });
    \%args,
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
        ->dbs->list_databases;
    $self;
  }

  __PACKAGE__->meta->make_immutable;
}

package App::pza::start {

  use App::pza::oo;
  extends 'App::pza';

  sub run ($self)
  {
    $self->start_unless_up;
    $self;
  }

  __PACKAGE__->meta->make_immutable;
}

package App::pza::stop {

  use App::pza::oo;
  extends 'App::pza';

  sub run ($self)
  {
    $self->dbs->stop if $self->dbs->is_up;
    $self;
  }

  __PACKAGE__->meta->make_immutable;
}

package App::pza::status {

  use App::pza::oo;
  extends 'App::pza';

  sub run ($self)
  {
    if($self->dbs->is_up)
    {
      say 'up';
    }
    else
    {
      say 'down';
      $self->exit_value(2);
    }
    $self;
  }

  __PACKAGE__->meta->make_immutable;
}

package App::pza::shell {

  use Carp qw( croak );
  use App::pza::oo;
  extends 'App::pza';
  
  has command => (
    is     => 'ro',
    isa    => OptStr,
    short  => 'c',
  );
  
  sub run ($self)
  {
    $self->start_unless_up;
    if($self->command)
    {
      my $dbs = $self->dbs;
      croak "unable to set environment for ", ref $dbs unless $dbs->can('env');
      $dbs->env(sub {
        exec $self->command;
      });
    }
    else
    {
      $self->dbs->interactive_shell($self->args->[0], exec => 1);
    }
    $self;
  }

  __PACKAGE__->meta->make_immutable;
}

package App::pza::dump {

  use File::Temp qw( tempfile );
  use App::pza::oo;
  extends 'App::pza';
  
  has data => (
    is    => 'ro',
    isa   => OptFlag,
    short => 'd',
  );
  
  has schema => (
    is    => 'ro',
    isa   => OptFlag,
    short => 's',
  );
  
  has access => (
    is    => 'ro',
    isa   => OptFlag,
    short => 'a',
  );
  
  has dbname => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
      shift->args->[0],
    },
  );
  
  sub run ($self)
  {
    $self->start_unless_up;
    
    my($fh, $filename) = tempfile('pzadumpXXXX', SUFFIX => '.sql', UNLINK => 1, TMPDIR => 1);
    close $fh;
    $self->dbs->dump($self->dbname => $filename,
      data   => $self->data,
      schema => $self->schema,
      access => $self->access,
    );
    open $fh, '<', $filename;
    print STDOUT while <$fh>;
    close $fh;
    
    $self;
  }

}

package App::pza::diff {

  use App::pza::oo;
  extends 'App::pza';
  
  has data => (
    is    => 'ro',
    isa   => OptFlag,
    short => 'd',
  );
  
  has schema => (
    is    => 'ro',
    isa   => OptFlag,
    short => 's',
  );
  
  has access => (
    is    => 'ro',
    isa   => OptFlag,
    short => 'a',
  );
  
  has dbname_a => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
      shift->args->[0],
    },
  );

  has dbname_b => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    default => sub {
      shift->args->[1],
    },
  );

  sub run ($self)
  {
    $self->start_unless_up;
    
    my $text = $self->dbs->diff($self->dbname_a, $self->dbname_b,
      data   => $self->data,
      schema => $self->schema,
      access => $self->access,
    );
    
    $self->exit_value(1) unless $text eq '';
    
    print $text;
    
    $self;
  }
}

package App::pza::main {

  use Getopt::Long    qw( GetOptionsFromArray );
  use Pod::Usage      qw( pod2usage           );
  use Module::Load    qw( load                );
  use List::MoreUtils qw( uniq                );
  use Path::Class     qw( file dir            );
  use YAML::XS        qw( LoadFile            );
  use File::HomeDir;

  sub App::pza::main ($, @args)
  {
    if(!defined $args[0] || $args[0] =~ /^-/)
    {
      GetOptionsFromArray(\@args, 
        'help|h'       => sub { pod2usage({ -verbose => 1}) },
        'version'      => sub {
          say 'App::pza version ', (App::pza->VERSION // 'dev');
          exit;
        },
      );
      pod2usage({ -exitval => 1 });
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

    if(defined $args[0] && $args[0] =~ /^(status|stop|destroy)$/)
    {
      my @dbs =
        map {
          eval qq{ load $_->[0]; 1 } || do { say STDERR "Install @{[ $_->[0] ]}"; exit 2 };
          $_->[0]->new(LoadFile($_->[1]));
        }
        grep { -f $_->[1] }
        map { ["Database::Server::$_", file( File::HomeDir->my_home, qw( .pizza etc ), lc($_).'.yml' ) ] }
        uniq 
        sort 
        values %dbs;

      if($args[0] eq 'status')
      {
        foreach my $dbs (@dbs)
        {
          my $name = ref($dbs) =~ s{^.*::}{}r;
          printf "%10s %s\n", $name, $dbs->is_up ? 'up' : 'down';
        }
      }
      elsif($args[0] =~ /^(stop|destroy)/)
      {
        foreach my $dbs (@dbs)
        {
          next unless $dbs->is_up;
          next if $dbs->isa('Database::Server::SQLite');
          my $name = ref($dbs) =~ s{^.*::}{}r;
          printf "%10s %s", $name, 'stopping...';
          $dbs->stop;
          print "stoped\n";
        }
        if($args[0] eq 'destroy')
        {
          my $dir = dir( File::HomeDir->my_home, '.pizza' );
          say "removing $dir";
          $dir->rmtree(0,1);
        }
      }
      exit;
    }
    
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

    eval { load $dbs_class };
    if($@)
    {
      say STDERR "Install $dbs_class";
      exit 2;
    }
    
    exit $class
      ->new(dbs_class => $dbs_class, args => \@args)
      ->run
      ->exit_value;
  }
}

1;

