#!/usr/bin/perl
use strict;
use warnings;

if(@ARGV!=2){
        print "Usage: perl $0 <project_dir> <Config>\n";
        exit 0;
}


my $project_dir=shift;
my $Config=shift;


my $out_dir="$project_dir/Result/06.UsageStat";
mkdir $out_dir unless -e $out_dir;

open LST,">$out_dir/team.lst" or die $!;
my @samples=();
open IN,$Config or die $!;
while(<IN>){
	chomp;
	if(s/^Sample\s*=\s*//g){
#		chomp;
		push @samples,$_;
	}
	if(s/^Group\s+//g){
#		chomp;
		my $lst=$_;
		$lst=~s/=/:\t/g;
		$lst=~s/,/\t/g;
		print LST "$lst\n";
		print "$lst\n";
	}
}
close IN;
print "Samples: ";
print join "\t",@samples;
print "\n";

my %V_usage=();
my %J_usage=();
my %D_usage=();

my %v_sum=();
my %j_sum=();
my %d_sum=();

foreach my $sample(@samples){
	my $vdj_file="$project_dir/Result/02.Alignment/$sample/$sample.align.xls";
	print "Load file: $vdj_file\n";
	open VDJ,$vdj_file or die $!;
	while(<VDJ>){
		chomp;
		next if /^MiTCR/ || /^Read/;
		my @data=split /\t/,$_;
	
		my $clone=$data[0];
		
		my $v_inf=$data[7];
		my $j_inf=$data[9];
		my $d_inf=$data[11];
		
		my $v_num=($v_inf=~s/,/\t/g);
		my $j_num=($j_inf=~s/,/\t/g);
		my $d_num=($d_inf=~s/,/\t/g);
		
		if($d_num<=2){
			my @dd=split /\s+/,$d_inf;
			foreach my $d(@dd){
				$D_usage{$d}{$sample}+=$clone;
				$d_sum{$sample}+=$clone;
			}
		}
		if($v_num<=2){
                        my @vv=split /\s+/,$v_inf;
                        foreach my $v(@vv){
                                $V_usage{$v}{$sample}+=$clone;
                                $v_sum{$sample}+=$clone;
                        }
                }
		if($j_num<=2){
                        my @jj=split /\s+/,$j_inf;
                        foreach my $j(@jj){
                                $J_usage{$j}{$sample}+=$clone;
                                $j_sum{$sample}+=$clone;
                        }
                }
	}
}

my $v_clone="$out_dir/V_family_usage.xls";
my $v_freq="$out_dir/V_family_usage_frequency.xls";

my $d_clone="$out_dir/D_family_usage.xls";
my $d_freq="$out_dir/D_family_usage_frequency.xls";

my $j_clone="$out_dir/J_family_usage.xls";
my $j_freq="$out_dir/J_family_usage_frequency.xls";

&Print_Clone(\%V_usage,"V",$v_clone,\%v_sum,\@samples);
&Print_Clone(\%J_usage,"J",$j_clone,\%j_sum,\@samples);
&Print_Clone(\%D_usage,"D",$d_clone,\%d_sum,\@samples);

&Print_Freq_Clone(\%V_usage,"V",$v_freq,\%v_sum,\@samples);
&Print_Freq_Clone(\%J_usage,"J",$j_freq,\%j_sum,\@samples);
&Print_Freq_Clone(\%D_usage,"D",$d_freq,\%d_sum,\@samples);

#########################  Draw Usage  ##############################
my $bar_graph="/ifswh1/BC_Asia/liuyf/user/liuyf/bin/Frequency_bar_graph_v3.pl";
system("perl $bar_graph $v_freq $out_dir/team.lst $out_dir V");
system("perl $bar_graph $d_freq $out_dir/team.lst $out_dir D");
system("perl $bar_graph $j_freq $out_dir/team.lst $out_dir J");
#########################  Draw Usage  ##############################

sub Print_Clone{
	my ($usage,$type,$clone,$sum,$sample)=@_;
	open OUT,">$clone" or die $!;
	print OUT "$type\_Family\t";
	print OUT join "\t",@$sample;
	print OUT "\n";
	my $sample_num=@$sample;
#	print "$sample_num\n";
	foreach my $vdj(keys %$usage){
		print OUT "$vdj\t";
		for(my $i=0;$i<$sample_num;$i++){
			if(exists $usage->{$vdj}{$sample->[$i]}){
				print OUT $usage->{$vdj}{$sample->[$i]}."\t";
			}
			else{
				print OUT "0\t";
			} 
		}
		print OUT "\n";
	}
	print OUT "Total_Uniq\t";
	for(my $i=0;$i<$sample_num;$i++){
		print OUT "$sum->{$sample->[$i]}\t";
	}
	print OUT "\n";
	close OUT;
}

sub Print_Freq_Clone{
        my ($usage,$type,$clone,$sum,$sample)=@_;
        open OUT,">$clone" or die $!;
        print OUT "$type\_Family\t";
        print OUT join "\t",@$sample;
	print OUT "\n";
	my $sample_num=@$sample;
        foreach my $vdj(keys %$usage){
                print OUT "$vdj\t";
                for(my $i=0;$i<$sample_num;$i++){
                        if(exists $usage->{$vdj}{$sample->[$i]}){
#				print "$usage->{$vdj}{$sample->[$i]}\n";
				my $inf=sprintf "%.6f",($usage->{$vdj}{$sample->[$i]}/$sum->{$sample->[$i]});
#                                print OUT $usage{$vdj}{$samples[$i]}."\t";
				print OUT "$inf\t";
                        }
                        else{
                                print OUT "0\t";
                        }
                }
                print OUT "\n";
        }
	close OUT;
}

