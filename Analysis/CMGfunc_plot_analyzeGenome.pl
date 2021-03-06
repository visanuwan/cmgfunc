#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Bio::SeqIO;
=put
#############################################################################
# Description
#############################################################################

# Tabs per line
printf $'hello\tworld\thugo\nfoo\tbar\nbaz\n' | awk -F$'\t' '{print NF-1;}'

#--------------------------------------------------------------
# Input source
#--------------------------------------------------------------

#--------------------------------------------------------------
# Input
#--------------------------------------------------------------

#--------------------------------------------------------------
# Output
#--------------------------------------------------------------

#--------------------------------------------------------------
# USAGE
#--------------------------------------------------------------

=cut

#.............. Get options ..............
#my ($res, $clancut, $gocut, $h);
my ($freqtablefiles, $h) = (undef,undef);
my ($freqcut,$percut,$width,$sdcut) = (10,0.5,20,1);
my $CMGfunc_path	= "/home/cmgfunc/CMGfunc/indirect";

#http://perldoc.perl.org/Getopt/Long.html#Options-with-multiple-values

&GetOptions ("freq=s" =>  \$freqtablefiles, "freqcut:f" => \$freqcut , "percut:f" => \$percut , "sdcut:f" => \$sdcut , "w:f" => \$width, "h|?" => \$h);

if (defined $h) { &usage }

#.............. Print usage ..............
sub usage {	
	print "#==================================================================================\n";
	printf ("%-40s:\t%-50s\n", "# USAGE", "Script takes one or more CMGfunc result tables generated by CMGfunc_analyzeGenome.pl");	
	printf ("%-40s:\t%-50s\n", "# Option", "-freqcut, frequency cutoff for plot. To plot all frequencies set -freqcut 0, default is 10");	
	printf ("%-40s:\t%-50s\n", "# Option", "-percut, percentage cutoff for plot. To plot all percentages set -percut 0, default is 0.5");	
	printf ("%-40s:\t%-50s\n", "# Option", "-sdcut, standard deviation across genomes cutoff for plot. To plot all functions set -sdcut 0, default is 1");	
	printf ("%-40s:\t%-50s\n", "# Option", "-w, sets the width of the plot, default is 20");	
	printf ("%-40s:\t%-50s\n", "# Option", "-w, should be adjusted if the plot does not fit into the PDF");		
	print "#==================================================================================\n";
	printf ("%-40s:\t%-50s\n", "# USAGE"  , "perl CMGfunc_plot_analyzeGenome.pl -freq <name of CMGfunc frequency table file>");	
	printf ("%-40s:\t%-50s\n", "# EXAMPLE", "perl CMGfunc_plot_analyzeGenome.pl -freq file.proteins.fsa.tab.vector.res.table");
	printf ("%-40s:\t%-50s\n", "# EXAMPLE", "perl CMGfunc_plot_analyzeGenome.pl -freq file.proteins.fsa.tab.vector.res.table -w 25 -freqcut 30");
	printf ("%-40s:\t%-50s\n", "# EXAMPLE", "perl CMGfunc_plot_analyzeGenome.pl -freq '*.proteins.fsa.tab.vector.res.table'");
	printf ("%-40s:\t%-50s\n", "# EXAMPLE", "perl CMGfunc_plot_analyzeGenome.pl -freq '*.proteins.fsa.tab.vector.res.table' -w 30 -freqcut 20");
	print "#==================================================================================\n";
	exit( 1 );	}

#.............. Input files and paths exists ..............

unless ($freqtablefiles)	{	
	print "#==================================================================================\n";
	printf ("%-40s:\t%-50s\n", "# ERROR", "CMGfunc frequency table file not defined, example: perl CMGfunc_plot_analyzeGenome.pl -freq file.fsa.tab.vector.res.table");
	&usage;	exit; }

my @freqtablefiles = glob("$freqtablefiles");
my $dirname = "multigenome_".scalar(@freqtablefiles).".PLOTS";
print "#==================================================================================\n";
printf ("%-40s:\t%-50s\n", "# RUNNING", "Input is a set of genomes, plots will be saved in $dirname") if scalar(@freqtablefiles) > 1;	
printf ("%-40s:\t%-50s\n", "# RUNNING", "Input is one genome, plots will be saved in ". $freqtablefiles[0]. ".PLOTS") if scalar(@freqtablefiles) == 1;	
print "#==================================================================================\n";


#....... Multi input..........
if (scalar(@freqtablefiles) > 1) {
	`rm -f _tmp  _tmpfunc`;

	for my $file (@freqtablefiles) {
		unless (-e $file) { printf ("%-40s:\t%-50s\n", "# ERROR", "File doesn't Exist!"); exit; } 
		`sed -i "s/'//" $file`;
		`grep -H -v "#" $file >> _tmp`;
		if (-e "_tmp")	{ `sed 's/\\./\t/1' _tmp >> _tmpfunc` } 
		else		{ printf ("%-40s:\t%-50s\n", "# WARNING", "No functions were detected in $file") }
	}
}

#....... Single input..........
elsif(scalar(@freqtablefiles) == 1) {
	my $file = $freqtablefiles[0];
	unless (-e $file) { printf ("%-40s:\t%-50s\n", "# ERROR", "File Doesn't Exist!"); exit; } 

	`rm -f _tmp  _tmpfunc`;
	`sed -i "s/'//" $file`;

	# create temporary file 
	`sed -i "s/'//" $file`;
	`grep -H -v "#" $file > _tmp`;
	if (-e "_tmp")	{ `sed 's/\\./\t/1' _tmp > _tmpfunc` } 
	else		{ printf ("%-40s:\t%-50s\n", "# WARNING", "No functions were detected in $file") }
}


#system("Rscript $CMGfunc_path/CMGfunc_plot_heatmaps.R _tmpfunc $freqcut $percut $widthsingle $widthmulti ");#>& /dev/null");
`Rscript $CMGfunc_path/CMGfunc_plot_heatmaps.R _tmpfunc $freqcut $percut $width $sdcut > /dev/null 2>&1`;

if (scalar(@freqtablefiles) > 1) {
	my $dirname = "multigenome_".scalar(@freqtablefiles).".PLOTS";
	my $file = "multigenome_".scalar(@freqtablefiles);
	`mkdir $dirname` unless (-d $dirname);
	printf ("%-40s:\t%-50s\n", "# INFO"  , "Saving plots to $dirname");	

	`mv plot_freqmultiple_bp.pdf $dirname/$file.freqmultiple_bp.pdf`;
	`mv plot_freqmultiple_cc.pdf $dirname/$file.freqmultiple_cc.pdf`;
	`mv plot_freqmultiple_mf.pdf $dirname/$file.freqmultiple_mf.pdf`;

	`mv plot_permultiple_bp.pdf $dirname/$file.permultiple_bp.pdf`;
	`mv plot_permultiple_cc.pdf $dirname/$file.permultiple_cc.pdf`;
	`mv plot_permultiple_mf.pdf $dirname/$file.permultiple_mf.pdf`;
	`mv _stats $dirname/DescriptiveStatistics.txt`; 
	`mv _tmp $dirname/DataTable.txt` 	;

}
elsif(scalar(@freqtablefiles) == 1) {
	my $file = $freqtablefiles[0];
	`mkdir $file.PLOTS` unless (-d $file.".PLOTS");
	printf ("%-40s:\t%-50s\n", "# INFO"  , "Saving plots to $file.PLOTS");	
	`mv plot_freqsingle_bp.pdf $dirname/$file.freqsingle_bp.pdf`;
	`mv plot_freqsingle_cc.pdf $dirname/$file.freqsingle_cc.pdf`;
	`mv plot_freqsingle_mf.pdf $dirname/$file.freqsingle_mf.pdf`;

	`mv plot_persingle_bp.pdf $dirname/$file.persingle_bp.pdf`;
	`mv plot_persingle_cc.pdf $dirname/$file.persingle_cc.pdf`;
	`mv plot_persingle_mf.pdf $dirname/$file.persingle_mf.pdf`;
	`mv _stats $dirname/DescriptiveStatistics.txt` ;
	`mv _tmp $dirname/DataTable.txt` 	;
}
`rm -f _tmp  _tmpfunc Rplots.pdf _stats`;




