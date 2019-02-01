#!/usr/bin/perl
use strict;
use warnings;
if(@ARGV!=1){
	print "perl $0 <project dir>\n";
	exit 0;
}
my $project_dir=shift;

my $bar_3d="/ifswh1/BC_PUB/biosoft/pipeline/IMMUNE/IR_pipeline/Bin_univ_201305/plot_3d_bar_using_R.13_data.R";

my $file_dir="$project_dir/Result/04.ExpProfile/";
opendir DIR,$file_dir or die $!;
my @samples=grep {!/\.$/ && !/txt$/}readdir(DIR);
closedir DIR;

#print join "\t",@samples;
#print "\n";
foreach my $sample(@samples){
#	chomp;	
	my $vj_pair="$file_dir/$sample/$sample.profile.VJ.xls";
	my $bar_3d_png="$file_dir/$sample/$sample.VJ.pair.3D";
	my $temp_out="$file_dir/$sample/out_temp";
	
	open TEMP,">$temp_out" or die $!;
	open VJ,$vj_pair or die $!;
	my $head=<VJ>;
	while(<VJ>){
		chomp;
		my($read,$freq,$type)=split /\t/,$_; # 583714  0.0550432900330846      TRBV25-1,TRBJ1-1
		
		my $count=($type=~s/,/\t/g);
#		print "$type\t$count\n";
		my @vj=split /\s+/,$type;
		if($count==1){
			print TEMP "$vj[0]\t$vj[1]\t$read\n";
		}
		elsif($count==2){
			print TEMP "$vj[0]\t$vj[2]\t$read\n";
			print TEMP "$vj[1]\t$vj[2]\t$read\n";
		}		
	}
	close VJ;
	close TEMP;
	print "VJ pair 3D plot ......\n";
	system("/opt/blc/genome/biosoft/R/bin/Rscript $bar_3d $temp_out $bar_3d_png $sample");
	system("rm $temp_out");
	print "Finished $sample\n";
}
