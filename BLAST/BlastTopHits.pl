#!/usr/bin/perl
#
# @File BlastTopHits.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jul 9, 2015 9:35:02 AM
#
# A script to parse BLAST output and obtain the top hit for each query protein
# Can work on multiple files, and also outputs a summary file with the number of top hits obtained from each file

# Input(s): blastp output
  # the file name format is very specific: blastp.query.db, where query is the name of the query species and db is the name of the database
# Outputs:
  # Top_Hits.txt, which contains a table of the number of top hits obtained for each input file
  # *.top_hits, the top BLAST hit for each query protein in each input file

# Warning message for people who would like to use my script
my $warn = "Warning: This script will only work for input files of a certain format.
The input files must be blastp output
The file name format must be blastp.query.db, where query is the name of the query species and db is the name of the database.
If your input meets these requirements, please comment out this warning in the script and re-run the code.\n";
die $warn;  # COMMENT THIS OUT TO REMOVE WARNING

use strict;
use warnings;

my $usage = "perl BlastTopHits.pl blastp.query.db\n";
die $usage unless @ARGV;

open TOPHITS, ">Top_Hits.txt" or die "Cannot create Top_Hits.txt: $!\n"; #tab-delimited file to store number of top hits
my %queryHash; #stores the query species so that we can keep track of which one we are working on
foreach (@ARGV)
{
    open IN, "$_" or die "Cannot open $_: $!\n";
    open OUT, ">$_.top_hits" or die "Cannot open $_.top_hits: $!\n";
    print "Processing $_\n";

    $_ =~ m/blastp\.([-\w]+)\.([-\w]+)/; #matching to obtain query species and db species names, should work with hyphens now
    my $query = $1;
    my $db = $2;

    my $topHitCount = 0;
    my %topHits; #keyed by query protein
    until (eof IN)
    {
        my $line = <IN>; #no chomping because I'll have to print it later
        my @splitLine = split /\s+/, $line;
        my $key = $splitLine[0]; #first field is query protein
        if (exists $topHits{$key})  #if this is not the top hit for the query protein
        {
            next;
        }
        else #if this is the first hit we've seen for the query protein
        {
            print OUT $line;
            $topHits{$key} = $splitLine[1]; #add protein to hash, with top hit as value
            $topHitCount++;
        }
    }
    print "Found $topHitCount top hits in $_\n";
    if (exists $queryHash{$query}) #if we are still working on the same species
    {
        print TOPHITS "\t$topHitCount";
    }
    else #we have moved on to the next query species and therefore need a new line in the TOPHITS file
    {
        print TOPHITS "\n$query\t$topHitCount"; #NOTE: if this is first query species, an extra newline will be put at beginning of file
        $queryHash{$query} = 1; #add query to hash, value arbitrary
    }
}
