use strict;
use warnings;
use feature 'say';
use File::Copy 'copy';
use File::Copy::Recursive qw/fmove rmove rcopy/;

my $arg = $ARGV[0];

print "f/d/a/q?\n> ";
chomp(my $init = <STDIN>);

my $fmt  = '';
if ($init eq 'f') {
    $fmt = 'file';
}
elsif ($init eq 'd') {
    $fmt = 'dir';
}
elsif ($init eq 'a') {
    $fmt = 'all';
}
else {
    exit;
}

my $dir  = '.';
my $tree = '';

result($fmt);
main($arg);

sub result {
    my $fmt = shift;

    my (@file, @dir) = ();
    my $last_dir = '';

    opendir(my $iter, $dir) or die $!;
    for (readdir $iter) {
        next if ($_ =~ /\A\./);
        if (-f $dir . '/' . $_) {
            push @file, "\tfile: $_\n";
        }
        elsif (-d $dir . '/' . $_) {
            push @dir, "\tdir: $_/\n";
            $last_dir = $_;
        }
    }
    closedir $iter;

    say 'ls:';
    if ($fmt eq 'dir') {
        print @dir;
    }
    elsif ($fmt eq 'file') {
        print @file;
    }
    else {
        print @dir;
        print @file;
    }

    if ($tree =~ /([^\/]+)\/([^\/]+)$/) {
        say "\t---";
        my @tree = `tree $1`;
        for (@tree) {
            print "\t$_";
        }
        $tree = '';
    }

    say '';
}

sub main {
    my $arg = shift;

    print "Put the words before & after\n> ";
    chomp(my $get = <STDIN>);

    unless ($get =~ /\A(q|quit)\z/) {
        chomp $get;
        my $before = '';
        my $after  = '';
        my $source = '';
        my @after  = ();
        my @source = ();
        my @match  = ();

        if ($get =~ /\A"(?<before>.+)"(?<after>( +(\S+))+)/) {
        }
        elsif ($get =~ /\A(?<before>\S+)(?<after>( +(\S+))+)/) {
        }

        if ($+{before} && $+{after}) {
            $before = $+{before};
            $after  = $+{after};
            if ($after =~ /("(.+)")/) {
                push @after, $2;
                $after =~ s/$1//;
            }
            my @split = split / /, $after;
            push @after, @split;

            opendir(my $iter, $dir) or die;
            for $source (readdir $iter) {
                next if ($source =~ /^\./);
                if ($fmt eq 'file') {
                    next unless (-f $dir . '/' . $source);
                }
                elsif ($fmt eq 'dir') {
                    next unless (-d $dir . '/' . $source);
                }
                elsif ($fmt eq 'all') {
                    next unless (-e $dir . '/' . $source);
                }

                if ($source =~ /$before/) {
                    $source = $source . '/' if (-d $source);
                    for (@after) {
                        next if ($_ eq '');
                        my $new = $source;
                        $new =~ s/$before/$_/;
                        if (-e $dir . '/' . $new) {
                            say "$new is already exist.";
                        }
                        else {
                            $new = $new . '/' if (-d $new);
                            push @match,  $new;
                            push @source, $source;
                        }
                    }
                }
            }
            closedir $iter;

            if (scalar(@match) > 0) {
                say "\nfrom:";
                for (@source) {
                    say "\t$_";
                }
                say "to:";
                $tree = '';
                for (@match) {
                    $tree = $_;
                    say "\t$_";
                }

                my $command;
                $command = 'Copy' if ($arg eq 'rcopy');
                $command = 'Change' if ($arg eq 'rname');
                my $message_confirmation = "$command OK? [y/N]\n> ";

                print "\n$message_confirmation";

                my $source = '';
                chomp(my $result = <STDIN>);

                if ($result =~ /\A(y|yes)\z/) {
                    for $source (@source) {
                        next if ($source =~ /^\./);
                        if ($source =~ /$before/) {
                            for (@after) {
                                next if ($_ eq '');
                                my $new = $source;
                                $new =~ s/$before/$_/;
                                if ($fmt eq 'file') {
                                    next unless (-f $source);
                                    if ($arg eq 'rcopy') {
                                        copy($source, $new) or die $!;
                                    }
                                    elsif ($arg eq 'rname') {
                                        fmove($source, $new) or die $!;
                                    }
                                }
                                else {
                                    if ($fmt eq 'dir') {
                                        next unless (-d $source);
                                    }
                                    if ($arg eq 'rcopy') {
                                        rcopy($source, $new) or die $!;
                                    }
                                    elsif ($arg eq 'rname') {
                                        rmove($source, $new) or die $!;
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    say "Nothing changes.\n";
                    $tree = '';
                }
            }
            else {
                say "Not matched: $before\n";
                exit;
            }
        }
        else {
            say "Incorrect command.";
            exit;
        }
        result($fmt);
        exit;
    }
}
