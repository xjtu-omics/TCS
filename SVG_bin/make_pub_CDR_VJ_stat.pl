#!/usr/bin/perl
if(@ARGV!=3){
	print "perl $0 <dir:pro_dir> <pub_file> <bms_lst>\n";
	exit;
}

$pro_dir=shift; #dir
$pub_file=shift;
$sample_lst=shift;

my @samples=();

if(-e $sample_lst){
	open IN,$sample_lst or die $!;
	while(<IN>){
		chomp;
		push @samples,(split /\s+/,$_)[0];
	}
	close IN;
}
else{
	opendir SM,$pro_dir or die $!;
	@samples=grep {!/\.$/ && !/BGI/ && !/\.xls/ && !/txt$/ && !/stat$/ && !/\.sh.*/ && !/\.pl$/ && !/list$/ && !/^BGI/ && !/gz$/}readdir(SM);
	closedir SM;
}

#my $pub_miRNA="$out_dir/pub_miRNA.stat";

print @samples."\n";

my %CDR_data;
foreach my $sample(sort {$b cmp $a} @samples){
#	$sample=~s/\.Gene\.rpkm\.xls//;
	my $cdr_file="$pro_dir/Result/04.ExpProfile/$sample/$sample.profile.VJ.xls";
	push @head,$sample;
	print $cdr_file."\n";
	open IN,$cdr_file or die $!;
	<IN>;
	while(<IN>){
		my($exp,$freq,$cdr)=split /\s+/,$_;
		$CDR_data{$cdr}{$sample}=$freq;
	}
	close IN;
}

my $head=join "\t",(sort {$a cmp $b}@head);
my @CDR=keys %CDR_data;
#my @gene=keys %gene_data;

open OUT,">$pub_file" or die $!;
print OUT "CDR\t$head\n";

foreach my $cdr(@CDR){
#	print OUT "$miR\t";
	my $line;
	my $flag=0;
	foreach my $s(sort {$a cmp $b}@samples){		
		if(exists $CDR_data{$cdr}{$s}){
			$line.="\t$CDR_data{$cdr}{$s}";
		}
		else{
			$line.="\t0.0000000001";
			if($CDR_data{$cdr}{$s}<=1){
                                $flag++;
                        }
		}
	}
#	$flag=3;
	if($#samples+1-$flag!=0 ){
		print OUT "$cdr";
		print OUT $line."\n";
	}
}
close OUT;
