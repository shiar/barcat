prefix = /usr/local
bindir = $(prefix)/bin

INSTALL = install

barcat: reformat-podusage
	./$< $@

test:
	prove -f t/regress.t

install: barcat
	$(INSTALL) -d '$(bindir)'
	$(INSTALL) $< '$(bindir)'
