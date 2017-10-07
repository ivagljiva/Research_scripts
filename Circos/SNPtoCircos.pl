#!/usr/bin/perl
#
# @File SNPtoCircos.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Oct 17, 2016
#
# Modified from IndelstoCircos.pl
# Takes SNP .vcf file (ie, from VarScan) and generates data for a Circos histogram mapping of SNPs/kb
# NOTE: change the window size, slide span, and genome length for each run

# Inputs:
  # first argument must be the karyotype label of the Circos chromosome to add the SNP map to
  # second argument must be the length (# of base pairs) of the chromosome
  # third argument is the .vcf file with SNPs in that chromosome
# Output: *.SNPplot.txt, a data file mapping SNP/kb to positions for a Circos plot

use strict;
use warnings;

my $usage = "perl SNPtoCircos.pl chromosomeLabel chromosomeLength SNPs.vcf\n";
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
    $genomeName =~ s/SNPs.vcf//;
    open OUT, ">$genomeName.SNPplot.txt" or die "Cannot open $genomeName.SNPplot.txt: $!\n";

    my %SNPs; #hash to store start positions of SNPs
    while (my $line = <VCF>)
    {
        chomp($line);
        next if ($line =~ /^#/); #skip comments
        #SNP line looks like: gi|482627867|gb|ARNN01000001.1|	959	.	A	G	.	PASS	ADP=1498;WT=0;HET=0;HOM=1;NC=0	GT:GQ:SDP:DP:RD:AD:FREQ:PVAL:RBQ:ABQ:RDF:RDR:ADF:ADR	1/1:255:1498:1498:0:1498:100%:0E0:0:40:0:0:856:642
        if ($line =~ /^[\w\|\.]+\s+(\d+)\s+\.\s+\w+\s+\w+\s+/)
        {
            my $start = $1; #position of SNP
            $SNPs{$start} = 1; #arbitrary value
        }
    }

    for(my $i = 0; $i <= $genomeLength-($winsize-1); $i += $slide) #for each window in the genome
    {
        my $startPosition = $i; #start of window
        my $endPosition = $startPosition + ($winsize-1); #end of window

        my $SNPCount = 0; #if winsize = 1000, this number is SNPs/Kb
        foreach($startPosition..$endPosition) #for each position in the window
        {
            if (exists $SNPs{$_}) #if a SNP is at this position, increment count
            {
                $SNPCount++;
            }
        }
        print OUT "$chromolabel\t$startPosition\t$endPosition\t$SNPCount\n";
    }

}
