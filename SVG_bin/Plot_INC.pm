# modify by zhuyuankun 2010-3-30: solve SVG convert to PNG promble while qsub; change line 55 to 59

package Plot_INC;
use strict;
use SVG;
use Exporter;
#use FindBin '$Bin';
use lib "/public/home/ybkliuyf/IR_seq_pipline/V1.1/bin/Exp_dif/";
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = qw(svg2png); ### default exported subroutine
@EXPORT_OK   = qw(); ### customed exported subroutine
%EXPORT_TAGS = ( DEFAULT =>[qw()], # the same as DEFAULT=>\@EXPROT
                 CUSTOMER => [qw()],
                 ALL =>[qw()]
                 
                ); 


my $batik_rasterizer="/public/home/ybkliuyf/IR_seq_pipline/V1.1/bin/Exp_dif/../../software/batik-rasterizer.jar";
sub svg2png
{
	my $svg_file=shift;
	my %para=@_;
	$para{'-bg'}='255.255.255.255'  unless($para{'-bg'});
	my @com_option=();
	while(my ($k,$v)=each %para)
	{
		if($k eq '-d' || $k eq 'd')
		{
			push @com_option,('-d',$v);
		}
		elsif($k eq '-m' || $k eq 'm')
		{
			push @com_option,('-m',$v);
		}
		elsif($k eq '-w' || $k eq 'w')
		{
			push @com_option,('-w',$v);
		}
		elsif($k eq '-h' || $k eq 'h')
		{
			push @com_option,('-h',$v);
		}
		elsif($k eq '-dpi' || $k eq 'dpi')
		{
			push @com_option,('-dpi',$v);
		}
                elsif($k eq '-bg' || $k eq 'bg')
                {
                        push @com_option,('-bg',$v);
                }					
        }
	my $com_opt=join("\t", @com_option);
#	open SHELL,">$svg_file.sh" or die;
#	print SHELL "/usr/java/jdk1.5.0_10/bin/java -Djava.awt.headless=true -jar $batik_rasterizer $com_opt $svg_file";
#	close SHELL;
#	system"sh $svg_file.sh;rm $svg_file.sh";
	system("/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.65-3.b17.el7.x86_64/bin/java -Djava.awt.headless=true -Xms15G -jar $batik_rasterizer $com_opt $svg_file");
#	system("rm $svg_file") if -e $svg_file;
}


1;
