barcat concatenates text input similar to _cat_, but can visualize number values
by appending graphs and statistics.

# Installation

Copy or link the [barcat](https://github.com/shiar/barcat/raw/master/barcat)
script to the command `PATH`.
No dependencies besides _Perl_, so should run on most *nix environments.

# Usage

	barcat [OPTIONS] [FILES|NUMBERS]

Expected `barcat -h` gives an overview of accepted options.
`barcat --help` to Read The Friendly Manual.

## Examples

Just draw relative sizes:

	$ du * | barcat
	  28 barcat            >
	   4 Makefile
	   4 mascot.txt
	   4 reformat-podusage
	   8 sample/media
	  12 sample
	 252 t/input           >-----=---
	1168 t                 >-----=----------------------------------------

Reformat values and add statistics:

	$ du -bS * | barcat -H --log --stat
	 27k barcat            ---------------------------<-+----->-
	238  Makefile          --------------------
	 27  mascot.txt        ------------
	1.7k reformat-podusage ---------------------------
	4.8k sample/media      ---------------------------<-+-
	4.1k sample            ---------------------------<-+
	152k t/input           ---------------------------<-+----->----=--
	464k t                 ---------------------------<-+----->----=------
	654k total in 8 values ( 27  min,  82k avg, 464k max)

Many more sample commands in the documentation.
