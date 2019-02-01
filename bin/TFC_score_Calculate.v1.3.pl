#!/usr/bin/perl

use warnings;
use strict;
use FindBin '$Bin';
use Cwd 'abs_path';
use Getopt::Long;
use File::Basename;
use File::Path;
use Data::Dumper;
use lib $Bin;

sub usage {
         print STDERR << "USAGE";
description: The program is used to Calculate TFC score with "AADistMatrix"
author: lyf10182\@126.com
date: 20180916
modified:
usage: perl $0 [options]
options:
        -highfile:        <str>   highfile  #
        -distdir:         <str>   
        -outdir:        <str>   outdir
        -sample:        <str>   sample name
        -help|?:    <str>       print help information

e.g.:
        perl $0 -highfile High.*.VJ.AA.xls -distdir <AAdistMatrix_Dir> -outdir <outdir> -sample <sample_name>
USAGE
         exit 1;
}

my($high_file,$dist_dir,$outdir,$sample,$help);
GetOptions(
        "highfile:s" => \$high_file,
        "distdir:s"  => \$dist_dir,
        "outdir:s" => \$outdir,
        "sample:s" => \$sample,
        "help|?" => \$help,
);

die &usage() if (!defined $high_file || !defined $dist_dir ||!defined $outdir || !defined $sample || $help);

open IN,$high_file or die $!;
my %Freq_vj=();
my %VJ=();
while(<IN>){
	chomp;
	my($vj,$aa,$freq)=split /\s+/,$_;
	$vj=~s/:/_/g;
		$VJ{$vj}{$aa}=$freq;
		$Freq_vj{$vj}+=$freq;
}
close IN;
my $outfile="$outdir/NewTCRs.$sample.Factor.Stat.xls";
open OUT,">$outfile" or die $!;
print OUT  "VJ\tFreq\tF50\tAAnum\tUniqDistNum\tEntropy\tTFC\n";
foreach my $vj(keys %VJ){
	my $dist_file="$dist_dir/$sample/$sample.$vj.AAdist.xls";
	next unless -e $dist_file;
	my %dist=();
	my %Freq_dist=();
	
	open DIST,$dist_file or die $!;
	my $head=<DIST>;
	chomp $head;
	my @AA=split /\s+/,$head;
	shift @AA;
	while(<DIST>){
		chomp;
		my @dd=split /\s+/,$_;
		my $aa=shift @dd;
		for(my $j=0;$j<=$#dd;$j++){
			$dist{$dd[$j]}++;
		}
	}
	close DIST;
	my $AAnum=$#AA+1;
	my @dist_freq=values %Freq_dist;
	my @uniq_dist_freq=();
	my $UniqDistNum=0;
	foreach my $daa(sort {$dist{$b} <=> $dist{$a}}keys %dist){
		$UniqDistNum++;
		push @uniq_dist_freq,$dist{$daa}/($AAnum*$AAnum);
	}
	next if $AAnum < 2;
	my $UniqEntropy=&Cal_Entropy(\@uniq_dist_freq);
	my $flag_D50=0;
	my $D50=0;
	my @saa=sort {$VJ{$vj}{$b} <=> $VJ{$vj}{$a}}keys %{$VJ{$vj}};
	$flag_D50=$VJ{$vj}{$saa[0]}/$Freq_vj{$vj};
	for(my $sk=1;$sk<=$#saa;$sk++){
		if($flag_D50>=0.5){
			$D50=$VJ{$vj}{$saa[$sk-1]};
			$sk=$#saa+1;
		}
		else{
			$flag_D50+=($VJ{$vj}{$saa[$sk-1]}/$Freq_vj{$vj});
				
		}
	}
	my $TCRs=(-1/(log($D50)/log(10)))/($UniqDistNum*$UniqEntropy);
	
	print OUT "$vj\t$Freq_vj{$vj}\t$D50\t$AAnum\t$UniqDistNum\t$UniqEntropy\t$TCRs\n";
}
close OUT;
print "Sample:$sample Finished!\n";

sub Cal_Entropy{
	my $arr=shift;
	my $ev=0;
	foreach my $v(@$arr){
		$ev+=log($v)*$v;
	}
	return -$ev;
}
