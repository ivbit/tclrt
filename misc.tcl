#! /bin/sh
# start \
exec tclsh "$0" ${1+"$@"}

# From 'tclsh' shell:
# source misc.tcl

# 'puts -nonewline' can be used with 'flush stdout'
# Set title of terminal emulator's window
puts "\u001b]0;Tcl programming language\u0021\u0007"

# Clear screen
puts "\u001b\[3J\u001b\[1;1H\u001b\[0J"

# Underlined text ('macron' symbol '\xaf', '\u00af', '\U000000af')
set title {Page title!}
# puts "$title\n[string repeat \xaf [string length $title]]"
puts "$title\n[string repeat \u00af [string length $title]]"
# puts "$title\n[string repeat \U000000af [string length $title]]"
puts {Page content.}
unset title

# Use 'scan' because Tcl treats numbers beginning with '0' as octal numbers.
proc minute_of_day {time_of_day} {
  lassign [split $time_of_day :] h m
  expr {[scan $h %d] * 60 + [scan $m %d]}
}

puts [minute_of_day 12:00]
puts [minute_of_day 09:00]

# ASCII in The hexadecimal (also base-16 or simply hex) numeral system.
proc ascii {} {
  set res {}
  for {set i 33} {$i < 127} {incr i} {
    append res [format %2.2x:%c $i $i] { }
    if {$i % 16 == 0} then {
      append res \n
    }
  }
  set res
}

puts [ascii]

# When part of the string is encoded with backslashes and decimal values
proc get_printable_name {encoded_name} { 
  return [
    subst [
      regsub -all {\\([0-9]{3})} $encoded_name {[format %c [scan \1 %d]]}
    ]
  ]
}
puts [
  get_printable_name {linux\032\09100\05826\05809\093._gnu._udp.localhost.}
]

# Clear screen procs in 'auto_index' array
set auto_index(clear) {proc clear {} {chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"}}
set auto_index(cls) {proc cls {} {chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"}}

return

