#!/usr/bin/perl
#
# @File markChanges.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jun 17, 2015 6:13:25 PM
#
# Used in conjunction with validChanges.pl and reannotate.pl
# The purpose of this set of scripts is to find manual curations of product names that can be automated
# ie, renaming of protein annotations to better match NCBI nomenclature guidelines

# This script (markChanges.pl):
# Compares original products.txt with the manually curated products_modified.txt
# Generates a file (changes.txt) that summarizes all the modifications made to the former
  # If there is only one kind of modification to a protein name, this change can automatically applied to other products.txt files
  # The output of this program can be used with validChanges.pl to find this unique modifications
  # Format of output changes.txt should be:
            #original protein name
            #\t modified protein name
            #\t modified protein name
            #original protein name
            #\t modified protein name
            #etc...

# Inputs:
  # First argument must be the original products.txt file (ie, original product names from annotation using PROKKA)
  # Second argument must be the manually curated products.txt file (ie, with changes to product names to be compliant with NCBI nomenclature guidelines)
  # format of each line in both of these files: locustag\tproduct annotation
# Outputs: changes.txt, file containing the original product name and each modification made to it in the manually curated products.txt
  # markChanges_log.txt, a logfile for debugging

use strict;
use warnings;

my $usage = "perl markChanges.pl originalFile.txt modifiedFile.txt\n"; #original and modified both in PROKKA products.txt format
#this should be run on the lowercased original file (use lcaser.pl), or it should be case insensitive
die $usage unless @ARGV == 2;

open ORIGINAL, "$ARGV[0]" or die "Can't open $ARGV[0]: $!\n";
open MODIFIED, "$ARGV[1]" or die "Can't open $ARGV[1]: $!\n";
open LOG, ">markChanges_log.txt" or die "Can't open log: $!\n";

my %changedLines; #hash of changes that have already been added to change file
print LOG "Reading from files...\n";
print "Reading from files...\n";

do
{
    chomp(my $originalLine = <ORIGINAL>); #format: PROKKA_00010    hypothetical protein
    chomp(my $modifiedLine = <MODIFIED>);
    my @splitOrig;
    my @splitMod;
    if ($originalLine =~ /\t/)
    {
        @splitOrig = split /\t/, $originalLine; #if it is tab separated
    }
    else
    {
        @splitOrig = split /\s{4}/, $originalLine; #if it is separated by 4 spaces
    }
    my $original = $splitOrig[1]; #obtain only the protein name from the line for comparison
    if ($modifiedLine =~ /\t/)
    {
        @splitMod = split /\t/, $modifiedLine;
    }
    else
    {
        @splitMod = split /\s{4}/, $modifiedLine;
    }
    my $modified = $splitMod[1];

    print "Processing $splitOrig[0]\n";
    print LOG "Comparing $original with $modified\n";

    #if these two lines are not the same
    unless (lc $original eq lc $modified) #case insenstive comparison
    {
        print LOG "They are different\n";
         if (exists $changedLines{$original}) #if we have already seen this protein name changed
         {
            print LOG "$original has been changed before\n";
            &update_change($original, $modified); #find it in the file and add a new modification if necessary
         }
         else #this is the first time we have seen this protein name changed
         {
            print LOG "$original has not been changed before\n";
            #add to hash
            $changedLines{$original} = 1;
            #add to changes file
            open CHANGES, ">>changes.txt" or die "Can't open changes.txt for appending: $!\n";
            print CHANGES "$original\n\t$modified\n";
            print LOG "Added $original to hash and changes.txt\n";
         }
    }
    else #the original line was not modified
    {
        print LOG "They are the same\n";
        #what if the name is changed only sometimes?
        #NOTE: this does not handle names that are not changed until the very last instance
        if (exists $changedLines{$original}) #if this line was previously changed
        {
            print LOG "But $original has been changed before\n";
            #add $modified anyway to changes.txt so that we know it isn't always changed
            &update_change($original, $modified);
        }
    }
    }
    until (eof ORIGINAL and eof MODIFIED);
    print LOG "All done! Exiting...\n";
    print "All done! Exiting...\n";
    #the original lines that have more than one modification listed in changes.txt should not be used to automatically
    #re-annotate the other files
    #validChanges.pl will read changes.txt and pull out the ones with only one modification


    #subroutine that checks the changes.txt file to see if the current modification is in there, and if not, adds it
    sub update_change #pass arguments ($original, $modified)
    {
        print LOG "Updating change file\n";
        my $original = $_[0];
        my $modified = $_[1];
        #print "Original is $original and modified is $modified\n";
        $original =~ s!\(!\\\(!g; #escape the parentheses so they don't cause trouble when matching
        $original =~ s!\)!\\\)!g;
        $original =~ s!\-!\\\-!g; #escape the dashes because they're causing trouble, too
        open CHANGES, "changes.txt" or die "Can't open changes.txt for reading: $!\n";
            while (<CHANGES>)
            {
                my $line = $_;
                chomp($line);
                if ($line =~ /^\Q$original\E/) #find the original protein name in the file; \Q and \E should cause literal matching
                {
                    print LOG "Found original name in file\n";
                    #check its block of modified names for $modified (go until next line does not begin with \t)
                    chomp (my $nextline = <CHANGES>);
                    my $inFile = "false";
                    my$numChanges = 0; #count how many lines down a new modification must be added
                    while ($nextline =~ /^\t.*/)
                    {
                        $numChanges++;
                        #print "next line is $nextline\n";
                        if ($nextline =~ /^\t$modified/) #this change is already in the file
                        {
                            print LOG "$modified is an already-recorded change for this name.\n";
                            $inFile = "true";
                            last; #so we can skip it
                        }
                        $nextline = <CHANGES>;
                    }

                    #print "$original has $numChanges changes listed\n";
                    if ($inFile eq "false") #we need to add this change to the file
                    {
                        open CHANGES, "changes.txt" or die "Can't re-open changes.txt: $!\n";
                        open TMP, ">changes.txt.tmp" or die "Can't open changes.txt.tmp : $!\n";
                        while (<CHANGES>)
                        {
                            my $line = $_;
                            print TMP "$line"; #copy line-by-line to temp file
                            chomp($line);
                            if ($line =~ /^$original/) #find the original protein name in the file
                            {
                                my $nextChange;
                                for (my $i = 0; $i < $numChanges; $i++)
                                {
                                    $nextChange = <CHANGES>;
                                    print TMP "$nextChange";
                                }
                                #now at end of change block
                                print LOG "adding $modified\n";
                                print TMP "\t$modified\n";
                                $inFile = "true";
                            }
                            #finish copying line-by-line to temp file after adding modification
                        }
                        close CHANGES;
                        close TMP;
                        unlink "changes.txt"; #remove old version
                        rename "changes.txt.tmp", "changes.txt"; #change name of modified version
                    }
                    last if ($inFile eq "true");
                }
            }
        }
