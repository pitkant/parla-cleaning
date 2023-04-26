#!/bin/bash
#
# (c) Pyry Kantanen, research assistant, 
# Turku Data Science Group
#
# Inspired by script done by Kimmo Elo during the following project:
# SEMPARL-hanke 2020-2022
# Turun yliopisto, eduskuntatutkimuksen keskus
#
# Data files (e.g. Speeches_2001.xml, Speeches_2002.xml ...) assumed to be in 
# the same directory as the script. 

# save the working directory which contains the script as the data directory 
DATADIR=$(pwd)
TARGETDIR="$DATADIR/PROCESSED"

# Make sure that the target directory exists by creating it
mkdir -p "$TARGETDIR"

# Loop over all xml files in the directory
for FILE in "$DATADIR/"*.xml; do

    # Save filename without path and file extension to variable
	PURENAME=$(basename "$FILE" ".xml")

    awk -F '"' '
    BEGIN { RS="<"; ORS="<"; OFS=""; } # set record separator to "<" and output record separator to "<" as well
    {
        if ($0 ~ /^u /) { # if the line starts with <u, then process it
            for (i=2;i<=NF;i+=2) {
                # In case <u xml:id value does not have .1 at the end
                if ($i ~ /^[0-9]{4}_[0-9]{1,3}_[0-9]{1,3}$/) {
                    # split xml:id attribute by "_" to an array a
                    split($i,a,"_");
                    # Year is the 1st element
                    year=a[1];
                    # meeting number is the 2nd element
                    meeting=sprintf("%d",a[2]);
                    # meeting topic number is the 3rd element
                    topic=sprintf("%d",a[3]);
                    # Remove leading zeroes
                    gsub(/^[0]+/,"",meeting);
                    gsub(/^[0]+/,"",topic);
                    # Combine different pieces together, add FI to beginning and .1 to the end
                    $i = sprintf("\"FI%s_%s_%s.1\"",year,meeting,topic);
                }
                # For values that start with # (names)
                else if ($i ~ /^#[^ ]*/) {
                    $i = "\"" $i "\"";
                }
                # For values that start with = (all other values)
                else if ($i ~ /^[^ ]*=/) {
                    $i = " " $i;
                }
                # In case <u xml:id value already has .1 at the end (if there are interruption, vocalisations etc)
                else if ($i ~ /^[0-9]{4}_[0-9]{1,3}_[0-9]{1,3}.[0-9]{1,2}$/) {
                    split($i,a,"_");
                    split($i,b,".");
                    year=a[1];
                    meeting=sprintf("%d",a[2]);
                    topic=sprintf("%d",a[3]);
                    subnumber=sprintf("%d",b[2]);
                    gsub(/^[0]+/,"",meeting);
                    gsub(/^[0]+/,"",topic);
                    # add FI to the beginning of xml:id attribute value
                    $i = sprintf("\"FI%s_%s_%s.%s\"",year,meeting,topic,subnumber); 
                }
            }
        }
        if ($0 ~ /^note /) { # if the line starts with <note, then process it
            for (i=2;i<=NF;i+=2) {
                if ($i ~ /^20[0-9]{2}_[0-9]{1,3}_[0-9]{1,3}$/) {
                    split($i,a,"_");
                    year=a[1];
                    meeting=sprintf("%d",a[2]);
                    topic=sprintf("%d",a[3]);
                    gsub(/^[0]+/,"",meeting);
                    gsub(/^[0]+/,"",topic);
                    # add FI to the beginning of xml:id attribute value
                    $i = sprintf("\"FI%s_%s_%s\"",year,meeting,topic);
                }
                else if ($i ~ /^#[^ ]*/) {
                    $i = "\"" $i "\"";
                }
                else {
                    $i = "\"" $i "\"";
                }
            }  
        }    
        print $0;
    }' "$FILE" > "$TARGETDIR/$PURENAME.xml"
    # Remove extra line at the end, which is probably added because of an empty newline at EOF
    # ORS = < adds an extra < at the end that prevents XML parsing
    sed -i '' -e '$ d' "$TARGETDIR/$PURENAME.xml"
    
done

exit 0