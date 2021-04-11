## Installation

Simply create a link with the name of the expansion to the xpn.sh. 

```sh
ln -s xpn.sh pf
```

## Expansion File Syntax 

Commands are composed of a sequence of options, args and subcommands.  These parameters are determined by parsing the command line into words.  No variable expansion is performed, dollar signs ($) are treated as literals.


### Xargs

The default parsing for the expansion is performed by the linux [xarg](https://man7.org/linux/man-pages/man1/xargs.1.html) command.  Parameters are delimited by blanks which can be protected with double or single quotes or a backslash.


```sh
pf               printf
printf>--quoted  "Hello World!" "Hello World!"
printf>--split   Hello World! Hello World!
```

Produces the following:

```sh
pf %s\\n --quoted
# Hello World!
# Hello World!

pf %s\\n --split
# Hello
```

### Single Word

A single word may be declared by using a single tilde (`) character:

```sh
pf               printf
printf>--word    `"Hello World!" "Hello World!"
```

Produces the following:

```sh
pf %s\\n --word
# "Hello World!" "Hello World!"
```

## Todo
