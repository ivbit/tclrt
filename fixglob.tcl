#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# Sorts the result of 'glob command'
# Removes . and .. entries from the result of 'glob' command (glob * .*)
proc fixglob {lst} {
  set lst [lsort -dictionary $lst]
  set range [lsearch -regexp -all $lst {^\.$|^\.\.$}]
  lreplace $lst [lindex $range 0] [lindex $range end]
}

# Sorts the result of 'glob command'
# Removes . and .. entries from the result of 'glob' command (glob * .*)
# Replaces ~ at the beginning of file names with ./~
proc fixglobt {lst} {
  set lst [lsort -dictionary $lst]
  set regr [lsearch -regexp -all $lst {^\.$|^\.\.$}]
  set lst [lreplace $lst [lindex $regr 0] [lindex $regr end]]
  set regr [lsearch -regexp -all $lst {^~.*$}]
  foreach idx $regr {
    lset lst $idx ./[lindex $lst $idx]
  }
  return $lst
}

# Sorts the result of 'glob command'
# Removes . and .. entries from the result of 'glob' command (glob * .*)
# Prefixes all file names with ./
proc fixglobta {lst} {
  set lst [lsort -dictionary $lst]
  set range [lsearch -regexp -all $lst {^\.$|^\.\.$}]
  set lst [lreplace $lst [lindex $range 0] [lindex $range end]]
  lmap itm $lst {
    string cat ./ $itm
  }
}

foreach itm [fixglobta {hello world . ~foo ~bar .. ~baz .... ~ 123 ~~ ABC.txt
HELLO abc.txt ... [word]}] {
  puts [file normalize $itm]
}

puts [string repeat * 30]

foreach itm [fixglobta [glob * .*]] {puts [file normalize $itm]}

# There are 'fileutil::find' and 'fileutil::findByPattern'
# from package 'fileutil' (package require fileutil)
# 'fileutil::find' passes each file name as an argument to a command:
# fileutil::find directory myFilterProc
# OR
# fileutil::find directory {string equal string}
# fileutil::find directory {string match pattern}

