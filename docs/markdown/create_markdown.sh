#!/usr/local/bin/bash

# Usage: create_markdown.sg <top level file>

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

if [ "$curdir" != "markdown" ]
then
	echo "Must run from markdown directory"
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
	./lpp.pl $entry > $base
done

# Generate new Markdown

echo -e "Convert LaTeX to Markdown...\n"
# conversion options stored in markdown.yaml
pandoc --defaults markdown ../$topfile.tex > $topfile.tmp 

# Process Table Captions
echo Updating markdown table captions:

if [ -f $topfile.md ]; then 
	rm $topfile.md
fi

IFS=''
while read -r line || [[ -n "${line}" ]]; do
	if [ "${line:0:2}" == ": " ]; then
		echo "  " $line
		echo "<p align=center><strong>Table${line}</strong></p>" >> $topfile.md
	else
		echo ${line} >> $topfile.md
	fi
done < $topfile.tmp

# Remove Preprocessed LaTeX source & install processed markdown
echo -e "\nCleaning Up...\n"
cp $topfile.md ../$topfile.md
rm -rf tex/* $topfile.tmp $topfile.md

echo "Done!"
