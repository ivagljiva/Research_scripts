#!/usr/bin/perl
#
# @File hypotheticals.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jul 7, 2015 10:11:38 PM
#

# A script to find all of the hypothetical proteins in a .faa file
# These proteins can be verified whether they are hypothetical or not

# Input(s): .faa files
# Output(s): *.hypotheticals files containing a list of hypothetical proteins found in each input file

use strict;
use warnings;

my $usage = "perl hypotheticals.pl *.faa\n";
die $usage unless @ARGV;

foreach (@ARGV)
{
    open IN, "$_" or die "Can't open $_: $!\n";
    my $basename = $_;
    $basename =~ s/\.faa//;
    open OUT, ">$basename.hypotheticals" or die "Can't create $basename.hypotheticals: $!\n";

    my $count = 0;
    print "Reading $_ and searching for hypotheticals.\n";

    die "Can't read first line of file: $!\n" unless (defined(my $line = <IN>)); #get first line of file
    until (eof IN)
    {
        if ($line =~ /^>.* hypothetical protein/) #check if it is a hypothetical protein. If it is...
        {
            print "Found hypothetical protein.\n";
            $count++;
            do
            {
                print OUT $line; #print to output file
                $line = <IN>; #and read next line
                last unless (defined($line)); #exit until loop if eof
            }
            until ($line =~ /^>/); #...until next header
            #at this point $line is the next header; go to next loop

        }
        else #read next line and go to next loop
        {
           $line = <IN>;
           last unless (defined($line)); #exit until loop if eof
        }
    }
    print "\nFound $count hypotheticals.\n";
}
