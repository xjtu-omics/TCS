#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);
use lib "/ifswh1/BC_Asia/liuyf/user/liuyf/bin";
use Plot_Log2ratio;
use Plot_Scatter_test;

#my($data, $xcol, $ycol, $xlab, $ylab, $head, $outdir, $help);
my ($data, $type, $ct, $outdir, $help);

GetOptions("data:s" => \$data, "type:s" => \$type, "ct:s" => \$ct, "outdir:s" => \$outdir, "help|?" => \$help);
$type ||= "DNA";
$outdir ||= "./";

if (!defined $data || defined $help) {
        print STDERR << "USAGE";
description: correlation statistics
usage: perl $0 [options]
options:
        -data <file> *  data file
        -type <file>    DNA/AA/VJ
	-ct   <file>    team.lst
        -outdir <file>  output dir, default is "./"

        -help|?         help information
e.g.: perl $0 -data AvsB.xls -type DNA -ct team.lst -outdir ./
USAGE
        exit 1;
}

## out_dir
mkdir $outdir unless (-d $outdir);
my $plotdir = "$outdir/DiffExp_$type/";
mkdir $plotdir unless (-d $plotdir);

## team lst
my %team=();
my %c_id=();
open CT,$ct or die $!;
my $ct_head=<CT>;
while(<CT>){
	chomp;
	my($c,$t)=split /\s+/,$_;
	my $id=$c."_vs_".$t;
	$team{$id}=$t;
	$c_id{$c}++;
}
close CT;
## read data
open IN, $data or die $!;
my (%log2ratio, %scatter);
my $header; $header = <IN>;
my @tmp_h = split /\t/, $header;
my (@s_list1, @s_list2);
for(my $i=0; $i<scalar(@tmp_h); $i++){
	if($tmp_h[$i] =~ /(\S+)_normalsize/){
		my $s = $1;
		push @s_list1, $i;
		push @s_list2, $s;
	}
}
while (<IN>){
        next if(/^#/ || /^$/);
	chomp; 
	my @a=split /\t/;
	for(my $i=0; $i<scalar(@s_list1); $i++){
		if(exists $c_id{$s_list2[$i]}){
			my $xcol = $s_list1[$i];
			for(my $j=0; $j<scalar(@s_list1); $j++){
				my $id=$s_list2[$i]."_vs_".$s_list2[$j];
				if(exists $team{$id}){
					my $ycol = $s_list1[$j];
					my $id = "$s_list2[$i]"."_vs_"."$s_list2[$j]".";$s_list1[$i]"."_vs_"."$s_list1[$j]";
					$scatter{$id}{$a[0]}=[$a[$xcol],$a[$ycol]];
				}
			}
		}
	}
}
close IN;

##plot
foreach my $key(keys %scatter){
	my @items = split /;/, $key;
	my ($xlab, $ylab) = split /_vs_/, $items[0]; my ($xcol, $ycol) = split /_vs_/, $items[1];
	my $name="$ylab\/$xlab";
	my @list = `/opt/blc/genome/biosoft/R/bin/Rscript /ifswh1/BC_PUB/biosoft/pipeline/IMMUNE/IRSEQ.v1.0/bin/Exp_dif/correlated.R $data $xcol $ycol T|cat`;
	chomp $list[0]; chomp $list[1];###### $list[0]=spearman $list[1]=pearson
	$list[0] =~ s/\[1\]//; $list[1] =~ s/\[1\]//;

	&plot_scatter(\%{$scatter{$key}},$xlab,$ylab,$list[0],$list[1],$plotdir,$type);
}

