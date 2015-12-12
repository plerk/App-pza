use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );
use File::HomeDir::Test;
use Test::More tests => 4;
use t::Mock;
use App::pza;

my %args = ( dbs_class => 'Database::Server::Foo' );
my $dbs = Database::Server::Foo->new(Database::Server::Foo->create->%*);

$dbs->start;
is $dbs->is_up, 1, 'up';

my $app = eval { App::pza::stop->new(%args)->run };
is $@, '', 'App::pza::stop.new.run';
is $app->exit_value, 0, 'exit';

is $dbs->is_up, 0, 'down';
