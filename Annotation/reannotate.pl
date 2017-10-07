#!/usr/bin/perl
#
# @File reannotate.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jun 18, 2015 12:48:21 PM
#
# Used in conjunction with markChanges.pl and validChanges.pl
# The purpose of this set of scripts is to find manual curations of product names that can be automated
# ie, renaming of protein annotations to better match NCBI nomenclature guidelines

# This script (reannotate.pl):
# Takes a PROKKA products.txt file and re-annotates only those proteins that are in the validChanges.txt file
# Marks all other protein names with !! at the end of the line so that those that are not re-annotated
# can be easily found (ie, with a search function) for manual curation

# Inputs:
  # one (or more) products.txt files to be reannotated
    # if reannotating several files at once, it is a good idea to make the original products.txt filename unique
    # for instance, by adding the species/strain name to the file name
  # validChanges.txt, file of unique modifications. It must be in the same directory as input files
    # It is generated by validChanges.pl and has format:
    #original protein name\t modified protein name
    #
    #original name\t modified name
    #
# Output(s): *.reannotated.txt, file that has been reannotated (one for each input products.txt file)

use strict;
use warnings;

#suggestion - rename the products.txt file to specify the strain if reannotating several at once
my $usage = "perl reannotate.pl strain_products.txt strain_products.txt\n";
die $usage unless @ARGV;

my %changes; #key is original protein name, value is modified protein name
open VALID, "validChanges.txt" or die "Can't open validChanges.txt: $!\n";
while (<VALID>)
{
    unless(/^\n/) #if this isn't an empty line
    {
        chomp( my $line = $_);
        my @splitLine = split /\t/, $line; #separate into [0] original and [1] modified
        $changes{$splitLine[0]} = $splitLine[1]; #add to changes hash
    }
}
close VALID;

foreach (@ARGV)
{
    my $currentFile = $_;
    print "Reannotating $currentFile\n";
    open INPUT, "$currentFile" or die "Can't open $_: $!\n";
    $currentFile =~ s/\.txt//; #get rid of .txt extension
    open OUTPUT, ">$currentFile.reannotated.txt" or die "Can't create output file: $!\n";

    while (<INPUT>)
    {
        chomp(my $line = $_);
        my @splitLine = split /\t/, $line; #[0] is PROKKA_##### [1] is protein name
        my $originalName = $splitLine[1];
        if (exists $changes{$originalName}) #if this protein can be re-annotated
        {
            my $newName = $changes{$originalName};
            print OUTPUT "$splitLine[0]\t$newName\n";
        }
        else #mark for manual curation
        {
            print OUTPUT "$splitLine[0]\t$originalName  !!\n";
        }

    }
    close INPUT;
    close OUTPUT;
    print "Done reannotating ${currentFile}.txt\n";
}