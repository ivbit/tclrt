#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# {*} - expansion operator: each item in the following list becomes
# an additionl word in the current command.

# args provide patterns in form of wildcards for matching dictionary keys
# * '0 or more'; ? 'exactly 1'; [characters]; [range]; [-a-zX] 'used together';
# backslash 'escape character'; double-backslash 'to escape backslash itself'
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

set sep [string repeat * 80]

namespace eval areas {
  variable pi 3.142
  proc circle {radius} {
    variable pi
    set area [::tcl::mathop::* $pi $radius $radius]
    return $area
  }
}
puts "Area: [areas::circle 2]."

# info level ?number?
# If number is not specified, this command returns a number giving the stack
# level of the invoking procedure, or 0 if the command is invoked at top-level.
# If number is specified, then the result is a list consisting of the name and
# arguments for the procedure call at level number on the stack. If number is
# positive then it selects a particular stack level (1 refers to the top-most
# active procedure, 2 to the procedure it called, and so on); otherwise it
# gives a level relative to the current level (0 refers to the current
# procedure, -1 to it's caller, and so on).
proc il {} {
  puts "Level: [info level]."
  puts [info level 0]
}
il

# upvar ?level? otherVar myVar ?otherVar myVar ...?
# If level is an integer then it gives a distance (up the procedure calling
# stack). If level consists of '#' followed by a number then the number gives
# an absolute level number. If level is omitted then it defaults to 1. Level
# cannot be defaulted if the first command argument starts with a digit or '#'. 
proc add2 {name} {
  upvar $name x
  incr x 2
}
set i 10
puts "add2 i: [add2 i]"

proc decr {varName {decrement 1}} {
  upvar 1 $varName var
  incr var [::tcl::mathop::- $decrement]
}
puts "decr j: [decr j]"

set myvar Global
proc gproc {} {
  set myvar gproc
  upvar #0 myvar var#0
  upvar #1 myvar var#1
  upvar 1 myvar var1 nsvar nsvar
  upvar 0 myvar var0
  puts "var#0 = ${var#0}, var#1 = ${var#1}, var1 = $var1, var0 = $var0"
  set nsvar {::ns::nsvar is created via linked variable.}
  unset var#0
}

namespace eval ns {
  variable myvar ns
  proc nproc {} {
    variable nsvar
    set myvar nproc
    gproc
  }
}

namespace eval ns nproc
puts "[info exists ::myvar] - ::myvar is unset via linked variable."
puts $::ns::nsvar

# lprepend variable ?element ...?
proc lprepend {varname args} {
  upvar 1 $varname var
  # expr {![info exists var] && [set var {}; string cat 1]}
  if {![info exists var]} then {set var {}}
  set var [linsert $var 0 {*}$args]
}
set lvar {2 1}
lprepend lvar 4 3
puts $lvar
lprepend lfoo hello world
puts $lfoo

# Change values of all array elements to uppercase
proc upcase_array {arrayvar} {
  upvar 1 $arrayvar arr
  foreach {key val} [array get arr] {
    set arr($key) [string toupper $val]
  }
}
array set myarr {1 one 2 two}
upcase_array myarr
parray myarr

# Create aliases
# 'upvar 0' is not changing the call frame or the variable context.
# New name is created and linked to a variable that was already available in
# the current context by using fully qualified name.
# Variable aliases created with 'upvar' can't be used with 'trace', 'vwait'
# and '-textvariable' option of Tk widgets. These commands require name of
# the original variable.
proc myproc {} {
  upvar 0 ::ns::nsvar nsvar
  upvar 0 ::myarr(0) elem
  puts $nsvar
  set elem zero
}
myproc
puts "myarr(0) = $myarr(0)"

# uplevel ?level? arg ?arg ...?
proc cmdA {} {cmdB}
proc cmdB {} {cmdC}
proc cmdC {} {
  uplevel 0 {puts [info level]:[info level [info level]]}
  uplevel 1 {puts [info level]:[info level [info level]]}
  uplevel 2 {puts [info level]:[info level [info level]]}
  uplevel #1 {puts [info level]:[info level [info level]]}
}
cmdA

proc repeat {loopvar count body} {
  upvar 1 $loopvar iter
  for {set iter 0} {$iter < $count} {incr iter} {
    uplevel 1 $body
  }
  return
}

set sum 0
repeat i 10 {
  incr sum $i
}
puts $sum

set sum 0
repeat i 5 {
  incr sum $i
}
puts "The sum of the first $i natural numbers is $sum."

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
    uplevel 1 $body
  }
  return
}
repeat 2 {puts "Repeat: [info level]: Hello world!"}

# Finding caller's namespace
# Example procedure
proc newobj {name} {
  if {[string match ::* $name]} {
    set cmdname $name
  } else {
    set ns [uplevel 1 {namespace current}]
    if {$ns eq {::}} then {
      set cmdname ::$name
    } else {
      set cmdname ${ns}::$name
    }
  }
  if {[namespace which -command $cmdname] ne {}} then {
    error "Command $name already exists!"
  }
  proc $cmdname {} "puts {I am $cmdname}"
  return
}

newobj cmd1
# ::cmd1
cmd1
newobj ns::cmd2
ns::cmd2
namespace eval ns {newobj cmd3}
# ::ns::cmd3
ns::cmd3
namespace eval ns {newobj ::cmd4}
cmd4

proc demo1 {} {
  puts "[info level [info level]]: Level [info level]"
  demo2
}
proc demo2 {} {
  puts "[info level [info level]]: Level [info level]"
  uplevel 1 {
    puts "uplevel: Level [info level]"
    demo3
  }
}
proc demo3 {} {
  puts "[info level [info level]]: Level [info level]"
}
demo1

puts $sep

# tailcall command ?arg ...?
# tailcall - replace the current procedure with another command.
# 'tailcall' can only be called from a proc, lambda or method.
#  'tailcall' may not be invoked from within an uplevel into a procedure
#  or inside a catch inside a procedure or lambda.
proc tcExample {} {
  tailcall info level
}
puts "'tailcall' replaced the procedure in global context at level [tcExample]"

# Print alternating lines with different colors
proc lstColor1 {lst} {
    if {[llength $lst]} {
        puts "\u001b\[34m[lindex $lst 0]\u001b\[0m"
        tailcall lstColor2 [lrange $lst 1 end]
    }
}
proc lstColor2 {lst} {
    if {[llength $lst]} {
        puts "\u001b\[35m[lindex $lst 0]\u001b\[0m"
        tailcall lstColor1 [lrange $lst 1 end]
    }
}
lstColor1 {tailcall in Tcl programming language}

# 'sum' without 'tailcall'
proc sum {n {total 0}} {
  if {$n == 0} then {return $total}
  sum [expr {$n - 1}] [incr total $n]
}
puts [sum 10]

# 'sum' with 'tailcall'
proc sum {n {total 0}} {
  if {$n == 0} then {return $total}
  tailcall sum [expr {$n - 1}] [incr total $n]
}
puts [sum 1000]

proc sum {n {total 0}} {
  if {$n == 0} then {return $total}
  tailcall sum [::tcl::mathop::- $n 1] [incr total $n]
}
puts [sum 1000]

# Fibonacci
proc fibh {n v1 v2} {
  if {$n == 1} then {
    return $v1
  } else {
    tailcall fibh [::tcl::mathop::- $n 1] [::tcl::mathop::+ $v1 $v2] $v1
  }
}
proc fib {n} {
  if {$n == 0} then {
    return 0
  } else {
    tailcall fibh $n 1 0
  }
}
puts [fib 8]

# Factorial
proc fac {n {acc 1}} {
  if {$n < 2} then {
    return $acc
  }
  tailcall fac [::tcl::mathop::- $n 1] [::tcl::mathop::* $acc $n]
}
puts [fac 8]

puts $sep

# _builtin_while will be executed in global context
rename while _builtin_while
proc while args {
  puts {while called}
  tailcall _builtin_while {*}$args
}
set i 2
while {$i > 0} {
  puts $i
  incr i -1
}

# 'puts {demo1 exit}' will never be executed
proc demo1 {} {
  puts {demo1 enter}
  tailcall puts {tailcalled puts}
  puts {demo1 exit}
}
proc demo {} {
  puts {demo enter}
  demo1
  puts {demo exit}
}
demo

puts $sep

# If called by 'uplevel' from 2nd procedure into 1st procedure,
# 'tailcall' will run after 1st procedure completes it's execution.
proc demo1 {} {
  puts {demo1 enter}
  uplevel 1 {
    tailcall puts {tailcalled puts}
  }
  puts {demo1 exit}
}
demo

puts $sep

proc seti1 {} {
  set ::i 3
  seti2
  set ::i 5
  puts $::i
}
proc seti2 {} {
  uplevel 1 {
    tailcall set i 9
  }
}
seti1
puts $i

puts $sep

# 'info frame' - metainformation about the script being executed (hidden frames)
proc demo {} {
  puts "demo level: [info level], frame: [info frame]"
  eval {
    puts "eval level: [info level], frame: [info frame]"
  }
  uplevel 1 {
    puts "uplevel level: [info level], frame: [info frame]"
  }
}
puts "global level: [info level], frame: [info frame]"
demo

proc demo {} {
  demo2 {argument}
}
proc demo2 {arg} {
  puts "Frame: [info frame]"
  puts "Command is \[info frame 2\]."
  print_dict [info frame 2]
}
demo

puts $sep

rename while {}
rename _builtin_while while

# Lazy initialization using 'trace' command
proc sum {n {acc 0}} {
  while {$n ^ 0} {
    incr acc $n
    incr n -1
  }
  return $acc
}
puts [sum 5]

proc calculate_sum {varname elem op} {
  upvar 1 $varname var
  if {![info exists var($elem)]} then {
    puts "Calculating sum of $elem"
    set var($elem) [sum $elem]
  }
}

array set sums {}
trace add variable sums read calculate_sum
puts "Sum of 1..=5 is $sums(5)."
puts "Sum of 1..=3 is $sums(3)."
puts "Sum of 1..=5 is $sums(5)."
parray sums

# Constant variables using 'trace' command
proc lambda {params body args} {
  return [list ::apply [list $params $body] {*}$args]
}

proc const {varname value} {
  upvar $varname var
  trace add variable var write \
    [lambda {constval name element op} {
      upvar 1 $name var
      set var $constval
      throw {CONST MODIFY} {Attempt to modify a constant.}
    } $value]
}

set e 2.71828
const e 2.71828
# set e 0
puts $e

puts $sep

# Data flow programming
proc getval cell {
  upvar #0 $cell var
  return [expr {[info exists var] ? $var : 0}]
}
proc updateB1 {args} {
  set ::B1 [expr {[getval ::A1] + [getval ::A2]}]
}
proc updateB2 {args} {
  set ::B2 [expr {[getval ::B1] ** 2}]
}

trace add variable A1 {write unset} updateB1
trace add variable A2 {write unset} updateB1
trace add variable B1 {write unset} updateB2

set A1 3
set A2 4
puts $B2
set A2 2
puts $B2

puts $sep

# Tracing array variables
proc tracer {varname elem op} {
  puts "Trace: varname=\"$varname\", elem=\"$elem\", op=\"$op\""
}

trace add variable arr(x) {read write unset} tracer
set arr(x) 100
set arr(x)
array set arr {x 0 y 1}
array get arr
unset arr

puts $sep

array set arr {x 0 y 1}
trace add variable arr {read write unset array} tracer
array set arr {a1 2 a2 3}
array unset arr a*
set arr(x) 10
array get arr
unset arr

# 'list' prevents double substitution by 'eval', 'namespace eval', 'uplevel'
proc uputs {str} {
  # uplevel 1 [list chan puts stdout $str]
  tailcall chan puts stdout $str
}

uputs {$sum}
uputs {String of text.}

uputs $sep

# Tracing command lifetimes
proc tracer {command elem op} {
  puts "Trace: command=\"$command\", elem=\"$elem\", op=\"$op\""
}

namespace eval ns {proc demoX {} {}}
trace add command ns::demoX {rename delete} tracer
rename ns::demoX demoY
rename demoY {}

# Tracing command execution
# Performance penalty due to inability of Tcl to compile byte code for
# commands with execution traces attached. Use only for debugging.
proc tracer args {
  puts "Trace: [join $args {, }]"
}
proc demo {args} {demo2 X Y}
proc demo2 {args} {demo3}
proc demo3 {} {return {result}}
trace add execution demo {enter leave} tracer
puts [demo]
trace add execution demo {enterstep leavestep} tracer
puts [demo]
# 'trace remove' should have the same args as 'trace add'
trace remove execution demo {enterstep leavestep} tracer
puts [demo]

uputs $sep

# trace info variable NAME
# trace info command NAME
# trace info execution NAME
trace add execution demo {enterstep leavestep} tracer
puts "trace info: [trace info execution demo]"
foreach tr [trace info execution demo] {
  trace remove execution demo {*}$tr
}
puts "trace info: [trace info execution demo]"

uputs $sep

proc print_args {args} {
  puts "Args: [join $args {, }]"
}

set callback {print_args A ; print_args B C}
proc script_cb {script} {
  uplevel 1 $script {(script)}
}
proc cmd_cb {cmdprefix} {
  tailcall {*}$cmdprefix {(command)}
}
script_cb $callback
cmd_cb $callback

# 'list' should be used to construct command prefixes
set some_value {First arg}
cmd_cb [list print_args $some_value {;} {Third arg}]

set part_numbers {part_100_b PART_100_C PART_20_B}
puts [lsort -command [lambda {s1 s2} {
  return [expr {[string length $s1] - [string length $s2]}]
}] $part_numbers]

puts $sep

proc proc_ex {name arglist initcode body} {
  if {![string match ::* $name]} {
    set ns [uplevel 1 {namespace current}]
    set name ${ns}::$name
  }
  set template {
    proc NAME {ARGS} {
      INIT
      proc NAME {ARGS} {BODY}
      tailcall {*}[info level 0]
    }
  }
  set replacements [list NAME $name ARGS $arglist INIT $initcode BODY $body]
  # {*}[string map $replacements $template]
  eval [string map $replacements $template]
}

proc_ex say_hello {message} {
  puts {Loading package msgcat}
  package require msgcat
} {
  puts [msgcat::mc $message]
}

puts [info body say_hello]
say_hello {Hello World!}
puts [info body say_hello]
say_hello {Hello Universe!}

puts $sep

proc proc_ex {name arglist initcode body} {
  if {![string match ::* $name]} {
    set ns [uplevel 1 {namespace current}]
    set name ${ns}::$name
  }
  # {*}[format {...}
  eval [format {
    proc %1$s {%2$s} {
      %3$s
      proc %1$s {%2$s} {%4$s}
      tailcall {*}[info level 0]
    }
  } $name $arglist $initcode $body]
}

proc_ex say_hello {message} {
  puts {Loading package msgcat}
  package require msgcat
} {
  puts [msgcat::mc $message]
}

puts [info body say_hello]
say_hello {Hello There!}
puts [info body say_hello]
say_hello {Hello Everybody!}

chan puts $sep

# Transform data into Tcl script
proc html_parse {html callback} {
  set re {<(/?)([^ \t\r\n>]+)[ \t\r\n]*([^>]*)>}
  set sub "\}\n[list $callback] {\\2} {\\1} {\\3} \{"
  regsub -all $re [string map {\{ \&ob; \} \&cb;} $html] $sub script
  eval "$callback PARSE {} {} \{ $script \}; $callback PARSE / {} {}"
}

set html {
  <p class="important">Something <b>really</b> important.</p>
  <p>A second paragraph.</p>
}

set callback html_cb

proc html_cb {tag place attrs content} {
  if {$tag ne {PARSE}} {
    if {$attrs ne {}} {
      set attrs " $attrs"
    }
    puts -nonewline "<$place[string toupper $tag]$attrs>$content"
  }
}

html_parse $html html_cb
chan puts {}

chan puts $sep

# Metaprogramming for generalization
proc pairs {la lb} {
  set res {}
  foreach a $la {
    foreach b $lb {
      lappend res [list $a $b]
    }
  }
  return $res
}

puts [pairs {a b} {1 2 3}]

# forall VAR LIST ?VAR LIST ...? BODY
proc forall args {
  if {[llength $args] < 3 || !([llength $args] & 1)} {
    return -code error {wrong # args: should be\
      "forall varList list ?varList list ...? body"}
  }
  set body [lindex $args end]
  set args [lrange $args 0 end-1]
  while {[llength $args]} {
    set varName [lindex $args end-1]
    set list [lindex $args end]
    set args [lrange $args 0 end-2]
    set body [list foreach $varName $list $body]
  }
  # puts "Debug: $body"
  uplevel 1 $body
}

forall x {a b} y {1 2 3} {lappend res [list $x $y]}
# foreach x {a b} {foreach y {1 2 3} {lappend res [list $x $y]}}
puts $res

set res {}
forall x {a b} y {1 2 3} z {M N} {append res $x$y$z}
# foreach x {a b} {foreach y {1 2 3} {foreach z {M N} {append res $x$y$z}}}
puts $res

# Tuple is the formal mathematical term for what is written in formulae as
# (a,b,...,z) - a finite ordered collection of (possibly very different)
# elements. The Tcl counterpart is list.
# When all elements are of the same type, it is more common to speak of it
# as a vector than a tuple.
proc tuples args {
  set res {}
  set listargs {}
  set body {lappend res [list}
  foreach arg $args {
    set loopvar v[incr i]
    append body " \$$loopvar"
    lappend listargs $loopvar $arg
  }
  append body {]}
  # puts "Debug: $listargs"
  # puts "Debug: $body"
  forall {*}$listargs $body
  return $res
}

puts [tuples {1 2} {a b c}]
# v1 {1 2} v2 {a b c}
# lappend res [list $v1 $v2]
puts [tuples {1 2} {a b c} {X Y}]
# v1 {1 2} v2 {a b c} v3 {X Y}
# lappend res [list $v1 $v2 $v3]

# 'forall' makes it easy to iterate over lists in nested fashion in a very
# generalized way without having to write custom scripts every time.


