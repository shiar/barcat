prefix = /usr/local
bindir = $(prefix)/bin

INSTALL = install

barcat: reformat-podusage
	./$< $@

test:
	t/regress.t
tests:
	mkdir -p sample/out
	prove -f

install: barcat
	$(INSTALL) -d '$(bindir)'
	$(INSTALL) $< '$(bindir)'
