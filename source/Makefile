NAME  = gurps
SHELL = bash
PWD   = $(shell pwd)
VERS  = $(shell ltxfileinfo -v $(NAME).dtx|sed -e 's/^v//')
LOCAL = $(shell kpsewhich --var-value TEXMFLOCAL)
UTREE = $(shell kpsewhich --var-value TEXMFHOME)
all:	$(NAME).pdf

$(NAME).pdf: $(NAME).dtx
	lualatex -recorder -interaction=batchmode $(NAME).dtx >/dev/null
	if [ -f $(NAME).glo ]; then makeindex -q -s gglo.ist -o $(NAME).gls $(NAME).glo; fi
	if [ -f $(NAME).idx ]; then makeindex -q -s gind.ist -o $(NAME).ind $(NAME).idx; fi
	lualatex --recorder --interaction=nonstopmode $(NAME).dtx
	lualatex --recorder --interaction=nonstopmode $(NAME).dtx
clean:
	rm -f $(NAME).{aux,fls,glo,gls,hd,idx,ilg,ind,ins,log,out}
distclean: clean
	rm -f *.log
	rm -f $(NAME).{pdf,sty}
inst: all
	mkdir -p $(UTREE)/{tex,source,doc}/latex/$(NAME)
	cp $(NAME).dtx $(UTREE)/source/latex/$(NAME)
	cp $(NAME).sty $(UTREE)/tex/latex/$(NAME)
	cp gurps-gcs-template.gcx $(UTREE)/tex/latex/gurps-gcs-template.gcx
	cp $(NAME).lua $(UTREE)/tex/latex/$(NAME)
	cp gurps_tables.lua $(UTREE)/tex/latex/$(TABLE_NAME)
	cp gurps_character.lua $(UTREE)/tex/latex/$(TABLE_NAME)
	cp etb_extensions.lua $(UTREE)/tex/latex/$(TABLE_NAME)
	cp $(NAME).pdf $(UTREE)/doc/latex/$(NAME)
install: all
	sudo mkdir -p $(LOCAL)/{tex,source,doc}/latex/$(NAME)
	sudo cp $(NAME).dtx $(LOCAL)/source/latex/$(NAME)
	sudo cp $(NAME).sty $(LOCAL)/tex/latex/$(NAME)
	sudo cp gurps-gcs-template.gcx $(UTREE)/tex/latex/gurps-gcs-template.gcx
	sudo cp $(NAME).lua $(UTREE)/tex/latex/$(NAME)
	sudo cp gurps_tables.lua $(UTREE)/tex/latex/$(NAME)
	sudo cp gurps_character.lua $(UTREE)/tex/latex/$(NAME)
	sudo cp etb_extensions.lua $(UTREE)/tex/latex/$(TABLE_NAME)
	sudo cp $(NAME).pdf $(LOCAL)/doc/latex/$(NAME)
zip: all
  # Check if the latest release date has been updated
	if grep -oP 1970/01/01 gurps.dtx; then echo -e '\033[0;31mRelease date needs updating!\033[0m'; exit 1; fi

	ln -sf . $(NAME)
	zip -Drq $(PWD)/$(NAME)-$(VERS).zip $(NAME)/{README.md,$(NAME).{pdf,dtx,lua},gurps_tables.lua,gurps_character.lua}
	rm $(NAME)

