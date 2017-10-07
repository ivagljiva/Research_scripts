#!/usr/bin/perl
#
# @File pseudoParser.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Dec 28, 2016 1:34:22 PM
#

# Takes the output of pseudoCheck.pl (Pseudos.txt) and parses it more stringently to divide them into 3 groups:
  # those to be annotated as pseudogenes (same annotation, range of BLAST match is close together),
  # those to be double checked to determine whether they are really pseudogenes,
  # those to be rejected (unlikely to be pseudogenes; hypothetical proteins or BLAST matches are too far apart).
# Also finds their annotations from the associated genome .faa file
# produces three output files, one for each group of pseudogenes

# Warning message for people who would like to use my script
my $warn = "Warning: This script will only work for input files of a certain format.
The first input file should be the output of pseudoCheck.pl.
The second input file should be the .faa file of the genome you are working with.
If your input meets these requirements, please comment out this warning in the script and re-run the code.\n";
die $warn;  # COMMENT THIS OUT TO REMOVE WARNING

use strict;
use warnings;

my $usage = "perl pseudoParser.pl Pseudos.txt genome.faa \n";
die $usage unless (@ARGV == 2);

my $inFile = shift @ARGV;
my $faa = shift @ARGV;
my $genome = $faa;
$genome =~ s/.faa//; # obtain the name of the genome from the first part of the .faa file name

open PSEUDOS, "$inFile" or die "Cannot open $inFile: $!\n";
open FAA, "$faa" or die "Cannot open $faa: $!\n";
open LEGIT, ">$genome.legit_pseudos.txt";
open RECHECK, ">$genome.recheck_pseudos.txt";
open DISCARD, ">$genome.discarded_pseudos.txt";

# first, go through the .faa file and map all the locus tags to their associated annotations
my %annotation;
while (my $line = <FAA>)
{
    chomp $line;
    if ($line =~ /^>(\w+) /) #check if it is a header. If it is...
    {
        # split on first whitespace, which should divide the locus tag from the annotation
        my ($tag, $annot) = split(/\s/, $line, 2);
        $tag =~ s/>//; # get rid of initial >

        # for use with modified_products.txt for Vitreoscilla - to get most recent annotations
            #$tag =~ s/SAMN03858388/PROKKA/;

        #print "$line was split into $tag and $annot\n";
        $annotation{$tag} = $annot;
    }
}

# then, go through the pseudos and parse them
# file format is:
# PROKKA_00630 (6 - 521)
# PROKKA_00640 (514 - 688)
# Match: gi|503770818|ref|WP_014004894.1|
# [blank line]

# one pair of genes parsed at a time. To avoid duplicates and to find multiple matches:
my $prev1 = "N/A";
my $prev2 = "N/A"; # previous matches

while (my $line1 = <PSEUDOS>)
{
    my $line2 = <PSEUDOS>;
    my $match = <PSEUDOS>;
    <PSEUDOS>; # skip blank line in between
    chomp($line1);
    chomp($line2);
    # don't chomp match so that there is an extra space between each pair

    # parse information in the lines
    my $start1;
    my $start2;
    my $end1;
    my $end2;
    my $annot1 = "No annotation found";
    my $annot2 = "No annotation found";

    my ($locus1, $baseRange1) = split(/\s/, $line1, 2);
    my ($locus2, $baseRange2) = split(/\s/, $line2, 2);
    #print ("locus1=$locus1\nlocus2=$locus2\n");
    if ( $baseRange1 =~ /\((\d+) - (\d+)\)/)
    {
        $start1 = $1;
        $end1 = $2;
    }
    else { die "$locus1 could not be parsed\n"; }
    if ( $baseRange2 =~ /\((\d+) - (\d+)\)/)
    {
        $start2 = $1;
        $end2 = $2;
    }
    else { die "$locus2 could not be parsed\n"; }

    # get annotations from hash
    if ( exists $annotation{$locus1} ) { $annot1 = $annotation{$locus1}; }
    if ( exists $annotation{$locus2} ) { $annot2 = $annotation{$locus2}; }

    print "Sorting $locus1 and $locus2: ";

    my $threeWay = 0;
    # check for duplicates or multiple matches (ie, 3+ in a row match)
    if (($locus1 eq $prev1 && $locus2 eq $prev2) || ($locus1 eq $prev2 && $locus2 eq $prev1))
    {
        print "Duplicate\n";
        next; # duplicate
    }
    elsif (($locus1 eq $prev1 && !($locus2 eq $prev2)) || ($locus1 eq $prev2 && !($locus2 eq $prev1)) ||
          ($locus2 eq $prev1 && !($locus1 eq $prev2)) || ($locus2 eq $prev2 && !($locus1 eq $prev1)))
    {
        print "Multiple match\n"; # Warning - will mark pseudogenes pairs that are next to each other as multiple match
        $threeWay = 1;
    }
    else { print "\n"; }

    # sort the pair
    # sorting criteria (change as desired):
    my $startRange = 50; # at least one start must be within this many bases of the start of the match
    my $keepRange = 15; # the two base ranges must be within this many bases of each other to keep
    my $recheckRange = 30; # the two  base ranges must be within this many bases of each other to qualify for rechecking
    # discard if hypothetical protein

    # keep
    if ( ($start1 <= $startRange || $start2 <= $startRange) &&
         (abs($start1-$end2) <= $keepRange || abs($start2-$end1) <= $keepRange) &&
         !($annot1 =~ /hypothetical/ && $annot2 =~ /hypothetical/))
    {
        if ($threeWay) {print LEGIT "Multiple match!\n"; }
        print LEGIT "Annotation1: $annot1\nAnnotation2: $annot2\n";
        print LEGIT "$line1\n$line2\n$match\n";
    }
    # recheck this pair - actually, all multiple matches should be here because these can be valid despite not following the criteria
    elsif ( ($start1 <= $startRange || $start2 <= $startRange) &&
         (abs($start1-$end2) <= $recheckRange || abs($start2-$end1) <= $recheckRange) &&
         !($annot1 =~ /hypothetical/ && $annot2 =~ /hypothetical/))
    {
        if ($threeWay) {print RECHECK "Multiple match!\n"; }
        print RECHECK "Annotation1: $annot1\nAnnotation2: $annot2\n";
        print RECHECK "$line1\n$line2\n$match\n";
    }
    # if we didn't already catch this multiple match, put it in recheck just in case
    # these might start past the limit, or be hypothetical
    elsif ($threeWay)
    {
        print RECHECK "Multiple match!\n";
        print RECHECK "Annotation1: $annot1\nAnnotation2: $annot2\n";
        print RECHECK "$line1\n$line2\n$match\n";
    }
    # discard this pair - hypothetical or too much gap
    else
    {
        if ($threeWay) {print DISCARD "Multiple match!\n"; }
        print DISCARD "Annotation1: $annot1\nAnnotation2: $annot2\n";
        print DISCARD "$line1\n$line2\n$match\n";
    }

    # update the previous loci
    $prev1 = $locus1;
    $prev2 = $locus2;
}
