#! /bin/sh
# Launch 'tclsh' \
exec tclsh "$0" ${1+"$@"}

# regexp ?options? RE STRING ?MATCHVAR MATCHVAR ...?
# 'Word' is alphanumeric characters and underscore _
# Differences between Tcl's RE engine and other RE engines:
# 1) \A - beginning of data (same as ^ if '-line' not specified)
# 2) \Z - end of data (same as $ if '-line' not specified)
# 3) \m - beginning of a word
# 4) \M - end of a word
# 5) \y - word boundary (beginning, or end)
# 6) \Y - a point that is not a word boundary (not at the beginning, or the end)
# 7) \B - a backslash (only understood by RE matcher, and not by Tcl parser)

set sampleText "This is some text with \[brackets\] in it."
puts $sampleText
set searchFor {[brackets]}
# Prefix the pattern with ***= to make RE engine treat the rest of
# the string as literal characters, disabling all further metacharacters.
if {[ regexp ***=$searchFor $sampleText ]} {
  # This message will be printer
  puts "Found it!"
}
# Literal string matching ***=
puts [regexp {***=Hello world.} {Hello world.}]

# Find real numbers at the end of a line:
set mydata {
  White 0.87 percent saturation.
  Specular reflection: 0.995
  Blue 0.56 percent saturation.
  Specular reflection: 0.421
}
# The -line switch will enable newline matching.
# Without -line, the $ would match the end of the data.
# The -expanded switch allows usage of comments inside regular expressions.
set mymatches [regexp -line -all -inline -expanded {
  \y      # word boundary
  \d\.\d+ # a real number
  $       # at the end of line
} $mydata]
puts $mymatches

# Expanded syntax: -expanded, or (?x)
puts [regexp -inline -all {(?x)
  \m    # beginning of a world
  (\w+) # followed by one or more word characters
  \s+   # then whitespace
  \1    # then the word that was matched
  \M    # then end of the word (a non-word char, end of string, etc.)
} {This sentence has has repeated words.}]

# regsub ?options? RE STRING SUBSPEC ?VARNAME?
# Back references and 'regsub'
puts [regsub {(\d+) (\d+)} "Example: 100 200" {\0 reversed is \2 \1}]
puts [regsub {(\d+) (\d+)} "Example: 100 200" {& reversed is \2 \1}]

# Character classes
# [:alnum:], [:alpha:], [:blank:], [:cntrl:], [:digit:], [:graph:],
# [:lower:], [:print:], [:punct:], [:space:], [:upper:], [:xdigit:]
puts [regexp {\A[[:alpha:][:digit:]].*d\Z} {1) Hello world}]

# Shorthands
# \d [[:digit:]]   - digit
# \D [^[:digit:]]  - not digit
# \s [[:space:]]   - white space (space, tabe, newline, ...)
# \S [^[:space:]]  - not white space
# \w [[:alnum:]_]  - alphanumeric, or underscore
# \W [^[:alnum:]_] - not alphanumeric and not underscore
puts [regexp {a\db} a2b]

# Quantifiers
# *     - 0 or more
# +     - 1 or more
# ?     - 0 or 1
# {M}   - exactly M
# {M,}  - M or more
# {M,N} - M to N, both inclusive
puts [regexp {aZ{1,5}b} aZZZb]

# Non-capturing groups (?:RE)
puts [regexp {a(?:BC){2}d} aBCBCd]
puts [regexp {(?:Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day} Saturday]

# Non-greedy matching (full match not needed - {} variable)
regexp {<item>(.+?)</item>} {<item>i1</item><item>i2</item>} {} var
puts "full match: ${}"
puts "match: $var"

# Embedded options can only appear at the beginning of regular expression
# Multiple options can be used together: (?in)
# (?i) - case-insensitive, -nocase
# (?c) - case-sensitive
# (?s) - newline-insensitive, opposite of (?n)
# (?n) - -line
# (?w) - -lineanchor
# (?p) - -linestop
# (?q) - RE is a literal string, similar to '***='
# (?x) - -expanded
# (?t) - opposite of (?x)

# (?=positive_lookahead) - RE that should be matched
# (?!negative_lookahead) - RE that should not be matched
puts [regexp {^(?=.{2,10}$)[[:upper:]]+[[:digit:]]+$} ABC2345678]
puts [regexp {^(?!.{3,10}$)[[:upper:]]+[[:digit:]]+$} A2]
puts [regexp {^(?!.{3,10}$)[[:upper:]]+[[:digit:]]+$} A1234567890]

# Collating elements [.identifier.] - long name for some symbols
# Full list of supported identifiers is in source code: generic/regc_locale.c
puts [regexp {a[[:digit:][.number-sign.]]b} a#b]
puts [regexp {a[[:digit:][.space.]]b} a\ b]
puts [regexp {a[[:digit:][.commercial-at.]]b} a@b]
puts [regexp {^a[[.left-brace.]]b$} a\{b]
puts [regexp {^a[[.left-curly-bracket.]]b$} a\{b]

