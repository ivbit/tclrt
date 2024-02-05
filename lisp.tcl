#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" ${1+"$@"}

# /bin/sh executes tclsh with arguments, if any.
# If there are no arguments, first argument $1 is unset in sh.
# If first argument $1 is set, 'sh' replaces it with all arguments $@.
# tclsh interprets backslash as continuation of the comment string, sh does not.

# man tclsh

set mylist {a b c d e f g h}
set r "\033\[1;97;41m"
set g "\033\[1;97;42m"
set n "\x1b\[0m"

proc car {lst} {
  lindex $lst 0
}

proc cdr {lst} {
  lrange $lst 1 end
}

puts "$r[car $mylist]$n : $g[cdr $mylist]$n"

