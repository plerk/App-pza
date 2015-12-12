# pza [![Build Status](https://secure.travis-ci.org/plicease/App-pza.png)](http://travis-ci.org/plicease/App-pza)

Command line interface to Database::Server

# SYNOPSIS

    % pza db command [options]

# DESCRIPTION

## Databases

The first argument should be the database server software
you intend to use.  Supported server software:

### PostgreSQL (may be abbreviated: pg)

Requires [Database::Server::PostgreSQL](https://metacpan.org/pod/Database::Server::PostgreSQL) to be installed.

### MySQL (may be abbreviated: my)

Requires [Database::Server::MySQL](https://metacpan.org/pod/Database::Server::MySQL) to be installed.

### SQLite (may be abbreviated: lt)

Requires [Database::Server::SQLite](https://metacpan.org/pod/Database::Server::SQLite) be installed.  Uses
a faux database instance.

# OPTIONS

## general

Options that work with any subcommand:

### --help

Print this help and exit.

### --version

Print version and exit.

## list

List databases

# AUTHOR

Graham Ollis &lt;plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
