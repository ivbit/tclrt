#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# Procedures to work with strings.

# Join list with commas into string, add 'or' before last element.
proc addOr lst {
  set str [join $lst {, }]
  set pos [string last , $str]
  string cat [string range $str 0 $pos] { or} [string range $str $pos+1 end]
}
chan puts stdout [addOr [list A B C D E F]]

