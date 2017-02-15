package Delete {
    use strict;
    use warnings;
    use feature 'say';

    my $dir = '.';
    my $fmt = '';
    my $trashbox = '$HOME/tmp_trash';

    sub init {
        print "f/d/a/q?\n>> ";
        chomp(my $init = <STDIN>);

        $fmt = '';
        if ($init eq 'f') {
            $fmt = 'file'
        }
        elsif ($init eq 'd') {
            $fmt = 'dir'
        }
        elsif ($init eq 'a') {
            $fmt = 'all'
        }
        elsif ($init eq 'q') {
            say "Exit.";
            exit;
        }
        else {
            init();
        }

        result($fmt);
        main($fmt);
    }

    sub result {
        my $fmt = shift;

        my (@file, @dir) = '';
        my $last_dir = '';

        opendir (my $iter, $dir) or die;
        for (readdir $iter) {
            next if ($_ =~ /^\./);
            if (-f $dir.'/'.$_) {
                push @file, "\tfile: $_\n";
            } elsif (-d $dir.'/'.$_) {
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
    }

    sub main {
        my $trash = [];
        say '';
        say "Put the target words.(or [ls/q/quit])";
        chomp(my $get = <STDIN>);

        if ($get =~ /\A(q|quit)\z/) {
            say "Exit.";
            exit;
        }
        elsif ($get =~ /\A\z/) {
            init();
        }
        elsif ($get =~ /\A(ls)\z/) {
            result($fmt);
            main($fmt);
        }
        else {
            my ($first, $other);
            my @other = '';
            if ($get =~ /\A(\S+)(( (\S+))+)/) {
                $first = $1;
                $other = $2;
                @other = split / /, $other;
            }
            elsif ($get =~ /\A(\S+)(\s*)\z/) {
                $first = $1;
            } else {
                die "Can't open target:$!";
            }
            unshift @other, $first;

            my $search = '';
            opendir (my $iter, $dir) or die;
            my $f = sub {
                $search = shift;
                for my $target (@other) {
                    next if ($target eq '');
                    if ($search =~ /$target/) {
                        $search = $search.'/' if (-d $search);
                        say 'Matched: '.$search;
                        $search =~ s/ +/\\ /g;
                        push @$trash, $search;
                    }
                }
            };
            for $search (readdir $iter) {
                next if ($search =~ /^\./);
                if ($fmt eq 'file') {
                    next unless (-f $dir.'/'.$search);
                }
                elsif ($fmt eq 'dir') {
                    next unless (-d $dir.'/'.$search);
                }
                $f->($search);
            }
            closedir $iter;

            if (scalar(@$trash) == 0) {
                say "Not matched: $get\n";
                init();
            } else {
                del($trash, $fmt);
            }
        }
    }

    sub del {
        my $trash = shift;
        my @trash = @$trash;

        say '';
        print "Delete it OK? [y/N]\n";

        chomp(my $decision = <STDIN>);
        if ($decision =~/(y|yes)/i) {
            system("if [ ! -e $trashbox ] ; then mkdir -p $trashbox ; fi") == 0 or die "system 'mkdir' failed: $?";
            for (@trash) {
                $_ =~ s/"/\\"/g;
                system("mv $_ $trashbox") == 0 or die "system 'mv' failed: $?";
                say "Deleted successful. $_\t->\t$trashbox";
            }
        } else {
            say "Nothing changes.";
        }
        say '';
        init();
    }
}

1;
