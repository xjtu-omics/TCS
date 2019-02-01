package Plot_Scatter_test;
use strict;
use Exporter;
#use FindBin qw($Bin);
use lib "/ifswh1/BC_PUB/biosoft/pipeline/IMMUNE/IRSEQ.v1.0/bin/Exp_dif/";
use Plot_INC qw(svg2png);
use Data::Dumper;

our @ISA=qw(Exporter);
our @EXPORT=qw(plot_scatter);


sub plot_scatter
{
	my $diff_ann=shift;
	my $contr=shift;
	my $treat=shift;
	my $spearman=shift;
	my $pearson=shift;
	my $out=shift;
	my $type=shift;
	
	$out.="$type\_scatter_4_$contr\_$treat.svg";
	my $convert='/usr/bin/convert';
	## plot
	
	my $unit=70;

	my $tic_log=1; ## 1og10(10)
	my $max_log=8; ## log10(1000000)+1 

	my @tags;
	map {push @tags, $_} values %$diff_ann;
	my $width=8 * $unit + 340;
	my $height=8 * $unit + 280;

	my $svg=SVG->new('width'=>$width,'height'=>$height);
	$svg->rect(                                         
		'style'=>{stroke=>'white', fill=>'white'},      
		x=>0, y=>0,                                     
		width=>$width, height=>$height,                 
		rx=>0, ry=>0,                                   
	);                                                  

	## defination colors
	my @group;
	my %def=(
		grout_x=>['blue','blue'],
	);
	&defination(\@group,\%def,$svg);
	my ($xx)=@group;

	## plot coordinate
	my $x=150;
	my $y=720;	
#	my $annoation="red points show x-value/y-value>2";
#	my $annoation_1="blue points show 1/2<$contr/$treat<2";
#	my $annoation_2="green points show  $contr/$treat<1/2";
	$svg->rect('x', $x+8, 'y', 100, 'width', 10, 'height', 10, 'stroke', 'black', 'fill', 'red');
	$svg->rect('x', $x+8, 'y', 120, 'width', 10, 'height', 10, 'stroke', 'black', 'fill', 'green');
	$svg->rect('x', $x+8, 'y', 140, 'width', 10, 'height', 10, 'stroke', 'black', 'fill', 'blue');
	$svg->text('x',$x+22,'y',109,'-cdata','up-expressed clonotype','font-family','Arial','font-size',15,'style'=>'fill:red');
	$svg->text('x',$x+22,'y',129,'-cdata','down-expressed clonotype','font-family','Arial','font-size',15,'style'=>'fill:green');
	$svg->text('x',$x+22,'y',149,'-cdata','equally-expressed clonotype','font-family','Arial','font-size',15,'style'=>'fill:blue');

	$svg->text('x',$x+300,'y',119,'-cdata',"spearman r=$spearman",'font-family','Arial','font-size',15,'style'=>'fill:black');
	$svg->text('x',$x+300,'y',139,'-cdata',"pearson r=$pearson",'font-family','Arial','font-size',15,'style'=>'fill:black');
	my $title="Scatter plot";
	$svg->text('x',$x+((length $title)*28)/2,'y',40,'-cdata',$title,'font-family','Arial','font-size',30,'style'=>'fill:rgb(0,0,0)');
	
	$svg->line('x1',$x,'y1',$y,'x2',$x,'y2',$y-($max_log+1)*$unit,'stroke','black','stroke-width',2);
	$svg->line('x1',$x,'y1',$y,'x2',$x+($max_log+1)*$unit,'y2',$y,'stroke','black','stroke-width',2);

	## y
	for (my $i=1; $i*$tic_log <= $max_log+1; $i++) {
		# plot y label
		$svg->line('x1',$x,'y1',$y-$i*$tic_log*$unit,'x2',$x-5,'y2',$y-$i*$tic_log*$unit,'stroke','black','stroke-width',2);
		
		# plot compair line
		my $y_label;
#		if($i>=2)
#		{
#			$y_label=sprintf "%3d", 10**($i-2);
#		}
#		else
#		{
#			$y_label=sprintf "%f", 10**($i-2);
#		}
		my $position=$x-$i*8-10;
                if($i>=2)
                {
                        $y_label=sprintf "%3d", 10**($i-2);
                }
                else
                {
                        $svg->text('x',$position-20,'y',$y-$i*$tic_log*$unit+5,'-cdata',0.1,'font-family','Arial','font-size',14,'style'=>'fill:rgb(0,0,0)');
                }
		$svg->line('x1',$x,'y1',$y-$i*$tic_log*$unit,'x2',$x+($max_log+1)*$unit,'y2',$y-$i*$tic_log*$unit,'stroke','black','stroke-width',1);
		$svg->text('x',$position,'y',$y-$i*$tic_log*$unit+5,'-cdata',$y_label,'font-family','Arial','font-size',14,'style'=>'fill:rgb(0,0,0)');	
	}

	## x
	for (my $i=1; $i*$tic_log <= $max_log+1; $i++) {
		# plot x label
		$svg->line('x1',$x+$i*$tic_log*$unit,'y1',$y,'x2',$x+$i*$tic_log*$unit,'y2',$y+5,'stroke','black','stroke-width',2);
		
		# plot compair line
		my $position=$x+$i*$tic_log*$unit-($i-1)*5;
		my $x_label;
		if($i>=2)
		{
			$x_label=sprintf "%3d", 10**($i-2);
		}
		else
		{
			$svg->text('x',$position-14,'y',$y+20,'-cdata',0.1,'font-family','Arial','font-size',14,'style'=>'fill:rgb(0,0,0)');
		}
#		my $position=$x+$i*$tic_log*$unit-($i-1)*5;
		if($i==1||$i==2||$i==3||$i==5||$i==6||$i==7)
		{
		$svg->line('x1',$x+$i*$tic_log*$unit,'y1',$y,'x2',$x+$i*($tic_log)*$unit,'y2',$y-($max_log)*$unit,'stroke','black','stroke-width',1);
		}
		else
		{
		$svg->line('x1',$x+$i*$tic_log*$unit,'y1',$y,'x2',$x+$i*($tic_log)*$unit,'y2',$y-($max_log+1)*$unit,'stroke','black','stroke-width',1);
		}
		$svg->text('x',$position,'y',$y+20,'-cdata',$x_label,'font-family','Arial','font-size',14,'style'=>'fill:rgb(0,0,0)');
	}	

	## plot data
	foreach my $num (0..$#tags) {
		my ($x_pos,$y_pos)=@{$tags[$num]};
		my $ratio;
          	next if(($y_pos == 0)&&($x_pos == 0));
		if($y_pos == 0){
			if($x_pos > 2){$ratio = 1/3;}
			else{$ratio = 1;}
		}elsif($x_pos == 0){
			if($y_pos > 2){$ratio = 3;}
			else{$ratio = 1;}
		}else{$ratio = $y_pos/$x_pos;}

		$x_pos=log10($x_pos); $y_pos=log10($y_pos);
                if($x_pos eq "NA"){$x_pos=0;}
                elsif($x_pos < 0 && $x_pos > -1){$x_pos = $x_pos +2;}
                elsif($x_pos <= -1){$x_pos = 10**($x_pos +1);}
                else{$x_pos = $x_pos+2; }
		if($y_pos eq "NA"){$y_pos=0;}
                elsif($y_pos < 0 && $y_pos > -1){$y_pos = $y_pos +2;}
                elsif($y_pos <= -1){$y_pos = 10**($y_pos +1);}
                else{$y_pos = $y_pos+2; }

                if($ratio>2)
                {
                        $xx->tag('circle', cx=>$x+($x_pos)*$unit, cy=>$y-($y_pos)*$unit, r=>2, id=>'circle1_in_'.$num,'stroke','red','style'=>'fill:red');
                }
                elsif($ratio<1/2)
                {
                        $xx->tag('circle', cx=>$x+($x_pos)*$unit, cy=>$y-($y_pos)*$unit, r=>2, id=>'circle1_in_'.$num,'stroke','green','style'=>'fill:green');
                }
                else
                {
                        $xx->tag('circle', cx=>$x+($x_pos)*$unit, cy=>$y-($y_pos)*$unit, r=>2, id=>'circle1_in_'.$num,'stroke','blue','style'=>'fill:blue');
                }
	}

	$svg->text('x',$x+2*$unit,'y',$y+60,'-cdata','Expression level ('.$contr.')','font-family','Arial','font-size',20,'style'=>'fill:rgb(0,0,0)');

	my $coor_x=$x-70;
	my $coor_y=$y-2*$unit;
	$svg->text('x',$coor_x,'y',$coor_y,'-cdata','Expression level ('.$treat.')','font-family','Arial','font-size',20,'transform'=>"rotate(-90,$coor_x,$coor_y)",'style'=>'fill:rgb(0,0,0)');

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
					fill   => $$clr[1],
				}
			);
	}
}

sub log10
{
	my $n=shift;
	if($n==0){return "NA";}
	else{return log($n)/log(10);}
}
