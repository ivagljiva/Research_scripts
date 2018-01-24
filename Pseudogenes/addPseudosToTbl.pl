#!/usr/bin/perl
#
# @File addPseudosToTbl.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jan 6, 2017 7:47:36 PM
#

# A script to update the .tbl file by adding in potential pseudogenes; from the (manually curated) output of
# the pseudoParser.pl script.
# Copies the original .tbl file into a new file, with pseudogenes modified
  # (removed CDS, updated base range for gene, added note, etc)
# Outputs: a new .tbl file and a log file
# Requirements:
  # First input file should be a text file containing manually curated output of pseudoParser.pl, referred to here as final.psuedos.txt
    # the final.pseudos.txt file must be in order of locus tag
    # any manual curation to the final.pseudos.txt file must have the same format as the automated output from pseudoParser.pl
    # .txt file should end with a blank line
  # Second input file should be the .tbl file of the genome you are working with
    # TBL file should have just one contig (but this script can be modified to make it handle more than one)
    # locus tag should not use the 3-character sequence "EOF", which is used below to mark 'end of file'

## Feb 2017 NOTE: previous version did not do removal of all sig-peptides for pseudogenes; I added this
## feature but have yet to test it!
## NOTE: all the pseudos' sig peptides that had to be taken out were for genes on complement strand - might be easier to parse them out based on this fact

# Warning message for people who would like to use my script
my $warn = "Warning: This script will only work for input files of a certain format.
Please check these requirements in the comments at the start of this script file.
If your input meets these requirements, please comment out this warning in the script and re-run the code.\n";
die $warn;  # COMMENT THIS OUT TO REMOVE WARNING

use strict;
use warnings;

my $usage = "perl pseudoParser.pl final.pseudos.txt genome.tbl \n";
die $usage unless (@ARGV == 2);

# note used to annotate the pseudogenes in the output .tbl file: change as necessary
my $pseudo_note = "This region contains an authentic in-frame stop or frameshift in the coding sequence which is not the result of sequencing error";

# get current time for logfile
my @time = localtime;
my $time_string = join(".", @time);

# input and output files
my $pseudoFile = shift @ARGV;
my $tblFile = shift @ARGV;
open TBL, "$tblFile" or die "Cannot open $tblFile: $!\n";
open PSEUDOS, "$pseudoFile" or die "Cannot open $pseudoFile: $!\n";
$tblFile =~ s/.tbl//;
open OUT, ">$tblFile.pseudos.tbl";
open LOG, ">$tblFile.addPseudos.$time_string.log"; #logfile for verbose output and troubleshooting

print LOG "Original .tbl file: $tblFile.tbl\nPseudogene file: $pseudoFile\nOutput .tbl file: $tblFile.pseudos.tbl\n";
print LOG "\nTimestamp: ";
print LOG join(".", @time)."\n\n";


# get locus tag information from first line of TBL file
my $TBLline1 = <TBL>;
print OUT $TBLline1;
$TBLline1 =~ m/^>Feature (\w+?)\_\w+/; # may need to change according to formatting for other genomes
my $locusTag = $1;
print "Locus tag from .tbl file: $locusTag\n"; # and copy this first line into the output file
print LOG "Locus tag from .tbl file: $locusTag\n";

# go through all pseudogene entries in the txt file
# format of one entry similar to below:
#Annotation1: SPFH domain/Band 7 family protein
#Annotation2: SPFH domain/Band 7 family protein
#ADP71_00220 (6 - 75)
#ADP71_00230 (86 - 338)
#Match: gi|516077154|ref|WP_017507737.1|
#[blank]

my @tags; # array to hold locus tags of the current pseudogene being annotated
my @annotations; # array to hold annotations of the current pseudogene
my $count = 0; # counter for number of pseudogene entries found in PSEUDOS

#priming read - first entry in PSEUDOS
@tags = &get_next_pseudo;
my $prev_pseudo_locus = "N/A"; # holds previous pseudogene locus that was parsed,so that we can detect
                               # signal peptides that belonged to the pseudogene and not copy these over
##print 'First entry in PSEUDOS has tag: '.$tags[0]."\n"; # debugging print statement

while (!($tags[0] eq "EOF"))  # while we haven't reached the end of PSEUDOS
{
    $count++;
    print LOG "Found pseudogene entry with the following info:\nLoci: ";
    print LOG join(", ", @tags);
    #print LOG "\nAnnotations: ";
    #print LOG join(", ", @annotations);
    print LOG "\n\n";

    # go through .tbl to find corresponding CDS and gene entries
    (my $loc, my $entry_lines) = &get_next_TBL; #get locus and reference to line array
    while (!($loc ~~ @tags)) # as long as the current tbl entry is not one that we need to modify
    {
        if ($loc gt $tags[0]) # this occurs if pseudogene entries are out of order
        {
            print LOG "Current pseudogene entry $tags[0] is out of order in .txt file - please correct order and try again\n";
            die "Current pseudogene entry $tags[0] is out of order in .txt file - please correct order and try again\n";
        }
        ## DOES NOT WORK YET - PLEASE UPLOAD CURRENT WORKING VERSION TO GITHUB BEFORE CHANGING
        #if ($loc eq $prev_pseudo_locus && @{$entry_lines}[0] =~ /^(\d+)\t(\d+)\tsig_peptide/)
        #{
            # skip signal peptides that come after last pseudogene entry
        #    print LOG "Skipping signal peptide found for previous pseudogene: $prev_pseudo_locus\n";
        #}
        #else {
            foreach my $line (@{$entry_lines}) # copy lines exactly to output .tbl
            {
                if ($line =~ "EOF")
                {
                 print "Reached end of .tbl file. Exiting....\n\n";
                    print LOG "Reached end of .tbl file. Exiting....\n\n";
                    exit 0;
                }
                print OUT $line;
            }
        #}
        undef(@{$entry_lines}); # clear array to prepare for next tbl entry
        ($loc, $entry_lines) = &get_next_TBL; # get next tbl entry
    }
    # now we have the first tbl entry of those that we need to modify as follows:
        # delete the CDS regions
        # combine the gene regions into one - need min and max base in range
        # add pseudogene note

    my $min_range, my $max_range, my $complement = 0, my $first_loc = $loc;
    @{$entry_lines}[0] =~ /^(\d+)\t(\d+)\t(\w+)/;
    if ($1 < $2) { $min_range = $1; $max_range = $2; }
    else { $min_range = $2; $max_range = $1; print LOG "Found gene on complement strand: $loc\n"; $complement = 1;}
    if (!($3 eq "gene")) { print LOG "A pseudo's initial tbl entry is not a gene feature, investigate: $loc\n"; die "A pseudo's initial tbl entry is not a gene feature, investigate: $loc\n"; }
    print LOG "TBL entry $loc has base range $min_range - $max_range\n";

    # get the remaining x tbl entries, according to how many tags are in the @tags array
    # there should be 2 entries (1 gene, 1 CDS) per each tag; but we already got the first gene entry
    for (my $i = 0; $i < (2*scalar(@tags)) - 1; $i++)
    {
        undef(@{$entry_lines}); # clear array to prepare for next tbl entry
        ($loc, $entry_lines) = &get_next_TBL;
        if (!($loc ~~ @tags)) # if the current tbl entry is not one that we need to modify
        {
            print "WARNING: current TBL locus ($loc) does not match one of the following pseudo tags: ".join(", ", @tags)."\n";
            print LOG "WARNING: current TBL locus ($loc) does not match one of the following pseudo tags: ".join(", ", @tags)."\n";
            foreach my $line (@{$entry_lines}) # copy lines exactly to output .tbl
            {
                if ($line =~ "EOF")
                {
                    print "Reached end of .tbl file. Exiting....\n\n";
                    print LOG "Reached end of .tbl file. Exiting....\n\n";
                    exit 0;
                }
                print OUT $line;
            }
        }
        # otherwise, it is one of the ones we need to modify
        else
        {
            @{$entry_lines}[0] =~ /^(\d+)\t(\d+)\t(\w+)/;
            # if it is a CDS, look for a product tag to get an annotation
            if ($3 eq "CDS")
            {
                foreach my $line (@{$entry_lines})
                {
                    if ($line =~ /^\t\t\tproduct\t/)
                    {
                        chomp($line);
                        my ($prod, $annotation) = split(/product\t/, $line, 2);
                        print LOG "Found annotation for $loc: $annotation\n";
                        push @annotations, $annotation;
                    }
                }
            }
        # otherwise (it is a gene feature), update the min/max base ranges
            elsif ($3 eq "gene")
            {
                if (!$complement)
                {
                    if ($1 < $min_range) { $min_range = $1;}
                    if ($2 > $max_range) { $max_range = $2;}
                }
                else
                {
                    if ($2 < $min_range) { $min_range = $2; print LOG "Complement $loc\n";}
                    if ($1 > $max_range) { $max_range = $1; print LOG "Complement $loc\n";}
                }
            }
            # otherwise, perhaps a signal peptide feature, ignore
            else
            {
                print LOG "Found $3 feature for $loc, ignoring this\n";
                $i--; # need one extra iteration of the loop to accommodate this
            }

        }
    }
    # now we should have the correct base range for all the associated locus tags
    print LOG "New base range for this pseudogene entry: $min_range - $max_range\n";

    # get a good annotation for this pseudogene
    my $pseudo_annot;
    my $index = 0;
    while (!$pseudo_annot) # while this is undefined
    {
        if (!($annotations[$index] =~ /hypothetical/))
        {
            $pseudo_annot = $annotations[$index];
        }
        else
        {
            $index++;
            if ($index >= scalar(@annotations)) # if we've run out of possible non 'hypothetical protein' annotations
            {
                $pseudo_annot = $annotations[$index - 1]; #just use the last annotation
                print "WARNING: annotating pseudo $loc as hypothetical protein - should re-annotate!\n";
                print LOG "WARNING: annotating pseudo $loc as hypothetical protein - should re-annotate!\n";
            }
        }
    }
    # if something failed and we get an undefined annotation, needs to be manually fixed:
    if (!$pseudo_annot)
    {
        $pseudo_annot = "UNDEFINED";
        print "WARNING: pseudo $loc annotated as UNDEFINED - needs manual fix!\n";
        print LOG "WARNING: pseudo $loc annotated as UNDEFINED - needs manual fix!\n";
    }

    # print only one gene entry for this pseudogene into the output .tbl
    print LOG "Printing the following pseudogene entry into the output .tbl file:\n";
    if (!$complement)
    {
        print OUT "$min_range\t$max_range\t";
        print LOG "$min_range\t$max_range\t";
    }
    else
    {
        print OUT "$max_range\t$min_range\t";
        print LOG "$max_range\t$min_range\t";
    }
    print OUT "gene\n";
    print LOG "gene\n";
    print OUT "\t\t\tlocus_tag\t$first_loc\n";
    print LOG "\t\t\tlocus_tag\t$first_loc\n";
    print OUT "\t\t\tgene_desc\t$pseudo_annot\n"; # put the annotation here
    print LOG "\t\t\tgene_desc\t$pseudo_annot\n";
    print OUT "\t\t\tnote\tPotentially non-functional; $pseudo_note\n";
    print LOG "\t\t\tnote\tPotentially non-functional; $pseudo_note\n";

    # update previous pseudogene locus
    $prev_pseudo_locus = pop @tags;

    # clear arrays to prepare for next pseudogene and tbl entries
    undef(@tags);
    undef(@annotations);
    undef(@{$entry_lines});

    # get information from next pseudo entry
    @tags = &get_next_pseudo;
}
print "\nFound $count pseudogene entries\n";
print LOG "\n\nFound $count pseudogene entries\n";

# NOW WE NEED TO COPY OVER THE REMAINDER OF THE TBL FILE
print "Finished modifying pseudogenes, now copying over remainder of original .tbl file\n";
print LOG "Finished modifying pseudogenes, now copying over remainder of original .tbl file\n";
until (eof(TBL))
{
    my $ln = <TBL>;
    print OUT "$ln";
}
print "Finished copying. New .tbl file is $tblFile.pseudos.tbl and logfile is $tblFile.addPseudos.$time_string.log\n";


# function to parse the .txt file and return the locus tags of the next group of potential pseudogenes
sub get_next_pseudo
{
    my @locus_tags; # array to get the locus tags
    if (eof(PSEUDOS))
    {
        # no more pseudo entries in file
        #print "Found EOF in PSEUDOS filehandle\n";
        print LOG "Found EOF in PSEUDOS filehandle\n";
        push @locus_tags, "EOF"; #signal to end while loop in main program
    }
    else
    {
        # first line of next entry
        my $line = <PSEUDOS>;
        chomp($line);
        while ($line =~ /\w+/) # break on chomped blank lines (between the entries)
        {
            # the annotations are giving me trouble, somehow not pushing correctly
            # so I won't use them for now
            if ($line =~ m/^Annotation[12]/)
            {
                #my ($head, $annot) = split(/: /, $line, 2); #the annotation is in the second half of the line
                #print "split $line into $head and $annot\n";
                #push @annotations, $annot;
            }
            elsif ($line =~ /^$locusTag/)
            {
                my ($tg, $range) = split(/ /, $line, 2); #split on first space to get entire locus tag in first half
                push @locus_tags, $tg;
                #print LOG "Found match to tag $locusTag in PSEUDOS: $tg\n";
            }
            else
            {
                #print "Ignoring line $line\n";
            }
            $line = <PSEUDOS>; # get next line in entry
            chomp($line) unless (!$line); # chomp unless EOF
        }

    }
    return @locus_tags;
}

# function to parse the TBL file and get next entry (ex. gene and CDS for the same locus tag)
# lines of the entry (NOT CHOMPED!) are put in an array
# and the locus tag is put in a scalar variable
# returns a list of the scalar and a reference to the array
# note that the array must be cleared before calling this function again
sub get_next_TBL
{
    my @tbl_entry; # array to hold all the lines of the tbl entry
    my $locus;     # holds the locus tag associated with this entry
    if (eof(TBL))
    {
        #print "Found EOF in TBL filehandle\n";
        print LOG "Found EOF in TBL filehandle\n";
        push @tbl_entry, "EOF"; # signal to break loop in main program
    }
    else
    {
        my $tbl_line = <TBL>; # first line of next tbl entry; format ^52\t165\tgene
        if ($tbl_line =~ /^\d+\t\d+\t\w+/)
        {
            push @tbl_entry, $tbl_line;
        }
        else
        {
            print LOG "TBL PARSING FAILED ON LINE: $tbl_line\n";
            die "TBL PARSING FAILED ON LINE: $tbl_line\n";
        }
        $tbl_line = <TBL>; # next line of that entry; format \t\t\tlocus_tag\tADP71_00010
        while ($tbl_line =~ /\t\t\t\w+\t[A-Za-z0-9(]+/) # go until we get to the first line of the next entry
        {
            if ($tbl_line =~ /locus_tag\t(\w+)/)
            {
                $locus = $1;
            }
            push @tbl_entry, $tbl_line;

            $tbl_line = <TBL>; # get next line
        }
        print LOG "Found feature in TBL file, with locus_tag=$locus\n";

        # now go back one line in the filehandle so that next time we get the first line of the next entry
        # code borrowed from http://code.izzid.com
        seek(TBL, -length($tbl_line), 1);

        return ($locus, \@tbl_entry);
    }

}

# how to change tbl entry for a pseudogene:
#20563	20820	gene
#			locus_tag	ADP71_00220
#20563	20820	CDS
#			locus_tag	ADP71_00220
#			inference	ab initio prediction:Prodigal:2.6
#			product	SPFH domain/Band 7 family protein
#			protein_id	gnl|IITBIO|ADP71_00220
#20844	21773	gene
#			locus_tag	ADP71_00230
#20844	21773	CDS
#			locus_tag	ADP71_00230
#			inference	ab initio prediction:Prodigal:2.6
#			product	SPFH domain/Band 7 family protein
#			protein_id	gnl|IITBIO|ADP71_00230
#
# should change to:
#20563  21773   gene
#           locus_tag	ADP71_00220
#           note    This region contains an authentic in-frame stop or frameshift in the coding sequence which is not the result of sequencing error; SPFH domain/Band 7 family protein; potentially non-functional
