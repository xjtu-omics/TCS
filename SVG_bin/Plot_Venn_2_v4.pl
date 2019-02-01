#!/usr/bin/perl

use strict;
use Data::Dumper;
use FindBin qw($Bin);

#use lib "/ifswh1/BC_PUB/biosoft/pipe/bc_hdh/SmallRNA/sRNA_pipeline_v1.0/lib/Plot";
use lib "/ifswh1/BC_PUB/biosoft/pipeline/RNA/RNA_smallRNA/RNA_smallRNA_version1.1/lib/Plot/";
#use Plot_First_base;
use Plot_INC;

if(@ARGV!=3){
	print "usage: perl Plot_Venn.pl <pub_CDR.xls> <team.lst> <outdir>\n";
	print "######## team.lst ########\nNC:     ZSK-cDNA        LYX-cDNA        ZHL-cDNA        XYH-cDNA\nP1:     ZGY-cDNA        LYF-cDNA        YZ-cDNA\n";
	exit;
}

my $pub_file=shift;
#my $sample_lst=shift; #/ifshk7/BC_HDH/PROJECT/IR/snc_F13FTSCCKF2431_HUMsncR_new/BGI_liuyf_analysis/team.lst
my $outdir=shift;

$outdir.="/" unless $outdir =~/\/$/;
mkdir $outdir unless (-e $outdir);
#my $samples_num=0;

my %pub_dat=();

open IN,$pub_file or die $!;
my $head=<IN>;
my @samples=split /\s+/,$head;
shift @samples;

my $venn_stat_file="$outdir/venn_stat.xls";
open STAT,">$venn_stat_file" or die $!;

my %stat=();
my %plot_dat=();
my %lable=();
my $lable_group;
my %bing_total_stat=();
while(<IN>){
	my $flag=();
	chomp;
	my @a=split /\s+/,$_;
	my $cdr_seq=shift @a;
	for(my $i=0;$i<=$#a;$i++){
		if($a[0]!= 0.000000001){
			$flag.=1;
		}
		else{ 
                        $flag.=0;
                }
	}

	if($flag eq "01"){
		$stat{$samples[1]}++;
		$plot_dat{"01"}++;
		$lable{"01"}=$samples[1];
	}
	elsif($flag eq "10"){
		$stat{$samples[0]}++;
		$plot_dat{"10"}++;
		$lable{"10"}=$samples[0];
	}
	elsif($flag eq "11"){
                $stat{"$samples[0]-VS-$samples[1]"}++;
		$plot_dat{"11"}++;
		$lable_group="$samples[0]-VS-$samples[1]";
        }
	else{
		print ERR "$cdr_seq\t$flag\t$group\t:data error!\n";
	}
}

foreach my $gg(keys %stat){
	print STAT "$gg:\t$stat{$gg}\n";
}
foreach my $gs(keys %bing_total_stat){
	print STAT "$gs:\t$bing_total_stat{$gs}\n";
}
close ERR;
close STAT;

if($lable{"01"} eq "" && $lable{"10"} eq ""){
	my($t,$s)=split /_VS_/,$lable_group;
	$lable{"01"}=$s;
	$lable{"10"}=$t;
	$plot_dat{"01"}=0;
	$plot_dat{"10"}=0;
}

######### SVG ########

my $width=710;
my $height=690;

my $svg=SVG->new('width'=>$width,'height'=>$height);
$svg->rect(
                'style'=>{stroke=>'white', fill=>'white'},
                x=>0, y=>0,
                width=>$width, height=>$height,
                rx=>0, ry=>0,
);

my $r=200;

my $left_w=50;
#my $righ_w=100;
my $up_h=50;
#my $down_h=50;

my $x1=$left_w+$r;
my $y1=$up_h+$r;

my $x2=$x1+$r;
my $y2=$y1;

#my $x3=$x1+$r/2;
#my $y3=$y1+sin(2/3*3.1415)*$r;

$svg->circle('cx',$x1,'cy',$y1,'r',$r,'fill','white','stroke','red','fill-opacity',0.5,'stroke-opacity',0.8,'stroke-width',3);
$svg->circle('cx',$x2,'cy',$y2,'r',$r,'fill','white','stroke','green','fill-opacity',0.5,'stroke-opacity',0.8,'stroke-width',3);
#$svg->circle('cx',$x3,'cy',$y3,'r',$r,'fill','white','stroke','blue','fill-opacity',0.5,'stroke-opacity',0.8,'stroke-width',3);

my $x_11=$x1+$r/2;
my $y_11=$y1;

my $x_01=$x2+$r/2;
my $y_01=$y2;

my $x_10=$x1-$r/2;
my $y_10=$y1;

$svg->text('x',$x_11,'y',$y_11,'-cdata',$plot_dat{"11"},'stroke','black','font-family','Arial','font-size',16);
$svg->text('x',$x_10,'y',$y_10,'-cdata',$plot_dat{"10"},'stroke','black','font-family','Arial','font-size',16);
$svg->text('x',$x_01,'y',$y_01,'-cdata',$plot_dat{"01"},'stroke','black','font-family','Arial','font-size',16);
#$svg->text('x',$x_100,'y',$y_100,'-cdata',$plot_dat{"100"},'stroke','black','font-family','Arial','font-size',16);
#$svg->text('x',$x_001,'y',$y_001,'-cdata',$plot_dat{"001"},'stroke','black','font-family','Arial','font-size',16);
#$svg->text('x',$x_010,'y',$y_010,'-cdata',$plot_dat{"010"},'stroke','black','font-family','Arial','font-size',16);
#$svg->text('x',$x_011,'y',$y_011,'-cdata',$plot_dat{"011"},'stroke','black','font-family','Arial','font-size',16);

my $lable_x_10=$x1-$r/2;
my $lable_y_10=$y1+$r*4/5;

my $lable_x_01=$x2;
my $lable_y_01=$y1+$r*4/5;

$svg->text('x',$lable_x_10,'y',$lable_y_10,'-cdata',$lable{"10"},'stroke','red','fill','red','font-family','Arial','font-size',20);
$svg->text('x',$lable_x_01,'y',$lable_y_01,'-cdata',$lable{"01"},'stroke','green','fill','green','font-family','Arial','font-size',20);
#$svg->text('x',$lable_x_010,'y',$lable_y_010,'-cdata',$lable{"010"},'stroke','blue','fill','blue','font-family','Arial','font-size',20);

my $out_svg=$outdir."Venn.svg";
my $out_png=$outdir."Venn.png";

open OUT, ">$out_svg" || die $!;
print OUT $svg->xmlify();
close OUT;

svg2png($out_svg,-d=>$out_png,-w=>$width,-h=>$height);
