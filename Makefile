prefix = /usr/local
bindir = $(prefix)/bin

INSTALL = install

barcat: reformat-podusage
	./$< $@

test:
	t/regress.t
tests:
	mkdir -p sample/out
	COLUMNS=80 prove -f

install: barcat
	$(INSTALL) -d '$(bindir)'
	$(INSTALL) $< '$(bindir)'
