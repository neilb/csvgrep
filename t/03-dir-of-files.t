#!perl

use strict;
use warnings;

use Test::More tests => 3;

use File::Temp;
use FindBin qw($RealBin);
use Capture::Tiny ':all';
use File::Spec;
use Time::Local;

my $tempdir = File::Temp->newdir();
my $dirname = $tempdir->dirname;

{
    my $stderr = capture_stderr { do_csvgrep() };
    my $expected_output =<<"EOD";
no .csv files found in $dirname
EOD

    is($stderr, $expected_output, "Die with empty directory");
}

{
    create_newest_file();
    my $stdout = capture_stdout { do_csvgrep() };
    my $expected_output =<<'EOD';
+-------------------+-----------------+-------+------+
| Book              | Author          | Pages | Date |
+-------------------+-----------------+-------+------+
| Norwegian Wood    | Haruki Murakami | 400   | 1987 |
| Men without Women | Haruki Murakami | 228   | 2017 |
+-------------------+-----------------+-------+------+
EOD

    is($stdout, $expected_output, "Grep in dir with one file");
}

{
    create_newest_file();
    create_oldest_file();
    my $stdout = capture_stdout { do_csvgrep() };
    my $expected_output =<<'EOD';
+-------------------+-----------------+-------+------+
| Book              | Author          | Pages | Date |
+-------------------+-----------------+-------+------+
| Norwegian Wood    | Haruki Murakami | 400   | 1987 |
| Men without Women | Haruki Murakami | 228   | 2017 |
+-------------------+-----------------+-------+------+
EOD

    is($stdout, $expected_output, "Grep in dir with multiple file");
}

sub create_newest_file {
    my @newest_file_data = split /^/, <<'EOT';
Book,Author,Pages,Date
Norwegian Wood,Haruki Murakami,400,1987
Men without Women,Haruki Murakami,228,2017
A Walk in the Woods,Bill Bryson,276,1997
Death Walks the Woods,Cyril Hare,222,1954
Mary Poppins,PL Travers,208,1934
Frankenstein,Mary Shelley,280,1818
EOT

    my $newest_fname = File::Spec->catfile($dirname, "newest.csv");
    open my $fh, ">", $newest_fname or die "Can't open $newest_fname for input: $!";
    foreach (@newest_file_data) {
        print $fh $_;
    }
    close $fh;

    # set the mtime explicitly
    my $newest_time = timelocal(0, 57, 21, 30, 10, 2021);
    utime $newest_time, $newest_time, $newest_fname;
}

sub create_oldest_file {
    my @oldest_file_data = split /^/, <<'EOT';
Book,Author,Pages,Date
Kafka on the Shore,Haruki Murakami,505,2002
A Wild Sheep Chase,Haruki Murakami,299,1989
Notes from a Small Island,Bill Bryson,351,1996
The Last Man,Mary Shelley,479,1826
EOT

    my $oldest_fname = File::Spec->catfile($dirname, "oldest.csv");
    open my $fh, ">", $oldest_fname or die "Can't open $oldest_fname for input: $!";
    foreach (@oldest_file_data) {
        print $fh $_;
    }
    close $fh;

    # set the mtime explicitly
    my $oldest_time = timelocal(0, 5, 20, 30, 9, 2021);
    utime $oldest_time, $oldest_time, $oldest_fname;
}

sub do_csvgrep {
    system("perl $RealBin/../bin/csvgrep -d $dirname Murakami")
}

__DATA__

