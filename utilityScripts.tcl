#! /usr/bin/tclsh

# Utility scripts (653)

# source ./utilityScripts.tcl

# Add a custom directory with tcl packages to 'auto_path'
# set auto_path [linsert $auto_path 0 ~/MyTclPkgs]
# set auto_path [linsert $auto_path 0 "${env(HOME)}/MyTclPkgs"]
set myTclPkgs [file normalize {~/MyTclPkgs}]
if {[file exists $myTclPkgs] && $myTclPkgs ni $auto_path} {
  lappend ::auto_path $myTclPkgs
}
unset myTclPkgs

# fileutil package from Tcllib
package require fileutil

proc print_args {args} {
  chan puts "Args: [join $args {, }]"
}

proc print_list {l} {
  chan puts [join $l \n]
}

# print_list [tcl::pkgconfig list]

proc print_sorted {l} {
  print_list [lsort -dictionary $l]
}

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

# Array name without dollar sign, optional wildcard pattern
proc print_array {args} {
  uplevel 1 parray $args
}

proc print_file {path} {
  fileutil::cat $path
}

proc write_file {path content} {
  fileutil::writeFile $path $content
}

proc wait {ms} {
  after $ms [list set ::_wait_flag 1]
  vwait ::_wait_flag
}

proc lambda {params body args} {
  return [list ::apply [list $params $body] {*}$args]
}

proc bin2hex {args} {
  regexp -inline -all .. [binary encode hex [join $args {}]]
}

# Instead of defining procedure 'plus', 'namespace path' can be used:
# namespace path ::tcl::mathop
# to make available command '+'
proc plus {args} {
  expr [join $args +]
}

# namespace path [list ::tcl::mathfunc ::tcl::mathop]

# {*} instructs parser to treat an argument as a list of values and
# extracts those values as single arguments to the command. Example:
# + {*}{3 4} 5 8 {*}"7 2"
# + {*}{3 4} 5 8 {*}"7 2" {*}$tcl_version {*}[expr $tcl_version + 0.8]

# Reconstruct any procedure's definition.
proc reconstruct {proc_name} {
  set proc_name [uplevel 1 [list namespace which -command $proc_name]]
  set params [lmap param_name [info args $proc_name] {
    if {[info default $proc_name $param_name defval]} {
      list $param_name $defval
    } else {
      list $param_name
    }
  }]
  return [list proc $proc_name $params [info body $proc_name]]
}

# Set title of terminal emulator's window on Linux
proc stitle {{title "Tcl programming language\u0021"} args} {
  chan puts -nonewline stderr "\u001b]0;${title} ${args}\u0007"
}
# stitle \u263eTCL\u263d

# Clear screen on Linux
# proc cls {} {
#   chan puts -nonewline "\u001b\[3J\u001b\[1;1H\u001b\[0J"
#   chan flush stdout
# }
# 
# proc clear {} {
#   chan puts -nonewline "\u001b\[3J\u001b\[1;1H\u001b\[0J"
#   chan flush stdout
# }

# 'stderr' has '-buffering none', no need to 'chan flush'
proc cls {} {
  chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"
}

proc clear {} {
  chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"
}

# Call external 'ls' program on Linux
proc lsc {{a .}} {
  exec ls -lhAF --color=always [fileutil::fullnormalize $a]
}

# Unglobbing
# set bar {x[y]}
# set foo($bar) yes
# There are 3 ways to unset such variable:
# unset foo($bar)
# array unset foo [string map {[ \\[ ] \\]} $bar]
# array unset foo [unglob $bar]
# 'unglob' procedure:
# regsub -all -lineanchor {^~|[][{}*?\\]} $str {\\&}
proc unglob {str} {
  regsub -all {(?w)^~|[][{}*?\\]} $str {\\&}
}
# unglob "~user\n~x~y"
# 'unglob' with extra characters to escape:
# regsub -all -lineanchor {^~|[][{}*?\\+()<>|.^$]} $str {\\&}
proc unregexp {str} {
  regsub -all {(?w)^~|[][{}*?\\+()<>|.^$]} $str {\\&}
}
# unregexp "~user\n~x~y"
# 'string map' is slower than 'regsub'
# 'string map version' can't check for '~' at the beginning of the string:
# string map {] \\] [ \\[ \{ \\\{ \} \\\} * \\* ? \\? \\ \\\\ + \\+ ( \\( ) \\) < \\< > \\> | \\| . \\. ^ \\^ $ \\$} $str
# string map {] \\] [ \\[ \{ \\\{ \} \\\} * \\* ? \\? \\ \\\\ + \\+ ( \\( ) \\) < \\< > \\> | \\| . \\. ^ \\^ $ \\$ ~ \\~} $str
proc unsmap {str} {
  string map {] \\] [ \\[ \{ \\\{ \} \\\} * \\* ? \\? \\ \\\\ + \\+ ( \\( ) \\) < \\< > \\> | \\| . \\. ^ \\^ $ \\$ ~ \\~} $str
}
# unsmap "~user\n~x~y"

# 'echo' command implementation
# puts [chan names]
# 'chan puts' is more modern method of calling 'puts' command
# 'chan puts' and 'puts' both call the same procedure
# 'puts' is deprecated in Tcl 9
proc echo {args} {
  chan puts stdout $args
}

proc eche {args} {
  chan puts stderr $args
}

# No-op (also available via the 'tcllib control' structure module)
# package require control
# control::no-op
proc noop {args} {}

# Add commas to numbers
proc cnumb {num} {
  while {[regsub {\A([-+]?\d+)(\d{3})} $num {\1,\2} num]} {}
  return $num
}

# Repeat command or script
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

# 'after ms' - 'ms' must be an integer giving a time in milliseconds. A negative
# number is treated as 0. The command sleeps for 'ms' milliseconds and then
# returns. While command is sleeping the application does not respond to events.
# A proper 'sleep' command, includes an interlock to prevent nested vwaits.
# namespace import ::_sleep::sleep
# namespace import ::_sleep::*
namespace eval _sleep {
  namespace export sleep sleepm
  variable status {done}
  proc sleep {seconds} {
    variable status
    set seconds [expr {int([string trimleft [string trim $seconds] 0] * 1000)}]
    if {![info exists status] || $status ne {sleeping}} then {
      set status {sleeping}
      after $seconds
      after 0 [namespace code {set status {done}}]
      vwait [namespace which -variable status]
    }
    return $status
  }
  proc sleepm {milliseconds} {
    variable status
    set milliseconds [expr {int([string trimleft [string trim $milliseconds] 0])}]
    if {![info exists status] || $status ne {sleeping}} then {
      set status {sleeping}
      after $milliseconds
      after 0 [namespace code {set status {done}}]
      vwait [namespace which -variable status]
    }
    return $status
  }
}

# vim:textwidth=140

