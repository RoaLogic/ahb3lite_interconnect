#!/bin/bash

#topfile="ahb3lite_interconnect_markdown"
topfile="ahb3lite_interconnect_datasheet"

# Run from markdown directory only

curdir=${PWD##*/}

if [ "$curdir" != "markdown" ]
then
	echo "Must run from markdown directory"
    exit
else
	echo "Starting in Markdown directory..."
fi

if [ ! -d "tex" ]; then
  mkdir tex
fi

# Pre-process LaTeX Source
echo "Generate markdown compatible LaTeX source..."
for entry in ../tex/*.tex
do
  	base="tex/${entry##*/}"
	./lpp.pl $entry > $base
done

# Generate new Markdown

echo "Convert LaTeX to Markdown..."
# conversion options stored in markdown.yaml
pandoc --defaults markdown ../$topfile.tex > ../$topfile.md 

# Remove Preprocessed LaTeX source
rm -rf tex/*

echo "Done!"
