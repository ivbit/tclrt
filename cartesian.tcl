#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# https://en.wikipedia.org/wiki/Cartesian_product
# ::tcl::unsupported::representation $varName
# chan puts stdout "Alpha\t\u03b1"
# chan puts stdout "Beta\t\u03b2"
# chan puts stdout "Gamma\t\u03b3"
# chan puts stdout "Delta\t\u03b4"
# chan puts stdout "Epsilon\t\u03b5"
# chan puts stdout "Zeta\t\u03b6"
# chan puts stdout "Eta\t\u03b7\n"

proc cart {args} {
  if {[llength $args] < 2} then {
    return NIL
  }
  set body {}
  set script \$body
  while {[llength $args]} {
    set var v[incr i]
    set body [string cat \$$var { } $body]
    set script [list foreach $var [lindex $args end] $script]
    set args [lrange $args 0 end-1]
  }
  set body [string cat lappend { } result { } \[list { } $body \]]
  set script [subst -nobackslashes -nocommands $script]
  {*}$script
  return $result
}

chan puts stdout "\ncart:"
chan puts stdout "[cart]\n"

chan puts stdout "cart {A B C}:"
chan puts stdout "[cart {A B C}]\n"

# foreach v2 {A B C} {foreach v1 {1 2} {$body}}
# foreach v2 {A B C} {foreach v1 {1 2} {lappend result [list $v2 $v1 ]}}
# result: {{A 1} {A 2} {B 1} {B 2} {C 1} {C 2}}
chan puts stdout "cart {A B C} {1 2}:"
chan puts stdout "[cart {A B C} {1 2}]\n"

chan puts stdout "cart {1 2 3} {A B C}:"
chan puts stdout "[cart {1 2 3} {A B C}]\n"

chan puts stdout "cart {A B C} {1 2 3} {α β γ}:"
chan puts stdout "[cart {A B C} {1 2 3} {α β γ}]\n"

chan puts stdout "cart {A B C} {1 2} {α β γ δ ε ζ η}:"
chan puts stdout "[cart {A B C} {1 2} {α β γ δ ε ζ η}]\n"

chan puts stdout "cart {1 2} {A B C} {α β γ} {δ ε}:"
chan puts stdout "[cart {1 2} {A B C} {α β γ} {δ ε}]\n"

chan puts stdout "cart ζ {1 2} {A B C} {α β γ} {δ ε}:"
chan puts stdout "[cart ζ {1 2} {A B C} {α β γ} {δ ε}]\n"

chan puts stdout "cart ζ {1 2} {A B C} {α β γ} {δ ε} η:"
chan puts stdout "[cart ζ {1 2} {A B C} {α β γ} {δ ε} η]\n"


