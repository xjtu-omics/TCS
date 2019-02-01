#!/usr/bin/perl -w
use strict;
if(@ARGV != 3)
{
	print "perl $0 <project_dir> <bms_info> <AA/DNA>\n";
	exit;
}
my($pro_dir, $bms_lst, $type) = @ARGV;
my $outdir="$pro_dir/Result/07.RareHighFreq/Percent95/";

`mkdir -p $outdir` unless(-d $outdir);

my %sample = ();
my $Z_score_err = 1.644854; #norm(Z_score_err < 1.644854) = 0.95; norm(Z_score_err < 2.326348) = 0.99
open I, $bms_lst or die $!;
while(<I>)
{
	chomp; next if(/^$/);
	my @t = split /\s+/, $_;
	$sample{$t[0]}=1;
}
close I;

open O, ">$outdir/RareHighFreq_$type.stat" or die $!;
print O "Sample\tType\tMax\tMin\tCutOff\tnum\tHigh(%)\tRare(%)\n";
for my $k(keys %sample)
{
#	for my $s(1..scalar(@{$sample{$k}})-1){
		my $sam = $k;
		my($num, $max, $min) = (0, -100, 100);
		my %hash = (); 
		my %clon = ();
		open I, "$pro_dir/Result/04.ExpProfile/$sam/$sam.profile.$type.xls" or die $!;
		my $tatil=<I>;
		while(<I>)
		{
			chomp; next if(/^$/);
			my @t = split /\s+/, $_;
			next if($t[0] <= 0);
			$hash{$t[2]} = $t[1];
			$clon{$t[2]} = $_;
			$num++;
			$max = $t[1] if($max < $t[1]);
			$min = $t[1] if($min > $t[1]);
		}
		close I;
		my($var, $sum) = (0, 0);
		for my $k(keys %hash)
		{
			my $t = ($hash{$k} - $min) / ($max - $min);
			$hash{$k} = $t;
			$var += $t * $t;
			$sum += $t;
		}
		my $mean = $sum / $num;
		my $sd = sqrt($var/$num - $mean * $mean);
		my($Z_score, $high) = (0, 0);
		$Z_score = $Z_score_err * $sd + $mean;
		my $cut_off = $min + $Z_score * ($max - $min);
		open H, ">$outdir/$sam.$type.high.txt" or die $!;
		for my $k(keys %hash)
		{
			if($hash{$k} >= $Z_score)
			{
				$high++;
				print H "$clon{$k}\n";
			}
		}
		close H;
		my $high_per = $high / $num * 100.0;
		my $rare_per = ($num - $high) / $num * 100.0;
		print O "$sam\t$k\t$max\t$min\t$cut_off\t$num\t$high_per\t$rare_per\n";
#	}
}
close O;
