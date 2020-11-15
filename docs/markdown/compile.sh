#!/bin/bash

set -e

#topfile="ahb3lite_interconnect_markdown"
topfile="ahb3lite_interconnect_datasheet"

# Run from markdown directory only

curdir=${PWD##*/}

if [ "$curdir" != "markdown" ]
then
	echo "Must run from markdown directory"
    exit
else
	echo -e "Starting in Markdown directory...\n"
fi

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
pandoc --defaults markdown ../$topfile.tex > $topfile.md 

# Process Table Captions
echo Updating markdown table captions:
rm ../$topfile.md
IFS=''
while read -r line || [[ -n "${line}" ]]; do
  if [ "${line:0:2}" == ": " ]; then
  	echo "  " $line
    echo "<p align=center><strong>Table${line}</strong></p>" >> ../$topfile.md
  else
    echo ${line} >> ../$topfile.md
  fi
done < $topfile.md

# Remove Preprocessed LaTeX source
echo -e "\nCleaning Up...\n"
rm -rf tex/* $topfile.md


echo "Done!"
