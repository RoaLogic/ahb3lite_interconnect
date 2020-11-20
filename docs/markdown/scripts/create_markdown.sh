#!/usr/local/bin/bash

# Usage: create_markdown.sh <top level file>

set -e

# Verify number of parameters specified
if [ $# -ne 1 ]; then
  echo -e "\nError: No input file specified\n"
  exit 1;
fi

# capture command line param & convert to lower case
topfile=${1,,}
echo -e "\nGenerating markdown for $topfile...\n"


# Run from markdown directory only
curdir=${PWD##*/}

if [ "$curdir" != "markdown" ] || [ ! -d "scripts" ] || [ ! -d "config" ]
then
	echo "Must run from project markdown directory"
	exit 2
fi

# Create temporary directory for processed tex files
if [ ! -d "tex" ]; then
	mkdir tex
fi

# Pre-process LaTeX Source
echo -e "Generate markdown compatible LaTeX source...\n"
for entry in ../tex/*.tex
do
	base="tex/${entry##*/}"
	./scripts/lpp.pl $entry > $base
done

# Generate new Markdown

echo -e "Convert LaTeX to Markdown...\n"
# conversion options stored in markdown.yaml
pandoc --defaults config/latex2markdown ../$topfile.tex > $topfile.tmp 

# Process Captions
echo -e "Updating markdown captions:\n"

if [ -f $topfile.md ]; then 
	rm $topfile.md
fi

tableindex=0
figindex=0

IFS=''
while read -r line || [[ -n "${line}" ]]; do

	case ${line:0:2} in

    ": ") # Table Caption
			echo "  Table" $((++tableindex))$line
			echo "<p align=center><strong>Table ${tableindex}${line}</strong></p>" >> $topfile.md
			;;

		"<f") # Figure Caption
			# Write current line to output & read next line
			echo ${line} >> $topfile.md
			read -r line

			# Verify line is an image
			if [ ${line:0:4} != "<img" ]; then 
				# Write line and continue
				echo ${line} >> $topfile.md 
			else
				# Filter tag <figcaption aria-hidden="true"> → <figcaption aria-hidden="true">Fig #:
				echo "  Figure" $((++figindex))
				echo ${line//<figcaption aria-hidden=\"true\">/<figcaption aria-hidden=\"true\">Figure ${figindex}: } >> $topfile.md
			fi
	  	;;

  	*) # Default = write line to output
			echo ${line} >> $topfile.md
	  	;;

	esac
done < $topfile.tmp

# Remove Preprocessed LaTeX source & install processed markdown
echo -e "\nCleaning Up...\n"
cp $topfile.md ../$topfile.md
rm -rf tex $topfile.tmp $topfile.md

echo "Done!"
