#!/usr/bin/tclsh

# Differences between Tcl's RE engine and other RE engines:
# 1) \m - Beginning of a word,
# 2) \M - End of a word,
# 3) \y - Word boundary,
# 4) \Y - a point that is not a word boundary,
# 5) \Z - matches end of data.
set sampleText "This is some text with \[brackets\] in it."
puts $sampleText
set searchFor {[brackets]}

# Prefix the pattern with ***= to make RE engine treat the rest of
# the string as literal characters, disabling all further metacharacters.
if {[ regexp ***=$searchFor $sampleText ]} {
  # This message will be printer
  puts "Found it!"
}

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

