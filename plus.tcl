#!/usr/bin/tclsh

# Instead of defining procedure '+', 'namespace path' can be used:
# namespace path [list ::tcl::mathfunc ::tcl::mathop]
# All numbers
proc + {args} {
  expr [join $args +]
}

# Only integers
proc plus {args} {
  set total 0
  foreach val $args {
    incr total $val
  }
  return $total
}

# {*} instructs parser to treat an argument as a list of values and
# extracts those values as single arguments to the command. Example:
puts [+ {*}{3 4} 5 8 {*}"7 2" {*}$tcl_version {*}[expr $tcl_version + 0.8]]
puts [plus {*}{3 4} 5 8 {*}"7 2"]

