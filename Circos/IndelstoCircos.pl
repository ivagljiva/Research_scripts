#!/usr/bin/perl
#
# @File IndelstoCircos.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jul 22, 2015 11:04:39 AM
#

# Takes an indel .vcf file (ie, from VarScan) and creates a Circos data file for an Indels/kb histogram
# NOTE: change the window size, slide span, and genome length for each run

# Inputs:
  # first argument must be the karyotype label of the Circos chromosome to add the indel map to
  # second argument must be the length (# of base pairs) of the chromosome
  # third argument is the .vcf file with indels in that chromosome
# Output: *.indelplot.txt, a data file mapping indel/kb to positions for a Circos plot

use strict;
use warnings;

my $usage = "perl IndelstoCircos.pl chromosomelabel chromosomeLength indels.vcf\n";
die $usage unless (@ARGV >= 3);

my $chromolabel = shift @ARGV;
my $genomeLength = shift @ARGV;
$genomeLength = int($genomeLength);
my $winsize = 1000;	## replace with the width of the sliding windows
my $slide = 1000;	## replace with the slide span you want

while (my $file = shift @ARGV)
{
    open VCF, "$file" or die "Cannot open $file: $!\n";
    my $genomeName = $file;
    $genomeName =~ s/.vcf//;
    open OUT, ">$genomeName.indelplot.txt" or die "Cannot open $genomeName.indelplot.txt: $!\n";

    my %indels; #hash to store start positions of indels
    while (my $line = <VCF>)
    {
        chomp($line);
        next if ($line =~ /^#/); #skip comments
        #INDEL line looks like: consensus.fasta|quiver	2717	.	A	AAC	.	PASS	ADP=409;WT=0;HET=1;HOM=0;NC=0	GT:GQ:SDP:DP:RD:AD:FREQ:PVAL:RBQ:ABQ:RDF:RDR:ADF:ADR	0/1:255:413:409:205:205:49.76%:1.7809E-77:34:22:31:174:97:108
        if ($line =~ /^[\w\|\.]+\s+(\d+)\s+\.\s+\w+\s+\w+\s+/)
        {
            my $start = $1; #start position of indel
            $indels{$start} = 1; #arbitrary value
        }
    }

    for(my $i = 0; $i <= $genomeLength-($winsize-1); $i += $slide) #for each window in the genome
    {
        my $startPosition = $i; #start of window
        my $endPosition = $startPosition + ($winsize-1); #end of window

        my $indelCount = 0; #if winsize = 1000, this number is indels/Kb
        foreach($startPosition..$endPosition) #for each position in the window
        {
            if (exists $indels{$_}) #if an indel starts at this position, increment count
            {
                $indelCount++;
            }
        }
        print OUT "$chromolabel\t$startPosition\t$endPosition\t$indelCount\n";
    }

}
