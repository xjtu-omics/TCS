#!/usr/bin/perl

use warnings;
use strict;
use FindBin '$Bin';
use Cwd 'abs_path';
use Getopt::Long;
use File::Basename;
use File::Path;
use Data::Dumper;
use lib $Bin;

sub usage {
	 print STDERR << "USAGE";
description: align -> score -> stat analysis
author: lyf10182\@126.com
date: 20180413
modified:
usage: perl $0 [options]
options:
	-infile:	<str>	infile     #处理后的标准化输入文件 #1、VJ pair 2、AA tag 3、AA freq
	-stand:		<str>   Y/N        #标明输入文件是否经过标准化处理
	-outdir:	<str>	outdir 
	-sample:	<str>	sample name
	-help|?:    <str>	print help information

e.g.:
	perl $0 -infile high.*.vjaa.xls -outdir <outdir> -sample <sample_name>
USAGE
	 exit 1;
}

my($file,$stand,$outdir,$sample_name,$help);
GetOptions(
	"infile:s" => \$file,
	"stand:s"  => \$stand,
	"outdir:s" => \$outdir,
	"sample:s" => \$sample_name,
	"help|?" => \$help,
);

die &usage() if (!defined $file || !defined $stand ||!defined $outdir || !defined $sample_name || $help);

#my $file=shift;
#my $outdir=shift;
#my $sample_name=shift;


my $blosum62="$Bin/../Database/BLOSUM62.xls";  #BLOSUM62数据表 http://www.uky.edu/Classes/BIO/520/BIO520WWW/blosum62.htm

mkdir $outdir unless -e $outdir;
my $stat_file="$outdir/$sample_name.FSN.stat.xls";
open STAT,">$stat_file" or die $!;
print STAT "VJpair\tEntropy\tNum\tFreq\n";
$outdir="$outdir/$sample_name";
mkdir $outdir unless -e $outdir;

my %BLSM62=();    ##存储BLOSUM62蛋白打分矩阵信息
open IN,$blosum62 or die "File $blosum62 is not exists!";
my $BL_head=<IN>;
chomp $BL_head;
my @Pipetid=split /\s+/,$BL_head;
shift @Pipetid;
while(<IN>){
        chomp;
        my @d=split /\s+/,$_;
        my $pip=shift @d;
        for(my $i=0;$i<=$#Pipetid;$i++){
                my $id=$pip.$Pipetid[$i];
                $BLSM62{$id}=$d[$i];
        }
}
close IN;


if($stand eq "Y"){
	$file=$file;
}
else{
	print "pleast check -stand:$stand\n";
	exit;
}

open IN,$file or die $!;  #处理后的标准化输入文件 #1、VJ pair 2、AA tag 3、AA freq
my %family=();  #存储vj对应AA信息
my %Freq=();    #存储AA对应Freq信息
while(<IN>){
	chomp;
	my($vj,$aa,$freq)=split /\s+/,$_;
	$vj=~s/:/_/g if $vj=~/:/;
	$family{$vj}{$aa}=$freq;
	$Freq{$vj}+=$freq;
}
close IN;

#my %Dis_Array=();  #存储距离信息
foreach my $vj(keys %family){
	my @AA=keys %{$family{$vj}};
	
	my $out_vj_dist="$outdir/$sample_name.$vj.AAdist.xls";       #存每个家族TCR距离矩阵
	my $out_vj_align="$outdir/$sample_name.$vj.AA.Align.aln";    #存每个家族TCR比对结果
	
	open OVJA,">$out_vj_align" or die $!;
	open OVJD,">$out_vj_dist" or die $!;
	
	print OVJD "AA\t";           #输出表头
	print OVJD join "\t",@AA;    
	print OVJD "\n";
	
	if($#AA < 1){
		print OVJD "$AA[0]\t0\n";
		print OVJA "$AA[0]\n$AA[0]\n";
		close OVJD;
		close OVJA;
	}
	else{
	my %Dis_Array=();  #存储距离信息
	for(my $i=0;$i<=$#AA;$i++){
		$Dis_Array{$AA[$i]}{$AA[$i]}=0;    #相同肽段距离为0；
#		print OVJD "$AA[$i]\t";
		for(my $j=$i+1;$j<=$#AA;$j++){
			if($AA[$i] eq "" || $AA[$j] eq ""){
				print "$i\t$j\n";
			}
			my $align_aa=&needleman_wunsch($AA[$i],$AA[$j]);   #两个序列的比对
			
			print OVJA "$align_aa\n\n";
			
			my ($tag1,$tag2)=split /\n/,$align_aa;
			my $length_tag=length($tag1);
			my $aadist=0;
			my @pip1=split //,$tag1;
			my @pip2=split //,$tag2;
			for(my $k=0;$k<$length_tag;$k++){
				if($pip1[$k] eq $pip2[$k]){
					$aadist+=0;   ##dist(a，a)=0;
				}
				else{
					if($pip1[$k] eq "-" || $pip2[$k] eq "-" || $pip1[$k] eq "_" || $pip2[$k] eq "_" || $pip1[$k] eq "~" || $pip2[$k] eq "~" || $pip1[$k] eq "*" || $pip2[$k] eq "*"){
						$aadist+=8;   ##gap 罚分  dist(a,-)=8;
					}
					else{
						my $pp=$pip1[$k].$pip2[$k];
						if(exists $BLSM62{$pp}){
							$aadist+= 4 < (4-$BLSM62{$pp}) ? 4:(4-$BLSM62{$pp});  ##错配罚分 在固定4分与BLOSUM62中择小
						}
						else{
							print "$pp\n";
						}
					}
				}
			}
			$Dis_Array{$AA[$i]}{$AA[$j]}=$aadist;
#			$Dis_Array{$AA[$j]}{$AA[$i]}=$aadist;
#			print OVJD "$aadist\t";
		}
#		print OVJD "\n";		
	}
	my %TCRdist=();    ##存储距离矩阵中每个元素的信息 用于计算Shannon
	my $dist_num=0;    ##存储距离矩阵中AA个数
#	my $SumDist=0;     ##距离总和
#	foreach my $taa(keys %Dis_Array){
	for(my $ii=0;$ii<=$#AA;$ii++){
		my $taa=$AA[$ii];
		print OVJD "$taa\t";
		$dist_num++;
#		foreach my $maa(keys %{$Dis_Array{$taa}}){
		for(my $jj=0;$jj<=$#AA;$jj++){
			my $maa=$AA[$jj];
			my $dist=0;
			$dist=$Dis_Array{$taa}{$maa} if exists $Dis_Array{$taa}{$maa};
			$dist=$Dis_Array{$maa}{$taa} if exists $Dis_Array{$maa}{$taa};
			$Dis_Array{$maa}{$taa}=$dist if !exists $Dis_Array{$maa}{$taa};  ##矩阵对角线反向赋值
			$Dis_Array{$taa}{$maa}=$dist if !exists $Dis_Array{$taa}{$maa};  ##矩阵对角线反向赋值
			print OVJD "$dist\t";
			$TCRdist{$dist}++;
#			$SumDist+=$dist;
		}
		print OVJD "\n";
	}
	close OVJA;
	close OVJD;
	
	my @transTCRdist=();
	foreach my $dd(keys %TCRdist){
		push @transTCRdist,$TCRdist{$dd}/($dist_num*$dist_num);
	}
	
	my $shannon_die=0;
	if($dist_num == 1){
		$shannon_die = 1;  ##家族中只有一个AA序列 其多样性赋最小值1；
	}
	else{
		$shannon_die=&Shannon(\@transTCRdist)
	}
	print STAT "$vj\t$shannon_die\t$dist_num\t$Freq{$vj}\n";
	}
}
close STAT;


sub Shannon{
        my $a=shift;
        my $res=0;

        my $l=$#$a+1;
        for(my $i=0;$i<$l;$i++){
                if($$a[$i]!=0){
                        $res=$res+$$a[$i]*log($$a[$i]);
                }
        }
        return (-$res);
}

sub needleman_wunsch{     ##needleman_wunsch 算法 两个序列比对
	my $str1=shift;
	my $str2=shift;
	
	my @seq1=split //,$str1;
	my @seq2=split //,$str2;

##赋予打分值##	
	my $mis=-1;
	my $mat=1;
	my $gap=-2;
	
	if($str1 eq "" || $str2 eq ""){
		print "Please Check $str1 or $str2\n";     # 序列为空
		return 0;
	}
	else{
		my $m=length($str1);
		my $n=length($str2);
		my @score=();
		my @check=();
		
		#print "$m\t$n\n";
		
		for(my $i=0;$i<1;$i++){
			for(my $j=0;$j<=$m;$j++){
				$score[$i][$j]= $gap*$j;   #第0行初始化
			}
		}
		for(my $i=0;$i<=$n;$i++){
			for(my $j=0;$j<1;$j++){
				$score[$i][$j]= $gap*$i;   #第0列初始化
			}
		}
##通过比较给打分矩阵赋予新值		
		for(my $i=1; $i<=$n;$i++){
			my $base2=$seq2[$i-1];
			for(my $j=1;$j<=$m;$j++){
				my $base1=$seq1[$j-1];
				my $diagonal=0;		   #对角线赋值初始化
				if($base1 eq $base2){
					$diagonal=$score[$i-1][$j-1]+$mat;
				}
				else{
					$diagonal=$score[$i-1][$j-1]+$mis;
				}
				my $left=$score[$i-1][$j]+$gap;       #当前对角值的上方区块赋值
				my $up=$score[$i][$j-1]+$gap;     #当前对角值的左方区块赋值
				#print "$diagonal\t$up\t$left\n";
				$score[$i][$j]=&Max($diagonal,$up,$left);
				
				$check[$i][$j]=1 if $score[$i][$j] == $diagonal;
				$check[$i][$j]=2 if $score[$i][$j] == $left;
				$check[$i][$j]=3 if $score[$i][$j] == $up;

				#print "$check[$i][$j]\t";
			}
			#print "\n";
		}
##标记矩阵中，寻找最优路径标记
		my $ci=$n;
		my $cj=$m;
		my $k=0;
		my @align1=();
		my @align2=();
		
		while(1){
			if($ci>0 && $cj>0){
				if($check[$ci][$cj] == 1){
					$align2[$k]=$seq2[$ci-1];
					$align1[$k]=$seq1[$cj-1];
					$k++;
					$ci--;
					$cj--;
					next;
				}
				elsif($check[$ci][$cj] == 2){
					$align2[$k]=$seq2[$ci-1];
					$align1[$k]="-";
					$k++;
					$ci--;
					next;
				}
				elsif($check[$ci][$cj] == 3){
					$align2[$k]="-";
					$align1[$k]=$seq1[$cj-1];
					$k++;
					$cj--;
					next;
				}
				else{
					last;
				}
			}
			elsif($ci!=0 && $cj==0){
				$align2[$k]=$seq2[$ci-1];
				$align1[$k]="-";
				$k++;
				$ci--;
			}
			elsif($ci==0 && $cj!=0){
				$align1[$k]=$seq1[$cj-1];
				$align2[$k]="-";
				$k++;
				$cj--;
			}
			elsif($ci==0 && $cj==0){
				last;
			}
		}
		
		@align1=reverse(@align1);
		@align2=reverse(@align2);
		
		my $Result_Align=join "",@align1;
		$Result_Align.="\n";
		$Result_Align.=join "",@align2;
		
		return $Result_Align;
	}
}

sub Max{
	my $mx=$_[0];
	for my $e(@_){$mx = $e if $e > $mx;}
	return $mx;
}
