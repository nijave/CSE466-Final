#!/usr/bin/perl
use warnings;
use strict;

# These are required so Perl can find modules in parent directory
use FindBin;
use lib "$FindBin::RealBin/.."; 

use DB_Helper;
use CGI;
use HTML::Template;
use Data::Dumper;

# Create CGI object
my $cgi = new CGI;

# Load up the template
my $template = HTML::Template->new(filename => 'templates/search.tmpl', associate => $cgi);
my $errorMessage = '';

my $searchTerm = $cgi->param('searchTerm');
my $searchType = $cgi->param('searchType');

if(!defined $searchTerm || $searchType eq '') {
	$errorMessage .= 'No search information provided! Please use the search box at the top right.<br><br>';
}

my $db_table;
if( $searchType eq "RNA" ) {
	$db_table = 'rna';
}
elsif( $searchType eq "Gene" ) {
	$db_table = 'genes';
}
elsif( $searchType eq "Transcript" ) {
	$db_table = 'transcripts';
}
else {
	$errorMessage .= 'Search type must be one of RNA, Gene, Transcript. Please use the search box at the top right.<br><br>';
}

my $tableHeaders = '';
my @tableRows;
if(defined $db_table) {
	# Connect to the database
	my $dbh = DB_Helper::handle();
	my $sql = "SELECT genome.genome_build as Organism, $db_table.* FROM $db_table LEFT JOIN genome USING(filename) WHERE `id` LIKE ?";
	if($db_table eq 'genes') {
		$sql .= ' OR `name` LIKE ?';
	}
	$searchTerm = '%' . $searchTerm . '%';
	my $stm = $dbh->prepare($sql);
	$stm->bind_param(1,$searchTerm);
	if($db_table eq 'genes') {
		$stm->bind_param(2,$searchTerm);
	}
	$stm->execute();
	my @headers = @{$stm->{NAME}};
	for my $header (@headers) {
		$tableHeaders .= '<th>' . $header . '</th>';
	}
	my @rows = @{$stm->fetchall_arrayref()};
	for my $_row (@rows) {
		my @row = @$_row;
		my $line = '';
		for my $col (@row) {
			if(!defined $col) {
				$col='&nbsp;';
			}
			$line .= '<td>' . $col . '</td>';
		}
		push(@tableRows, {LINE => $line});
	}
	$dbh->disconnect;
}

if(length $errorMessage > 0) {
	$template->param(MESSAGE => $errorMessage);
}
else {
	$template->param(TABLE_HEADER => $tableHeaders);
	$template->param(TABLE_ROWS => \@tableRows);
}

# Start outputting the page
print $cgi->header;
print $template->output;