#!/usr/bin/perl
#
# @File lcaser.pl
# @Author Iva Veseli, Illinois Institute of Technology
# @Created Jun 9, 2015 1:44:34 PM
#
# lcaser ~= "Lowercaser"
# Prokka product names often do not follow the NCBI nomenclature rules, particularly in that many of them are uppercase
# This is a script that will take a list of the product names and change the capitals to Lowercaser for certain words
# It creates/updates two files of words that should be changed to lowercase and words that should remain uppercase (ie, acronyms like UDP)
# If it finds an unknown word, it queries the user whether or not to convert to lowercase, and thereafter saves the behavior for that word
# Thus, the more times you run it, the less manual input has to be provided to the program

# Input: a .txt file containing PROKKA product annotations for each locus tag
  # format of each line of this file is: locustag\tannotation
  # See example format below
# Outputs:
  # *.lowercase, file containing the lowercased product annotations
  # change_hash.txt, file that saves words that should be changed to lowercase
  # nonchange_hash.txt, file that saves words that should remain uppercase
  
use strict;
use warnings;

my $usage = "perl lcaser.pl products.txt\n";
#input file(s) in PROKKA product list format (e.g products.txt):
#PROKKA_00010    hypothetical protein
#PROKKA_00020    UDP-N-acetylenolpyruvoylglucosamine reductase
#... etc

die $usage unless @ARGV;

open CHANGES, "<change_hash.txt" or die "Can't open change_hash.txt: $!\n"; #file of words to be automatically changed to lowercase
#format is list of words, one per line
open NONCHANGES, "<nonchange_hash.txt" or die "Can't open nonchange_hash.txt: $!\n"; #file of words that do not need to be changed
#format is list of words, one per line

#hash of words that should be changed each time - key is word, value is arbitrary
my %changes;
while (<CHANGES>)
{
    chomp($_);
    $changes{$_} = 1;
}
#print "Changes hash contains:\n";
#while ((my $key, my $value) = each %changes)
#{
 #   print "$key";
#}
#hash of words that should stay the same - key is word, value is arbitrary
my %nonchanges;
while (<NONCHANGES>)
{
    chomp($_);
    $nonchanges{$_} = 1;
}

foreach (@ARGV)
{
    open INPUT, "$_" or die "Can't open $_: $!\n";
    open OUTPUT, ">$_.lowercase" or die "Can't create $_.lowercase: $!\n";
    open ADD_CHANGES, ">>change_hash.txt" or die "Can't write to change_hash.txt: $!\n";
    open ADD_NONCHANGES, ">>nonchange_hash.txt" or die "Can't write to nonchange_hash.txt: $!\n";

    while (<INPUT>)
    {
        my $line = $_;
        chomp($line);
        my @split_line = split /\s+/, $line; #first element is PROKKA_#####, second is first word, etc.
        my $first_word = $split_line[1];

        print "Processing $split_line[0]\n";

        if ($first_word =~ m/^[a-z1-9]/) #if it is already lowercase or starts with a number, skip
        {
            print OUTPUT "$line\n"; #print original line to output file, plus newline
        }
        elsif (exists $changes{$first_word}) #change first letter of word automatically to lowercase
        {
            $split_line[1] =~ s/(^[A-Z]?)/\L$1/;
            $line = shift(@split_line) . "\t"; #re-create format of line, with added change
            foreach (@split_line)
            {
                $line .= "$_ ";
            }
            $line =~ s/\s+$/\n/; #remove trailing whitespace, replace with newline
            print OUTPUT $line; #print original line to output file
        }
        elsif (exists $nonchanges{$first_word}) #don't change word automatically
        {
            print OUTPUT "$line\n"; #print original line to output file, plus newline
        }
        else #prompt user for decision
        {
            print "$line\nShould the first word ( $first_word ) be changed? (y)es/(n)o/e(x)it: ";
            chomp(my $decision = <STDIN>);
            if ($decision =~ m/y|yes/i)
            {
                $changes{$first_word} = 1; #add to changes hash
                print "Added $first_word to changes hash\n" if (exists $changes{$first_word});
                print ADD_CHANGES "$first_word\n"; #add to file

                #same code as before to change word and print to output (make sub eventually)
                print "Changed $split_line[1] ";
                $split_line[1] =~ s/(^[A-Z]?)/\L$1/;
                print "to $split_line[1].\n";
                $line = shift(@split_line) . "\t"; #re-create format of line, with added change
                foreach (@split_line)
                {
                    $line .= "$_ ";
                }
                $line =~ s/\s+$/\n/; #remove trailing whitespace, replace with newline
                print OUTPUT "$line"; #print original line to output file

            }
            elsif ($decision =~ m/n|no/i)
            {
                $nonchanges{$first_word} = 1; #add to nonchanges hash
                print "Added $first_word to nonchange hash\n" if (exists $nonchanges{$first_word});
                print ADD_NONCHANGES "$first_word\n"; #add to file

                print OUTPUT "$line\n"; #print original line to output file, plus newline
            }
            elsif ($decision =~ m/x|exit/i) #save all changes and exit program
            {
                close INPUT;
                close OUTPUT;
                close ADD_CHANGES;
                close ADD_NONCHANGES;
                last;
            }
            else #any other response will result in no change, nothing added to hashes/files
            {
                print "Invalid decision. No changes will be made to this line.\n";
                print OUTPUT "$line\n"; #print original line to output file, plus newline
            }
        }
    }

}

print "Detected 'exit' key or reached EOF. Exiting...\n";
