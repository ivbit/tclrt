

# package ifneeded parse_args 0.5.1 [list load [file join $dir libparse_args0.5.1.so] Parse_args]

package ifneeded parse_args 0.5.1 [
  list ::apply {
    {dir}
    {
      if {[package vsatisfies [package provide Tcl] 9.0-]} then {
        set libfile [file join $dir libtcl9parse_args0.5.1.so]
      } else {
        set libfile [file join $dir libparse_args0.5.1.so]
      }
      load $libfile Parse_args
    }
  } $dir
]


