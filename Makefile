SHELL=/bin/bash

.PHONY = html all diff-fetch-tagged diff-common-after-bbl diff-commands diffnew-commands difftagged diff-common-after-pdfaux diff-common-after-pdf diff-common-after-pdfaux open-pdf glossary pdflatex-all pdflatex pdfview pdfview2 pdfview3 pandoc bib 
LATEXOPTIONS=-synctex=1 -shell-escape  -interaction=nonstopmode
LATEXCMD=TEXINPUTS=.build: pdflatex $(LATEXOPTIONS) -output-directory=.build
safecmdstr = "eg,ie,htss,htst,wsrt,mwut,el,acro,pps,hz,khz,db,us,ms,s,pc,de,nv,uv,bdr,lbdr,cu,sd,se,ir,ac,acp,acf,acs,acsp,acl,aclp,gls,Gls,glsentryname,rm,subref,multirow,autoref"
LATEXDIFFOPTIONS = -t FONTSTRIKE -s COLOR --floattype IDENTICAL --encoding=utf8 --append-safecmd=$(safecmdstr) --math-markup=0 --packages=$(LATEXDIFFPACKAGES)
LATEXCMDDIFF=TEXINPUTS=.build/diff: pdflatex $(LATEXOPTIONS) -output-directory=.build/diff
LATEXDIFFPACKAGES=siunitx,glossaries,amsmath,endfloat,hyperref
BASENAME= main
BBLFILE = $(BASENAME).bbl
BIBFILE = library.bib 
JOURNALABBREVIATIONS = /home/jundurraga/Dropbox/Documents/journalabbreviations.txt
LASTTAG = submitted_01
FIGURES = figures
PREAMBLEFILES = acronyms.tex bibPreamble.tex documentPreamble.tex refPreamble.tex
STYLEFILES = bioRxiv.cls bioRxiv_logo.png bxv_abbrvnat.bst

all: pdflatex-all

#pdflatex-all: mkbuilddir pdflatex-$(BASENAME) bib-$(BASENAME) glossaryorig-$(BASENAME) pdflatex-$(BASENAME)  pdfview3-$(BASENAME)

pdflatex-all: mkbuilddir pdflatex-$(BASENAME) bib-$(BASENAME) pdflatex-$(BASENAME)  pdfview3-$(BASENAME)

pdflatex-all-bibtex: mkbuilddir pdflatex-$(BASENAME) bibtex pdflatex-$(BASENAME)  pdfview3-$(BASENAME)


glossaryorig-%: %.tex
	-cp *.tex .build/
	-cd .build && makeglossaries $(basename $(<F)) && makeindex -s $(basename $(<F)).ist -t $(basename $(<F)).glg -o $(basename $(<F)).gls $(basename $(<F)).glo
	-mv .build/$(basename $(<F)).pdf ./$(basename $(<F)).pdf

glossaryorigdiff-%: %.tex
	-cd .build/diff && makeglossaries $(basename $(<F)) && makeindex -s $(basename $(<F)).ist -t $(basename $(<F)).glg -o $(basename $(<F)).gls $(basename $(<F)).glo
	-mv .build/diff/$(basename $(<F)).pdf ././$(basename $(<F))-diff.pdf

html:
	-cp *.tex .build/
	-cp config.cfg -d .build
	-cd .build &&  \
	htlatex $(BASENAME).tex config && \
	cat $(BASENAME).html \
		| perl -p0e 's/\n/~#~/g' \
		| perl -pe 's/<\?xml\s*version=*.*\?>//g' \
		| perl -p0e 's/<img\s*~#~src="$(BASENAME)\d*x.png" alt="PICT"\s*\/>/''/g' \
		| sed 's/~#~/\n/g' \
		| sponge $(BASENAME).html;
	-mkdir html
	-cp .build/$(BASENAME).css html/
	-cp .build/$(BASENAME).html html/
	-mkdir html/figures
	-cp .build/$(FIGURES)/*.png html/figures/
	-cp .build/*.png html/
htmldiff:
	-cp config.cfg .build/diff
	-cd .build/diff &&  \
	htlatex $(BASENAME).tex && \
	cat $(BASENAME).html \
		| sponge $(BASENAME)-diff.html;
	-mkdir html-diff
	-cp .build/diff/$(BASENAME).css html-diff/
	-cp .build/diff/$(BASENAME)-diff.html html-diff/
	-mkdir html-diff/figures
	-cp .build/diff/$(FIGURES)/*.png html-diff/figures/

# htmldiff:
#	-cp config.cfg .build/diff
#	-cd .build/diff &&  \
#	htlatex $(BASENAME).tex config && \
#	cat $(BASENAME).html \
#		| perl -p0e 's/\n/~#~/g' \
#		| perl -pe 's/<\?xml\s*version=*.*\?>//g' \
#		| perl -p0e 's/<img\s*~#~src="$(BASENAME)\d*x.png" alt="PICT"\s*\/>/''/g' \
#		| sed 's/~#~/\n/g' \
#		| sponge $(BASENAME)-diff.html;
#	-mkdir html-diff
#	-cp .build/diff/$(BASENAME).css html-diff/
#	-cp .build/diff/$(BASENAME)-diff.html html-diff/
#	-mkdir html-diff/figures
#	-cp .build/diff/$(FIGURES)/*.png html-diff/figures/

rtf: 
	-latex2rtf $(BASENAME).tex

mkbuilddir: 
	-mkdir -p .build
	-cp $(BIBFILE) .build/
	-cp $(FIGURES) .build/ -R
	-cp $(STYLEFILES) .build/ 

#mkbuilddir: 
# 	-mkdir -p .build
# 	-cp $(BIBFILE) .build/
# 	-cp $(FIGURES) .build/ -R
# 	-cp $(STYLEFILES) .build/ 
# 	for i in $^; do \
#           cp $$i .build/; \
#       done;

buildpdf: 
	-$(LATEXCMD) $(BASENAME).tex

pdflatex-%: %.tex .build
	-$(LATEXCMD) $<
	cp .build/$(<:.tex=.pdf) .

diff-fetch-tagged:
	mkdir -p .build/diff
	for i in *.tex; do \
		latexdiff $(LATEXDIFFOPTIONS) <(git show $(LASTTAG):$$i) $$i > .build/diff/$${i%.tex}.tex; \
	done;
	sed -i 's/include{/&diff\//' .build/diff/*.tex
	cp $(BIBFILE) .build/diff/
	cp $(FIGURES) .build/diff/ -R

diff-keep-preamblefiles: $(PREAMBLEFILES)
	for i in $^; do \
	   cp $$i .build/diff/; \
        done;
	 
bibtex: $(patsubst %-blx.aux,%-blx.bbl,$(wildcard .build/*-blx.aux))

diff-common-after-bbl: .build/diff/*.aux .build/diff/*.bib $(BIBFILE)
	 -cd $(<D) && biber $(basename $(<F))
	 -cd $(<D) && biber $(basename $(<F))
	 -cd $(<D) && biber $(basename $(<F))

diff-commands: *.tex
	cd .build/diff/; \
	for i in $^; do \
		cat $$i \
		| perl -p0e 's/\n/|#|/g' \
		| perl -pe 's/\\DIFaddbegin \\\\|%DIF > \\DIFaddend//g' \
		| perl -pe 's/\\DIFaddbegin \\begin/\\DIFaddbegin|#|\\begin/g' \
		| perl -pe 's/\\DIFaddbeginFL \\end/\\DIFaddbeginFL|#|\\end/g' \
		| sed 's/|#|/\n/g' \
		| sed 's/\\cmidrule\\DIFaddFL{\(.*\)}{\\DIFaddFL{\(.*\)}}/\\cmidrule\1{\2}/g' \
		| sed '/\\providecommand{\\DIFaddtex}/i\\\RequirePackage{color}\\definecolor{dtextcolor}{rgb}{1,0,0}\\definecolor{ntextcolor}{rgb}{1,0,0}' \
		| sed 's/\\protect\\color{blue}/\\protect\\color{ntextcolor}/g' \
		| sed 's/\\protect\\color{red}/\\protect\\color{dtextcolor}/g' \
		| sed 's/\\sf\s\#1/\\color{ntextcolor}\\textbf{\\sf{\#1}}/g' \
		| sed 's/\\sout{\#1}/\\color{dtextcolor}\\textit{\\sout{\#1}}/g' \
		| sponge $$i; \
	done;
	
diff-common-after-pdfaux:  
	-$(LATEXCMDDIFF) $(BASENAME).tex

diff-common-after-pdf:
	-$(LATEXCMDDIFF) $(BASENAME).tex
	-cp .build/diff/$(BASENAME).pdf ./$(BASENAME)_diff.pdf

open-pdf-%: %*.pdf
	-xdg-open $< &

pdfview-%: %.pdf
	trap '' HUP; xpdf -remote $< $< &

pdfview2-%: %.pdf
	trap '' HUP; acroread $< &

pdfview3-%: %.pdf
	trap '' HUP; evince $< &

#difftagged: diff-fetch-tagged diff-keep-preamblefiles diff-common-after-pdfaux bibdiff-$(BASENAME) diff-common-after-pdf glossaryorigdiff-$(BASENAME) open-pdf $(BASENAME)-diff.pdf

difftagged: diff-fetch-tagged diff-keep-preamblefiles diff-common-after-pdfaux bibdiff-$(BASENAME) diff-common-after-pdf pdfview3-$(BASENAME)_diff

eps-figures: Figures/*.eps

pdf-figures: $(patsubst %.eps,%.pdf,$(wildcard Figures/*.eps))

Figures/%.pdf: Figures/%.eps
	cat $< | sed 's/\(^\/DO.*\)4/\12/;s/\(^\/DA.*\)6/\13/;' | epstopdf -f > $@

bibtex-check: $(BBLFILE)
	@comm -3 <(grep '\field{journaltitle}' $(BBLFILE) | sort -u) <(grep -o '/.*$$' journalabbreviations.txt | sed 's/\/\(.*\)/\\field{journaltitle}{\1},/' | sort -u)

bib-%: %.tex 
	biber .build/$(basename $(<F))
#	cat $(BIBFILE) \
	| perl -p0e 's/\\o\s*/{\\o}/g' \
	| sed -e "`sed 's/\(.*\)\/\(.*\)/s\/journal = {\1}\/journal = {\2}\/g/' $(JOURNALABBREVIATIONS)`" \
	| sponge $(BIBFILE) 

bibdiff-%: %.tex 
	biber .build/diff/$(basename $(<F))

glossary: %.tex
	cd .build && makeglossaries $(basename $<)
	-$(LATEXCMD) $<

index: %.tex
	cd .build && makeindex -s %.ist -t %.glg -o %.gls %.glo
	-$(LATEXCMD) $<

pandoc-doc: 
	-cp  *.tex .build/
	pandoc -f latex -s -S $(BASENAME).tex --biblatex --chapters --default-image-extension=.pdf --metadata --bibliography $(BIBFILE) --csl chicago-author-date.csl -o $(BASENAME).docx 
	-mv .build/$(BASENAME).docx $(BASENAME).docx

pandoc-pdf: 
	-cp  *.tex .build/
	pandoc -f latex -s $(BASENAME).tex -o $(BASENAME)-pandoc.pdf --biblatex --chapters --biblio $(BIBFILE) --default-image-extension=.pdf 
	-mv .build/$(BASENAME)-pandoc.pdf $(BASENAME)-pandoc.pdf
pandoc-md: 
	-cp  *.tex .build/
	pandoc -f latex -s -S .build/$(BASENAME).tex --biblatex --chapters --default-image-extension=.pdf --metadata --bibliography $(BIBFILE) --csl chicago-author-date.csl -o .build/$(BASENAME).md --filter pandoc-crossref 
	-mv .build/$(BASENAME).md $(BASENAME).md
pandoc-json: 
	-cp  *.tex .build/
	pandoc -f latex -s -S $(BASENAME).tex --biblatex --chapters --default-image-extension=.pdf --metadata --bibliography $(BIBFILE) --csl chicago-author-date.csl -o $(BASENAME)-pandoc.json --verbose 
	-mv .build/$(BASENAME)-pandoc.json $(BASENAME)-pandoc.json
