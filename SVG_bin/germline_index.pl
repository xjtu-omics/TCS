#!/usr/bin/perl
use strict;
if(@ARGV!=2){
	print "perl $0 <data_path> <sample.list>\n";
	exit;
}
my $path=shift;
my $list=shift;
open IN,"$list" or die $!;
my @l=split /\s+/,<IN>;
open OUT2,">GermLineIndex.stat";
#print <$list>;
foreach my $sample (@l){
	open IN2,"$path/$sample.data.txt" or die $!;
	open OUT,">$path/$sample.plusindex.txt";
	my $sum=0;
	my $addsum=0;
	my $count=0;
	while(<IN2>){
		chomp;
		my @str=split /\s+/,$_;
		my $index=($str[1]+$str[2]+$str[3])/(length $str[0]);
		my $addition=(length $str[0])-($str[1]+$str[2]+$str[3]);
		$sum+=$index;
		$addsum+=$addition;
		$count++;
		print OUT "$str[0]\t$str[1]\t$str[2]\t$str[3]\t$addition\t$index\n";
		}
	my $germline_index=$sum/$count;
	my $sam_addition=$addsum/$count;	
	print OUT2 "$sample\t$sam_addition\t$germline_index\n";
	close IN2;
	close OUT;
	}
	
	

