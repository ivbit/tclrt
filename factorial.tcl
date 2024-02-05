#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" ${1+"$@"}

# /bin/sh executes tclsh with arguments, if any.
# If there are no arguments, first argument $1 is unset in sh.
# If first argument $1 is set, 'sh' replaces it with all arguments $@.
# tclsh interprets backslash as continuation of the comment string, sh does not.

# man tclsh

proc fac1 {n} {
  if {$n == 0} {
    return 1
  }
  expr {$n * [fac1 [expr {$n - 1}]]}
}

proc fac2 {n} {
  expr {$n == 0 ? 1 : $n * [fac2 [expr {$n -1}]]}
}

# 'tailcall' avoids using stack
proc fac3 {n {acc 1}} {
  if {$n < 2} {
    return $acc
  }
  tailcall fac3 [expr {$n - 1}] [expr {$acc * $n}]
}

proc fac4 {n {acc 1}} {
  if [::tcl::mathop::< $n 2] {return $acc}
  tailcall fac4 [::tcl::mathop::- $n 1] [::tcl::mathop::* $acc $n]
}

puts [fac1 50]
puts [fac2 50]
puts [fac3 80]
puts [fac4 80]

