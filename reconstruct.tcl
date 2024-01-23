#!/usr/bin/tclsh

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

puts "\n**********************************************************************\n"
puts [reconstruct reconstruct]
puts "\n**********************************************************************\n"
puts [reconstruct tclLog]
puts "\n**********************************************************************\n"

