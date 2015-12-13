use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );
use File::HomeDir::Test;
use Test::More tests => 4;
use lib 'inc';
use Test::Exec;
use Mock;
use App::pza;

my %args = ( dbs_class => 'Database::Server::Foo' );
my $dbs = Database::Server::Foo->new(Database::Server::Foo->create->%*);

$dbs->start;
$dbs->create_database('roger');
$dbs->stop;

subtest 'default db' => sub {
  is_deeply exec_arrayref { App::pza::shell->new(%args)->run }, ['foodb', 'foo'], 'foodb foo';
};

subtest 'not default db' => sub {
  is_deeply exec_arrayref { App::pza::shell->new(%args, args => ['roger'])->run }, ['foodb', 'roger'], 'foodb roger';
};

subtest '--command' => sub {
  is_deeply exec_arrayref { App::pza::shell->new(%args, args => ['--command', 'foo'])->run }, ['foo'], 'foo';
};

subtest '-c' => sub {
  is_deeply exec_arrayref { App::pza::shell->new(%args, args => ['-c', 'foo'])->run }, ['foo'], 'foo';
};
