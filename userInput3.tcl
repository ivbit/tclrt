#! /usr/bin/tclsh

# Max value
set maxValue 85

# Get user input, trim leading zeroes
proc getUserInput {} {
  puts -nonewline "Enter the numer (0..$::maxValue): "
  flush stdout
  set ::userNum [string trimleft [gets stdin] 0]
  return 1
}

# Check user input
# 'digit' character class always works with Unicode characters:
# string is digit \u096a
# returns '1' because '\u096a' is a valid unicode digit, however:
# string is integer \u096a
# returns '0'
proc checkUserInput {} {
  expr {
    [string is integer -strict $::userNum] &&
    [string is digit -strict $::userNum] &&
    $::userNum > 0 &&
    $::userNum <= $::maxValue
  }
}

# Get 1st arg, or ask user for an input; trim leading zeroes
expr {
  $argc > 0 &&
  [set userNum [string trimleft [lindex $argv 0] 0]; string cat 1] &&
  [checkUserInput] ||
  [getUserInput] &&
  [checkUserInput] ||
  [set userNum $maxValue]
}

# Result
puts "The number is: $userNum"

