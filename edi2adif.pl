#!/usr/bin/perl -w

# George Smart, M1GEO
# Simple EDI to ADIF Converter for parsing RSGB Contest Results
# for use with Cloudlog.
# 21 May 2012 - Free software under GNU GPL.
# Modified for generic EDI to ADIF conversion by Mario Roessler, DH5YM
# 11 Dec 2022 - Free software under GNU GPL.


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
my $ContestBand = "0cm";
my $ContestMode = "SSB";

# Stats
my $QSOsRead = 0;
my $LinesRead= 0;
my $QSOsWrote= 0;
my $LinesWrote= 0;
my $QSOError=0;

# Main data
my @QSOData;

#hash map for bands frequency conversion
my %bands = (  '50 MHz' => '6m',
	       '70 MHz' => '4m',
	       '144 MHz' => '2m',
	       '432 MHz' => '70cm',
	       '1,3 GHz' => '23cm',
	       '2,3 GHz' => '13cm',
	       '3,4 GHz' => '9cm',
	       '5,7 GHz' => '6cm',
	       '10 GHz' => '3cm',
	       '24 GHz' => '1.25cm',
	       '47 GHz' => '6mm',
	       '76 GHz' => '4mm',
	       '122 GHz' => '2.5mm',
	       '134 GHz' => '2mm',
	       '241 GHz' => '1mm',
	       '300 GHz' => 'submm'
		);
my $Band = '0cm';

# Hashmap for band to frequency conversion
my %frequencies = (  '50 MHz' => '50',
	       '70 MHz' => '70',
	       '144 MHz' => '144',
	       '432 MHz' => '432',
	       '1,3 GHz' => '1296',
	       '2,3 GHz' => '2320',
	       '3,4 GHz' => '3400',
	       '5,7 GHz' => '5760',
	       '10 GHz' => '10368',
	       '24 GHz' => '24048',
	       '47 GHz' => '47088',
	       '76 GHz' => '77500',
	       '122 GHz' => '122250',
	       '134 GHz' => '134928',
	       '241 GHz' => '241920',
	       '300 GHz' => 'submm'
		);
my $Frequency = '0';

# TX mode conversion table
my %txmodes = (
		'0' => 'NON',
		'1' => 'SSB',
		'2' => 'CW',
		'3' => 'CW',
		'4' => 'SSB',
		'5' => 'AM',
		'6' => 'FM',
		'7' => 'RTTY',
		'8' => 'SSTV',
		'9' => 'ATV'
);
# RX mode conversion table (not currently supported in ADIF)
my %rxmodes = (
		'0' => 'NON',
		'1' => 'SSB',
		'2' => 'CW',
		'3' => 'SSB',
		'4' => 'CW',
		'5' => 'AM',
		'6' => 'FM',
		'7' => 'RTTY',
		'8' => 'SSTV',
		'9' => 'ATV'
);


print ("George Smart, M1GEO\n");
print ("EDI to ADIF Converter for parsing RSGB Contest Results for use with Cloudlog.\n");
print ("21 May 2012 - Free software under GNU GPL.\n");
print ("Modified for generic EDI to ADIF conversion by Mario Roessler, DH5YM\n");
print ("09 Dec 2022 - Free software under GNU GPL.\n\n");

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
	if ($line =~ m/^TName/i) {
		$ContestName = $line; 
		$ContestName =~ s/TName=//;
		chomp $ContestName;
		$ContestName =~ s/\s+$//;
		}
	
	#ContestCall
	if ($line =~ m/^PCall/i) {$ContestCall = $line; $ContestCall =~ s/PCall=//;}
	
	#ContestClub
	if ($line =~ m/^PClub/i) {$ContestClub = $line; $ContestClub =~ s/PClub=//;}
	
	#ContestLocator
	if ($line =~ m/^PWWLo/i) {
		$ContestLoc = $line; 
		$ContestLoc =~ s/PWWLo=//;
		chomp $ContestLoc;
		$ContestLoc =~ s/\s+$//;
		}
	
	#ContestClass
	if ($line =~ m/^PSect/i) {$ContestClass = $line; $ContestClass =~ s/PSect=//;}

        #ContestBand and frequency
	if ($line =~ m/^PBand/i) {
		#print("\nHier!\n");
		#print($line);
		$ContestBand = $line;
		$ContestBand =~ s/PBand=//;
		#print("\n",$ContestBand,"\n");
		chomp($ContestBand);
		$ContestBand =~ s/\s+$//;
		#print($ContestBand);
		#print("\n Length: ",length($ContestBand),"\n");
		#if(exists $bands{$ContestBand}) {
		#	print("Key exists");};
		$Band = $bands{$ContestBand};
		#print("\nBand=",$Band,"\n");
		$Frequency = $frequencies{$ContestBand};
		$ContestBand = $Band;
		#print("\n--- Band ",$Band,"\n");
		#print("\n--- Frequency ", $Frequency,"\n");
	}

	#ContestRemarks
	if ($line =~ m/^\[Remarks\]/i) {
		my $nextline = <INFILE>; # read the next line for the remark!
		if($nextline =~ m/^\[QSORecords/i) { #in case there is no Remark in the remark section, just proceed
			print("\nNo Remarks in Remark section.\n");
			$line = $nextline;
		} else
		{   #if there is a remark line, then proceed normal
			$LinesRead++;
			chomp($nextline);
			$ContestRmrk = $nextline;
		}
	}
	
	#QSOs
	if ($line =~ m/^\[QSORecords/i) {
		print("processing log...\n");
		while (my $QSOline = <INFILE>) {
			$LinesRead++;
			chomp($QSOline);
			# date;time;callsign;mode;hisrpt;hisserial;ourrpt;ourserial;??;locator;distance;??;??;??;??
			my ($QSOdate, $QSOtime, $QSOcallsign, $QSOMode, $QSOtxRST, $QSOtxSER, $QSOrxRST, $QSOrxSER, $QSOunknownB, $QSOlocator, $QSOdistance, $QSOunknownC, $QSOunknownD, $QSOunknownE, $QSOunknownF) = split(";", $QSOline);
			if ($QSOcallsign && ($QSOcallsign ne 'ERROR')) {
				push @QSOData, [$QSOdate, $QSOtime, $QSOcallsign, $QSOMode, $QSOtxRST, $QSOtxSER, $QSOrxRST, $QSOrxSER, $QSOunknownB, $QSOlocator, $QSOdistance, $QSOunknownC, $QSOunknownD, $QSOunknownE, $QSOunknownF];
				$QSOsRead++;
			}
			if ($QSOcallsign && $QSOcallsign eq 'ERROR') {
				$QSOError++;
			}
		}
	}
		
	#Stats
	$LinesRead++;
}

print ("Finished Reading: $QSOsRead QSOs processed from $LinesRead lines.\n");

print ("* Writing to \"$OUTFILE\": ");

print (OUTFILE "<ADIF_VERS:3>3.1\n");
print (OUTFILE "<PROGRAMID:30>M1GEO+DH5YM EDI-ADIF Converter\n");
print (OUTFILE "<PROGRAMVERSION:9>Version 2\n");
print (OUTFILE "<EOH>\n\n");
$LinesWrote+=5;

my $QSORecord = "";
foreach $QSORecord (@QSOData) {
	# Get element from array
	my ($QSOdate, $QSOtime, $QSOcallsign, $QSOMode, $QSOtxRST, $QSOtxSER, $QSOrxRST, $QSOrxSER, $QSOunknownB, $QSOlocator, $QSOdistance, $QSOunknownC, $QSOunknownD, $QSOunknownE, $QSOunknownF) = @$QSORecord;
	
	# Made the date full.
	$QSOdate = "20" . $QSOdate;
	
	# Lowercase the QRA last two letters.
	if (length($QSOlocator) == 6) {	
		my @QRAChars = split(//, $QSOlocator);
		my $QSOlocatorN = uc($QRAChars[0]) . uc($QRAChars[1]) . $QRAChars[2] . $QRAChars[3] . lc($QRAChars[4]) . lc($QRAChars[5]);
		$QSOlocator = $QSOlocatorN;
	}

	# Convert QSO Mode
        my $Mode = $txmodes{$QSOMode};
	#print("\n",$Mode,"\n");	
	
	# write the data out
	print (OUTFILE "<CALL:" . length($QSOcallsign) . ">" . $QSOcallsign);
	print (OUTFILE "<BAND:" . length($ContestBand) . ">" . $ContestBand);
	print (OUTFILE "<FREQ:" . length($Frequency) . ">" . $Frequency);
	print (OUTFILE "<MODE:" . length($Mode) . ">" . $Mode);
	print (OUTFILE "<QSO_DATE:" . length($QSOdate) . ">" . $QSOdate);
	print (OUTFILE "<TIME_ON:" . length($QSOtime) . ">" . $QSOtime);
	print (OUTFILE "<TIME_OFF:" . length($QSOtime) . ">" . $QSOtime); # not needed.
	print (OUTFILE "<RST_RCVD:" . length($QSOrxRST) . ">" . $QSOrxRST);
	print (OUTFILE "<RST_SENT:" . length($QSOtxRST) . ">" . $QSOtxRST);
	print (OUTFILE "<SRX:" . length($QSOrxSER) . ">" . $QSOrxSER);
	print (OUTFILE "<STX:" . length($QSOtxSER) . ">" . $QSOtxSER);
	print (OUTFILE "<MY_GRIDSQUARE:" . length($ContestLoc) . ">" . $ContestLoc);
	print (OUTFILE "<GRIDSQUARE:" . length($QSOlocator) . ">" . $QSOlocator);
	print (OUTFILE "<COMMENT:" . length($ContestName) . ">" . $ContestName);
	print (OUTFILE "<EOR>\n");
	
	
	
	$LinesWrote++;
	$QSOsWrote++;
}

print ("Finished Writing: $QSOsWrote QSOs processed into $LinesWrote lines.\n");

print ("\n* Summary:\n");
print ("Contest Name     : $ContestName\n");
print ("Contest Band     : $ContestBand\n");
print ("Station Callsign : $ContestCall\n");
print ("Club Name        : $ContestClub\n");
print ("Station Locator  : $ContestLoc\n");
print ("Station Class    : $ContestClass\n");
print ("Uploader Remarks : $ContestRmrk\n");
print ("QSO Errors       : $QSOError\n");

close(INFILE);
close(OUTFILE);

if ($QSOsWrote == $QSOsRead) {
	print ("\n* All records processed successfully.\n");
	exit (0);
} else {
	print ("\n* Some records were not converted correctly.  Check \"$OUTFILE\"!\n");
	exit (1);
}
