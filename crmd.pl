#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use lib 'lib';
use CopyRename;
use Delete;
use Move;

my $command = $ARGV[0];

if ($command eq 'd') {
    $command = 'delete';
    Delete::init();
}
else {
    if ($command eq 'm') {
        $command = 'rmove';
        Move::init();
    }
    else {
        if ($command eq 'c') {
            $command = 'rcopy';
        }
        elsif ($command eq 'r') {
            $command = 'rname';
        }
        CopyRename::init($command);
    }
}

