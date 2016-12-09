#!/usr/bin/perl
use warnings;
use strict;

# These are required so Perl can find modules in parent directory
use FindBin;
use lib "$FindBin::RealBin/.."; 

use DB_Helper;
use CGI;
use HTML::Template;

# Connect to the database
my $dbh = DB_Helper::handle();
my $rowsref;
my @rows;
my $sql;

# Create CGI object
my $cgi = new CGI;

# Load up the template
my $template = HTML::Template->new(filename => 'templates/dashboard.tmpl', associate => $cgi);

# Populate the parameters
$template->param(PAGE_TITLE => 'BIO466 Gene Overview');

# Grab the organism names from the database
$sql = "SELECT genome_build FROM genome ORDER BY genome_build ASC";
$rowsref = $dbh->selectall_arrayref($sql) || die $dbh->errstr;
@rows = @{$rowsref};
$template->param(ORGANISM1 => $rows[0][0]);
$template->param(ORGANISM2 => $rows[1][0]);

# Grab gene count information from the database
$sql = <<'SQL_STATEMENT';
SELECT * FROM (
	SELECT Organism, SUM(Count) as 'Count' FROM (
		SELECT genome_build as 'Organism', 1 as 'Count' 
		FROM genes JOIN genome USING(filename) 
		GROUP BY name HAVING COUNT(DISTINCT genome_build) = 1
	) t GROUP BY Organism ORDER BY Organism ASC
) t1
UNION ALL
SELECT 'Genes in Common' as 'Type', COUNT(*) as 'Count' FROM (SELECT name FROM genes GROUP BY name HAVING COUNT(DISTINCT filename) > 1) t2;
SQL_STATEMENT
$rowsref = $dbh->selectall_arrayref($sql) || die $dbh->errstr;
@rows = @{$rowsref};
$template->param(ORGANISM1_geneBreakdown => $rows[0][1]);
$template->param(ORGANISM2_geneBreakdown => $rows[1][1]);
$template->param(INCOMMON_geneBreakdown => $rows[2][1]);

# For holding data from flattened array
my %out;
my $sortedKeys;

# Breakdown of RNA, genes, and transcripts per organism
$sql = <<'SQL_STATEMENT';
SELECT genome_build as 'Organism', 'RNA' as 'Type', COUNT(*) as 'Count' FROM rna JOIN genome USING(filename) GROUP BY genome_build
UNION ALL
SELECT genome_build as 'Organism', 'Gene' as 'Type', COUNT(*) as 'Count' FROM genes JOIN genome USING(filename) GROUP BY genome_build
UNION ALL
SELECT genome_build as 'Organism', 'Transcripts' as 'Type', COUNT(*) as 'Count' FROM transcripts JOIN genome USING(filename) GROUP BY genome_build ORDER BY Organism, Type
SQL_STATEMENT
$rowsref = $dbh->selectall_arrayref($sql) || die $dbh->errstr;
($sortedKeys, %out) = flatten($rowsref);
$template->param(ORGANISM1_DATA_BREAKDOWN_LABELS => '[' . join(',', @{$out{@$sortedKeys[0]}{labels}}) . ']');
$template->param(ORGANISM1_DATA_BREAKDOWN_DATA => '[' . join(',', @{$out{@$sortedKeys[0]}{data}}) . ']');
$template->param(ORGANISM2_DATA_BREAKDOWN_LABELS => '[' . join(',', @{$out{@$sortedKeys[1]}{labels}}) . ']');
$template->param(ORGANISM2_DATA_BREAKDOWN_DATA => '[' . join(',', @{$out{@$sortedKeys[1]}{data}}) . ']');

# Display gene biotype breakdowns
$sql = <<'SQL_STATEMENT';
SELECT genome_build as 'Organism', `type` as 'Type', COUNT(`type`) as 'Count' 
FROM genes JOIN genome USING(filename) 
GROUP BY filename, `type` 
ORDER BY Organism ASC, Count DESC;
SQL_STATEMENT
$rowsref = $dbh->selectall_arrayref($sql) || die $dbh->errstr;
($sortedKeys, %out) = flatten($rowsref);
$template->param(ORGANISM1_GENE_BREAKDOWN_LABELS => '[' . join(',', @{$out{@$sortedKeys[0]}{labels}}) . ']');
$template->param(ORGANISM1_GENE_BREAKDOWN_DATA => '[' . join(',', @{$out{@$sortedKeys[0]}{data}}) . ']');
$template->param(ORGANISM2_GENE_BREAKDOWN_DATA => '[' . join(',', @{$out{@$sortedKeys[1]}{data}}) . ']');

# Display rna type breakdowns
$sql = <<'SQL_STATEMENT';
SELECT genome_build as 'Organism', `type` as 'Type', COUNT(`type`) as 'Count' 
FROM rna JOIN genome USING(filename) 
GROUP BY filename, `type` 
ORDER BY Organism ASC, Count DESC;
SQL_STATEMENT
$rowsref = $dbh->selectall_arrayref($sql) || die $dbh->errstr;
($sortedKeys, %out) = flatten($rowsref);
$template->param(ORGANISM1_RNA_BREAKDOWN_LABELS => '[' . join(',', @{$out{@$sortedKeys[0]}{labels}}) . ']');
$template->param(ORGANISM1_RNA_BREAKDOWN_DATA => '[' . join(',', @{$out{@$sortedKeys[0]}{data}}) . ']');
$template->param(ORGANISM2_RNA_BREAKDOWN_DATA => '[' . join(',', @{$out{@$sortedKeys[1]}{data}}) . ']');

# Start outputting the page
print $cgi->header;
print $template->output;

sub flatten {
	my $arrayRef = shift;
	@rows = @{$arrayRef};
	my %out = ();
	# Turn the results into a multi-dimensional hash
	for my $_row (@rows) {
		my @row = @{$_row};
		if(!exists $out{$row[0]}{labels}) {
			$out{$row[0]}{labels} = [];
			$out{$row[0]}{data} = [];
		}
		push( @{$out{$row[0]}{labels}}, "'" . $row[1] . "'");
		push( @{$out{$row[0]}{data}}, $row[2]);
	}
	# Get the organism names in alphabetic order
	my @sortedKeys = sort keys %out;
	
	return (\@sortedKeys, %out);
}