use strict;
use warnings;
use Data::Dumper;

my $file = $ARGV[0];
open (my $fh, '<', $file) or die ("Couldn't open the input file.");


my %target_data;
$target_data{'gene'} = {};
$target_data{'gene'}{'columns'} = [0, 3, 4, 8];
$target_data{'gene'}{'attribute'} = [];

my %attrs_list;
my %gene_biotypes;

while(my $line = <$fh>) {
	chomp $line;
	my @gff_parts = split(/\t/, $line);
	if($#gff_parts < 8) {
		next;
	}
	if($gff_parts[2] =~ /transcript/) {
		my @attrs = split(/;/, $gff_parts[8]);
		foreach my $attr (@attrs) {
			my @split = split(/=/, $attr);
			my $key = $split[0];
			my $val = $split[1];
			if(!exists $attrs_list{$key}) {
				$attrs_list{$key} = 0;
			}
			$attrs_list{$key} += 1;
			
			if($key eq 'gene_biotype') {
				if(!exists $gene_biotypes{$val}) {
					$gene_biotypes{val} = 0;
				}
				$gene_biotypes{$val} += 1;
			}
		}
	}
}

print Dumper(\%attrs_list);
print Dumper(\%gene_biotypes);