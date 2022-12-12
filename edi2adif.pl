#!/usr/bin/perl -w

# George Smart, M1GEO
# Simple EDI to ADIF Converter for parsing RSGB Contest Results
# for use with Cloudlog.
# 21 May 2012 - Free software under GNU GPL. (Uploaded to GitHub 12/12/2022)

use strict;
use warnings;

# Don't buffer output.
$| = 1;

# Files
my $INFILE = "";
my $OUTFILE = "";

# Station Details
my $ContestName  = "";
my $ContestCall  = "";
my $ContestClub  = "";
my $ContestLoc   = "";
my $ContestClass = "";
my $ContestRmrk  = "";

# Contest Details
my $ContestBand = "2m";
my $ContestMode = "SSB";

# Stats
my $QSOsRead = 1;
my $LinesRead= 1;
my $QSOsWrote= 1;
my $LinesWrote= 1;

# Main data
my @QSOData;

print ("George Smart, M1GEO\n");
print ("EDI to ADIF Converter for parsing RSGB Contest Results for use with Cloudlog.\n");
print ("21 May 2012 - Free software under GNU GPL.\n\n");

unless ((($ARGV[0]) && ($ARGV[1]))||($#ARGV > 1)) {
	print ("* Syntax Error.\n");
	print ("$0 <input_edi> <output_adi>\n");
	exit(2);
}

$INFILE = "$ARGV[0]";
$OUTFILE = "$ARGV[1]";

open (INFILE, "<", $INFILE) or die("Could not open input file, \"$INFILE\".\n");
open (OUTFILE, ">", $OUTFILE) or die("Could not open output file, \"$OUTFILE\".\n");

print ("* Reading in \"$INFILE\": ");

while (my $line = <INFILE>) {
	
	#Remove \n from line.
	chomp($line);
	
	#ContestName
	if ($line =~ m/^TName/i) {$ContestName = $line; $ContestName =~ s/TName=//;}
	
	#ContestCall
	if ($line =~ m/^PCall/i) {$ContestCall = $line; $ContestCall =~ s/PCall=//;}
	
	#ContestClub
	if ($line =~ m/^PClub/i) {$ContestClub = $line; $ContestClub =~ s/PClub=//;}
	
	#ContestLocator
	if ($line =~ m/^PWWLo/i) {$ContestLoc = $line; $ContestLoc =~ s/PWWLo=//;}
	
	#ContestClass
	if ($line =~ m/^PSect/i) {$ContestClass = $line; $ContestClass =~ s/PSect=//;}
	
	#ContestRemarks
	if ($line =~ m/^\[Remarks\]/i) {
		my $nextline = <INFILE>; # read the next line for the remark!
		$LinesRead++;
		chomp($nextline);
		$ContestRmrk = $nextline;
	}
	
	#QSOs
	if ($line =~ m/^\[QSORecords/i) {
		while (my $QSOline = <INFILE>) {
			$LinesRead++;
			chomp($QSOline);
			# date;time;callsign;??;hisrpt;hisserial;ourrpt;ourserial;??;locator;distance;??;??;??;??
			my ($QSOdate, $QSOtime, $QSOcallsign, $QSOunknownA, $QSOtxRST, $QSOtxSER, $QSOrxRST, $QSOrxSER, $QSOunknownB, $QSOlocator, $QSOdistance, $QSOunknownC, $QSOunknownD, $QSOunknownE, $QSOunknownF) = split(";", $QSOline);
			if ($QSOcallsign) {
				push @QSOData, [$QSOdate, $QSOtime, $QSOcallsign, $QSOunknownA, $QSOtxRST, $QSOtxSER, $QSOrxRST, $QSOrxSER, $QSOunknownB, $QSOlocator, $QSOdistance, $QSOunknownC, $QSOunknownD, $QSOunknownE, $QSOunknownF];
				$QSOsRead++;
			}
		}
	}
		
	#Stats
	$LinesRead++;
}

print ("Finished Reading: $QSOsRead QSOs processed from $LinesRead lines.\n");

print ("* Writing to \"$OUTFILE\": ");

print (OUTFILE "<ADIF_VERS:3>2.2\n");
print (OUTFILE "<<PROGRAMID:24>M1GEO EDI-ADIF Converter\n");
print (OUTFILE "<PROGRAMVERSION:9>Version 1\n");
print (OUTFILE "<EOH>\n\n");
$LinesWrote+=5;

my $QSORecord = "";
foreach $QSORecord (@QSOData) {
	# Get element from array
	my ($QSOdate, $QSOtime, $QSOcallsign, $QSOunknownA, $QSOtxRST, $QSOtxSER, $QSOrxRST, $QSOrxSER, $QSOunknownB, $QSOlocator, $QSOdistance, $QSOunknownC, $QSOunknownD, $QSOunknownE, $QSOunknownF) = @$QSORecord;
	
	# Made the date full.
	$QSOdate = "20" . $QSOdate;
	
	# Lowercase the QRA last two letters.
	if (length($QSOlocator) == 6) {	
		my @QRAChars = split(//, $QSOlocator);
		my $QSOlocatorN = uc($QRAChars[0]) . uc($QRAChars[1]) . $QRAChars[2] . $QRAChars[3] . lc($QRAChars[4]) . lc($QRAChars[5]);
		$QSOlocator = $QSOlocatorN;
	}
	
	# write the data out
	print (OUTFILE "<call:" . length($QSOcallsign) . ">" . $QSOcallsign);
	print (OUTFILE "<band:" . length($ContestBand) . ">" . $ContestBand);
	print (OUTFILE "<mode:" . length($ContestMode) . ">" . $ContestMode);
	print (OUTFILE "<qso_date:" . length($QSOdate) . ">" . $QSOdate);
	print (OUTFILE "<time_on:" . length($QSOtime) . ">" . $QSOtime);
	print (OUTFILE "<time_off:" . length($QSOtime) . ">" . $QSOtime); # not needed.
	print (OUTFILE "<rst_rcvd:" . length($QSOrxRST) . ">" . $QSOrxRST);
	print (OUTFILE "<rst_sent:" . length($QSOtxRST) . ">" . $QSOtxRST);
	print (OUTFILE "<srx:" . length($QSOrxSER) . ">" . $QSOrxSER);
	print (OUTFILE "<stx:" . length($QSOtxSER) . ">" . $QSOtxSER);
	print (OUTFILE "<gridsquare:" . length($QSOlocator) . ">" . $QSOlocator);
	print (OUTFILE "<eor>\n");
	
	
	
	$LinesWrote++;
	$QSOsWrote++;
}

print ("Finished Writing: $QSOsWrote QSOs processed into $LinesWrote lines.\n");

print ("\n* Summary:\n");
print ("Contest Name     : $ContestName\n");
print ("Contest Band     : $ContestBand\n");
print ("Contest Mode     : $ContestMode\n");
print ("Station Callsign : $ContestCall\n");
print ("Club Name        : $ContestClub\n");
print ("Station Locator  : $ContestLoc\n");
print ("Station Class    : $ContestClass\n");
print ("Uploader Remarks : $ContestRmrk\n");

close(INFILE);
close(OUTFILE);

if ($QSOsWrote == $QSOsRead) {
	print ("\n* All records processed successfully.\n");
	exit (0);
} else {
	print ("\n* Some records were not converted correctly.  Check \"$OUTFILE\"!\n");
	exit (1);
}
