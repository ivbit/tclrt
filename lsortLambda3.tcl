#!/usr/bin/tclsh

# Aliases can be defined within an interpreter by using an empty string for the
# interpreter name, which is useful for defining one command in terms of another
interp alias {} abs {} ::tcl::mathfunc::abs

set list_of_ints {-1 5 -5 10 -5 -1000 100}

puts [lsort -command {apply {
  {a b}
  {
    if {[abs $a] < [abs $b]} { return -1 }
    if {[abs $a] > [abs $b]} { return 1 }
    if {$a < $b} { return -1 }
    if {$a > $b} { return 1 }
    return 0
  }
}} $list_of_ints]

proc helper {params body args} {
  return [list ::apply [list $params $body] {*}$args]
}

puts [lsort -command [helper {a b} {
  if {[abs $a] < [abs $b]} { return -1 }
  if {[abs $a] > [abs $b]} { return 1 }
  if {$a < $b} { return -1 }
  if {$a > $b} { return 1 }
  return 0
}] $list_of_ints]

# 'lambda' is an anonymous procedure,
# apply {args body} ?arg1 arg2 ...?
# apply {args body namespace} ?arg1 arg2 ...?
apply {args {puts [expr [join $args +]]}} 1 2 3 4
apply {{x y} {puts [expr $x * $y]}} 321 8

