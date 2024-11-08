#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

package require json
package require json::write

set sep [string cat \n\u001b\[33m [string repeat * 70] \u001b\[0m\n]

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

set jsondict [
  dict create \
    city \"Tucson\" \
    country \"US\" \
    hostname \"tcl.tk\" \
    ip \"104.16.75.106\" \
    loc \"32.217653,-110.973182\" \
    org \"Starlink\" \
    postal \"85742\" \
    readme \"https://www.tucsonaz.gov/\" \
    region \"Arizona\" \
    timezone \"MST\"
]

set jsondata [json::dict2json $jsondict]
set jsonc [json::json2dict $jsondata]

print_dict $jsondict
chan puts stdout \n$jsondata\n
print_dict $jsonc

chan puts stdout $sep

proc DictToJson {data spec {indent false}} {
  ::json::write::indented $indent
  set jsonData [dict create]
  dict for {field typeInfo} $spec {
    if {![dict exists $data $field]} {continue}
    lassign $typeInfo type meta
    set value [dict get $data $field]
    switch $type {
      object {
        set value [DictToJson $value $meta $indent]
      }
      array {
        set value [ListToJsonArray $value {*}$meta]
      }
      string {
        set value [::json::write string $value]
      }
      bare {}
      default {
        return -code error "Unknown type: $type"
      }
    }
    dict set jsonData $field $value
  }
  return [::json::write object {*}$jsonData]
}

proc ListToJsonArray {list type {meta {}}} {
  set jsonArray [list]
  switch $type {
    object {
      foreach element $list {
        lappend jsonArray [DictToJson $element $meta false]
      }
    }
    array {
      lassign $meta subtype submeta
      foreach element $list {
        lappend jsonArray \
          [ListToJsonArray $element $subtype $submeta]
      }
    }
    string {
      foreach element $list {
        lappend jsonArray [::json::write string $element]
      }
    }
    bare {
      set jsonArray $list
    }
    default {
      return -code error "Invalid array element type: $type"
    }
  }
  return [::json::write array {*}$jsonArray]
}

# Create the dict
set a [dict create K1 {lower 0 upper 20}]
# This defines the value type for each key
set spec {K1 {object {lower string upper string}}}

chan puts stdout [DictToJson $a $spec true]
chan puts stdout {}

# Tcl's string is double does not conform to JSON specification.
# Using string is double allows non-valid numbers to slip through.
# E.g. '00', '0x0', '0.'.
# For testing valid numbers, you should use the following regexp.
# The regular expression is fine for limiting the acceptable number forms,
# but also continue to use string is double to check for over/underflow.
proc is_valid_json_number {value} {
  regexp -- {-?(?:[1-9][[:digit:]]*|0)(?:\.[[:digit:]]+)?(?:[eE][+-]?[[:digit:]]+)?} $value
}

chan puts stdout [is_valid_json_number 324.798]
# 'is_valid_json_number' does not seem to work correctly:
chan puts stdout [is_valid_json_number {0x0}]

