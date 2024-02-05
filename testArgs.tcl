#! /bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" ${1+"$@"}

# /bin/sh executes tclsh with arguments, if any.
# If there are no arguments, first argument $1 is unset in sh.
# If first argument $1 is set, 'sh' replaces it with all arguments $@.
# tclsh interprets backslash as continuation of the comment string, sh does not.

# man tclsh

# ./testArgs.tcl $(uname -a)

if {$argc > 0} {
  puts "\nThe name of the script is:            $argv0"
  # puts "Total count of arguments passed is:   [llength $argv]"
  puts "Total count of arguments passed is:   $argc"
  puts "The arguments passed are:             $argv"
  puts "The first argument passed was:        \{[lindex $argv 0]\}"
  # puts "The last argument passed was:         \{[lindex $argv [expr {[llength $argv] - 1}]]\}\n"
  puts "The last argument passed was:         \{[lindex $argv end]\}\n"
} else {
  puts "\nThe name of the script is:            $argv0"
  puts "There are no arguments!\n"
}

# puts [join $argv "\n"]

# END OF SCRIPT

