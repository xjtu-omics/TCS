#!/usr/bin/perl
use strict;
if(@ARGV!=2){
	print "perl $0 <pro_dir> <bms_lst>\n";
	exit;
}
my $pro_dir=shift;
my $list=shift;
open IN,"$list" or die $!;
my @l=();
while(<IN>){
	chomp;
	push @l,(split /\s+/,$_)[0];
}
close IN;
my $out_dir="$pro_dir/Result/09.D50AndGermline/Germline/";
`mkdir -p $out_dir` unless(-d $out_dir);

open OUT2,">$out_dir/GermLineIndex.stat";
print OUT2 "Smaple\tAverage_insert\tGermline_index\n";
#print <$list>;
foreach my $sample (@l){
	open IN,"$pro_dir/Result/02.Alignment/$sample/$sample.align.xls" or die $!;
	open OUT,">$out_dir/$sample.plusindex.txt";
	print OUT "CDR3\tV_Length\tD_Length\tJ_length\tInsert\tIndex\n";
	my $sum=0;
	my $addsum=0;
	my $count=0;
#	my $head=<IN>;
	while(<IN>){
		chomp;
		next if /^MiTCR/;
		next if /^Read/;
		my @str=split /\t/,$_;
		my $length=length($str[2]);
		my $v=$str[12];
		my $d=$str[14]-$str[13]+1;
		my $j=$length-$str[15]+1;
		my $index=($v+$d+$j)/$length;
		my $addition=$length-($v+$d+$j);
		$sum+=$index;
		$addsum+=$addition;
		$count++;
		print OUT "$str[2]\t$v\t$d\t$j\t$addition\t$index\n";
	}
	my $germline_index=$sum/$count;
	my $sam_addition=$addsum/$count;	
	print OUT2 "$sample\t$sam_addition\t$germline_index\n";
	close IN;
	close OUT;
}
close OUT2;	
	

