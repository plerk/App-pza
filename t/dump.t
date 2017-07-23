use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );
use Test2::Plugin::FauxHomeDir;
use Test::More tests => 5;
use lib 'inc';
use Mock;
use App::pza;
use Capture::Tiny qw( capture );
use YAML::XS qw( Load );

my($out, $err) = capture { App::pza::dump->new(dbs_class => 'Database::Server::Foo', dbname => 'foo', schema => 1, data => 1)->run };
isnt $out, '', 'at least some output';
note $out;

my $data = Load($out);

is $data->{dbname}, 'foo';
is !!$data->{args}->{schema}, 1;
is !!$data->{args}->{data}, 1;
is !!$data->{args}->{access}, '';
