package Plot_Log2ratio;
use strict;
use Exporter;
#use FindBin qw($Bin);
use lib "/ifswh1/BC_PUB/biosoft/pipeline/IMMUNE/IRSEQ.v1.0/bin/Exp_dif/";
use Plot_INC qw(svg2png);
use Data::Dumper;

our @ISA=qw(Exporter);
our @EXPORT=qw(plot_log2ratio);

use SVG;
use Data::Dumper;

sub plot_log2ratio
{
	my $diff_ann=shift;
	my $name=shift;
	my $out=shift;
	
	my $convert='/usr/bin/convert';
	## plot

	my $unit_y=40;
	
	my $height=380;
	
	my @tags;
	map {push @tags, $_} values %$diff_ann;
	my $unit_x=800/$#tags;
	my $width=$#tags * $unit_x + 400;

	my $svg=SVG->new('width'=>$width,'height'=>$height);
	$svg->rect(                                         	
		'style'=>{stroke=>'white', fill=>'white'},      
		x=>0, y=>0,                                     
		width=>$width, height=>$height,                 
		rx=>0, ry=>0,                                   
	);                                                  

	# defination colors
	my @group;
	my %def=(
		grout_x=>['blue','blue'],
		grout_y=>['yellowgreen','yellowgreen'],
		grout_z=>['red','red']
	);
	&defination(\@group,\%def,$svg);
	my ($xx,$yy,$zz)=@group;

	## plot  tables
	my $x=50;
	my $y=220;

	my $title="log2ratio ($name)";
	$svg->text('x',$x+($width-(length $title)*18)/2,'y',40,'-cdata',$title,'font-family','Arial','font-size',30,'style'=>'fill:rgb(0,0,0)');

	my $y_tic=1;
	my $x_max=$#tags; my $y_max=3;

	$svg->line('x1',$x,'y1',$y+$y_max*$unit_y,'x2',$x,'y2',$y-$y_max*$unit_y,'stroke','black','stroke-width',2);
	$svg->line('x1',$x+$x_max*$unit_x,'y1',$y+$y_max*$unit_y,'x2',$x+$x_max*$unit_x,'y2',$y-$y_max*$unit_y,'stroke','black','stroke-width',1);

	for (my $i=0; $i*$y_tic<=$y_max; $i++) {
		# plot y label
		$svg->line('x1',$x,'y1',$y-$i*$y_tic*$unit_y,'x2',$x-5,'y2',$y-$i*$y_tic*$unit_y,'stroke','black','stroke-width',2);
		$svg->line('x1',$x,'y1',$y+$i*$y_tic*$unit_y,'x2',$x-5,'y2',$y+$i*$y_tic*$unit_y,'stroke','black','stroke-width',2);

		# plot compair line
		my $y_label=sprintf "%3d", $i*$y_tic;
		if ($i == 0) {
			$svg->line('x1',$x,'y1',$y,'x2',$x+$x_max*$unit_x,'y2',$y,'stroke','black','stroke-width',2);
			$svg->text('x',$x-20,'y',$y+$i*$y_tic*$unit_y+5,'-cdata',$i,'font-family','Arial','font-size',14,'style'=>'fill:rgb(0,0,0)');
		}else{
			$svg->line('x1',$x,'y1',$y-$i*$y_tic*$unit_y,'x2',$x+$x_max*$unit_x,'y2',$y-$i*$y_tic*$unit_y,'stroke','black','stroke-width',1);
			$svg->text('x',$x-20,'y',$y-$i*$y_tic*$unit_y+5,'-cdata',$y_label,'font-family','Arial','font-size',14,'style'=>'fill:rgb(0,0,0)');

			$svg->line('x1',$x,'y1',$y+$i*$y_tic*$unit_y,'x2',$x+$x_max*$unit_x,'y2',$y+$i*$y_tic*$unit_y,'stroke','black','stroke-width',1);
			$svg->text('x',$x-30,'y',$y+$i*$y_tic*$unit_y+5,'-cdata','-'.$y_label,'font-family','Arial','font-size',14,'style'=>'fill:rgb(0,0,0)');
		}
	}
	my $a="Log2(fold change)"; $a=~s/\_/\//;
	$svg->text('x',$x-40,'y',$y-$y_max*$unit_y-13,'-cdata',$a,'font-family','Arial','font-size',14);	
	
	## plot data
	foreach my $num (0..$#tags) {
		if (abs($tags[$num]) <=1) {
			$xx->tag('circle', cx=>$x+$num*$unit_x, cy=>$y-$tags[$num]*$unit_y, r=>2, id=>'circle1_in_'.$num);
		} elsif(abs($tags[$num]) >1 && abs($tags[$num]) < 2){
			$yy->tag('circle', cx=>$x+$num*$unit_x, cy=>$y-$tags[$num]*$unit_y, r=>2, id=>'circle1_in_'.$num);
		} else{
			next if (abs($tags[$num]*$unit_y) > $y_max*$unit_y);
			$zz->tag('circle', cx=>$x+$num*$unit_x, cy=>$y-$tags[$num]*$unit_y, r=>2, id=>'circle1_in_'.$num);
		}
	}

#	# a <= 1		==> "blue";
#	# 1 < a <= 2	==> "yellowgreen";	
#	# a > 2			==> "red"
#
	my $x_pos=$x+$x_max*$unit_x+30;
	my $y_stt=$y-30;
	my $y_pos=$y_stt;
	my @bases=("fold change(<=2)","fold change(>2 && <=4)","fold change(>4)");
	my @color=("blue","yellowgreen","red");
	foreach  (0..2) {
		my $clr=$color[$_];
		$svg->line('x1',$x_pos,'y1',$y_pos,'x2',$x_pos+20,'y2',$y_pos,'stroke',$clr,'stroke-width',20);
		$svg->text('x',$x_pos+30,'y',$y_pos+6,'-cdata',$bases[$_],'font-family','Arial','font-size',20,'style'=>'fill:rgb(0,0,0)');
		$y_pos-=30;
	}
	
	$name=~s/\//\_/;
	$out.="log2ratio_4_$name.svg";
	open OUT, ">$out" || die $!;
	print OUT $svg->xmlify();
	close OUT;

	my $out_png=$out; $out_png=~s/svg/png/;
	svg2png($out,-d=>$out_png);
	#system "$convert $out $out_png";
}

sub defination
{
	my $group=shift;
	my $def=shift;
	my $svg=shift;
	
	foreach my $id (sort keys %$def) {
		my $clr=$def->{$id};
		push @$group,$svg->tag
			('g',
				id    => $id,
				style => {
					stroke => $$clr[0],
					fill   => $$clr[1]
				}
			);
	}
}
