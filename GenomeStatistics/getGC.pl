#!/usr/bin/perl
#
# @File getGC.pl.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Apr 15, 2017 3:05:53 PM
#
# Takes fasta files as input
# Calculates the length of each sequence, the gc content, and the numbers of A's, T's, C's, G's
# Outputs a .gc.txt file (prefixed by the fasta file prefix) containing these statistics for each sequence

use strict;
use warnings;

my $usage = "perl getGC.pl *.fasta \n";
die $usage unless (@ARGV);

while (my $inFile = shift @ARGV)
{
    open FASTA, "$inFile" or die "Cannot open $inFile: $!\n";
    $inFile =~ s/.fasta//;
    open OUT, ">$inFile.gc.txt" or die "Cannot open output file: $!\n";

    print OUT "Sequence\tLength\tGC%\t#G\t#C\t#A\t#T\n";
    print "Parsing $inFile.fasta. Output will be stored in $inFile.gc.txt\n";

    my $seqName;
    my $length = 0;
    my $gc_count = 0;
    my $g = 0;
    my $c = 0;
    my $a = 0;
    my $t = 0;

    while (<FASTA>)
    {
        chomp(my $line = $_);

        if($line =~ m/^>(\w+)/)
        {
            # header - print counts for previous sequence and start counts over for next sequence
            if (! defined $seqName) # first header, just store sequence Name
            {
                $seqName = $1;
            }
            else
            { # intermediate header
            my $gc = $gc_count / $length * 100;
            print OUT "$seqName\t$length\t$gc\t$g\t$c\t$a\t$t\n";
            $seqName = $1;
            $length = 0;
            $gc_count = 0;
            $g = 0;
            $c = 0;
            $a = 0;
            $t = 0;
            }
        }
        else
        {
            $length += length($line);
            $line = lc($line);
            foreach my $char (split //, $line)
            {
                if ($char =~ m/g/)
                {
                    $g++;
                    $gc_count++;
                }
                elsif ($char =~ m/c/)
                {
                    $c++;
                    $gc_count++;
                }
                elsif ($char =~ m/a/)
                {
                    $a++;
                }
                elsif ($char =~ m/t/)
                {
                    $t++;
                }
                else
                {
                    print "WARNING: Unrecognized character $char found\n"
                }
            }
        }

    }
    # final sequence:
    my $gc = $gc_count / $length * 100;
    print OUT "$seqName\t$length\t$gc\t$g\t$c\t$a\t$t\n";
}
