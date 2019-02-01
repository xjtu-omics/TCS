#!/usr/bin/perl
use strict;
use SVG;
#use Data::Dumper;
#use FindBin qw($Bin);

#use lib "/ifshk4/BC_PUB/biosoft/pipe/bc_hdh/SmallRNA/sRNA_pipeline_v1.0/lib/Plot";
#use Plot_First_base;
#use Plot_INC;
#use File::Find;
#use lib "/ifs4/BC_PUB/biosoft/pipe/bc_hdh/SmallRNA/sRNA_pipeline_v1.0/lib/Plot";


if(@ARGV!=6){
	print "usage: Frequency_bar_graph.pl <*_family_usage_frequency.xls> <team_lst> <changname_lst> <out_dir> <V/D/J>\n";
	exit;
}

my $infile=shift;
my $team_lst=shift;
my $change_lst=shift;
my $outdir=shift;
my $VDJ=shift;
my $col_list=shift;

## out_dir
$outdir.="/" unless $outdir =~/\/$/;
mkdir $outdir unless (-e $outdir);

my %changname=();
open IN,$change_lst or die $!;
while(<IN>){
	chomp;
	my ($old,$new)=split /\s+/,$_;
	$changname{$old}=$new."A";
	#print "$old\t$new\ta\n";
	}
close IN;

my %team_sample=();
my @team=();
my @samples=();
open IN,$team_lst or die $!;
while(<IN>){
	chomp;
	my $line=$_;
	my $group=(split /=/,$line)[0];
	push @team,$group;
	my @dd=split /,/,(split /=/,$line)[1];
	push @samples,@dd;
	$team_sample{$group}=$#dd+1;
}
close IN;

my %data_plot;
my %total_dat;
open IN,$infile or die $!;
#my @samples;
#shift @samples;
my @usage;
my %usage_hash=();
#print "@samples\nfdajlkfda\n";
while(<IN>)
{
	chomp;
	my @dd=split /\s+/,$_;
	my $us=shift @dd;
	if($us=~/Family/){
#		@samples=@dd;
	}
	else{
#		print "$us\n";
#		push @usage,$us;
		for(my $i=0;$i<=$#samples;$i++){
			$data_plot{$samples[$i]}{$us}=$dd[$i];
			$total_dat{$us}+=$dd[$i];
		}
	}
}
close IN;
#print Dumper %hash;
my $usage_num=15;
foreach my $us(sort {$total_dat{$b} <=> $total_dat{$a}} keys %total_dat){
	if($usage_num>0){
		push @usage,$us;
		$usage_hash{$us}++;
		$usage_num--;
	}
}
#print "$#usage+1\n";
if($#usage+1>=15){
	push @usage,"Other";
}

my %dat_plot;
foreach my $sample(keys %data_plot){
	foreach my $us(keys %{$data_plot{$sample}}){
		if(exists $usage_hash{$us}){
			$dat_plot{$sample}{$us}=$data_plot{$sample}{$us};
		}
		else{
			$dat_plot{$sample}{"Other"}+=$data_plot{$sample}{$us};
		}
	}
}

## hash->arry to plot
#my %dat_plot;
my @color;
my $r=255;
my $g=255;
my $bb=255;

for(my $i=0;$i<=5;$i++){
	$r=255-$i*50;
	for(my $j=5;$j>0;$j--){
		$g=255-$j*50;
		for(my $k=abs($j-$i);$k<=5;$k++){
			$bb=255-$k*50;
			my $rgb="rgb($r,$g,$bb)";
			push @color,$rgb;
		}
	}
}

#print "$#color\n";
my @ccolor = ();
open IN,$col_list or die $!;
while(<IN>){
	chomp;
	push @ccolor,$_;
}
close IN;
my %col=();

my %flag=();
my $col_l=0;
my $col_h=$#color;
for(my $i=0;$i<=$#usage;$i++){
#	my $ff=int(rand($#color));
#	if(!exists $flag{$ff}){
#		$col{$usage[$i]}=$color[$ff]; 
#		$flag{$ff}++;
#	}
#	if($i%2==0){
#		$col_l+=5;
		$col{$usage[$i]}=$ccolor[$i];
#		$col_l+=5;
#	}
#	else{
#		$col{$usage[$i]}=$color[$col_h];
#		$col_h-=1;
#	}
}

print join "\t",@usage;
print join "\t",values %col;

## plot
my $out=$outdir."$VDJ\_Frequency_bar_pic.svg";
my $png=$outdir."$VDJ\_Frequency_bar_pic.png";
#&plot_first_base(\%dat_plot,\%col,$out);

my $unit_x=20;
my $unit_y=2;

my $left_w=100;
my $righ_w=200;
my $up_h=80;
my $down_h=200;

my $width=($#samples+1)*$unit_x*1.5+$left_w+$righ_w;
my $height=800;

my $svg=SVG->new('width'=>$width,'height'=>$height);
$svg->rect(
                'style'=>{stroke=>'white', fill=>'white'},
                x=>0, y=>0,
                width=>$width, height=>$height,
                rx=>0, ry=>0,
);

#my $left_w=100;
#my $righ_w=200;
#my $up_h=80;
#my $down_h=150;

my $x_o=$left_w;
my $y_o=$height-$down_h;

$svg->line('x1',$x_o,'y1',$y_o,'x2',$width-$righ_w,'y2',$y_o,'stroke','black','stroke-width',3);
$svg->line('x1',$x_o,'y1',$y_o,'x2',$x_o,'y2',$up_h,'stroke','black','stroke-width',2);

my $tx=$left_w-60;
my $ty=$y_o-140;
$svg->text('x',$tx,'y',$ty,'-cdata',"Frequency (% of reads)","transform"=>"rotate(-90,$tx,$ty)",'stroke','black','stroke-width',1,'font-family','Arial','font-size',20);

my $usage_flag=0;

foreach my $usage_id(sort {$a cmp $b} keys %col){
	my $usage_x=$width-$righ_w+40;
	my $usage_y=$up_h+$usage_flag*30;
	my $usage_w=18;
	my $usage_h=18;
	
	$svg->rect('x',$usage_x,'y',$usage_y,'width',$usage_w,'height',$usage_h,'stroke',$col{$usage_id},'fill',$col{$usage_id},'stroke-width',1);
	$svg->text('x',$usage_x+$usage_w+10,'y',$usage_y+$usage_h,'-cdata',$usage_id,'stroke','black','font-family','Arial','font-size',16);
	$usage_flag++;
}


for(my $i=0;$i<=10;$i++){
	my $y_i=($height-$up_h-$down_h)/10*$i;
	$svg->line('x1',$x_o,'y1',$y_o-$y_i,'x2',$x_o-5,'y2',$y_o-$y_i,'stroke','black','stroke-width',3);
	if($i%2==0){
		my $x_text=$x_o-10*length($i*10)-8;
		$svg->text('x',$x_text,'y',$y_o-$y_i+5,'-cdata',10*$i,'stroke','black','font-family','Arial','font-size',18);
	}
}


my $group_length_unit_x=($width-$left_w-$righ_w)/($#samples+1);
my $group_x_o=$x_o+10;
my $group_y_o=$height-60;
my $group_text_x=$x_o;
my $group_text_y=$group_y_o+30;

for(my $i=0;$i<=$#team;$i++){
	if(exists $team_sample{$team[$i]}){
#		print "$team_sample{$team[$i]}\n";
		my $team_length=$team_sample{$team[$i]}*$group_length_unit_x;
#		print "$group_length_unit_x\t$team_length\n";

		$svg->line('x1',$group_x_o,'y1',$group_y_o,'x2',$group_x_o+$team_length-5,'y2',$group_y_o,'stroke','black','stroke-width',3);
		$svg->text('x',$group_text_x+$team_length/2,'y',$group_text_y,'-cdata',$team[$i],'stroke','black','font-family','Arial','font-size',18);
		$group_x_o=$group_x_o+$team_length+5;
		$group_text_x=$group_x_o;
	}
}

for(my $i=0;$i<=$#samples;$i++){
	my $x_lable=$samples[$i];
	my $x_i=$x_o+$unit_x/2+$i*$unit_x*1.5;
	my $y_i=$y_o;
	foreach my $vdj(sort {$b cmp $a} keys %{$dat_plot{$samples[$i]}}){
		#print "$vdj\n";
		my $y_hei=$dat_plot{$samples[$i]}{$vdj}*($height-$up_h-$down_h);
		
		$svg->rect('x',$x_i,'y',$y_i-$y_hei,'width',$unit_x,'height',$y_hei,'stroke',$col{$vdj},'fill',$col{$vdj},'stroke-width',1);
		$y_i-=$y_hei;
	}
#	my $x_text=$x_i-40;
#	my $y_text=$y_o+10+length($samples[$i])*16;
	
#	$svg->text('x',$x_text,'y',$y_text,'-cdata',$samples[$i],"transform"=>"rotate(-45,$x_text,$y_text)",'stroke','black','font-family','Arial','font-size',20);
	my $x_text=$x_i;
	my $y_text=$y_o+15;
	if(exists $changname{$samples[$i]}){
		$svg->text('x',$x_i,'y',$y_text,'-cdata',$changname{$samples[$i]},"transform"=>"rotate(60,$x_text,$y_text)",'stroke','black','font-family','Arial','font-size',20);
	}
	else{
		$svg->text('x',$x_i,'y',$y_text,'-cdata',$samples[$i],"transform"=>"rotate(60,$x_text,$y_text)",'stroke','black','font-family','Arial','font-size',20);
	}
}

open OUT, ">$out" || die $!;
print OUT $svg->xmlify();
close OUT;

#svg2png($out,-d=>$png,-w=>$width,-h=>$height);
