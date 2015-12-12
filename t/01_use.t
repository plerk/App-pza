use strict;
use warnings;
use Test::More tests => 5;
use Test::Script;

require_ok 'App::pza';
require_ok 'App::pza::oo';
require_ok 'App::pza::oo::role';
require_ok 'App::pza::type';

script_compiles 'bin/pza';
