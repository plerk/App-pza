use strict;
use warnings;
use 5.020;
use File::HomeDir::Test;
use Test::More tests => 3;
use t::Mock;
use App::pza;
use Capture::Tiny qw( capture );

my %args = ( dbs_class => 'Database::Server::Foo' );
my $dbs = Database::Server::Foo->new(Database::Server::Foo->create->%*);

subtest 'create' => sub {
  plan tests => 1;
  my $app = App::pza::list->new(%args);
  isa_ok $app, 'App::pza';
};

subtest before_create => sub {
  plan tests => 2;

  my($out, $err, $app) = capture { App::pza::list->new(%args)->run };
  chomp $out;
  my @list = split /\r?\n/, $out;

  is_deeply \@list, [qw( foo template0 template1 )], 'list';
  is $app->exit_value, 0, 'exit';
};

$dbs->create_database('bar');

subtest after_create => sub {
  plan tests => 2;

  my($out, $err, $app) = capture { App::pza::list->new(%args)->run };
  chomp $out;
  my @list = split /\r?\n/, $out;

  is_deeply \@list, [qw( bar foo template0 template1 )], 'list';
  is $app->exit_value, 0, 'exit';
};
