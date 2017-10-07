#!/usr/bin/perl
#
# @File getFastas.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created May 28, 2016 7:32:33 PM
#
# A script to obtain protein sequences from a genome .faa and write them to another .fasta file for BLAST (or other programs that need FASTA format)
# Takes a file with a list of specific protein headers, and pulls the corresponding sequences from the .faa file

# Inputs:
  # The first argument should be a .txt file with the FASTA headers (>) of the desired protein sequences
  # The second argument should be the genome .faa file
  # The third argument should be the desired name of the output file
# Output: a FASTA file with the specific protein sequences

use strict;
use warnings;

my $usage = "perl getFastas.pl headers.txt genome.faa outputName\n";
die $usage unless (@ARGV == 3);

my $inFile = shift @ARGV;
my $genome = shift @ARGV;
my $out = shift @ARGV;

print "Headers file: $inFile\nGenome file: $genome\nOutput file: $out.fasta\n\n";

open HEADERS, "$inFile" or die "Cannot open $inFile: $!\n";
open GENOME, "$genome" or die "Cannot open $genome: $!\n";
open OUT, ">$out.fasta" or die "Cannot open $out.fasta: $!\n";

# format of file: # before comment lines
# first column in every line is a header; ignore the rest of the line
my %headers;
# obtain the list of headers as a hash
while( <HEADERS>)
{
    chomp(my $line = $_);
    (my $header) = split(/\s+/, $line);

    unless ($header =~ /^\#/)
    {
        #print "$header\n";
        $headers{$header} = 1;  # add header to hash
    }
    else
    {
        #print "Found comment: $line\n";
    }
}
print "Starting copy from genome to output file\n";
# go through the genome and add all proteins from hash to output file
 die "Can't read first line of file: $!\n" unless (defined(my $line = <GENOME>)); #get first line of file
 until (eof GENOME)
    {
        #print "$line";
        if ($line =~ /^>(\w+) /) #check if it is a header. If it is...
        {
            #print "first word in line is: $1\n";
            if (exists $headers{$1})
            {
                #print "Found header in hash: $1\n";
                do
                {
                    print OUT $line; #print to output file
                    $line = <GENOME>; #and read next line
                    last unless (defined($line)); #exit until loop if eof
                }
                until ($line =~ /^>/); #...until next header
                #at this point $line is the next header; go to next loop
            }
            else {$line = <GENOME>;}
        }
        else #read next line and go to next loop
        {
        #print "Skipping $line";
        $line = <GENOME>;
        last unless (defined($line)); #exit until loop if eof
        }

    }
