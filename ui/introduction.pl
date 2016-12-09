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
my $template = HTML::Template->new(filename => 'templates/introduction.tmpl', associate => $cgi);

# Start outputting the page
print $cgi->header;
print $template->output;