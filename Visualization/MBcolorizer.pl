#!/usr/bin/perl
# @File MBcolorizer.pl
# @Author Iva Veseli, Illinois Institute of Technology
# November 2017
# Credit to Alexandru Orhean for the idea

# Script that takes a MrBayes .con.tre (consensus tree) file and colorizes it by species name
# This works when each name has underscores instead of spaces
# Colors all those species/strains that have the same initial name (before the first underscore) with the same color.
# Also adds some formatting to the end of the file (creates a radial tree) - not customizable by user yet
# Assumption: species are named such that text before first underscore places that species in a logical group

use strict;
use warnings;

my $usage = "perl MBcolorizer.pl *.con.tre\n";
die $usage unless @ARGV;

# some HTML colors (taken from https://www.colorcodehex.com/html-color-names.html)
# TODO: Extend to more colors
# TODO: Implement a system that lets users choose colors
my @hexColors = ('#CD5C5C','#FF0000','#DC143C','#8B0000','#FFC0CB','#FF69B4','#FF1493', '#C71585','#FF7F50','#FF8C00', '#FF8C00','#FFA500','#FFD700','#FFFF00', '#BDB76B','#E6E6FA','#D8BFD8','#DA70D6','#9370DB','#9400D3','#800080','#4B0082','#00FF00','#90EE90','#3CB371','#228B22','#008000', '#006400','#808000','#556B2F','#66CDAA','#8FBC8F','#008B8B','#008080','#00CED1', '#4682B4','#ADD8E6','#00BFFF','#1E90FF','#4169E1','#0000FF', '#000080','#191970','#FFE4C4','#F5DEB3','#DEB887','#D2B48C', '#BC8F8F','#F4A460','#DAA520','#B8860B','#8B4513', '#A52A2A','#800000','#D3D3D3', '#A9A9A9', '#808080','#708090');

while(my $treefile = shift @ARGV)
{
	my $basename = $treefile;
	$basename =~ s/.con.tre//; # remove file extension
	open IN, "<$treefile" or die "Cannot open $treefile: $!\n";
	open OUT, ">$basename.colored.tre" or die "Cannot open $basename.colored.tre for writing: $!\n";
	print "Parsing $treefile...\n";

	my %color; #hash that maps species group to color
	my $numColors = 0;	#counter for number of colors we need

	# count number of species (color) groups
	while(my $line = <IN>)
	{
		chomp $line;
		# match species names (up to first underscore) in the taxlabels section
		if($line =~ /^\t([A-Za-z0-9]+)_/)
		{
			my $speciesGroup = $1;
			if(exists $color{$speciesGroup})
			{
				next;
			}
			else
			{
				$color{$speciesGroup} = "#000000"; #set color to black by default
				$numColors++;
			}
		}
	}
	print "\t$numColors species groups found in $treefile\n";

	#choose appropriate number of (distinct) colors
	my %chosen; # hash for easy lookup of color indices that were previously chosen
	my @randColors; # array for easy assignment of chosen colors (in hex) to species groups
	my $numHexColors = scalar(@hexColors);
	for(my $i = 0; $i < $numColors; $i++)
	{
		my $rand = int(rand($numHexColors));
		while(exists $chosen{$rand}) # if we picked the same color again
		{
			$rand = int(rand($numHexColors));
		}
		# once we have a new color, add to hash/array
		$chosen{$rand} = 1; #arbitrary value
		push @randColors, $hexColors[$rand]; #hex of the color
	}

	# assign the random colors to each species group
	foreach my $key (keys %color)
	{
		$color{$key} = shift @randColors;
	}
	print "\tSelected $numColors random color groups\n";
	print "\tCopying and modifying input tree...\n";
	# copy .tre file and add color modifications to species taxlabel lines
	seek IN, 0, 0; # moves pointer back to start of file
	while(my $line = <IN>)
	{
		chomp $line;
		#add color if we match species name as above
		if($line =~ /^\t([A-Za-z0-9]+)_/)
		{
			my $speciesGroup = $1;
			my $groupColor = $color{$speciesGroup}; #hex of color
			print OUT "$line"."[&!color=$groupColor]\n";
		}
		else{ print OUT "$line\n";}
	}

	# at end of file, add figtree block (with default formatting given to a radial tree)
	# TODO: make this configurable by the user (ie, they can pick radial vs linear and add formatting)
	my $figtree = 'begin figtree;
	set appearance.backgroundColorAttribute="Default";
	set appearance.backgroundColour=#ffffff;
	set appearance.branchColorAttribute="User selection";
	set appearance.branchColorGradient=false;
	set appearance.branchLineWidth=1.0;
	set appearance.branchMinLineWidth=0.0;
	set appearance.branchWidthAttribute="Fixed";
	set appearance.foregroundColour=#000000;
	set appearance.hilightingGradient=false;
	set appearance.selectionColour=#2d3680;
	set branchLabels.colorAttribute="User selection";
	set branchLabels.displayAttribute="Branch times";
	set branchLabels.fontName="sansserif";
	set branchLabels.fontSize=8;
	set branchLabels.fontStyle=0;
	set branchLabels.isShown=false;
	set branchLabels.significantDigits=4;
	set layout.expansion=0;
	set layout.layoutType="POLAR";
	set layout.zoom=200;
	set legend.attribute="length_mean";
	set legend.fontSize=10.0;
	set legend.isShown=false;
	set legend.significantDigits=4;
	set nodeBars.barWidth=4.0;
	set nodeBars.displayAttribute="length_95%HPD";
	set nodeBars.isShown=false;
	set nodeLabels.colorAttribute="User selection";
	set nodeLabels.displayAttribute="Node ages";
	set nodeLabels.fontName="sansserif";
	set nodeLabels.fontSize=8;
	set nodeLabels.fontStyle=0;
	set nodeLabels.isShown=false;
	set nodeLabels.significantDigits=4;
	set nodeShapeExternal.colourAttribute="User selection";
	set nodeShapeExternal.isShown=false;
	set nodeShapeExternal.minSize=10.0;
	set nodeShapeExternal.scaleType=Width;
	set nodeShapeExternal.shapeType=Circle;
	set nodeShapeExternal.size=4.0;
	set nodeShapeExternal.sizeAttribute="Fixed";
	set nodeShapeInternal.colourAttribute="User selection";
	set nodeShapeInternal.isShown=false;
	set nodeShapeInternal.minSize=10.0;
	set nodeShapeInternal.scaleType=Width;
	set nodeShapeInternal.shapeType=Circle;
	set nodeShapeInternal.size=4.0;
	set nodeShapeInternal.sizeAttribute="Fixed";
	set polarLayout.alignTipLabels=true;
	set polarLayout.angularRange=0;
	set polarLayout.rootAngle=0;
	set polarLayout.rootLength=100;
	set polarLayout.showRoot=true;
	set radialLayout.spread=0.0;
	set rectilinearLayout.alignTipLabels=false;
	set rectilinearLayout.curvature=0;
	set rectilinearLayout.rootLength=100;
	set scale.offsetAge=0.0;
	set scale.rootAge=1.0;
	set scale.scaleFactor=1.0;
	set scale.scaleRoot=false;
	set scaleAxis.automaticScale=true;
	set scaleAxis.fontSize=8.0;
	set scaleAxis.isShown=false;
	set scaleAxis.lineWidth=1.0;
	set scaleAxis.majorTicks=1.0;
	set scaleAxis.minorTicks=0.5;
	set scaleAxis.origin=0.0;
	set scaleAxis.reverseAxis=false;
	set scaleAxis.showGrid=true;
	set scaleBar.automaticScale=true;
	set scaleBar.fontSize=10.0;
	set scaleBar.isShown=true;
	set scaleBar.lineWidth=1.0;
	set scaleBar.scaleRange=0.0;
	set tipLabels.colorAttribute="User selection";
	set tipLabels.displayAttribute="Names";
	set tipLabels.fontName="sansserif";
	set tipLabels.fontSize=8;
	set tipLabels.fontStyle=0;
	set tipLabels.isShown=true;
	set tipLabels.significantDigits=4;
	set trees.order=false;
	set trees.orderType="increasing";
	set trees.rooting=false;
	set trees.rootingType="User Selection";
	set trees.transform=false;
	set trees.transformType="cladogram";
end;';

	print OUT "\n$figtree\n";

	print "Colored tree can be found in $basename.colored.tre file\n\n";
}



# function to select a random key from the hash
# call it with list of keys as argument
# see http://www.perlmonks.org/?node_id=187772 for citation of this method
# TODO: make this more efficient by using a numerical value as key (then hash function + modulo to pick)
# although in this case we would lose the association of string color name with hex, so users couldn't pick colors by name (could find a way around this - two hashes?)
sub getRandKey {
	my @hashkeys = @_;
	my $randkey = $hashkeys[rand @hashkeys];
	$randkey; # return random key
}
