## Installation

Simply create a link with the name of the expansion to the xpn.sh. 

```sh
ln -s xpn.sh tf
```

## Expansion File Syntax 

### Words

### Splitting

Normal expansions are subject to field splitting.  Unless the expansion is deisgnated as a word, double quotes may not be used to start or end a field.

If multiple fields are needed, the following work around may be used:

```
p printf
printf>
printf>-one `Hello World
printf>-split Hello World
printf>-lines -split -one
printf>-dang edge case
printf>-dang= edge case=
printf>-word= `edge case=
printf>-b `[%s]
```

```sh
printf '[%s]' "Hello World"
# [Hello World]

dr= p -b -word
# printf [%s] Hello World

p -b -word
# [Hello World]

p -b -split
# [Hello][World]

p -b "-split"
# [Hello][World]

p -b "-split me"
# [-split me]

p -b -lines
# [Hello][World][Hello World]

p -b -dang
# [edge][case]

p -b "-dang"
# [edge][case]

p -b -dang edge case
# [edge][case][edge][case]

p -b "-dang edge case"
# [-dang edge case]

p -b -dang=
# [edge][case=]

p -b -dang=edge case
# [edge][case=edge][case]

p -b "-dang=edge case"
# [edge][case=edge case]

p -b -dang="edge case"
# [edge][case=edge case]

p -b -dangword=edge case
# [edge case=edge][case]

p -b -warning
```

## Quotes

## Todo
