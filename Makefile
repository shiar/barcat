barcat: reformat-podusage
	./$< $@

test:
	prove -f t/regress.t
