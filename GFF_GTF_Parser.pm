package GFF_GTF_Parser;

use warnings;
use strict;

# Params:
## -file_name = [filename]
## -file_type = [GFF|GTF]
## -file_src = [ENSEMBL|NCBI]
sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = bless {}, $class;
	
	# Set parameters from arguments
	foreach my $key ( keys %args ) {
		my $value = $args{$key};
		$self->{$key} = $value;
	}
	
	# Check to make sure file type is valid
	if($self->{-file_type} ne 'GFF') {
		die "File type " . $self->{-file_type} . " not supported. Only GFF is currently supported.\n";
	}
	
	# Check to make sure source is valid
	if($self->{-file_src} ne 'NCBI') {
		die "File source " . $self->{-file_src} . " not supported. Only NCBI is currently supported.\n";
	}
	
	open($self->{-input_file}, "<" . $self->{-file_name}) or die "Couldn't open input file $self->{-file_type} . Quitting\n";

	my %headers = \();
	$headers{'filename'} = $self->{-file_name};
	$headers{'file_type'} = $self->{-file_type};
	$headers{'genome_build'} = '';
	$headers{'accession'} = '';
	$headers{'url'} = '';

	my $line;

	# Loop through header lines (lines that start with #)
	while(($line = readline($self->{-input_file})) =~ /^#/ ) {
		# Remove surrounding white space
		chomp $line;
		
		if($line =~ m/#!genome-build (.*)/) {
			$headers{'genome_build'} = $1;
		}
		elsif($line =~ m/#!genome-build-accession (.*)/) {
			$headers{'accession'} = $1;
		}
		elsif($line =~ m/.*?(http.*)/) {
			$headers{'url'} = $1;
		}
	}
	
	# place the same line back onto the filehandle
	seek($self->{-input_file}, -length($line), 1);

	$self->{headers} = \%headers;
	
	return $self;
}

sub next_line {
	my $self = shift;
	my $line = readline($self->{-input_file});
	
	if(defined $line) {
		chomp $line;
		
		# Skip this line and read the next one
		if($line =~ /^#/) {
			return $self->next_line();
		}
		
		my @parts = split( /\t/, $line);
		if($#parts < 8) {
			print "\n" . $line . "\n";
		}
		my $seqid = $parts[0];
		my $type = $parts[2];
		my $start = $parts[3];
		my $end = $parts[4];
		my $strand = $parts[6];
		my @attrs = split( /;/, $parts[8]);
		my %attributes;
		
		for my $a (@attrs) {
			my @keyValue = split( /=/, $a );
			$attributes{$keyValue[0]} = $keyValue[1];
		}
		
		return ($type, $start, $end, $strand, \%attributes);
	}
	else {
		return;
	}
}
1;