#!/usr/bin/perl
#

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
description: alignfile -> <transform> ->stand out file
author: lyf10182\@126.com
date: 20180411
modified:
usage: perl $0 [options]
options:
        -align:     <str>   align file     # using the software (miTCR or miXCR) to obtain the alignment result.
        -sample:    <str>   sample name
	-cutoff:    <float> frequency of VJs  # cutoff = 0.0001.
	-Vrow:	    <int>   v gene locate in vrow
	-Jrow:	    <int>   j gene locate in jrow
        -outdir:    <str>   outdir
        -help|?:    <str>   print help information

e.g.:
        perl $0 -align *.align.xls -sample <name> -outdir <outdir> -cutoff 0.0001 -Vrow 8 -Jrow 10
USAGE
         exit 1;
}
my($align,$sample,$cutoff,$vrow,$jrow,$outdir,$help);
GetOptions(
        "align:s" => \$align,
        "sample:s"  => \$sample,
        "cutoff:f" => \$cutoff,
	"Vrow:i" => \$vrow,
	"Jrow:i" => \$jrow,
        "outdir:s" => \$outdir,
        "help|?" => \$help,
);

die &usage() if (!defined $align || !defined $sample ||!defined $outdir || !defined $cutoff ||!defined $vrow || !defined $jrow || $help);

my $outfile="$outdir/$sample.align.xls";
open OUT,">$outfile" or die $!;
print OUT "count\tfreq\tcdr3nt\tcdr3aa\tv\td\tj\n";

open IN,$align or next;
my %FreqVJ=();
my %VJ=();
while(<IN>){
	chomp;
	next if /^MiTCR/ || /^Read/;
	my @d=split /\t/,$_;
	my $v_lst=$d[$vrow-1];
	my $j_lst=$d[$jrow-1];
	my $freq=$d[1];
	my $count=$d[0];
	my $aa=$d[5];
	my $cdr=$d[2];
	my $vj=();
	
	if($v_lst!~/,/ && $j_lst!~/,/){
                print OUT "$count\t$freq\t$cdr\t$aa\t$v_lst\t$v_lst\t$j_lst\n";
		$vj="$v_lst:$j_lst";
		$VJ{$vj}{$aa}+=$freq;
		$FreqVJ{$vj}+=$freq;
        }
        else{
                my @V=();
                my @J=();
                if($v_lst=~/,/ && $j_lst!~/,/){
                        $v_lst=~s/\s+//g;
                        @V=split /,/,$v_lst;
                        push @J,$j_lst;
                }
                if($j_lst=~/,/ && $v_lst!~/,/){
                        $j_lst=~s/\s+//g;
                        @J=split /,/,$j_lst;
                        push @V,$v_lst;
                }
                if($v_lst=~/,/ && $j_lst=~/,/){
                        $v_lst=~s/\s+//g;
                        @V=split /,/,$v_lst;
                        $j_lst=~s/\s+//g;
                        @J=split /,/,$j_lst;
                }
                for(my $vi=0;$vi<=$#V;$vi++){
                        for(my $ji=0;$ji<=$#J;$ji++){
                                print OUT "$count\t$freq\t$cdr\t$aa\t$V[$vi]\t$V[$vi]\t$J[$ji]\n";
				$vj="$V[$vi]:$J[$ji]";
				$VJ{$vj}{$aa}+=$freq;
				$FreqVJ{$vj}+=$freq;
                        }
                }
        }
}
close IN;
close OUT;

my $outfile2="$outdir/High.$sample.VJ.AA.xls";
open OUT2,">$outfile2" or die $!;
foreach my $vj(keys %VJ){
	if($FreqVJ{$vj} >= $cutoff){
		foreach my $aa(keys %{$VJ{$vj}}){
			print OUT2 "$vj\t$aa\t$VJ{$vj}{$aa}\n";
		}
	}
}
close OUT2;
