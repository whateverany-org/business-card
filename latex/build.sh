#!/bin/bash
#
# tex > dvi > svg
#
#lualatex --output-format=dvi business-card.tex
#dvisvgm --no-fonts business-card.dvi business-card.svg

#
# tex > dvi > ps > svg
#
#lualatex --output-format=dvi business-card.tex
#dvips -q -f -e 0 -E -D 10000 -x 10000 -o business-card.ps business-card.dvi
#pstoedit -f plot-svg -dt -ssp business-card.ps business-card.svg

# tex > pdf > svg
lualatex business-card.tex
pdftocairo -svg business-card.pdf business-card.svg

