#!/usr/bin/perl -w
use strict;

die "perl $0 <fq> <out.fa_index>\n" unless(@ARGV==2);

my ($fq_f , $out) = @ARGV;

if($fq_f =~ /\.gz$/){
	open I , "gzip -dc $fq_f|" or die;
}else{
	open I , "$fq_f" or die;
}
open OUT, ">$out" or die;  # modified by huanglr on 2014.01.06: remove gunzip function to generate a unziped fasta

my %fa=();
#my $total=0;

my $flag = 0;
while(<I>)
{
	chomp;
	$flag++;
	my $id = $_;
	my $new_id = "cp$flag";
	$id = (split)[0];
	chomp(my $seq = <I>);
	my $len = length($seq);
	$fa{$seq}[1]++;
	$fa{$seq}[2]=$len;
#	print "$id\t$new_id\t$len\n";
	<I>;<I>;
#	print OUT ">$new_id\n$seq\n";
}
close I;

foreach my $tag(sort {$fa{$b}[1] <=> $fa{$a}[1]} keys %fa){
	my $percent=$fa{$tag}[1]/$flag;
	print OUT "$tag\t$fa{$tag}[2]\t$fa{$tag}[1]\t$percent\n";
}
close OUT;
