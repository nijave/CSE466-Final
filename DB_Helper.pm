#!/usr/bin/perl
#################################################################
# Provides a database handle using connection stored
# in a config file
#
# By: Nick Venenga
# Date: 9 December 2016
#################################################################

package DB_Helper;

use DBI;

sub handle {
	# Read the database configuration information from the config file
	open(INPUT, "<.db_creds") or die "Couldn't open database credentials file. Quitting\n";
	my @contents = <INPUT>;
	close INPUT;
	my %data;
	for my $line (@contents) {
		chomp($line);
		my @parts = split(/=/, $line);
		$data{$parts[0]} = $parts[1];
	}
	
	# Create friendly references to db info
	my $user = $data{username};
	my $password = $data{password};
	my $host = $data{host};
	my $db = $data{db_name};
	my $driver = "mysql";
	# connect to database
	my $dsn = "DBI:$driver:database=$db;host=$host";
	my $dbh = DBI->connect($dsn, $user, $password, {
	   PrintError       => 1,
	   RaiseError       => 0,
	   AutoCommit       => 0,
	   FetchHashKeyName => 'NAME_lc',
	}) or die("Couldn't connect to database.\n");
	
	# Return handle
	return $dbh;
}
1;