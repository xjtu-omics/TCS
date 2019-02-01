#!/usr/bin/perl

use strict;
use warnings;
use Math::Trig;
use constant PI => 4 * atan2(1,1);
use FindBin '$Bin';
use lib "$Bin/../SVG_bin";
use SVG;
use Plot_INC;

my $indir=shift;
my $tsne_dir=shift;
my $Stand_dir=shift;
my $sample_list=shift;
my $svg_dir=shift;
my $Max_freq=shift;
#my $cor_lst=shift;

mkdir $svg_dir unless -e $svg_dir;

open IN,$sample_list or die $!;
my @samples=();
while(<IN>){
	chomp;
	next if /^Old/;
	next if /^LW/;
	my($old,$new,$type,undef)=split /\s+/,$_;
	push @samples,$new;
}
close IN;

for(my $i=0;$i<=$#samples;$i++){

my $sub_svg_dir="$svg_dir/$samples[$i]";
mkdir $sub_svg_dir unless -e $sub_svg_dir;
my $sample=$samples[$i];
my @VJ=();
my %vjlist=();
my %AA=();
my %AA_num=();
my $Top_AA=();
my $Top_Freq=0;
my $vj_file="$tsne_dir/$sample/Top50.$sample.VJ.xls";
open IN,$vj_file or die $!;
while(<IN>){
	next if /^VJ/;
	chomp;
	my @dd=split /\s+/,$_;
#	if($dd[1]>=0.0001){
		#push @VJ,$dd[0];
		$vjlist{$dd[0]}+=$dd[-1];
		$AA{$dd[0]}{$dd[1]}=$dd[-1];
        $AA_num{$dd[0]}++;
        if($Top_Freq<=$dd[-1]){
                $Top_Freq=$dd[-1];
                $Top_AA=$dd[1];
        }
#	}
}
#print "$Top_Freq\n";
close IN;
@VJ=keys %vjlist;
for(my $j=0;$j<=$#VJ;$j++){

#my $dist_file="$tsne_dir/$sample/$sample.$VJ[$j].Dist.xls";
my $zb_file="$tsne_dir/$sample/$VJ[$j].coords.txt";
my $stat_file="$indir/NewTCRs.$sample.Factor.Stat.xls";
my @s_aa=sort {$AA{$VJ[$j]}{$a} <=> $AA{$VJ[$j]}{$b}}keys %{$AA{$VJ[$j]}};
#print "$zb_file\n";
#print "$stat_file\n";
my %Ev=();
my %Freq=();
my %X=();
my %MD=();
open IN,$stat_file or die $!;
while(<IN>){
	chomp;
	next if /^VJ/;
	my($vj,$freq,$D50,$num,$uniqDistnum,$uniqentropy,$undef)=split /\s+/,$_;
	$Ev{$vj}=sprintf "%.4f",$uniqentropy;
	$Freq{$vj}=sprintf "%.4f",$D50*100;
	my $x=(-1/(log($D50)/log(10)))/($uniqDistnum*$uniqentropy);
	$MD{$vj}=sprintf "%.4f",$uniqDistnum*$uniqentropy;
	$X{$vj}=sprintf "%.6f",$x;
}
close IN;


next unless -e $zb_file;
open IN,$zb_file or die $!;
my @zb=();
while(<IN>){
	chomp;
	s/://g;
	s/\[//g;
	s/\]//g;
	s/^\s*//g;
	s/\.\.\.//g;
	push @zb,split /\s+/,$_;
}
close IN;
shift @zb;
my %xy=();
my $Max_zbx=0;
my $Max_zby=0;
#print "$#zb\t$AA_num\n";
next if $#zb/2 != $AA_num{$VJ[$j]};

#print "$VJ[$j]\t$AA_num{$VJ[$j]}\t$#zb\t$zb[$AA_num{$VJ[$j]}]\n";
for(my $i=0;$i<=$#zb;$i++){
	if($i<$AA_num{$VJ[$j]}){
		$xy{$s_aa[$i]}->{'x'}=$zb[$i];
		$Max_zbx = abs($zb[$i]) if $Max_zbx < abs($zb[$i]);
	}
	if($i>$AA_num{$VJ[$j]}){
#	else{
		$xy{$s_aa[$i-$AA_num{$VJ[$j]}-1]}->{'y'}=$zb[$i];
		$Max_zby = abs($zb[$i]) if $Max_zby < abs($zb[$i]);
	}
#	$Max_zbx = abs
}

my $up=70;
my $down=50;
my $left=50;
my $right=50;

my $length=300;
my $du=60;

my $lyy=$length*sin($du*PI/180);
$lyy=$length;
my $width=$left+$right+$length;
my $height=$up+$lyy+$down;

my $svg=SVG->new('width'=>$width,'height'=>$height);
$svg->rect(
                'style'=>{stroke=>'white', fill=>'white'},
                x=>0, y=>0,
                width=>$width, height=>$height,
                rx=>0, ry=>0,
);

my $x_o=$left+$length/2;
my $y_o=$up+$lyy/2;

#print join "\n",sort{$b<=>$a}values %dist;

my $unit_x=($length/2)/$Max_zbx;
my $unit_y=($lyy/2)/$Max_zby;

$unit_x = $length/2*1000 if $Max_zbx <=0.001;
$unit_y = $lyy/2*1000 if $Max_zby <= 0.001;
$svg->rect('x',$left,'y',$up,'width',$length,'height',$lyy,'stroke','rgb(208,208,208)','stroke-width',1,'fill','rgb(228,228,228)');
$svg->line('x1',$left+$length/2,'y1',$up,'x2',$left+$length/2,'y2',$up+$lyy,'stroke','rgb(255,255,255)','stroke-width',1);
$svg->line('x1',$left,'y1',$up+$lyy/2,'x2',$left+$length,'y2',$up+$lyy/2,'stroke','rgb(255,255,255)','stroke-width',1);

$svg->text('x',$left+$length,'y',$up-7,'-cdata'," TCRs: $X{$VJ[$j]}",'text-anchor','end','stroke','black','stroke-width',0,'font-family','Arial','font-size',18);
my $text=" Entropy:$Ev{$VJ[$j]}";#Frequency:$Freq{$vj_lst}%";
$svg->text('x',$left,'y',$up-37,'-cdata',$text,'stroke','black','stroke-width',0,'font-family','Arial','font-size',18);
$svg->text('x',$left+$length,'y',$up-37,'-cdata',"F50:$Freq{$VJ[$j]}%",'text-anchor','end','stroke','black','stroke-width',0,'font-family','Arial','font-size',18);
$svg->text('x',$left,'y',$up-7,'-cdata',"E-V score:$MD{$VJ[$j]}",'stroke','black','stroke-width',0,'font-family','Arial','font-size',18);
$Top_Freq=$Max_freq if $Top_Freq < $Max_freq;
my $max_r=30;
$Top_Freq=0.2 if $Top_Freq>0.2;
for(my $i=0;$i<=$#s_aa;$i++){
#	print "($xy{$s_aa[$i]}->{'x'}\t$xy{$s_aa[$i]}->{'y'})\n";
	my $rx=$x_o+$xy{$s_aa[$i]}->{'x'}*$unit_x;
	my $ry=$y_o-$xy{$s_aa[$i]}->{'y'}*$unit_y;
#	print "$dist{$s_aa[$i]}\t$Max_D\t$Ave_D\t";
#	my $rgb=&cor($dist{$s_aa[$i]},$Max_D,$Min_D);
#	my $rgb="rgb(251,54,54)";
#	print "$rx\t$ry\t$rgb\n";

#	print "$AA{$s_aa[$i]}\t";
	my $nr=&cal_r($AA{$VJ[$j]}{$s_aa[$i]},$Top_Freq);
	my $r=$nr*$max_r;
#	$r=0.1 if $r<0.1;
	$r=$max_r if $r>$max_r;
	my $rgb=&cor($AA{$VJ[$j]}{$s_aa[$i]},$Top_Freq);
	print "$AA{$VJ[$j]}{$s_aa[$i]}\t$Top_Freq\t$nr\t$r\t$rgb\n";
#	my $opa=0.9*$nr;	
	$svg->circle('cx',$rx,'cy',$ry,'r',$r,'stroke',$rgb,'fill',$rgb,'fill-opacity',0.95,'stroke-width',1);
#	if()
}


my $svg_file="$sub_svg_dir/$sample.TSNE.$VJ[$j].Fig1.svg";
#print "$svg_file\n";
my $png=$svg_file;
$png=~s/svg/png/g;

open OUT,">$svg_file" or die $!;
print OUT $svg->xmlify();
close OUT;
#svg2png($svg_file,-d=>$png,-w=>$width,-h=>$height);
}
}

sub cal_r{
	my $r=shift;
	my $top=shift;

#	my $n=(1/(log($r)/log(10)))/(1/(log($top)/log(10)));
	my $n=(1/log($r))/(1/log($top));
	return $n;
}

sub cor{
#        my $pfc=shift;
#        my $max=shift;
#	my $min=shift;
	my $f=shift;
	my $top=shift;
	my $r=0;
        my $rgb;
	if($f>=$top){
		$rgb="rgb(251,1,1)";
	}
	elsif($f>=0.001){
		my $n=(-1/log($f))/(-1/log(0.2));
                $r=(50-int(50*$n));
                $rgb="rgb(251,$r,$r)";
		$rgb="rgb(251,30,30)";
	}
	elsif($f>=0.0001){
		my $n=(-1/log($f))/(-1/log(0.001));
		$r=54+(50-int(50*$n));
		$rgb="rgb(251,$r,$r)";
		$rgb="rgb(251,65,65)";
	}
	elsif($f>=0.00001){
                my $n=(-1/log($f))/(-1/log(0.0001));
                $r=54+(50-int(50*$n));
                $rgb="rgb(251,$r,$r)";
		$rgb="rgb(251,100,100)";
        }
	elsif($f>=0.000001){
		my $n=(-1/log($f))/(-1/log(0.00001));
                $r=100+(100-int(100*$n));
                $rgb="rgb(251,$r,$r)";
		$rgb="rgb(251,180,180)";
	}
	else{
		$rgb="rgb(251,220,220)";
	}
	return $rgb;
}
