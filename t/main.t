use strict;
use warnings;
use 5.020;
use File::HomeDir::Test;
use Test::More tests => 3;
use Test::Exit;
use Capture::Tiny qw( capture );
use lib 'inc';
use Mock;

require App::pza;

is exit_code { App::pza->main }, 1, 'no arguments';

subtest '--help' => sub {
  plan tests => 2;
  is exit_code { App::pza->main('--help') }, 1, '--help';
  is exit_code { App::pza->main('-h') }, 1, '--h';
};

subtest '--version' => sub {
  plan tests => 3;
  local $App::pza::VERSION = '1.23';  
  my($out,$err, $exit) = capture { exit_code { App::pza->main('--version') } };
  is $exit, 0, 'exit = 0';
  like $out, qr{^App::pza version 1.23$}, 'output matches';
  is $err, '', 'error empty';  
};
