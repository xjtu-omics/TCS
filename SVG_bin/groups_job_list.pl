#!/usr/bin/perl
#!/bin/bash
use warnings;
use strict;
use Getopt::Long;

sub usage {
	print <<USAGE;
usage:
	perl $0 [options]
author
	nixiaoming   nixiaoming\@genomics.cn
description:
	look jobs info of group
options:
	-help: print help info
	-mem : get mem info
	-s :     1 or name : sort by name (default)
		     2 or job :  sort by jobs number
		     3 or vf :  sort by vf (need  -m )
		     4 or mem : sort by mem (need  -m )
		-t : if not sort by name ; you can choice jobs status for sort 
			     r   (default)
			     qw
			     eqw
e.g.:
	perl $0 dge_sr
	perl $0 dge_sr -mem
USAGE
}
my $Sort="name";
my $St="r";
my ($help,$mem);
GetOptions(
	"help"=>\$help,
	"mem"=>\$mem,
	"s=s"=>\$Sort,
	"t=s"=>\$St,
);
if (defined $help ||(@ARGV !=1)) {
	&usage();
	exit 0;
}
if ($Sort eq "1") {
	$Sort="name";
}elsif($Sort  eq "2"){
	$Sort="job";
}elsif($Sort eq "3"){
	$Sort="vf";
}elsif($Sort  eq "4"){
	$Sort="mem";
}
if ($Sort ne "vf" && $Sort ne "mem" && $Sort ne "name" && $Sort ne "job" ) {
	print STDERR <<SORt;
	-s :     1 or name : sort by name (default)
		     2 or job :  sort by jobs number
		     3 or vf :  sort by vf (need  -m )
		     4 or mem : sort by mem (need  -m )
SORt
		exit 0;
	if (!defined $mem &&  ($Sort eq "mem" || $Sort eq "vf" )) {
	print STDERR <<SORt;
	-mem : get mem info
	-s : 
		     3 or vf :  sort by vf (need  -m )
		     4 or mem : sort by mem (need  -m )
SORt
		exit 0;
	}
}

my $group=shift;
################## ȡ�� ���� group �ĳ�Ա����
my $cwd='awk -F ":" \'$1=="'.$group.'" {print $3}\' /etc/group';
my $group_id=`$cwd`;
if ($group_id eq '') {
	die "this group name $group not exists \n";
}
chomp $group_id;
$cwd='awk -F ":" \'$4=='.$group_id.' {print $1}\' /etc/passwd';
my $usr=`$cwd`;
if ($usr eq ''){
	$cwd='awk -F ":" \'$1=="'.$group.'" {print $1}\' /etc/passwd';
	$usr=`$cwd`;
	if ($usr eq ''){
		print STDERR "can't find the  users in group $group \n";
		exit 1;
	}
}
chomp $usr;
my @usrname=split/\n/,$usr;
print scalar (@usrname)." users in group $group : \n";
$usr=~s/\n/,/g;
print $usr."\n";
#################ȡ�� ����group �ĳ�Ա�� ����������Ϣ ��������״̬ �����У�
my $listinfo=`qstat -u $usr`; ###�����˵� ���� ��Ϣ
my @task = split /\n/,$listinfo; 
shift @task ;shift @task ;
my %out=();##$out{�û���}
my %statue=();## ״̬
my %Queue=();### ���� 
my %Job=();
my %For_sort=();### Ϊ��sort ����¼һ�� sort ����Ϣ $For_sort{$name}=info for sort;

my $jobs='';
foreach my $job ( @task ) {
	$job=~s/^\s+//;
	my @tab=split /\s+/,$job;#### $tab[0] = job id ; $tab[3]= �û��� ; $tab[4] = ״̬ ; $tab[7] = ���� ;
	$statue{$tab[4]}=1;
	$Job{$tab[0]}{'status'}=$tab[4];
	$Job{$tab[0]}{'user'}=$tab[3];
	###### Ϊ��sort 
	if ($Sort eq "name") {
		$For_sort{$tab[3]}=$tab[3];
	}elsif($Sort eq "job" && $tab[4] eq $St){
		$For_sort{$tab[3]}++;
	}
	######
	$jobs.=$tab[0].',';
	if (exists $out{$tab[3]}{'status'}{$tab[4]} ) { ########���� ״̬
		$out{$tab[3]}{'status'}{$tab[4]}++;
	}else{
		$out{$tab[3]}{'status'}{$tab[4]}=1;
	}
	if ($tab[7]=~/(\S+)\@/) {
		my $queue=$1;
		$Queue{$queue}=1;
		$Job{$tab[0]}{'queue'}=$queue;
		if (exists $out{$tab[3]}{'queue'}{$queue}) {########## ����״̬ �������
			$out{$tab[3]}{'queue'}{$queue}++;
		}else{
			$out{$tab[3]}{'queue'}{$queue}=1;
		}
	}else{
	}
}

######################### ȡ�� ����group �ĳ�Ա�� ����������Ϣ �������ڴ� �������ڴ棬�� �����ڴ� > �����ڴ� �� ����id �������ڴ� - �����ڴ棩
my $overload=0;
if (defined $mem) {
	my $detail=`qstat -j $jobs`;###��ϸ�� ���� ������Ϣ
	my @jobinfos=split /={2,}/,$detail;####ÿ���������Ϣ
	foreach my $info (@jobinfos) {
		if ($info =~/job_number:\s+(\d+)/) {
			my $jobnum=$1;### job id
			my $user=$Job{$jobnum}{'user'};
			my $status=$Job{$jobnum}{'status'};
			my $hard_mem=0;
			if ($info =~/hard resource_list:\s+virtual_free=(\S+)\n/) {
				$hard_mem=$1;### ����� �ڴ�
				$hard_mem= MEM_GMKT ($hard_mem);
				### Ϊ�� sort 
				if ($Sort eq "vf" && $St eq $status) {
					$For_sort{$user}+=$hard_mem;
				}
				if (exists $out{$user}{'hard'}{'status'}{$status}) {
					$out{$user}{'hard'}{'status'}{$status}+=$hard_mem;
				}else{
					$out{$user}{'hard'}{'status'}{$status}=$hard_mem;
				}
				if (exists $Job{$jobnum}{'queue'}) {
					my $queue=$Job{$jobnum}{'queue'};
					if (exists $out{$user}{'hard'}{'queue'}{$queue}) {
						$out{$user}{'hard'}{'queue'}{$queue}+=$hard_mem;
					}else{
						$out{$user}{'hard'}{'queue'}{$queue}=$hard_mem;
					}
					my $vmem=0;
					while ($info =~/vmem=(\S+), maxvmem=\S+/g) {
						my $mmm=$1;
						if ($mmm ne 'N/A') {
							$vmem+=MEM_GMKT ($mmm);
						}
					}
					### Ϊ�� sort 
					if ($Sort eq "mem" && $St eq $status) {
						$For_sort{$user}+=$vmem;
					}
					my $over=$vmem-$hard_mem;
					if ($over >0) {
						my $intover=(int (10*$over+0.5))/10;
						if (exists $out{$user}{'overid'}) {
							$out{$user}{'overid'}.=','.$jobnum;
							$out{$user}{'overmem'}.=','.$intover;
							$out{$user}{'overnum'}+=1;
							$out{$user}{'totalover'}+=$over;
						}else{
							$out{$user}{'overid'}=$jobnum;
							$out{$user}{'overmem'}=$intover;
							$out{$user}{'overnum'}=1;
							$out{$user}{'totalover'}=$over;
						}
						$overload++;
					}
					if (exists $out{$user}{'mem'}{'queue'}{$queue}) {
						$out{$user}{'mem'}{'queue'}{$queue}+=$vmem;
					}else{
						$out{$user}{'mem'}{'queue'}{$queue}=$vmem;
					}
					if (exists $out{$user}{'mem'}{'status'}{$status}) {
						$out{$user}{'mem'}{'status'}{$status}+=$vmem;
					}else{
						$out{$user}{'mem'}{'status'}{$status}=$vmem;
					}
				}
			}
		}
	}
}
########################################################
########### sort
################################
my @sort_name=sort keys %For_sort;
if ($Sort ne "name") {
	foreach my $k (keys %out) {
		if (!exists $For_sort{$k}) {
			$For_sort{$k}=0;
		}
	}
	@sort_name=sort {$For_sort{$a} <=> $For_sort{$b}} keys %For_sort;
}


########################################################
########### ��� ��Ϣ 
################################
if (defined $mem) {
	printf "%11s",'user';
	print "\t".'number of jobs , vf (G) , vmem (G) '."\n"; 
}
printf "%11s",'user';
my %total=();
my ($stat,$que,$user);
########### ��� ��ͷ
foreach $stat (keys %statue) {
	print '  ';
	printf "%14s",$stat;
	$total{'status'}{$stat}=0;
	if (defined $mem) {
		$total{'hard'}{'status'}{$stat}=0;
		$total{'mem'}{'status'}{$stat}=0;
	}
}
foreach $que (keys %Queue) {
	print '  ';
	printf "%14s",$que;
	$total{'queue'}{$que}=0;
	if (defined $mem) {
		$total{'hard'}{'queue'}{$que}=0;
		$total{'mem'}{'queue'}{$que}=0;
	}
}
if ($overload>0) {
	print "\t"."over_jobs\tover_mem\t".'overload_id\'s'."\t".'overload_mem(G)';
}

print "\n";
######## group ����Ա ���� ��Ϣ
foreach $user (@sort_name ) {
	printf "%11s",$user;
	foreach $stat (keys %statue) { ######## ���� ״̬
		my $outtab='';
		if (exists $out{$user}{'status'}{$stat}) {
			$outtab.=$out{$user}{'status'}{$stat};
			$total{'status'}{$stat}+=$out{$user}{'status'}{$stat};
			if (defined $mem) {
				if (exists $out{$user}{'hard'}{'status'}{$stat}) {
					my $hard=(int (10*$out{$user}{'hard'}{'status'}{$stat} + 0.5))/10;
					$outtab.=','.$hard;
					$total{'hard'}{'status'}{$stat}+=$out{$user}{'hard'}{'status'}{$stat};
				}else{
					$outtab.=',-';
				}
				if (exists $out{$user}{'mem'}{'status'}{$stat}) {
					my $vmem=(int (10*$out{$user}{'mem'}{'status'}{$stat} + 0.5))/10;
					$outtab.=','.$vmem;
					$total{'mem'}{'status'}{$stat}+=$out{$user}{'mem'}{'status'}{$stat};
				}else{
					$outtab.=',-';
				}
			}
		}else{
			$outtab.='-';
			if (defined $mem) {
				$outtab.=',-,-';
			}
		}
		print '  ';
		printf "%14s",$outtab;
	}
	foreach $que (keys %Queue) { ########## ����״̬ ���������
		my $outtab='';
		if (exists $out{$user}{'queue'}{$que} ) {
			$outtab.=$out{$user}{'queue'}{$que};
			$total{'queue'}{$que}+=$out{$user}{'queue'}{$que};
			if (defined $mem) {
				if (exists $out{$user}{'hard'}{'queue'}{$que}) {
					my $hard=(int (10*$out{$user}{'hard'}{'queue'}{$que} + 0.5))/10;
					$outtab.=','.$hard;
					$total{'hard'}{'queue'}{$que}+=$out{$user}{'hard'}{'queue'}{$que};
				}else{
					$outtab.=',-';
				}
				if (exists $out{$user}{'mem'}{'queue'}{$que}) {
					my $vmem=(int (10*$out{$user}{'mem'}{'queue'}{$que} + 0.5))/10;
					$outtab.=','.$vmem;
					$total{'mem'}{'queue'}{$que}+=$out{$user}{'mem'}{'queue'}{$que};
				}else{
					$outtab.=',-';
				}
			}
		}else{
			$outtab.='-';
			if (defined $mem) {
				$outtab.=',-,-';
			}
		}
		print '  ';
		printf "%14s",$outtab;
	}
	if ($overload>0) {
		if (exists $out{$user}{'overid'} ) {
			print "\t".$out{$user}{'overnum'}."\t".(int(10*$out{$user}{'totalover'}+0.5)/10)."\t".$out{$user}{'overid'}."\t".$out{$user}{'overmem'};;
		}else{
			print "\t".'---'."\t".'---'."\t".'---'."\t".'---';
		}
	}
	print "\n";
}
printf "%11s",'total';

############��� total 
foreach $stat (keys %statue) {
	my $outtab='';
	$outtab.=$total{'status'}{$stat};
	if (defined $mem) {
		my $hard=(int(10*$total{'hard'}{'status'}{$stat}+0.5))/10;
		$outtab.=','.$hard;
		my $vmem=(int(10*$total{'mem'}{'status'}{$stat}+0.5))/10;
		$outtab.=','.$vmem;
	}
	print '  ';
	printf "%14s",$outtab;
}
foreach $que (keys %Queue) {
	my $outtab='';
	$outtab.=$total{'queue'}{$que};
	if (defined $mem) {
		my $hard=(int(10*$total{'hard'}{'queue'}{$que}+0.5))/10;
		$outtab.=','.$hard;
		my $vmem=(int(10*$total{'mem'}{'queue'}{$que}+0.5))/10;
		$outtab.=','.$vmem;
	}
	print '  ';
	printf "%14s",$outtab;

}
print "\n";


####################################################
############# ���ڴ� ת����λ Ϊ G 
###########################################
sub MEM_GMKT{
	my $num=shift;
	if ($num=~/(\S+)g/i) {
		$num=$1;
	}elsif ($num=~/(\S+)m/i) {
		$num=$1/1024;
	}elsif ($num=~/(\S+)k/i) {
		$num=$1/1048576;## 1048576 =1024*1024
	}elsif ($num=~/(\S+)t/i) {
		$num=$1*1024;## 
	}else{
	}
	return $num;
}


