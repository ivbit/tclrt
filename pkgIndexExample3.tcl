# -*- tcl -*-
# Tcl package index file, version 1.1
#
# Make sure that TDBC is running in a compatible version of Tcl, and
# that TclOO is available.

if {![package vsatisfies [package provide Tcl] 8.6-]} then {
    return
}

# Why is there 'string totitle tdbc'? Why not just type 'Tdbc' instead?
apply {
  {dir}
  {
    set libraryfile [file join $dir tdbc.tcl]
    if {
      ![file exists $libraryfile] &&
      [info exists ::env(TDBC_LIBRARY)]
    } then {
      set libraryfile [file join $::env(TDBC_LIBRARY) tdbc.tcl]
    }
    if {[package vsatisfies [package provide Tcl] 9.0-]} then {
      package ifneeded tdbc 1.1.5 \
        "package require TclOO;\
        [list load [file join $dir libtcl9tdbc1.1.5.so] Tdbc]\;\
        [list source $libraryfile]"
    } else {
      package ifneeded tdbc 1.1.5 \
        "package require TclOO;\
        [list load [file join $dir libtdbc1.1.5.so] [string totitle tdbc]]\;\
        [list source $libraryfile]"
    }
  }
} $dir

