use strict;
use warnings;
use DBI;
use CGI;
use Data::Dumper;
use DB_Helper;
use GFF_GTF_Parser;

# connect to database
my $dbh = DB_Helper::handle();

# Create a new file parser object
my $parser = GFF_GTF_Parser->new(
	-file_name => $ARGV[0],
	-file_type => 'GFF',
	-file_src => 'NCBI'
	);

my $filename = $parser->{headers}{filename};
# Get the file header-level information
my @genome_data = (
	$filename, 
	$parser->{headers}{file_type}, 
	$parser->{headers}{genome_build},
	$parser->{headers}{accession},
	$parser->{headers}{url}
);
# Insert it in to the database
my $stm = $dbh->prepare("INSERT INTO `genome` (`filename`, `file_type`, `genome_build`, `accession`, `url`) VALUES (?,?,?,?,?)");
$stm->execute(@genome_data);

my %counts;
$counts{genes} = 0;
$counts{transcripts} = 0;
$counts{rna} = 0;

while(my @data = $parser->next_line()) {	
	# Case gene
	if($data[0] eq 'gene') {
		my $stm = $dbh->prepare("INSERT INTO `genes` (`filename`, `id`, `name`, `type`, `start`, `end`, `strand`, `desc`) VALUES(?,?,?,?,?,?,?,?)");
		my @insert = (
			$filename,
			$data[4]{'ID'},
			$data[4]{'gene'},
			$data[4]{'gene_biotype'},
			$data[1],
			$data[2],
			$data[3],
			$data[4]{'desc'}
		);
		$stm->execute(@insert);
		$counts{genes}++;
	}
	# Case transcipt
	elsif($data[0] eq 'transcript') {
		my $stm = $dbh->prepare("INSERT INTO `transcripts` (`filename`, `id`, `parent`, `start`, `end`, `evidence`, `product`) VALUES(?,?,?,?,?,?,?)");
		my @insert = (
			$filename,
			$data[4]{'ID'},
			$data[4]{'Parent'},
			$data[1],
			$data[2],
			$data[4]{'model_evidence'},
			$data[4]{'product'}
		);
		$stm->execute(@insert);
		$counts{transcripts}++;
	}	
	# Case RNA
	elsif($data[0] =~ /RNA/) {
		my $stm = $dbh->prepare("INSERT INTO `rna` (`filename`, `id`, `type`, `parent`, `start`, `end`, `evidence`, `product`) VALUES(?,?,?,?,?,?,?,?)");
		my @insert = (
			$filename,
			$data[4]{'ID'},
			$data[0],
			$data[4]{'Parent'},
			$data[1],
			$data[2],
			$data[4]{'model_evidence'},
			$data[4]{'product'}
		);
		$stm->execute(@insert);
		$counts{rna}++;
	}
}

print Dumper(\%counts);

# Commit data
$dbh->commit;

# Disconnect from the database
$dbh->disconnect;