#!/usr/bin/perl
#
# @File GBFtoCircos.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jul 20, 2015 11:24:53 AM
#

# Takes a .gbf file and pulls out the forward-stranded/reverse-stranded genes for Circos mapping
# Modified from Yukun Sun's EMBLtoCircos.pl script

# Inputs:
	# First argument must be karyotype label of the Circos chromosome
	# Second argument must be the GBF file
	# You can change the coloring of hte forward/reverse strand genes below
# Outputs:
	# *.forward.txt file of forward strand genes only
	# *.reverse.txt file of reverse strand genes only
	# *.both.txt file of both strands (with fill-color indicated)

use strict;
use warnings;

my $usage = "perl GBFtoCircos.pl chromosomelabel genome.gbf\n";
die unless (@ARGV > 1);

my $color1 = "red"; #color of forward strand genes; change as desired
my $color2 = "blue"; #color of reverse strand genes; change as desired

my $chromoLabel = shift@ARGV; #first argument is karyotype label - see Circos tutorials

while (my $file = shift@ARGV){ #next argument is .gbf file
	open IN, "<$file";
	open FORWARD, ">$file.forward.txt"; #LABEL START END
	open REVERSE, ">$file.reverse.txt"; #LABEL START END
	open BOTH, ">$file.both.txt"; #LABEL START END COLOR
	while (my $line = <IN>){
		chomp $line;
		if ($line =~ /^\s+gene\s+(\d+)\.\.(\d+)/){ #forward strand gene
		my $start = $1;
		my $end = $2;
		print FORWARD "$chromoLabel $start $end\n";
		print BOTH "$chromoLabel $start $end fill_color=$color1\n";
		}
		elsif ($line =~ /^\s+gene\s+complement\((\d+)\.\.(\d+)/){ #reverse strand gene
		my $start = $1;
		my $end = $2;
		print REVERSE "$chromoLabel $start $end\n";
		print BOTH "$chromoLabel $start $end fill_color=$color2\n";
		}
	}
}
