#!/usr/bin/perl
#
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jul 20, 2015 11:59:52 AM
#
# A script to highlight certain genes on a chromosome (ie, genes that are shared with some other organism, potential virulence factors, etc)
# given a .txt file of the locus tags of these genes (and the .gbf of the genome/chromosome)
# The .gbf file is used to obtain the start/end locations of the gene at each locus tag.
 # These locations are printed to a file for use in making Circos <highlights>.

 # Inputs:
  # First argument must be karyotype label of the Circos chromosome plot
  # Second argument must be .gbf file
  # Third argument must be .txt file with locus tags to highlights
# Output: *.highlights.txt, file with positions to highlight on Circos chromosome plot

use strict;
use warnings;

my $usage = "perl CircosHighlights.pl chromosomelabel genome.gbf locustags.txt\n";
die "Not enough arguments\n$usage" unless (@ARGV == 3);

my $chromoLabel = $ARGV[0]; #first argument is karyotype label - see Circos tutorials
my $color = "vit5"; #color of highlight - change for each plot

my $GBFfile = $ARGV[1]; #second argument is .gbf
my $file = $ARGV[2]; #third argument is .txt with locus tags

    open GBF, "$GBFfile" or die "Cannot open $GBFfile: $!\n";
    open IN, "$file" or die "Cannot open $file: $!\n";
    $file =~ s/.txt//;
    open OUT, ">$file.highlights.txt" or die "Cannot open $file.highlights.txt: $!\n";

    #read locus tags into hash
    my %locustags;
    print "\n Adding locus tags from file into hash\n";
    while (<IN>)
    {
        chomp (my $locus = $_);
        $locustags{$locus} = 1; #arbitrary value
    }

    #go through .gbf and obtain locations
    while (my $line = <GBF>)
    {
        chomp $line;
        my $start;
        my $end;
        my $tag;

        if ($line =~ /^\s+gene\s+(\d+)\.\.(\d+)/)
        {
            $start = $1;
            $end = $2;
            my $nextLine;
            do {$nextLine = <GBF>;} until ($nextLine =~ m/\s+\/locus_tag="(\w+)"/);
            $tag = $1;
        }
        elsif ($line =~ /^\s+gene\s+complement\((\d+)\.\.(\d+)/)
        {
            $start = $1;
            $end = $2;
            my $nextLine;
            do {$nextLine = <GBF>;} until ($nextLine =~ m/\s+\/locus_tag="(\w+)"/);
            $tag = $1;
        }

        if (exists $locustags{$tag})
        {
            print OUT "$chromoLabel $start $end fill_color=$color\n";
            print "$chromoLabel $start $end fill_color=$color\n";
        }
    }
