#!/usr/bin/perl

use strict;
use Data::Dumper;
use FindBin qw($Bin);

use lib "/ifs4/BC_PUB/biosoft/pipe/bc_hdh/SmallRNA/sRNA_pipeline_v1.0/lib/Plot";
#use Plot_First_base;
use Plot_INC;

if(@ARGV!=3){
	print "usage: perl Plot_Venn.pl <pub_CDR.xls> <team.lst> <outdir>\n";
	print "######## team.lst ########\nNC:     ZSK-cDNA        LYX-cDNA        ZHL-cDNA        XYH-cDNA\nP1:     ZGY-cDNA        LYF-cDNA        YZ-cDNA\nP2:     WDD-cDNA        ZYY-cDNA        ZRH-cDNA\n";
	exit;
}

my $pub_file=shift;
my $team_lst=shift; #/ifshk7/BC_HDH/PROJECT/IR/snc_F13FTSCCKF2431_HUMsncR_new/BGI_liuyf_analysis/team.lst
my $outdir=shift;

$outdir.="/" unless $outdir =~/\/$/;
mkdir $outdir unless (-e $outdir);

my %team=();
open IN,$team_lst or die $!;
while(<IN>){
	chomp;
	my @data=split /\s+/,$_;
	my $team_id=shift @data;
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
	print "$cdr_seq\t";
	foreach my $tm_id(keys %team){
	$pub_dat{$cdr_seq}{$tm_id}=$team{$tm_id}->{'num'};
		for(my $i=0;$i<=$#data;$i++){
#		$pub_dat{$cdr_seq}{$samples[$i]}=$data[$i];
		my $ss=$samples[$i];
#		foreach my $tm_id(keys %team){
#			print "$ss\t$team{$tm_id}\t iiiiiiii\n";
                        if($team{$tm_id}->{'data'}=~/$ss/){
#				print "$ss\t$team{$tm_id}\taaaaaaaaaaa\n";
				if($data[$i] == 0.01){
					$pub_dat{$cdr_seq}{$tm_id}--;
				}
#				else{
#					$pub_dat{$cdr_seq}{$tm_id}--;
#				}
                        }
#			print "ss$ss\ttt$tm_id\t$pub_dat{$cdr_seq}{$tm_id}\n";
                }
#		$pub_dat{$cdr_seq}{$tm_id}=$team{$tm_id}->{'num'};		
		print "$tm_id\t$pub_dat{$cdr_seq}{$tm_id}\t";
	}
	print "\n";
#	print "$cdr_seq\n";
}
close IN;

my $error_file="$outdir/error_data.o";
my $venn_stat_file="$outdir/venn_stat.xls";

open ERR,">$error_file" or die $!;
open STAT,">$venn_stat_file" or die $!;


my %stat=();
my %plot_dat=();
my %lable=();
my $lable_group;
my %bing_total_stat=();

#open OUT,">$outdir/non_public.o" or die $!;
foreach my $cdr_seq(keys  %pub_dat){
	my $flag=();
	my $group=();
	foreach my $tm_id(keys %{$pub_dat{$cdr_seq}}){
#		print "(exists $pub_dat{$cdr_seq}{$tm_id})\t";
		if($pub_dat{$cdr_seq}{$tm_id} >= 2 ){
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
#	my $test=0.00000001;
#	if($test ==0){		
#		print "$cdr_seq\t$flag\t$group\t!!!!!!!!\n";
#	}
	

	if($flag eq "001"){
		$stat{$group}++;
		$plot_dat{"001"}++;
		$lable{"001"}=$group;
	}
	elsif($flag eq "010"){
		$stat{$group}++;
		$plot_dat{"010"}++;
		$lable{"010"}=$group;
	}
	elsif($flag eq "100"){
                $stat{$group}++;
		$plot_dat{"100"}++;
		$lable{"100"}=$group;
        }
	elsif($flag eq "110"){
                $stat{$group}++;
		$plot_dat{"110"}++;
		
        }
	elsif($flag eq "101"){
                $stat{$group}++;
		$plot_dat{"101"}++;
        }
	elsif($flag eq "011"){
                $stat{$group}++;
		$plot_dat{"011"}++;
        }
	elsif($flag eq "111"){
                $stat{$group}++;
		$plot_dat{"111"}++;
        }
	else{
		print ERR "$cdr_seq\t$flag\t$group\n";
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

my $x3=$x1+$r/2;
my $y3=$y1+sin(2/3*3.1415)*$r;

$svg->circle('cx',$x1,'cy',$y1,'r',$r,'fill','white','stroke','red','fill-opacity',0.5,'stroke-opacity',0.8,'stroke-width',3);
$svg->circle('cx',$x2,'cy',$y2,'r',$r,'fill','white','stroke','green','fill-opacity',0.5,'stroke-opacity',0.8,'stroke-width',3);
$svg->circle('cx',$x3,'cy',$y3,'r',$r,'fill','white','stroke','blue','fill-opacity',0.5,'stroke-opacity',0.8,'stroke-width',3);

my $x_111=$x1+$r/2;
my $y_111=$y1+sin(2/3*3.1415)*$r/2;

my $x_101=$x_111;
my $y_101=$y_111-sin(2/3*3.1415)*$r;

my $x_100=$x_111-$r;
my $y_100=$y_101;

my $x_001=$x_111+$r;
my $y_001=$y_101;

my $x_110=$x1;
my $y_110=$y_111+sin(2/3*3.1415)*$r/4;

my $x_011=$x2;
my $y_011=$y_110;

my $x_010=$x_111;
my $y_010=$y_111+sin(2/3*3.1415)*$r;

$svg->text('x',$x_111,'y',$y_111,'-cdata',$plot_dat{"111"},'stroke','black','font-family','Arial','font-size',16);
$svg->text('x',$x_110,'y',$y_110,'-cdata',$plot_dat{"110"},'stroke','black','font-family','Arial','font-size',16);
$svg->text('x',$x_101,'y',$y_101,'-cdata',$plot_dat{"101"},'stroke','black','font-family','Arial','font-size',16);
$svg->text('x',$x_100,'y',$y_100,'-cdata',$plot_dat{"100"},'stroke','black','font-family','Arial','font-size',16);
$svg->text('x',$x_001,'y',$y_001,'-cdata',$plot_dat{"001"},'stroke','black','font-family','Arial','font-size',16);
$svg->text('x',$x_010,'y',$y_010,'-cdata',$plot_dat{"010"},'stroke','black','font-family','Arial','font-size',16);
$svg->text('x',$x_011,'y',$y_011,'-cdata',$plot_dat{"011"},'stroke','black','font-family','Arial','font-size',16);

my $lable_x_100=$x1-$r*3/4;
my $lable_y_100=$y1;

my $lable_x_001=$x2+$r*3/4;
my $lable_y_001=$y1;

my $lable_x_010=$x_010-10;
my $lable_y_010=$y_010+sin(2/3*3.1415)*$r/2;

$svg->text('x',$lable_x_100,'y',$lable_y_100,'-cdata',$lable{"100"},'stroke','red','fill','red','font-family','Arial','font-size',20);
$svg->text('x',$lable_x_001,'y',$lable_y_001,'-cdata',$lable{"001"},'stroke','green','fill','green','font-family','Arial','font-size',20);
$svg->text('x',$lable_x_010,'y',$lable_y_010,'-cdata',$lable{"010"},'stroke','blue','fill','blue','font-family','Arial','font-size',20);

my $out_svg=$outdir."Venn.svg";
my $out_png=$outdir."Venn.png";

open OUT, ">$out_svg" || die $!;
print OUT $svg->xmlify();
close OUT;

svg2png($out_svg,-d=>$out_png,-w=>$width,-h=>$height);
