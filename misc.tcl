#! /bin/sh
# start \
exec tclsh "$0" ${1+"$@"}

# From 'tclsh' shell:
# source misc.tcl

# 'chan puts -nonewline' can be used with 'flush stdout'
# 'stderr' has '-buffering none', no need to 'chan flush'
# Set title of terminal emulator's window
chan puts stderr "\u001b]0;Tcl programming language\u0021\u0007"

# Set title of terminal emulator's window on Linux
proc stitle {{title "Tcl programming language\u0021"} args} {
  chan puts -nonewline stderr "\u001b]0;${title} ${args}\u0007"
}
# stitle \u263eTCL\u263d

# Clear screen on Linux
proc cls {} {
  chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"
}
proc clear {} {
  chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"
}
# Clear screen procs in 'auto_index' array
set auto_index(clear) {proc clear {} {chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"}}
set auto_index(cls) {proc cls {} {chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"}}

# Clear screen
chan puts "\u001b\[3J\u001b\[1;1H\u001b\[0J"

# Underlined text ('macron' symbol '\xaf', '\u00af', '\U000000af')
set title {Page title!}
# chan puts "$title\n[string repeat \xaf [string length $title]]"
chan puts "$title\n[string repeat \u00af [string length $title]]"
# chan puts "$title\n[string repeat \U000000af [string length $title]]"
chan puts {Page content.}
unset title

# Use 'scan' because Tcl treats numbers beginning with '0' as octal numbers.
proc minute_of_day {time_of_day} {
  lassign [split $time_of_day :] h m
  expr {[scan $h %d] * 60 + [scan $m %d]}
}

chan puts [minute_of_day 12:00]
chan puts [minute_of_day 09:00]

# ASCII in the hexadecimal (also base-16 or simply hex) numeral system.
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

chan puts [ascii]

# When part of the string is encoded with backslashes and decimal values
proc get_printable_name {encoded_name} { 
  return [
    subst [
      regsub -all {\\([0-9]{3})} $encoded_name {[format %c [scan \1 %d]]}
    ]
  ]
}
chan puts [
  get_printable_name {linux\032\09100\05826\05809\093._gnu._udp.localhost.}
]


# Print odd numbers
set lst [list 0 1 2 3 4 5 6 7 8 9]
foreach i $lst {if {$i % 2} then {chan puts -nonewline $i\ }}; chan puts {}
foreach i $lst {if {$i & 1} then {chan puts -nonewline $i\ }}; chan puts {}

# Print even numbers
foreach i $lst {if {!($i % 2)} then {chan puts -nonewline $i\ }}; chan puts {}
foreach i $lst {if {$i % 2 == 0} then {chan puts -nonewline $i\ }}; chan puts {}
foreach i $lst {if {!($i & 1)} then {chan puts -nonewline $i\ }}; chan puts {}
foreach i $lst {if {($i & 1) == 0} then {chan puts -nonewline $i\ }}; chan puts {}

# https://stackoverflow.com/questions/40226851/rename-a-global-array-tcl
# https://wiki.tcl-lang.org/page/How+to+pass+arrays
array set ar1 {item1 A item2 B item3 C}
parray ar1
array set ar2 [array get ar1]
parray ar2

# Non-deterministic choice operator
foreach x {1 2 3 4} {
  foreach y {3 9 7} {
    if {$x**2 == $y} then {chan puts stderr "x = $x; y = $y"}
  }
}

# Command parsing demonstration:
chan puts stdout "[catch {set somevar hello} result] $result"

# Checking user input with 'for'
for {set lst [list]} {[llength $lst] != 2} {
  chan puts -nonewline stderr {Type exactly 2 words: }
  chan gets stdin lst
} { }
chan puts stderr "1: [lindex $lst 0]; 2: [lindex $lst 1]"

# https://wiki.tcl-lang.org/page/corovars
# 'Private' variables in coroutine at stack level 1 with 'upvar #1'
proc pr1 {} {
  upvar #1 private var
  set var 15
  pr2
}
proc pr2 {} {
  upvar #1 private i
  incr i 20
}
# Procedure 'prLvl1' is running at stack level 1 in coroutine's stack
proc prLvl1 {} {
  pr1
  yield
  yield "'Private' value is $private"
}
coroutine testPrivate prLvl1
catch {set private} result
chan puts stdout $result
chan puts stdout [testPrivate]

# Deleting a procedure after is has been 'copied' into coroutine's context
proc EvenNumbers {} {
  yield
  set i 0
  while 1 {
    yield $i
    incr i 2
  }
}
coroutine nextEven EvenNumbers
rename EvenNumbers {}
for {set i 0} {$i <= 10} {incr i} {
  chan puts -nonewline stdout [nextEven]\u0020
}
chan puts stdout {}

# Slow, for interactive use only:
# Using 'time' to repeat script
time {lappend tLst [incr tInt]} 20
chan puts stdout time:\ $tLst

# Flawed floating point representation (result is 200 instead of 201):
chan puts stdout [expr {int(100 * 2.01)}]
# How to fix the problem:
chan puts stdout [expr {round(100 * 2.01)}]

# 'NaN' is not equal to itself, skip 'NaN' values:
set lst {1 2.0 NaN -3 4.6 -NaN 7 -2 -4 -NaN NaN 9 3 8 1.2}
set sum 0.0
foreach num $lst {
  if {$num == $num} then {
    set sum [expr {$sum + $num}]
  }
}
chan puts stdout "Sum without 'NaN' values is: $sum"

chan puts stdout {}
return

