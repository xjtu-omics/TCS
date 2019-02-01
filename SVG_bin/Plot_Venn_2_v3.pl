#!/usr/bin/perl

use strict;
use Data::Dumper;
use FindBin qw($Bin);

#use lib "/ifs4/BC_PUB/biosoft/pipe/bc_hdh/SmallRNA/sRNA_pipeline_v1.0/lib/Plot";
use lib "/ifswh1/BC_PUB/biosoft/pipeline/RNA/RNA_smallRNA/RNA_smallRNA_version1.1/lib/Plot/";
use lib "/ifswh1/BC_Asia/liuyf/user/liuyf/";
#use Plot_First_base;
use Plot_INC;

if(@ARGV!=3){
	print "usage: perl Plot_Venn.pl <pub_CDR.xls> <team.lst> <outdir>\n";
	print "######## team.lst ########\nNC:     ZSK-cDNA        LYX-cDNA        ZHL-cDNA        XYH-cDNA\nP1:     ZGY-cDNA        LYF-cDNA        YZ-cDNA\n";
	exit;
}

my $pub_file=shift;
my $team_lst=shift; #/ifshk7/BC_HDH/PROJECT/IR/snc_F13FTSCCKF2431_HUMsncR_new/BGI_liuyf_analysis/team.lst
my $outdir=shift;

$outdir.="/" unless $outdir =~/\/$/;
mkdir $outdir unless (-e $outdir);
#my $samples_num=0;
my %team=();
open IN,$team_lst or die $!;
while(<IN>){
	chomp;
	my @data=split /\s+/,$_;
	my $team_id=shift @data;
#	$team{$team_id}=join "\t",@data;
#	$samples_num=$samples_num+($#data+1);
	$team{$team_id}->{'data'}=join "\t",@data;
        $team{$team_id}->{'num'}=$#data+1;
}
close IN;

my %pub_dat=();

open IN,$pub_file or die $!;
my $head=<IN>;
my @samples=split /\s+/,$head;
shift @samples;
#print join "\t",@samples;
#print "\n";
while(<IN>){
	chomp;
	my @data=split /\s+/,$_;
	my $cdr_seq=shift @data;

	foreach my $tm_id(keys %team){
		$pub_dat{$cdr_seq}{$tm_id}=$team{$tm_id}->{'num'};
		for(my $i=0;$i<=$#data;$i++){
#		$pub_dat{$cdr_seq}{$samples[$i]}=$data[$i];
			my $ss=$samples[$i];
#		foreach my $tm_id(keys %team){
#			print "$ss\t$team{$tm_id}\t iiiiiiii\n";
                        if($team{$tm_id}->{'data'}=~/$ss/){
#				print "$ss\t$team{$tm_id}\taaaaaaaaaaa\n";
				if($data[$i] == 0.000000001){
#					$pub_dat{$cdr_seq}{$tm_id}+=$samples_num;
#				}
#				else{
					$pub_dat{$cdr_seq}{$tm_id}--;
				}
                        }
#			print "ss$ss\ttt$tm_id\t$pub_dat{$cdr_seq}{$tm_id}\n";
                }
		
	}
#	print "$cdr_seq\n";
}
close IN;


my $error_file="$outdir/error_data.o";
my $venn_stat_file="$outdir/$samples[0]-VS-$samples[1]_venn_stat.xls";

open ERR,">$error_file" or die $!;
open STAT,">$venn_stat_file" or die $!;

my %stat=();
my %plot_dat=();
my %lable=();
my $lable_group;
my %bing_total_stat=();
foreach my $cdr_seq(keys  %pub_dat){
	my $flag=();
	my $group=();
	foreach my $tm_id(keys %{$pub_dat{$cdr_seq}}){
#		print "(exists $pub_dat{$cdr_seq}{$tm_id})\t";
		if($pub_dat{$cdr_seq}{$tm_id} >= 1){
			$flag.=1;
			$group.=$tm_id;
		}
#		elsif($pub_dat{$cdr_seq}{$tm_id} > 0){
		else{ 
                        $flag.=0;
			if($pub_dat{$cdr_seq}{$tm_id}>=1){
				$bing_total_stat{$tm_id}++;
			}
#			$group.=$tm_id;
                }
	}
#	print "\n";
	$group=~s/:$//;
	$group=~s/:/_VS_/g;

	if($flag eq "01"){
		$stat{$group}++;
		$plot_dat{"01"}++;
		$lable{"01"}=$group;
	}
	elsif($flag eq "10"){
		$stat{$group}++;
		$plot_dat{"10"}++;
		$lable{"10"}=$group;
	}
#	elsif($flag eq "100"){
#                $stat{$group}++;
#		$plot_dat{"100"}++;
#		$lable{"100"}=$group;
#        }
#	elsif($flag eq "110"){
#                $stat{$group}++;
#		$plot_dat{"110"}++;
#        }
#	elsif($flag eq "101"){
#                $stat{$group}++;
#		$plot_dat{"101"}++;
#        }
#	elsif($flag eq "011"){
#                $stat{$group}++;
#		$plot_dat{"011"}++;
#        }
	elsif($flag eq "11"){
                $stat{$group}++;
		$plot_dat{"11"}++;
		$lable_group=$group;
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

my $out_svg=$outdir."$samples[0]-VS-$samples[1].Venn.svg";
my $out_png=$outdir."$samples[0]-VS-$samples[1].Venn.png";

open OUT, ">$out_svg" || die $!;
print OUT $svg->xmlify();
close OUT;

svg2png($out_svg,-d=>$out_png,-w=>$width,-h=>$height);
