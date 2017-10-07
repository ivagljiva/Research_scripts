#!/usr/bin/perl
#
# @File BLASTsplitter.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created May 26, 2015 1:40:36 PM
#
# A script to parse BLAST output (outfmt 6) for all matches with a bit score higher than some minimum value

# Input(s): BLAST output file with outfmt 6
  # Change the minimum bit score as desired
# Output(s):  File with the BLAST matches of > min bit score

# Warning message for people who would like to use my script
my $warn = "Warning: This script will only work for input files of a certain format.
The input files must be BLAST output with outfmt 6.
If your input meets these requirements, please comment out this warning in the script and re-run the code.
You may also want to change the minimum bit score, which is currently set to 5000.\n";
die $warn;  # COMMENT THIS OUT TO REMOVE WARNING

use strict;
use warnings;

my $usage = "perl BLASTsplitter.pl *.txt\n";
die $usage unless @ARGV;

#threshold value for last column (bit score)
my $MIN = 5000; # change as desired

#input files given as argument (BLAST file - outfmt 6)
foreach (@ARGV)
{
    open IN, "$_";
    open OUTPUT, ">$_.out";

    my %matches;
    while (<IN>)
    {
        my @columns = split /\s+/, $_;
        my $key = $columns[0] . $columns[1];
        unless (exists $matches{$key})
        {
            $matches{$key} = $_; #put entire line into hash if it's not already in there
            print OUTPUT $_ if ($columns[11] >= $MIN); #prints line to output file if 12th column value greater than threshold
        }
    }
}
