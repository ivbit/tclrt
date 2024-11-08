#! /usr/bin/tclsh

# Max value
set maxValue 85

# Get user input
# On failure, 'scan' does not create/modify a variable 'varName':
# scan string format ?varName ...?
proc getUserInput {} {
  puts -nonewline "Enter the numer (1..=$::maxValue): "
  flush stdout
  set ::userNum [scan [gets stdin] %d]
  return 1
}

# Check user input
proc checkUserInput {} {
  expr {
    $::userNum ne {} &&
    $::userNum > 0 &&
    $::userNum <= $::maxValue
  }
}

# Get 1st arg, or ask user for an input
expr {
  $argc > 0 &&
  [set userNum [scan [lindex $argv 0] %d]; string cat 1] &&
  [checkUserInput] ||
  [getUserInput] &&
  [checkUserInput] ||
  [set userNum $maxValue]
}

# Result
puts "The number is: $userNum"

