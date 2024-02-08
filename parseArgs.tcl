#! /usr/bin/tclsh

# Add a custom directory with tcl packages to 'auto_path'
# set auto_path [linsert $auto_path 0 ~/MyTclPkgs]
# set auto_path [linsert $auto_path 0 "${env(HOME)}/MyTclPkgs"]
set myTclPkgs [file normalize {~/MyTclPkgs/}]
if {[file exists $myTclPkgs] && $myTclPkgs ni $auto_path} {
  lappend ::auto_path $myTclPkgs
}
unset myTclPkgs

package require parse_args

proc fontify {text args} {
  parse_args::parse_args $args {
    -family {-default Arial}
    -italic {-boolean}
    -size   {-default 10}
    -weight {-default medium}
  }
  set style [expr {$italic ? "italic" : "normal"}]
  return "<span font-family=\"${family}\" font-style=\"${style}\" \
           font-weight=\"${weight}\" font-size=\"${size}\">${text}</span>"
}

puts [fontify "Some text." -italic -size 22]
puts [fontify "More text." -family "Liberation Serif" -weight bold]
# fontify "Wrong option." -slanted -size 12

# parse_args manual:
# https://www.tcl-lang.org/community/tcl2016/assets/talk33/parse_args-paper.pdf

