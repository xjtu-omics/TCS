#!/usr/bin/perl -w
use strict;
if(@ARGV != 2)
{
	print "perl $0 <sample.list> <outdir>\n";
	exit;
}
my($in, $outdir) = @ARGV;
`mkdir -p $outdir` unless(-d $outdir);

my %sample = ();
my $Z_score_err = 2.326348;#norm(Z_score_err < 1.644854) = 0.95; norm(Z_score_err < 2.326348) = 0.99
open I, $in or die $!;
while(<I>)
{
	chomp; next if(/^$/);
	my @t = split /\s+/, $_;
	push @{$sample{$t[0]}}, @t;
}
close I;

open O, ">$outdir/RareHighFreq_v2.stat" or die $!;
print O "Sample\tType\tMax\tMin\tCutOff\tnum\tHigh(%)\tRare(%)\n";
for my $k(keys %sample)
{
	for my $s(1..scalar(@{$sample{$k}})-1)
	{
		my $sam = $sample{$k}[$s];
		my($num, $max, $min) = (0, -100, 100);
		my %hash = (); 
		my %clon = ();
		open I, "/ifs4/BC_HDH/PROJECT/IR_PROJECT/roy_F13FTSCCKF1468_HUMroyR/CP_DATA/$sam/$sam.CDR3_AA.frequency" or die $!;
		while(<I>)
		{
			chomp; next if(/^$/);
			my @t = split /\s+/, $_;
			next if($t[1] <= 0);
			$hash{$t[0]} = $t[2];
			$clon{$t[0]} = $_;
			$num++;
			$max = $t[2] if($max < $t[2]);
			$min = $t[2] if($min > $t[2]);
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
		open H, ">$outdir/$sam.high" or die $!;
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
	}
}
close O;
