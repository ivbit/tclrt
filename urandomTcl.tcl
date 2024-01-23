#!/usr/bin/tclsh

# Getting true random numbers from /dev/urandom on *nix systems.

# Maximum limit for the range
set max 1371812
# Minimum limit for the range
set min 0
# How many bytes to read at once (8 bytes = 64 bits = 64 bit integer)
set readSingle 8
# How many integers are needed
set readAll [expr $readSingle * 100]

# Procedure will read all the data from /dev/urandom in a single step and store
# it in a list. This is a better solution than reading from /dev/urandom every
# single time, opening and closing the file. For example instead of opening and
# closing /dev/urandom 100 times, it will be done only once.
proc genRandList {maxValue {minValue 0} {amtBytes 800}} {
  set devUrandom [open /dev/urandom rb]
  set randList [read $devUrandom $amtBytes]
  close $devUrandom
  # Converting binary data into unsigned integers for future use:
  # Order can be 'little endian', 'big endian', or 'native' for the CPU;
  # m = 64 bit integer in native order; n = 32 bit integer in native order; 
  # u = unsigned flag; * = count, all bytes will be stored in one variable
  binary scan $randList mu* randList
  # Storing random numbers separated by space character ' ' in a string
  set randStr "\n"
  foreach {num} $randList {
    append randStr [expr {$num % ($maxValue - $minValue + 1) + $minValue}] " "
  }
  append randStr "\n"
  return $randStr
}

puts [genRandList $max $min $readAll]
puts [genRandList 100 15 400]
puts [genRandList 14]

# END OF SCRIPT

