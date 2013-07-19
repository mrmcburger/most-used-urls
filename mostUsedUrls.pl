#!/usr/bin/perl
################################################################################
# Migeon Cyril                                                                 #
# 2013/07/19                                                                   #
#                                                                              #
# Script taking a common log format file in parameter and processing it to see #
# which are the most requested urls                                            #
################################################################################                

use strict;
use Regexp::Log::Common;
use Chart::Gnuplot;
use Getopt::Std;

sub usage()
{
	print STDERR <<EOF;
Script taking a common log format file in parameter and processing it to see which are the most requested urls  

usage: $0 [-ph] [-f file]
	-h        : this (help) message
	-f file   : file containing the logs (mandatory)
	-p        : plot the results graph
EOF
    exit;
}

my %options=();
getopts("f:ph", \%options);
usage() if $options{h} || !defined($options{f});

my $logfile = $options{f};

die 'Logfile not found' unless -e $logfile;

open(LOGFILE, $logfile) || die ("Error while opening the file") ;

my $regex = Regexp::Log::Common->new(format  => ':common', capture => [qw( request )]);
my $re = $regex->regexp;
my @fields = $regex->capture;
my %requestHash;
my @urls;
my @urlsCount;

while(<LOGFILE>)
{
    my %data;
    @data{@fields} = /$re/;
    $data{'request'} =~ s/.*GET (.*) HTTP.*/\1/;

    if(exists($requestHash{$data{'request'}}))
    {
    	$requestHash{$data{'request'}}++;
    }
    else
    {
    	$requestHash{$data{'request'}} = 1;
    }
}

close(LOGFILE);

open(RESULTFILE, '>results.txt') || die ("Error while opening the results file") ;

foreach (sort{($requestHash{$b} <=> $requestHash{$a})} keys (%requestHash)) 
{
    print RESULTFILE "$_ : $requestHash{$_}\n";
    if($options{p})
    {
        push(@urls, $_) && push(@urlsCount, $requestHash{$_});
    }		
}

close(RESULTFILE);

# Works for a limited amount of requested urls
if($options{p})
{
	my $chart = Chart::Gnuplot->new(
	    output => "results.png",
	    title  => "Most $logfile requested urls",
	    xlabel => "Url",
	    ylabel => "Request count"
	);

	my $dataSet = Chart::Gnuplot::DataSet->new(
	    xdata => \@urls,
	    ydata => \@urlsCount,
	    using => "2:xticlabels(1)",
	    style => "histograms",
	);

	$chart->plot2d($dataSet);
}
