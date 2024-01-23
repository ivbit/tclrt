#!/usr/bin/tclsh

# https://wiki.tcl-lang.org/page/rand
puts [::tcl::mathfunc::rand]

# Cryptographically secure random numbers using /dev/urandom.
# Procedure does not work with floating point numbers.
proc randInt { min max } {
  set randDev [open /dev/urandom rb]
  set random [read $randDev 8]
  close $randDev
  binary scan $random H16 random
  set random [expr {([scan $random %x] % (($max-$min) + 1) + $min)}]
  return $random
}

puts [randInt 1 100]
puts [randInt 1001 9999]

