#! /usr/bin/tclsh

# Utility scripts (653)

# source ./utilityScripts.tcl

# Add a custom directory with tcl packages to 'auto_path'
# set auto_path [linsert $auto_path 0 ~/MyTclPkgs]
# set auto_path [linsert $auto_path 0 "${env(HOME)}/MyTclPkgs"]
set myTclPkgs [file normalize {~/MyTclPkgs/}]
if {[file exists $myTclPkgs] && $myTclPkgs ni $auto_path} {
  lappend ::auto_path $myTclPkgs
}
unset myTclPkgs

# fileutil package from Tcllib
package require fileutil

proc print_args {args} {
  puts "Args: [join $args {, }]"
}

proc print_list {l} {
  puts [join $l "\n"]
}

# print_list [tcl::pkgconfig list]

proc print_sorted {l} {
  print_list [lsort -dictionary $l]
}

# args provide patterns in form of wildcards for matching dictionary keys
# * '0 or more'; ? 'exactly 1'; [characters]; [range]; [-a-zX] 'used together';
# backslash 'escape character'; double-backslash 'to escape backslash itself'
proc print_dict {dict args} {
  if {[llength $args] == 0} {
    set names [lsort -dict [dict keys $dict]]
  } else {
    set names {}
    foreach pattern $args {
      lappend names {*}[lsort -dict [dict keys $dict $pattern]]
    }
  }
  set maxl 0
  foreach name $names {
    if {[string length $name] > $maxl} {
      set maxl [string length $name]
    }
  }
  set maxl [expr {$maxl + 2}]
  set lines {}
  foreach name $names {
    set nameString [format %s $name]
    lappend lines [format "%-*s = %s" $maxl $nameString [dict get $dict $name]]
  }
  puts [join $lines "\n"]
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
  regexp -inline -all .. [binary encode hex [join $args ""]]
}

# Instead of defining procedure 'plus 'namespace path' can be used:
# namespace path ::tcl::mathop
# to make available command '+'
proc plus {args} {
  expr [join $args " + "]
}

# namespace path [list ::tcl::mathfunc ::tcl::mathop]

# {*} instructs parser to treat an argument as a list of values and
# extracts those values as single arguments to the command. Example:
# + {*}{3 4} 5 8 {*}"7 2"
# + {*}{3 4} 5 8 {*}"7 2" {*}$tcl_version {*}[expr $tcl_version + 0.8]

# Reconstruct any procedure's definition.
proc reconstruct proc_name {
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

# Clear screen on Linux
proc cls {} {
  puts -nonewline "\x1b\[3J\x1b\[1;1H\x1b\[0J"
}

proc clear {} {
  puts "\x1b\[3J\x1b\[1;1H\x1b\[0J"
}

# Unglobbing
# set bar {x[y]}
# set foo($bar) yes
# There are 3 ways to unset such variable:
# unset foo($bar)
# array unset foo [string map {[ \\[ ] \\]} $bar]
# array unset foo [unglob $bar]
proc unglob {str} {
  regsub -all {^~|[][{}*?\\]} $str {\\&}
}

