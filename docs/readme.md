---
title: ReadMe
permalink: /readme/
---

# AHB3lite_interconnect Documentation ReadMe

The **`/docs`** subfolder is a self contained sub-repository of all documentation for the `AHB3lite_interconnect` IP

All documentation is written in LaTeX from which a standalone PDF datasheet and HTML data sheet (via markdown) are generated. The HTML datasheet is served via GitHub pages

The following sections describe in detail the contents of this sub-repository

## LaTeX Source:

All documentation generated from LaTex Source

- Top Level: [`ahb3lite_interconnect_datasheet.tex`](./ahb3lite_interconnect_datasheet.tex)
- `tex/` → Datasheet Content
- `pkg/` → Layout definition
- `assets/` → Graphics Content, including source files

## PDF: 

Compiled from LaTeX source using pdfLaTeX

- Generated as → [`ahb3lite_interconnect_datasheet.pdf`](./ahb3lite_interconnect_datasheet.pdf)

## Markdown: 

Generated from LaTeX source via 'pandoc' utility

- Generated as → [`ahb3lite_interconnect_datasheet.md`](./ahb3lite_interconnect_datasheet.md)
- `markdown/` → Compilation script(s) to create markdown

## HTML:

Generated via GitHub Pages (ie jekyll static generator)

- Generated as → [https://roalogic.github.io/ahb3lite_interconnect](https://roalogic.github.io/ahb3lite_interconnect)
- `_pages/` → Non-datasheet content
- `_layout/` → Custom page generation layout
- `_config.yml` → jekyll configuration
- `Gemfile` → offline environment setup
- `favicon.ico` → Site icon (shown in browsers, eg when page bookmarked)
