#!/usr/bin/perl
#
# @File Pcounts.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jul 23, 2015 1:58:07 PM
#
# Pcounts ~= "Protein counts"
# Given .fasta file of a genome, counts total # proteins
# Also counts # proteins of two minimum sizes (change sizes as desired in code below)
# This results in three categories of proteins:
  # all proteins
  # proteins greater than some size A
  # proteins greater than some size B
# Within each category, counts the number of proteins that have putative functions (at least one GO in interproscan)

# Input file Requirements:
  # .fasta file(s) for some genome(s)
  # Interproscan output file(s) for each genome must be located in the same directory
    # ie, *.ipr.tsv files
    # These output files must be named with same prefix as the associated .fasta file

# Output file: Pcounts.txt

# Warning message for people who would like to use my script
my $warn = "Warning: This script will only work for input files of a certain format.
Please check these requirements in the comments at the start of this script file.
If your input meets these requirements, please comment out this warning in the script and re-run the code.
You may also want to change the size categories before running\n";
die $warn;  # COMMENT THIS OUT TO REMOVE WARNING

use strict;
use warnings;

my $usage = "perl Pcounts.pl *.fasta\n";
die $usage unless @ARGV;

#change these sizes as needed
my $size1 = 200; #find all proteins greater than 200 AAs long
my $size2 = 100; #find all proteins greater than 100 AAs long

open RESULTS, ">Pcounts.txt" or die "Cannot open Pcounts.txt: $!\n";    #overall output file
print RESULTS "Genome\t\tTotal Proteins\tpFunc(total)\t>$size1\tpFunc($size1)\t>$size2\tpFunc($size2)\n\n";

while (my $file = shift @ARGV)
{
    open IN, "<$file" or die "Cannot open $file: $!\n";
    open TSV, "<$file.ipr.tsv" or die "Cannot open $file.ipr.tsv: $!\n";

    my $genome = $file;
    $genome =~ s/.fasta//;
    my $totProt = 0;    #total number of proteins in genome
    my $totFunc = 0;    #total proteins with pFunc (putative function)
    my $size1Prot = 0;  #number of proteins greater than specified size1
    my $size1Func = 0;  #number of proteins greater than specified size1 with pFunc
    my $size2Prot = 0;  #number of proteins greater than specified size2
    my $size2Func = 0;  #number of proteins greater than specified size2 with pFunc

    #first read the .ipr.tsv file and generate hash of all proteins with putative functions
    my %pFuncs;
    print "Reading .tsv file to find pFunc proteins\n";
    while (<TSV>)
    {
        chomp(my $line = $_);
        my @splitLine = split /\t/, $line; #.tsv files are tab-delimited, first field is locus tag
        my $iprlocus = $splitLine[0];
        unless (exists $pFuncs{$iprlocus}) #if this protein isn't already in the hash, put it in
        {
            $pFuncs{$iprlocus} = 1; #arbitrary value
            print "Added pFunc protein $iprlocus to hash\n";
        }
    }

    #then go through the .fasta file and count the proteins
    chomp(my $line = <IN>); #read first line
    until (eof IN)
    {
        my $locus;
        my $length = 0;
        my $func = 0;

        #the .fasta headers either start with >gi or >lcl -> must find locus appropriately
        if ($line =~ m/^>gi\|\d+\|\w+\|([\w.]+)\|/)
        {
            $locus = $1;
        }
        elsif ($line =~ m/^>lcl\|([\w.]+)\s/) #>lcl|CP007446.1_prot_SALWKB2_0002_2 [protein=hypothetical]
        {
            $locus = "lcl|$1";
        }
        elsif ($line =~ m/^>(PROKKA_\d+)\s/) #>PROKKA_00000 hypothetical
        {
            $locus = $1;
        }
        else
        {
            print "An error occurred while reading headers: unable to find locus tag\n";
        }

        print "Found protein with locus $locus, incrementing total proteins\n";
        $totProt++;

        if (exists $pFuncs{$locus})
        {
            print "This protein has a function, incrementing pFuncs(total)\n";
            $func = 1;
            $totFunc++;
        }

        do #every protein has at least one line of AAs
        {
            chomp($line = <IN>);
            unless ($line =~ m/^>/)
            {
                $length += length($line); #add the number of characters in this line to the protein's length unless header
                print "length of protein is now $length\n";
            }
        }
        until ($line =~ m/^>/ || eof IN); #until we find the next header or reach eof
        #$line is now next header (or last line of file)


        print "This protein has length= $length AAs\n";

        if ($length >= $size1)
        {
            print "Length is greater than or equal to $size1, incrementing appropriate count\n";
            $size1Prot++;
            if ($func == 1)
            {
                print "Also incrementing pFuncs($size1)\n";
                $size1Func++;
            }
        }
        if ($length >= $size2)
        {
            print "Length is greater than or equal to $size2, incrementing appropriate count\n";
            $size2Prot++;
            if ($func == 1)
            {
                print "Also incrementing pFuncs($size2)\n";
                $size2Func++;
            }
        }
        #$line is still next header (or last line of file)
    }
    print "Reached end of .fasta file for $genome, writing results\n";
    print RESULTS "$genome\t\t$totProt\t\t$totFunc\t\t$size1Prot\t\t$size1Func\t\t$size2Prot\t\t$size2Func\n";

}
