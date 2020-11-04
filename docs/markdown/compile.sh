#!/bin/bash

topfile="ahb3lite_interconnect_markdown"

# Run from markdown directory only
curdir=${PWD##*/}

if [ "$curdir" != "markdown" ]
then
	echo "Must run from markdown directory"
    exit
fi

if [ ! -d "tex" ]; then
  mkdir tex
fi


# Pre-process LaTeX Source
for entry in ../tex/*.tex
do
  	base="tex/${entry##*/}"
	./lpp.pl $entry > $base
done

# Generate new Markdown
cd ..
pandoc 	--atx-headers \
		--base-header-level=2 \
		--number-sections \
		--default-image-extension=png \
		--file-scope \
		--toc \
		--toc-depth=1 \
		-t markdown_github \
		-B markdown/frontmatter.md \
		-o datasheet.md \
		$topfile.tex

cd markdown

# Remove Preprocessed LaTeX source
rm -rf tex/*
