#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# /usr/share/tcltk/tcl8.6/parray.tcl
# parray:
# Print the contents of a global array on stdout.

proc parray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} {
    return -code error "\"$a\" isn't an array"
  }
  set maxl 0
  set names [lsort [array names array $pattern]]
  foreach name $names {
    if {[string length $name] > $maxl} {
      set maxl [string length $name]
    }
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name $names {
    set nameString [format %s(%s) $a $name]
    puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
}

parray tcl_platform

