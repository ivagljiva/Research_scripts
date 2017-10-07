#!/usr/bin/perl
#
# @File validChanges.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jun 18, 2015 10:49:41 AM
#
# Used in conjunction with markChanges.pl and reannotate.pl
# The purpose of this set of scripts is to find manual curations of product names that can be automated
# ie, renaming of protein annotations to better match NCBI nomenclature guidelines

# This script (validChanges.pl):
# Intended for use on output of markChanges.pl (changes.txt)
# Finds all original protein names that have only one modification and
# Writes these original / modification pairs to the file validChanges.txt
# validChanges.txt can then be used to automatically re-annotate other product files using reannotate.pl

# Input: changes.txt file (output from markChanges.pl)
# Output: validChanges.txt, a file containing original protein names and their unique modifications
  # validChangesLog.txt, a logfile for debugging

use strict;
use warnings;

my $usage = "perl validChanges.pl changes.txt\n"; #should be used on the output of markChanges.pl
die $usage unless @ARGV == 1;

my $changeFile = $ARGV[0];
open CHANGES, "$changeFile" or die "Cannot open $changeFile: $!\n";
open LOG, ">validChangesLog.txt" or die "Cannot create log file: $!\n";

my %numChanges; #key is original name, value is number of changes
my %validChanges; #key is original name, value is modification

#first pass through file counts the number of changes per original name and adds them to %numChanges
#all those with numChanges = 1 are added to %validChanges
#second pass through file finds the original names from %validChanges and changes their values to their listed modification

print "Counting modifications per original protein name in $changeFile\n";
print LOG "Counting modifications per original protein name in $changeFile\n";
chomp(my $original = <CHANGES>); #get first original name from file
until (eof CHANGES)
{
    my $numberOfChanges = 0;
    chomp(my $nextLine = <CHANGES>);
    while ($nextLine =~ /^\t/) #lines that start with a tab are modifications
    {
        $numberOfChanges++;
        last if eof CHANGES;
        chomp($nextLine = <CHANGES>);
    }
    #next line is now next original name from file
    $numChanges{$original} = $numberOfChanges;
    $original = $nextLine;
}
close CHANGES;

print "Finding valid original names\n";
print LOG "Finding valid original names\n";
foreach my $key (sort keys %numChanges)
{
    print LOG "\t$key has $numChanges{$key} changes\n";
    if ($numChanges{$key} == 1) #if this original name has only one modification
    {
        $validChanges{$key} = 1; #add it to the hash of valid changes
        print LOG "\t\t$key has been added to valid changes hash\n" if (exists $validChanges{$key});
    }
}

print "Finding corresponding valid modifications\n";
print LOG "Finding corresponding valid modifications\n";
foreach my $key (sort keys %validChanges)
{
    print "\tFinding $key in file...\n";
    my $original = $key;
    open CHANGES, "$changeFile" or die "Cannot open $changeFile: $!\n";
    #$original =~ s!\(!\\\(!g; #escape the parentheses so they don't cause trouble when matching
    #$original =~ s!\)!\\\)!g;
    #$original =~ s!\-!\\\-!g; #escape the dashes because they're causing trouble, too
    while (<CHANGES>)
        {
            my $modification;
            my $line = $_;
            chomp($line);
            if ($line =~ /^\Q$original\E/) #find the original protein name in the file
            {
                $modification = <CHANGES>; #next line should be the only modification for this name
                $modification =~ s/^\t//; #remove leading tab
                $validChanges{$key} = $modification; #add this modification to the hash
                print "\tFound it - $key is changed to $validChanges{$key}\n";
                last;
            }

        }
    close CHANGES;
}
    print "Writing hash to file validChanges.txt...\n";
    print LOG "Writing hash to file validChanges.txt...\n";
    #write all original-modification pairs to file
    open VALID, ">validChanges.txt" or die "Can't open validChanges/txt: $!\n";
    foreach my $key (sort keys %validChanges)
    {
        print "$key\t$validChanges{$key}\n";
        print VALID "$key\t$validChanges{$key}\n";
    }
    close VALID;
