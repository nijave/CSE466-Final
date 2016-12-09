#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

print "#################################################################\n";
print "## BIO 466 Setup File\n";
print "#################################################################\n\n";

# Check to see if gff files exist
my $cmd = `ls data/*.gff`;
my @fileList = split(/\s/, $cmd);
if($#fileList != 1) {
	die "Please put 2 GFF files in data/ directory.\n";
}

print "Found the following GFF files:\n";
for my $file (@fileList) {
	print " - $file\n";
}

my $smallSize = 0;
for my $file (@fileList) {
	my $size = `stat -c%s "$file"`;
	chomp($size);
	if($size < 500) {
		$smallSize++;
	}
}
if($smallSize > 0) {
	print "GFF files appears to be a git lfs pointer. Correct file will be downloaded.\n";
	`rm -f data/*`;
	`wget ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/vertebrate_mammalian/Erinaceus_europaeus/latest_assembly_versions/GCF_000296755.1_EriEur2.0/GCF_000296755.1_EriEur2.0_genomic.gff.gz`;
	`wget ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/vertebrate_mammalian/Echinops_telfairi/latest_assembly_versions/GCF_000313985.1_EchTel2.0/GCF_000313985.1_EchTel2.0_genomic.gff.gz`;
	`gunzip *.gz`;
	`mv *.gff data/`;
}

print "\n!!! If these are incorrect, press CTRL-C to cancel script and place the correct GFFs in data/ !!!\n\n";

# Get the name of the user running the script
my $me = `whoami`;
chomp($me);

my $host = getInput("Where is the database located?", "localhost");
my $user = getInput("What is the database username?", $me);
my $pass = getInput("What is the database password?", 'bio466');
my $db = getInput("What is the name of the database on the server?", $user);

# Check to see if the information gathered is correct
print "\nUsing the following database information:\n";
print " Host: $host\n";
print " Username: $user\n";
print " Password: $pass\n";
print " Database: $db\n\n";
my $ok = getInput("Is this information correct?", "yes");

# Die if the info is incorrect and have user try again
if(substr($ok, 0, 1) ne 'y') {
	die "Please re-run setup and enter correct information.\n";
}

# This should be the first line of the SQL file
my $sqlCreate = "CREATE DATABASE IF NOT EXISTS `$db`; USE `$db`;\n";
# Read in the SQL file
my @sql = getFile('Create_Database.sql');
my @output;
push(@output, $sqlCreate);
push(@output, @sql);
# Create a modified SQL file with correct info
putFile('_temp_CreateDatabase.sql', \@output);
print "Created temporary database file with inputted information.\n";
# Setup the database
`mysql -h $host --user=$user --password=$pass < _temp_CreateDatabase.sql`;
print "\nSetup database using mysql command.\n";
# Remove the temp file
`rm _temp_CreateDatabase.sql`;
print "Removed temporary database setup file.\n\n";

# Create database credentials file
my @creds;
push(@creds, "username=$user\n");
push(@creds, "password=$pass\n");
push(@creds, "host=$host\n");
push(@creds, "db_name=$db\n");
# Write the database credentials to the cred file
putFile('.db_creds', \@creds);
print "Wrote database credentials to .db_creds file.\n\n";

# Start GFF import
print "Starting to import GFF files into the database.\n";
print "Please standby...\n";
`perl db_import.pl $fileList[0]`;
print "  -> Imported: $fileList[0]\n";
`perl db_import.pl $fileList[1]`;
print "  -> Imported: $fileList[1]\n";
print "Files have been imported into the database!\n\n";

print "It's recommended to delete the following files used during setup:\n";
print "  - setup.pl\n";
print "  - $fileList[0]\n";
print "  - $fileList[1]\n";
print "  - Create_Database.sql\n";
print "  - GFF_GTF_Parser.pm\n";

$ok = getInput("Would you like to delete these?", "yes");
# Delete setup files
if(substr($ok, 0, 1) ne 'y') {
	`rm setup.pl $fileList[0] $fileList[1] Create_Database.sql GFF_GTF_Parser.pm`;
	print "Setup files deleted.\n";
}
else {
	print "Leaving setup files in place.\n";
}

print "\nSetup Complete!!\n\n";
print "Visit http://bio466-f15.csi.miamioh.edu/~$me/ui or the website where you set this up.\n";

sub getInput {
	my ($prompt, $default) = @_;
	
	# Ask for configuration information from the user
	print "$prompt [$default] ";
	
	# Read stdin
	my $userInput = <STDIN>;
	
	# Remove new line character
	chomp($userInput);
	
	# Set as default if they pressed enter
	if( $userInput eq '') {
		$userInput = $default;
	}
	
	return $userInput;
}

sub getFile {
	# Get filename argument
	my ($filename) = @_;
	
	# Read the file contents to array
	open(INPUT, "<$filename") or die "Couldn't open file $filename. Quitting\n";
	my @contents = <INPUT>;
	close INPUT;
	
	# Remove whitespace at ends of lines
	for(my $i = 0; $i <= $#contents; $i++) {
		chomp($contents[$i]);
	}
	
	return @contents;
}

sub putFile {
	my ($filename, $contents) = @_;
	my @lines = @$contents;
	
	# Open file for writing
	open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
	
	# Write lines
	for my $line (@lines) {
		print $fh "$line\n";
	}
	
	# Close file
	close $fh;
}