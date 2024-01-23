#!/usr/bin/tclsh

proc abs {v} {
  ::tcl::mathfunc::abs $v
}

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

