#!/usr/bin/tclsh

set list_of_ints {-1 5 -5 10 -5 -1000 100}

puts [lsort -command {apply {
  {a b}
  {
    if {[::tcl::mathfunc::abs $a] < [::tcl::mathfunc::abs $b]} { return -1 }
    if {[::tcl::mathfunc::abs $a] > [::tcl::mathfunc::abs $b]} { return 1 }
    if {$a < $b} { return -1 }
    if {$a > $b} { return 1 }
    return 0
  }
}} $list_of_ints]

proc lambda {params body args} {
  return [list ::apply [list $params $body] {*}$args]
}

puts [lsort -command [lambda {a b} {
  if {[::tcl::mathfunc::abs $a] < [::tcl::mathfunc::abs $b]} { return -1 }
  if {[::tcl::mathfunc::abs $a] > [::tcl::mathfunc::abs $b]} { return 1 }
  if {$a < $b} { return -1 }
  if {$a > $b} { return 1 }
  return 0
}] $list_of_ints]

