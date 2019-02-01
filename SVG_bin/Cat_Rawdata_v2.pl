#!/usr/bin/perl

if(@ARGV!=4){
	print "perl $0 <fq_dir>	<out_dir> <bms.xls> <sub-project>\n";
	print "eg:	perl $0 /nas/fqdata013/data/F14FTSNWKF0636_CHIedfT/ /ifswh1/BC_Asia/liuyf/Project/edf140911_F14FTSNWKF0636_CHIedfT/rawdata /ifswh1/BC_Asia/liuyf/Project/edf140911_F14FTSNWKF0636_CHIedfT/bms.xls CHIedfT\n";
	exit 0;
}

my $rawdata_fq_dir=shift;
my $out_dir=shift;
my $bms=shift;
my $P=shift;
#9       F0-C-1A WHCHIedfTAAARAAPEI-8    SHK14092615     2014-9-29       HS171   FCC5EKDACXX     2
#15      F0-C-1A WHCHIedfTAAARAAPEI-8    SHK14092615     2014-9-29       HS171   FCC5EKDACXX     1
#13      F0-C-2A WHCHIedfTAAFRAAPEI-14   SHK14092615     2014-9-29       HS171   FCC5EKDACXX     2
#35      F0-C-2A WHCHIedfTAAFRAAPEI-14   SHK14092615     2014-9-29       HS171   FCC5EKDACXX     1
#18      F0-C-3A WHCHIedfTAAKRAAPEI-19   SHK14092615     2014-9-29       HS171   FCC5EKDACXX     3
#30      F0-C-3A WHCHIedfTAAKRAAPEI-19   SHK14092615     2014-9-29       HS171   FCC5EKDACXX     4
mkdir $out_dir unless -e $out_dir;
#140925_I806_FCC560PACXX_L8_WHCHIedfTABBRAAPEI-88
my %sample_inf=();
my %wenku_inf=();
open IN,$bms or die $!;
while(<IN>){
	chomp;
	my @dd=split /\s+/,$_;
	my($y,$m,$d)=split /-/,$dd[4];
	$y=14 if $y==2014;
	if($m!=10 && $m!=11 && $m!=12 && length($m)==1){
		$m="0$m";
	}
	if($d<10 && length($d)==1){
		$d="0$d";
	}
	my $day="$y$m$d";
	$dd[5]=~s/^HS/I/;
	$dd[5]=~s/^WH/I/;
	my $id="$day\_$dd[5]\_$dd[6]\_L$dd[-1]\_$dd[2]";
#	print "$id\n";
	$sample_inf{$dd[1]}{$id}=0;
	$wenku_inf{$id}=$dd[1];
}
close IN;

opendir DIR, $rawdata_fq_dir or die $!;
my @flowcell=grep{!/\.$/ && !/bms$/ && !/xls$/} readdir(DIR);
closedir DIR;

my %fq=();

foreach my $flow(@flowcell){
	my $lane_dir="$rawdata_fq_dir/$flow/";
	print "$lane_dir\n";
	opendir LDIR,$lane_dir or die $!;
	my @wenku=grep{!/\.$/ && !/bms$/ && !/xls$/} readdir(LDIR);
	closedir LDIR;
	foreach my $id(@wenku){
		if(exists $wenku_inf{$id} && $sample_inf{$wenku_inf{$id}}{$id}==0){
	#		print "fdafda";
			my @fq=();
			my @fq_name=();
			foreach my $wen(keys %{$sample_inf{$wenku_inf{$id}}}){
				my $fq1="$lane_dir/$wen/$wen\_1.fq.gz";
				my $fq2="$lane_dir/$wen/$wen\_2.fq.gz";
				push @fq,$fq1;
				push @fq,$fq2;				
				push @fq_name,$wen;
				
				$sample_inf{$wenku_inf{$id}}{$wen}=1;
			}
			
			my $cat_dir="$out_dir/$fq_name[0]/";
                        mkdir $cat_dir unless -e $cat_dir;
                        my $cat_sh="$cat_dir/cat_cp.sh";
                        open SH,">$cat_sh" or die $!;

			print SH "cp $lane_dir/$fq_name[0]/1.* $cat_dir\n";
			print SH "cp $lane_dir/$fq_name[0]/2.* $cat_dir\n";
			print SH "cp $lane_dir/$fq_name[0]/*.png $cat_dir\n";
			print SH "cp $lane_dir/$fq_name[0]/*.report $cat_dir\n";
			print SH "cp $lane_dir/$fq_name[0]/report.htm $cat_dir\n";
			print SH "cat $fq[0] $fq[2] >$cat_dir/$fq_name[0]_1.fq.gz\n";
			print SH "cat $fq[1] $fq[3] >$cat_dir/$fq_name[0]_2.fq.gz\n";
			
			close SH;
			chdir $cat_dir;
			system("qsub -cwd -l vf=0.5G -P $P $cat_sh");		
			chdir $out_dir;
			
			$fq{$wenku_inf{$id}}->{'fq1'}="$cat_dir/$fq_name[0]_1.fq.gz";
			$fq{$wenku_inf{$id}}->{'fq2'}="$cat_dir/$fq_name[0]_2.fq.gz";
		}
		else{
			print "Error: $id is not exist!\n";
		}
	}	
}

open OUT,">$out_dir/../fq.lst" or die $!;
print OUT "##### 12.FASTQ path #####\n";

foreach my $name(keys %fq){
#	print OUT "##### 12.FASTQ path #####\n";
	print OUT "KeyName=$name\n";
	print OUT "length=90,90\ninsert=200\n";
	print OUT "q1=$fq{$name}->{'fq1'}\n";
	print OUT "q2=$fq{$name}->{'fq2'}\n\n";
}
close OUT;
my $num=keys %fq;
print "Finished: $num Samples\n";

