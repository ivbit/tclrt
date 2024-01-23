#!/usr/bin/tclsh

# Max value
set m 85

puts -nonewline "Enter the numer (0..${m}): "
flush stdout

# Get user input
set n [gets stdin]

# Trim leading zeroes
set n [string trimleft $n 0]

# Check user input
expr {[string is digit -strict $n] && $n > 0 && $n <= $m || [set n $m]}

# Result
puts "The number is: $n"

