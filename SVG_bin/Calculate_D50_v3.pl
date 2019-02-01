#!/usr/bin/perl
use strict;
use warnings;

if(@ARGV!=1){
	print "perl $0 <project dir>\n";
	exit 0;
}

my $project_dir=shift;

my $file_dir="$project_dir/Result/04.ExpProfile/";
opendir DIR,$file_dir or die $!;
my @samples=grep {!/\.$/ && !/txt$/ && !/xls$/ && !/stat!/}readdir(DIR);
closedir DIR;

my $out_dir="$project_dir/Result/09.D50AndGermline/D50/";
`mkdir -p $out_dir` unless(-d $out_dir);
#my %d50_inf=();
open STAT,">$out_dir/D50.stat.xls" or die $!;
print STAT "Sample:\t";
print STAT join "\t",sort {$a cmp $b} @samples;
print STAT "\n";
my $DNA_D50;
my $Peptide_D50;

foreach my $sample(sort {$a cmp $b} @samples){
	my $dna_file="$file_dir/$sample/$sample.profile.DNA.xls";
	my $aa_file="$file_dir/$sample/$sample.profile.AA.xls";
	
	my $d50_dna=&cal_d50($dna_file,"CDR3-DNA");
	my $d50_aa=&cal_d50($aa_file,"CDR3-Peptide");
	
	my $D50_stat="$out_dir/$sample.D50.stat";
	open DD,">$D50_stat" or die $!;
	print DD $d50_dna.$d50_aa;
	close DD;
	
	$DNA_D50.=(split /\s+/,$d50_dna)[2]."\t";
	$Peptide_D50.=(split /\s+/,$d50_aa)[2]."\t";
}

print STAT "CDR3-DNA:\t$DNA_D50\n";
print STAT "CDR3-Peptide:\t$Peptide_D50\n";
close STAT;

sub cal_d50
{
        my ($file,$flag)= @_;
        my $all_num = 0;
        my @abundance;

        open IN, $file or die;
	my $head=<IN>;
        while(<IN>)
#	ld50_inf{"CDR3-Peptide"}{$sample}=(split /\s+/,$d50_aa)[2];
        {
                chomp;
		my($count,$freq,$seq)=split /\t/,$_;
                push @abundance , $count;
                $all_num = $all_num + $count;
        }
        close IN;

        @abundance = sort {$b<=>$a} @abundance;
        my $half_abundance = 0;
	my $return;
        for(my $i=0 ; $i<=$#abundance ; $i++)
        {
                if($half_abundance < $all_num/2 && $half_abundance+$abundance[$i] >= $all_num/2){
			my $zuobiao=$i+1;
			my $d50=($i+1)*100/($#abundance+1);
#                        $return="$flag:\t",$i+1,"\t",($i+1)*100/($#abundance+1),"\n";
			$return="$flag:\t$zuobiao\t$d50\n";
                        last;
                }
                $half_abundance += $abundance[$i];
        }
	return $return;
}
