#!/usr/bin/perl
use warnings;
use strict;
use CGI;

# Create CGI object
my $cgi = new CGI;

# Start outputting the page
print $cgi->redirect('introduction.pl');