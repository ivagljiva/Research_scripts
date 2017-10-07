#!/usr/bin/perl
#
# @File pseudoCheck.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created May 31, 2016 3:18:33 PM
#
# This script looks for potential psuedogenes by checking for adjacent genes that have a BLAST match to the same gene

# Parses BLAST output (outfmt 6) of potential pseudogenes against the NCBI database
# Compares them in pairs (if they are subsequent CDS):
# If they have the same match in the database, they could be pseudogenes
# If their coverage of this match is close, ie one covers the first part of the match and the other
# covers the second part, they are likely pseudogenes
  # pseudoParser.pl script will sort the output of this script to determine which are more likely to be real pseudogenes

# Warning message for people who would like to use my script
my $warn = "Warning: This script will only work for an input file of a certain format.
The input file should be a blastp output, using outfmt 6.
If your input meets this requirement, please comment out this warning in the script and re-run the code.\n";
die $warn;  # COMMENT THIS OUT TO REMOVE WARNING

use strict;
use warnings;

my $usage = "perl pseudoCheck.pl blastp.query.txt \n";
die $usage unless (@ARGV == 1);

my $inFile = shift @ARGV;
# the following line is commented out to remove dependency on specific input file name format
#my $blastq = $inFile; $blastq =~ s/blast.\.//; $blastq =~ s/\.\w+//; # get name of query genome from input file name

my %query1;
my %query2;

open IN, "$inFile" or die "Cannot open $inFile: $!\n";
my $outfileName = "Pseudos.txt";
open OUT, ">$outfileName" or die "Cannot open $outfileName: $!\n";
#open OUT, ">$blastq.pseudos.txt" or die "Cannot open $blastq.pseudos.txt: $!\n"; # commented out to remove dependency on specific input file name format

# priming reads - add matches of first protein to hash 1
chomp(my $line = <IN>);
my @fields = split(/\s+/, $line);
my $prev_query = $fields[0];
print "Processing $prev_query\n";
&add(1, $fields[1], $line);

chomp($line = <IN>);
@fields = split(/\s+/, $line);
my $query = $fields[0];
while ($query eq $prev_query)
{
    &add(1, $fields[1], $line);
    chomp($line = <IN>);
    @fields = split(/\s+/, $line);
    $query = $fields[0];
}
# at this point, $line holds the first match with a new protein query
print "Changed $prev_query to ";
$prev_query = $query;
print "$prev_query\n";
my $next_hash = 2; # the next hash to add to

until (eof(IN))
{
    #add the protein matches to the next hash until we reach a new protein query
    print "Processing $prev_query\n";
    while ($query eq $prev_query)
    {
        &add($next_hash, $fields[1], $line);
        if (eof(IN)) { print "Found EOF\n"; last;} # break out of this reading loop if EOF
        chomp($line = <IN>);
        @fields = split(/\s+/, $line);
        $query = $fields[0];
    }
    # at this point, $line holds the first match with a new protein query
    # compare the two hashes
    &compare_hashes;

    #update $prev_query and $next_hash for next loop; clear next hash for re-use
    $prev_query = $query;
    if ($next_hash == 2)
    {
        $next_hash = 1;
        undef %query1;
        #print "Cleared query 1\n";
    }
    else
    {
        $next_hash = 2;
        undef %query2;
        #print "Cleared query 2\n";
    }
}


sub add
{
    # parameters: hash# (1 or 2), key, value
    if ($_[0] == 1) # add to hash1
    {
        $query1{$_[1]} = $_[2];
    }
    elsif ($_[0] == 2) # add to hash2
    {
        $query2{$_[1]} = $_[2];
    }
    else
    {
        die "Fatal error: hash #$_[0] does not exist\n";
    }
    #print "Added match $_[1] to query $_[0]\n";
}

sub compare_hashes
{
    # compare hashes to determine whether or not the genes have hits against the same protein
    # and whether or not they collectively make up a pseudogene
    my $count = 0; # used to limit number of potential pseudogenes added to output file - change limit below as necessary
    while (((my $match, my $val) = each %query1) && ($count < 2))
    {

        if (exists $query2{$match})
        {
            my @subj1 = split(/\s+/, $val);           # each value is the BLAST outfmt 6 line for a hit
            my @subj2 = split(/\s+/, $query2{$match});# split this output on the tabs
            #query subject &id ? ? ? qstart qend sstart send eval ?
            my $quer1 = $subj1[0];
            my $quer2 = $subj2[0];
            my $start1 = $subj1[8];
            my $start2 = $subj2[8];
            my $end1 = $subj1[9];
            my $end2 = $subj2[9];

            if (($start2 - $end1 <= 30) || ($start1 - $end2 <= 30))
            {
                print "Pseudogenes: $quer1 ($start1 - $end1), $quer2 ($start2 - $end2) => match with $match\n";
                print OUT "$quer1 ($start1 - $end1)\n$quer2 ($start2 - $end2)\nMatch: $match\n\n";
                $count++;
            }
            else
            {
                print "\tNot pseudogenes: $quer1 ($start1 - $end1), $quer2 ($start2 - $end2) => match with $match\n";
            }
        }
#        else
#        {
#            print "\t\tNo match found in query2 for $match in query1\n";
#        }
    }
    print "$count potential pseudogene matches found for this query\n";
}
