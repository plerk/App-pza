use strict;
use warnings;
use 5.020;
use File::HomeDir::Test;
use Test::More tests => 4;
use t::Mock;
use App::pza;

my %args = ( dbs_class => 'Database::Server::Foo' );
my $dbs = Database::Server::Foo->new(Database::Server::Foo->create->%*);

is $dbs->is_up, 0, 'down';

my $app = eval { App::pza::start->new(%args)->run };
is $@, '', 'App::pza::start.new.run';
is $app->exit_value, 0, 'exit';

is $dbs->is_up, 1, 'up';

