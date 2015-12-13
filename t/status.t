use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );
use File::HomeDir::Test;
use Test::More tests => 2;
use lib 'inc';
use Mock;
use App::pza;
use Capture::Tiny qw( capture );

my %args = ( dbs_class => 'Database::Server::Foo' );
my $dbs = Database::Server::Foo->new(Database::Server::Foo->create->%*);

subtest status_when_down => sub {

  my($out, $err, $app) = capture { App::pza::status->new(%args)->run };
  chomp $out;
  is $out, 'down';
  is $app->exit_value, 2, 'exit';

};

$dbs->start;

subtest status_when_up => sub {

  my($out, $err, $app) = capture { App::pza::status->new(%args)->run };
  chomp $out;
  is $out, 'up';
  is $app->exit_value, 0, 'exit';

};
