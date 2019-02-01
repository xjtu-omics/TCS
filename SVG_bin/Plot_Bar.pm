package Plot_Bar;
use SVG;
use strict;
use Exporter;
use List::Util qw(max);
use FindBin qw($Bin);
use lib "$Bin/../../../../lib/Plot/";
use Plot_INC qw(svg2png);
use Data::Dumper;

our @ISA=qw(Exporter);
our @EXPORT=qw(plot_bar);

sub plot_bar
{
	my $bar_id2value=shift;
	my $out=shift;
	my $title=shift;

	my $front_size=12; #defualt,1 pound = 0.35 mm, 1 char_length = 0.35 * front-size 
	my $rect_width=400; #defualt

	my @id_order=sort {$bar_id2value->{$b} <=> $bar_id2value->{$a}} keys %$bar_id2value;
	while($#id_order >19){
		pop @id_order;
	}
	my $id_length_max=max map {length scalar$_} @id_order;
	my $value_max= max map{$bar_id2value->{$_}} @id_order;
	
	if($value_max==0){
		exit;
	}
 	my $x_trace=$rect_width/$value_max;
    my $y_trace=20;

#	my $x_start=200+$id_length_max*0.35*$front_size;
	my $x_start=500;
	my $id_length_threshold=($x_start-200)/($front_size*0.35);
	my $y_start=100;
	
	my $width=$x_start+$value_max*$x_trace+100;
	my $height=$y_start+$y_trace*(1+$#id_order)+50;
	##### plot the title and x-axis trace
	my $svg=SVG->new('width'=>$width,'height'=>$height,'title'=>$title);
	$svg->text(x=>$x_start,y=>$y_start-50,'text-anchor'=>'middle','fill'=>'black','font-size',$front_size+4,'font-family','Arial')->cdata($title);

	my $value_trace=scalar sprintf("%e",$value_max/8);# usually value_max is bigger than 1;
	my($value,$index)=split /e/,$value_trace;
	$value_trace=(int $value+0.5)*10**$index; # value for each trace
	
	my$xx_trace=[$x_start];
	my$xy_trace=[$y_start-$y_trace/2,$y_start-$y_trace/2-5,$y_start-$y_trace/2-5]; 
	my$temp_count=0;
	do{
		$temp_count++;
		push @$xx_trace,($xx_trace->[0],$x_start+$x_trace*$value_trace*$temp_count);
		my$points=$svg->get_path(x=>$xx_trace,y=>$xy_trace,-type=>'polyline',-closed=>'false');
    	$svg->polyline(%$points,style=>{'stroke-width'=>'2','fill'=>'white','stroke'=>'black','stroke-color'=>'rgb(255,0,0)'});
		$svg->text(x=>$xx_trace->[0],
				y=>$y_start-$y_trace/2-10,
				-cdata=>$value_trace*($temp_count-1),
				'text-anchor'=>'middle',
				'fill'=>'black',
				'font-size',$front_size,
				'font-family','Arial');
		shift @$xx_trace for(1 .. 2);
	}while($x_trace*$value_trace*$temp_count<400);
	##### plot the rect
	foreach my$id(@id_order){
		my $color=num2color($bar_id2value->{$id}/$value_max);
		$svg->rect(
			'style'=>{stroke=>'black', fill=>$color},
			x=>$x_start, y=>$y_start,
			width=>$bar_id2value->{$id}*$x_trace, height=>$y_trace-5,
			rx=>0, ry=>10,
		);
		#### plot the id
		my $id_text=$svg->text(x=>$x_start-20,y=>$y_start+$y_trace/2,'text-anchor'=>'end','fill'=>'black','font-size',$front_size,'font-family','Arial');
		if(length scalar$id >$id_length_threshold){
			my$position_sep=index($id,' ',int (length scalar$id)/2);
			my$id_text1=substr($id,0,$position_sep+1);
			my$id_text2=substr($id,$position_sep+1);
			$id_text->tspan(x=>$x_start-20,dy=>'-5')->cdata($id_text1);
			$id_text->tspan(x=>$x_start-20,dy=>'10')->cdata($id_text2);
		}
		else{
			$id_text->cdata($id);
		}
		#### plot the value
		$svg->text(x=>$x_start+$bar_id2value->{$id}*$x_trace+20,
			y=>$y_start+$y_trace/2,
			-cdata=>$bar_id2value->{$id},
			'text-anchor'=>'start',
			'fill'=>'blue',
			'font-size',$front_size,
			'font-family','Arial');
		$y_start +=$y_trace;
	}
	#### generate svg document

	$out.=".svg";
	open OUT, ">$out" || die $!;
	print OUT $svg->xmlify();
	close OUT;

    my $out_png=$out; $out_png=~s/svg/png/;
    svg2png($out,-d=>$out_png);
}

sub num2color
{
	my $num=shift;

	my ($r,$g,$b);
	if ($num > 0) {	## red
		$r=int 255*$num; $r=255 if ($r > 255);
		$g=4;
		$b=4;
		$r=255-$r; 
	}else{	## green
		$r=4;
		$g=int abs(255*$num); $g=255 if ($r > 255);
		$b=4;
		$g=255-$g;
	}
	return "rgb($r,$g,$b)";
}
