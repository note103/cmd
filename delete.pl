use strict;
use warnings;
use feature 'say';

my $dir = '.';
my $fmt = '';
my $home = qx(echo \$HOME | tr -d "\n");
my $trashbox = "$home/tmp_trash";

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
else {
    exit;
}
result($fmt);
main($fmt);

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
        exit;
    }
    elsif ($get =~ /\A\z/) {
        exit;
    }
    elsif ($get =~ /\A(ls)\z/) {
        result($fmt);
        main($fmt);
    }
    else {
        my $query = $1 if ($get =~ /\A(\S+)/) or die "Can't open target:$!";
        my $search;

        opendir (my $iter, $dir) or die;
        for $search (readdir $iter) {
            next if ($search =~ /^\./);
            if ($fmt eq 'file') {
                next unless (-f $dir.'/'.$search);
            }
            elsif ($fmt eq 'dir') {
                next unless (-d $dir.'/'.$search);
            }
            if ($search =~ /$query/) {
                $search = $search.'/' if (-d $search);
                say 'Matched: '.$search;
                push @$trash, $search;
            }
        }
        closedir $iter;

        if (scalar(@$trash) == 0) {
            say "Not matched: $get\n";
            exit;
        } else {
            del($trash);
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
            `mv "$_" $trashbox`;
            # system("mv $_ $trashbox") == 0 or die "system 'mv' failed: $?";
            say "Deleted successful. $_\t->\t$trashbox";
        }
    } else {
        say "Nothing changes.";
    }
}
