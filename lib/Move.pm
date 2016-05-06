package Move {
    use strict;
    use warnings;
    use feature 'say';
    use File::Copy::Recursive 'rmove';

    my $dir                  = '.';
    my $tree                 = '';
    my $fmt                  = '';
    my $message_choice       = "Put the words before & after.(or [ls/q/quit])";
    my $message_confirmation = "Move it OK? [y/N]\n";

    sub init {

        print "f/d/a/q?\n>> ";
        chomp(my $init = <STDIN>);

        if ($init eq 'f') {
            $fmt = 'file';
        }
        elsif ($init eq 'd') {
            $fmt = 'dir';
        }
        elsif ($init eq 'a') {
            $fmt = 'all';
        }
        elsif ($init eq 'q') {
            say "Exit.";
            exit;
        }
        else {
            init();
        }

        current_dir($fmt);
        main();
    }

    sub current_dir {
        my $fmt = shift;
        my (@file, @dir) = ();
        my $last_dir = '';

        opendir(my $iter, $dir) or die;
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
        if ($tree =~ /([^\/]+)\//) {
            say "\t---";
            my @tree = `tree $1`;
            for (@tree) {
                print "\t$_";
            }
            $tree = '';
        }
        print "\n";
    }

    sub main {

        say $message_choice;
        chomp(my $get = <STDIN>);

        unless ($get =~ /\A(q|e|quit|exit)\z/) {
            chomp $get;
            my $before = '';
            my $after  = '';
            my $source = '';
            my @before = ();
            my @after  = ();
            my @source = ();
            my @match  = ();
            my @buffer = ();

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
                my @split  = split / /, $after;
                push @after, @split;

                for (@after) {
                    next if ($_ eq '');
                    push @buffer, $_;
                }
                if (scalar(@buffer) >= 2) {
                    unshift @buffer, $before;
                    $after  = pop @buffer;
                    @before = @buffer;
                }
                elsif (scalar(@buffer) == 1) {
                    $after = $buffer[0];
                    $before[0] = $before;
                }

                my @target;
                opendir(my $iter, $dir) or die;
                for my $source (readdir $iter) {
                    for (@before) {
                        if ($source =~ /$_/) {
                            if ($fmt eq 'file') {
                                next unless (-f $source);
                            }
                            elsif ($fmt eq 'dir') {
                                next unless (-d $source);
                            }
                            push @target, $source;
                        }
                    }
                }
                closedir $iter;

                say 'from:';
                if (scalar(@target) == 0) {
                    say "Not matched: $before\n";
                    init();
                }
                else {
                    for (@target) {
                        next if ($_ =~ /^\./);
                        if (-d $_) {
                            say "\t$_/";
                        }
                        else {
                            say "\t$_";
                        }
                    }
                }

                my @moved;
                opendir(my $iter_dir, $dir) or die;
                for my $source (readdir $iter_dir) {
                    if ($source =~ /$after/) {
                        next unless (-d $source);
                        push @moved, $source . '/';
                    }
                }
                closedir $iter_dir;
                if (scalar(@moved) == 0) {
                    push @moved, $after . '/';
                }
                my $dist = $moved[0];

                say 'to:';
                $tree = $dist;
                say "\t$dist";

                my @omit;
                for (@target) {
                    unless ("$_/" eq $dist) {
                        push @omit, $_;
                    }
                }
                @target = @omit;

                say "\n$message_confirmation";
                chomp(my $result = <STDIN>);
                if ($result =~ /\A(y|yes)\z/) {
                    opendir(my $iter, $dir) or die;
                    for $source (readdir $iter) {
                        next if ($source =~ /^\./);
                        for (@target) {
                            if ($source =~ /\A$_\z/) {
                                my $rdist = $dist;
                                if ($fmt eq 'file') {
                                    next unless (-f $source);
                                }
                                elsif ($fmt eq 'dir') {
                                    next unless (-d $source);
                                    $rdist = "$dist$source";
                                }
                                else {
                                    $rdist = "$dist$source" if (-d $dist);
                                }
                                rmove($source, $rdist) or die $!;
                                $rdist = $dist;
                            }
                            else {
                            }
                        }
                    }
                    closedir $iter;
                }
                else {
                    say "Nothing changes.\n";
                    $tree = '';
                }
            }
            else {
                say "Incorrect command.";
            }
            current_dir($fmt);
            init();
        }
        else {
            say "Exit.";
        }
    }
}

1;
