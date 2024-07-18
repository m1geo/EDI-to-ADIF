#!/usr/bin/env python3

# George Smart, M1GEO
# Simple EDI to ADIF Converter for parsing RSGB Contest Results
# for use with Cloudlog.
# 21 May 2012 - Free software under GNU GPL.
# Modified for generic EDI to ADIF conversion by Mario Roessler, DH5YM
# 11 Dec 2022 - Free software under GNU GPL.

import sys

# Don't buffer output.
sys.stdout.reconfigure(line_buffering=True)

# Files
INFILE = ""
OUTFILE = ""

# Station Details
ContestName = ""
ContestCall = ""
ContestClub = ""
ContestLoc = ""
ContestClass = ""
ContestRmrk = ""

# Contest Details
ContestBand = "0cm"
ContestMode = "SSB"

# Stats
QSOsRead = 0
LinesRead = 0
QSOsWrote = 0
LinesWrote = 0
QSOError = 0

# Main data
QSOData = []

# hash map for bands frequency conversion
bands = {
    '50 MHz': '6m',
    '70 MHz': '4m',
    '144 MHz': '2m',
    '432 MHz': '70cm',
    '1,3 GHz': '23cm',
    '2,3 GHz': '13cm',
    '3,4 GHz': '9cm',
    '5,7 GHz': '6cm',
    '10 GHz': '3cm',
    '24 GHz': '1.25cm',
    '47 GHz': '6mm',
    '76 GHz': '4mm',
    '122 GHz': '2.5mm',
    '134 GHz': '2mm',
    '241 GHz': '1mm',
    '300 GHz': 'submm'
}
Band = '0cm'

# Hashmap for band to frequency conversion
frequencies = {
    '50 MHz': '50',
    '70 MHz': '70',
    '144 MHz': '144',
    '432 MHz': '432',
    '1,3 GHz': '1296',
    '2,3 GHz': '2320',
    '3,4 GHz': '3400',
    '5,7 GHz': '5760',
    '10 GHz': '10368',
    '24 GHz': '24048',
    '47 GHz': '47088',
    '76 GHz': '77500',
    '122 GHz': '122250',
    '134 GHz': '134928',
    '241 GHz': '241920',
    '300 GHz': 'submm'
}
Frequency = '0'

# TX mode conversion table
txmodes = {
    '0': 'NON',
    '1': 'SSB',
    '2': 'CW',
    '3': 'CW',
    '4': 'SSB',
    '5': 'AM',
    '6': 'FM',
    '7': 'RTTY',
    '8': 'SSTV',
    '9': 'ATV'
}
# RX mode conversion table (not currently supported in ADIF)
rxmodes = {
    '0': 'NON',
    '1': 'SSB',
    '2': 'CW',
    '3': 'SSB',
    '4': 'CW',
    '5': 'AM',
    '6': 'FM',
    '7': 'RTTY',
    '8': 'SSTV',
    '9': 'ATV'
}

print("George Smart, M1GEO")
print("EDI to ADIF Converter for parsing RSGB Contest Results for use with Cloudlog.")
print("21 May 2012 - Free software under GNU GPL.")
print("Modified for generic EDI to ADIF conversion by Mario Roessler, DH5YM")
print("09 Dec 2022 - Free software under GNU GPL.\n")

if len(sys.argv) != 3:
    print("* Syntax Error.")
    print(f"{sys.argv[0]} <input_edi> <output_adi>")
    sys.exit(2)

INFILE = sys.argv[1]
OUTFILE = sys.argv[2]

with open(INFILE, "r") as infile, open(OUTFILE, "w") as outfile:
    print(f"* Reading in \"{INFILE}\": ", end="")

    for line in infile:
        line = line.strip()

        if line.startswith("TName"):
            ContestName = line.replace("TName=", "").strip()
        elif line.startswith("PCall"):
            ContestCall = line.replace("PCall=", "")
        elif line.startswith("PClub"):
            ContestClub = line.replace("PClub=", "")
        elif line.startswith("PWWLo"):
            ContestLoc = line.replace("PWWLo=", "").strip()
        elif line.startswith("PSect"):
            ContestClass = line.replace("PSect=", "")
        elif line.startswith("PBand"):
            ContestBand = line.replace("PBand=", "").strip()
            Band = bands.get(ContestBand, '0cm')
            Frequency = frequencies.get(ContestBand, '0')
            ContestBand = Band
        elif line.startswith("[Remarks]"):
            nextline = next(infile).strip()
            if not nextline.startswith("[QSORecords"):
                LinesRead += 1
                ContestRmrk = nextline
            else:
                print("\nNo Remarks in Remark section.")
                line = nextline
        elif line.startswith("[QSORecords"):
            print("processing log...")
            for QSOline in infile:
                LinesRead += 1
                QSOline = QSOline.strip()
                QSOdata = QSOline.split(";")
                if len(QSOdata) >= 11 and QSOdata[2] != 'ERROR':
                    QSOData.append(QSOdata)
                    QSOsRead += 1
                elif len(QSOdata) >= 3 and QSOdata[2] == 'ERROR':
                    QSOError += 1

        LinesRead += 1

    print(f"Finished Reading: {QSOsRead} QSOs processed from {LinesRead} lines.")

    print(f"* Writing to \"{OUTFILE}\": ", end="")

    outfile.write("<ADIF_VERS:3>3.1\n")
    outfile.write("<PROGRAMID:30>M1GEO+DH5YM EDI-ADIF Converter\n")
    outfile.write("<PROGRAMVERSION:9>Version 2\n")
    outfile.write("<EOH>\n\n")
    LinesWrote += 5

    for QSORecord in QSOData:
        QSOdate, QSOtime, QSOcallsign, QSOMode, QSOtxRST, QSOtxSER, QSOrxRST, QSOrxSER, QSOunknownB, QSOlocator, QSOdistance = QSORecord[:11]

        QSOdate = "20" + QSOdate

        if len(QSOlocator) == 6:
            QSOlocator = QSOlocator[:4] + QSOlocator[4:].lower()

        Mode = txmodes.get(QSOMode, 'UNKNOWN')

        outfile.write(f"<CALL:{len(QSOcallsign)}>{QSOcallsign}")
        outfile.write(f"<BAND:{len(ContestBand)}>{ContestBand}")
        outfile.write(f"<FREQ:{len(Frequency)}>{Frequency}")
        outfile.write(f"<MODE:{len(Mode)}>{Mode}")
        outfile.write(f"<QSO_DATE:{len(QSOdate)}>{QSOdate}")
        outfile.write(f"<TIME_ON:{len(QSOtime)}>{QSOtime}")
        outfile.write(f"<TIME_OFF:{len(QSOtime)}>{QSOtime}")
        outfile.write(f"<RST_RCVD:{len(QSOrxRST)}>{QSOrxRST}")
        outfile.write(f"<RST_SENT:{len(QSOtxRST)}>{QSOtxRST}")
        outfile.write(f"<SRX:{len(QSOrxSER)}>{QSOrxSER}")
        outfile.write(f"<STX:{len(QSOtxSER)}>{QSOtxSER}")
        outfile.write(f"<MY_GRIDSQUARE:{len(ContestLoc)}>{ContestLoc}")
        outfile.write(f"<GRIDSQUARE:{len(QSOlocator)}>{QSOlocator}")
        outfile.write(f"<COMMENT:{len(ContestName)}>{ContestName}")
        outfile.write("<EOR>\n")

        LinesWrote += 1
        QSOsWrote += 1

    print(f"Finished Writing: {QSOsWrote} QSOs processed into {LinesWrote} lines.")

    print("\n* Summary:")
    print(f"Contest Name     : {ContestName}")
    print(f"Contest Band     : {ContestBand}")
    print(f"Station Callsign : {ContestCall}")
    print(f"Club Name        : {ContestClub}")
    print(f"Station Locator  : {ContestLoc}")
    print(f"Station Class    : {ContestClass}")
    print(f"Uploader Remarks : {ContestRmrk}")
    print(f"QSO Errors       : {QSOError}")

if QSOsWrote == QSOsRead:
    print("\n* All records processed successfully.")
    sys.exit(0)
else:
    print(f"\n* Some records were not converted correctly. Check \"{OUTFILE}\"!")
    sys.exit(1)

