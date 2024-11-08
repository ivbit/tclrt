#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

set cNorm \u001b\[0m
set cRed \u001b\[31m
set cYel \u001b\[33m
set cBlue \u001b\[34m

proc print_dict {dict args} {
  if {[llength $args] == 0} then {
    set names [lsort -dict [dict keys $dict]]
  } else {
    set names [list]
    foreach pattern $args {
      lappend names {*}[lsort -dict [dict keys $dict $pattern]]
    }
  }
  set maxl 0
  foreach name $names {
    expr {
      [string length $name] > $maxl &&
      [set maxl [string length $name]]
    }
  }
  incr maxl 2
  set lines [list]
  foreach name $names {
    lappend lines [format {%-*s = %s} $maxl $name [dict get $dict $name]]
  }
  chan puts stdout [join $lines \n]
}

# Each command decides for itself how to intrepret any return code.
# Custom return code must be an integer.
# Any return code other than 0 is an 'exceptional return' - 'exception'.
# In case of 'return -code 2', 'return' competes with return code 2,
# and -level is increased by 1, -code is set to 0.
# Procedures and 'source' command handle code 2 (return) in a special way:
# 1. Decrement the -level by 1
# 2. If the -level became 0, return with code from -code
# 3. If the -level > 0, propagate the exception to the caller, return with code 2
# Looping commands handle code 3 (break) and code 4 (continue).
# Code 0 (ok) and any exceptional code can be handled by 'catch' and 'try' commands.
#
# Tcl-defined return codes
# 0 ok
# The command was completed successfully.
# 
# 1 error
# An error occured during the execution of a command.
# 
# 2 return
# Signals the caller that is should stop it's own execution and
# return control back to it's own caller.
# 
# 3 break
# If caller is a looping construct, 'break' signifies termination of the loop.
# 
# 4 continue
# If caller is a looping construct, 'continue' signifies skipping the
# remaining part of the current iteration and move to the next iteration.

set sep [string repeat * 80]

set i 0
while {1} {
  incr i
  if {$i == 1} then {
    incr i
    continue
  }
  puts "i = $i"
  if {$i >= 4} then {break}
}

proc cmdB {} {
  return {a value}
  puts {cmdB returning}
}
proc cmdA {} {
  cmdB
  puts {cmdA returning}
}
cmdA

proc cmdB {} {
  set x cmdB
  uplevel 1 {
    puts "x = $x"
    return
  }
  puts {cmdB returning}
}
proc cmdA {} {
  set x cmdA
  cmdB
  puts {cmdA returning}
}
cmdA

# Default is: return -code 0 -level 1 {}
proc demo1 {} {
  puts {demo1 enter}
  return -code ok -level 1
  puts {demo1 exit}
}
proc demo0 {} {
  puts {demo0 enter}
  return -code ok -level 0
  puts {demo0 exit}
}
demo1
demo0

# Identity function
# https://en.wikipedia.org/wiki/Multiplicative_inverse
# 'string cat Inf' can be used instead of 'return -level 0 Inf' (in Tcl 8.6)
set n 0
set reciprocal [if {$n == 0} then {return -level 0 Inf} else {expr {1.0 / $n}}]
puts $reciprocal

# Return from different levels in the call stack
proc demo1 {levels} {
  puts {demo1 enter}
  demo2 $levels
  puts {demo1 exiting}
  return {demo1 return value}
}
proc demo2 {levels} {
  puts {demo2 enter}
  demo3 $levels
  puts {demo2 exiting}
  return {demo2 return value}
}
proc demo3 {levels} {
  return -level $levels {demo3 return value}
}
puts $sep
puts [demo1 1]
puts $sep
puts [demo1 2]
puts $sep
puts [demo1 3]
puts $sep

proc check_integer {arg} {
  if {![string is integer -strict $arg]} then {
    error "$arg is not an integer."
  }
}

proc tohex {arg} {
  check_integer $arg
  return [format %x $arg]
}

# Better to understand error message
proc check_integer {arg} {
  if {![string is integer -strict $arg]} then {
    return -level 2 -code error "$arg is not an integer."
  }
}

chan puts stdout [tohex 127]

puts $sep

# Emulating other commands with return
# 'break'
proc stop {} {
  return -code 3
}
foreach char {a b c} {
  puts $char
  stop
}

# Custom return codes
proc ret5 {result} {return -code 5 $result}
catch {ret5 {Code 5!}} result
puts $result

# Custom 'return options dictionary'
# 'return' will add any unknown option to 'return options dictionary'
proc badcode {} {
  error {Something went wrong}
}
proc demo {} {
  if {[catch {badcode} result ropts]} then {
    return -options $ropts -timestamp [clock seconds] $result
  } else {
    return $result
  }
}
catch demo result ropts
puts $result
puts [dict get $ropts -timestamp]

puts $sep

# catch SCRIPT ?RESULTVAR? ?OPTSVAR?
# 'catch' returns result code from the script
puts [catch {set x {Normal completion}}]
puts [catch {error {An error message}}]
puts [catch {return {Return result}}]
puts [catch {break}]
puts [catch {continue}]
puts [catch {return -code 5 -level 0}]
puts [catch {return -code 6 -level 1}]

puts $sep

# RESULTVAR holds the result of the script
puts [catch {set x 100} result]
puts $result
puts [catch {set x $nosuchvar} result]
puts "Error: $result"

puts $sep

# OPTSVAR holds 'return options dictionary'
# unset ropts
proc badproc {} {
  set y $nosuchvar
}
puts [catch {badproc} result ropts]
puts "Result: $result"
# Error info
puts [dict get $ropts -errorinfo]
# Same information is stored in errorInfo global variable
puts $::errorInfo
# Error line number
puts "Error line number: [dict get $ropts -errorline]"
# Error code
puts [dict get $ropts -errorcode]
# Same information is stored in errorCode global variable
puts $::errorCode

if {[catch {open /tmp/options.ini r} result ropts]} then {
  if {[lindex $::errorCode 0] eq "POSIX" &&
    [lindex $::errorCode 1] eq "ENOENT"} then {
      # File does not exist
      puts {Using default options.}
  } else {
    # Explicitly propagate the error
    return -code error -options $ropts $result
  }
} else {
  # $result holds opened channel
  puts {Reading from $result.}
  close $result
}

# Error stack
puts [dict get $ropts -errorstack]
# Information about the last error encountered
puts [info errorstack]

puts $sep

# try BODY ?HANDLER ...? ?finally FINALSCRIPT?
# HANDLER forms:
# on CODE VARLIST HANDLEBODY
# trap ERRORPATTERN VARLIST HANDLERBODY
# on CODE: interer, or one of: ok, error, return, break, continue
# trap matches if BODY completes with a return code of 'error' and
# ERRORPATTERN matches the 'return options dictionary' -errorcode value.

# Any return code can be handled, including ok and custom numeric codes.

# 'try' is byte compiled, 'eval' is not byte compiled. 'try' without handlers
# evaluates the script similar to 'eval'. Use 'try' instead of 'eval' to
# evaluate a single script in the current context.
puts [try {set x 1}]

# Completes normally: 'error' return code is trapped
puts [catch {
  try {error {Error!}} on error result {puts Trapped!}
}]

# Propagates 'break' as no handler defined for it
puts [catch {
  try {break} on error result {puts Trapped!}
}]

try {
  error {Something went wrong!}
} on 1 {result ropts} {
  puts "${cBlue}Result${cNorm}: $result"
  puts "${cYel}Return options dictionary${cNorm}:"
  print_dict $ropts
} finally {
  puts [string cat $cRed $sep $cNorm]
}

try {
  set x $nosuchvar
} on ok {result ropts} {
  puts $result
  print_dict $ropts
} on error {result ropts} {
  puts "${cBlue}Result${cNorm}: $result"
  puts "${cYel}Return options dictionary${cNorm}:"
  print_dict $ropts
} finally {
  puts [string cat $cYel $sep $cNorm]
}

proc div {a b} {
  try {
    return [::tcl::mathop::/ $a $b]
  } trap {ARITH DIVZERO} result {
    return [::tcl::mathop::/ $a 0.0]
  }
}
puts [div 3 0]
puts [div 4 2]

chan puts {set fd [open data.xml]}
try {
  chan puts {return -level 0 [parse_data [chan read $fd]]}
} finally {
  chan puts {close $fd}
}

# 'finally' completes before the return from 'try'
chan puts [try {return -level 0 RESULT} finally {chan puts DONE}]

chan puts stdout $sep

# Raising errors
# throw ERRORCODE MESSAGE
# error MESSAGE ?ERRORINFO? ?ERRORCODE?
proc change_password {name pass} {
  set len [string length $pass]
  if {$len < 8} {
    error {Password length must be at least 8.} {} [list OAUTH PASSLEN $len]
  }
  chan puts "$name : $pass"
}
# General convention for the format of error codes:
# a word that identifies the module, or package (OAUTH),
# one, or more failure 'reason' codes (PASSLEN),
# optionally some detail about the error (minimum password length).
catch {change_password user abc} result ropts
puts stdout [string cat $cBlue $result $cNorm]
print_dict $ropts
puts stdout [string cat $::cRed $::errorCode $::cNorm]

proc change_password {name pass} {
  set len [string length $pass]
  if {$len < 8} {
    throw [list OAUTH PASSLEN $len] {Password length must be at least 8.}
  }
  chan puts "$name : $pass"
}
catch {change_password user abc123} result ropts
puts stdout [string cat $cBlue $result $cNorm]
print_dict $ropts
puts stdout [string cat $::cRed $::errorCode $::cNorm]

# return -code 1 ?-errorcode ECODE? ?-errorinfo EINFO? ?-errorstack ESTACK? MSG
proc check_boolean_1 {arg} {
  if {![string is boolean -strict $arg]} {
    throw {TYPECHECK BOOLEAN} "$arg is not a boolean"
  }
}
proc check_boolean_2 {arg} {
  if {![string is boolean -strict $arg]} {
    return -code error -errorcode {TYPECHECK BOOLEAN} "$arg is not a boolean"
  }
}
proc check_boolean_3 {arg} {
  if {![string is boolean -strict $arg]} {
    return -level 0 -code error -errorcode {TYPECHECK BOOLEAN}\
      "$arg is not a boolean"
  }
}
proc check_boolean_4 {arg} {
  if {![string is boolean -strict $arg]} {
    return -level 5 -code error -errorcode {TYPECHECK BOOLEAN}\
      "$arg is not a boolean"
  }
}
try {check_boolean_1 abc} trap {TYPECHECK BOOLEAN} {result ropts} {
  chan puts stdout [string cat $cBlue $result $cNorm]
  chan puts stdout [dict get $ropts -errorinfo]
}
try {check_boolean_2 jkl} trap {TYPECHECK BOOLEAN} {result ropts} {
  chan puts stdout [string cat $cBlue $result $cNorm]
  chan puts stdout [dict get $ropts -errorinfo]
}
try {check_boolean_3 xyz} trap {TYPECHECK BOOLEAN} {result ropts} {
  chan puts stdout [string cat $cBlue $result $cNorm]
  chan puts stdout [dict get $ropts -errorinfo]
}
try {check_boolean_4 FOO} trap {TYPECHECK BOOLEAN} {result ropts} {
  chan puts stdout [string cat $cBlue $result $cNorm]
  chan puts stdout [dict get $ropts -errorinfo]
} on return {result ropts} {
  chan puts stdout [string cat $cRed $result $cNorm]
  chan puts stdout [dict get $ropts]
} finally {
  chan puts stdout [string cat $cYel $sep $cNorm]
}

# Forwarding exceptions
proc recover args {return 0}
proc do_something {} {
  set x $nosuchvar
}
# -options OPTIONS
# The value OPTIONS must be a valid dictionary. The entries of that dictionary
# are treated as additional option value pairs for the 'return' command. 
proc demo {} {
  if {[catch {do_something} result ropts]} then {
    if {![recover]} then {
      return -options $ropts $result
    }
  }
}
catch {demo} result ropts
chan puts stdout [string cat $cBlue $result $cNorm]
print_dict $ropts

chan puts stdout $sep

# 'error' is used in legacy code to forward exceptions, use 'return' instead
proc demo {} {
  if {[catch {do_something} result]} then {
    if {![recover]} then {
      error $result $::errorInfo $::errorCode
    }
  }
}
catch {demo} result ropts
chan puts stdout [string cat $cYel $result $cNorm]
print_dict $ropts

chan puts stdout $sep

# Custom control statements
proc repeat {loopvar count body} {
  upvar 1 $loopvar iter
  for {set iter 0} {$iter < $count} {incr iter} {
    set ret_code [catch {uplevel 1 $body} result ropts]
    switch $ret_code {
      0 {}
      3 {return}
      4 {}
      default {
        dict incr ropts -level
        return -options $ropts $result
      }
    }
  }
  return
}
set sum 0
repeat i 10 {
  incr sum $i
}
chan puts stdout $sum

# New command to skip iterations inside 'repeat' loop.
# 'skip' behaves like 'continue', but lets the user specify
# how many iterations to skip.
proc skip {skip_count} {
  return -code 5 $skip_count
}

proc repeat {loopvar count body} {
  upvar 1 $loopvar iter
  for {set iter 0} {$iter < $count} {incr iter} {
    set ret_code [catch {uplevel 1 $body} result ropts]
    switch $ret_code {
      0 {}
      3 {return}
      4 {}
      5 {incr iter $result}
      default {
        dict incr ropts -level
        return -options $ropts $result
      }
    }
  }
  return
}

repeat n 5 {
  chan puts stdout "Iteration $n"
  if {$n == 1} then {
    skip 2
  }
}

chan puts stdout $sep

repeat n 5 {
  chan puts stdout "Iteration $n"
  if {$n == 1} then {
    skip 2
  }
  chan puts stdout [string cat $cYel "IEND      $n" $cNorm]
}

proc repeat {count body} {
  set count [scan $count %d]
  if {
    $count eq {} ||
    $count < 1 ||
    $count > 999
  } then {
    set count 10
  }
  for {set iter 0} {$iter ^ $count} {incr iter} {
    set ret_code [catch {uplevel 1 $body} result ropts]
    switch $ret_code {
      0 {}
      3 {return}
      4 {}
      default {
        dict incr ropts -level
        return -options $ropts $result
      }
    }
  }
  return
}
repeat 2 {puts "Repeat: [info level]: Hello world!"}

repeat 6 {
  chan puts stdout [incr z]
  if {$z == 3} break
}

chan puts stdout $sep

# Procedure replacement for 'return' command
proc myReturn {args} {
  set result {}
  if {[llength $args] & 1} {
    set result [lindex $args end]
    set args [lrange $args 0 end-1]
  }
  set options [dict merge {-level 1} $args]
  dict incr options -level
  return -options $options $result
}
catch {myReturn -level 55 -code 12 {Hello world!}} result ropts
chan puts stdout $result
chan puts stdout $ropts


