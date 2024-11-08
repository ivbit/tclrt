#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

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

set sep [string repeat * 70]
set cNor \u001b\[0m
set cRed \u001b\[31m
set cGre \u001b\[32m
set cYel \u001b\[33m
set cBlu \u001b\[34m
set cMag \u001b\[35m
set cCya \u001b\[36m

# Nested namespaces
# 'namespace eval' creates namespaces if needed
namespace eval nn1::nn2::nn3 {
  puts [namespace current]
}

namespace eval nsA {
  variable my_var "[namespace current] variable"
  namespace eval nsB {
    variable my_var "[namespace current] variable"
  }
}
namespace eval nsB {
  variable my_var "[namespace current] variable"
}
variable my_var "[namespace current] variable"

puts {Namespace            - ::nsA}
namespace eval nsA {puts "Current namespace    - $my_var"}
namespace eval nsA {puts "Global namespace     - $::my_var"}
namespace eval nsA {puts "Relative namespace   - $nsB::my_var"}
namespace eval nsA {puts "Absolute namespace   - $::nsB::my_var"}

# 'namespace current', 'namespace parent', 'namespace children'
namespace eval nsA {
  proc whereami {} {return [namespace current]}
}
puts "namespace current    - [nsA::whereami]"

puts "namespace parent     - [namespace eval nsA {namespace parent}]"
puts "namespace parent     - [namespace eval nsA {namespace parent nsB}]"
puts "namespace parent     - [namespace parent nsB]"
# Global namespace has a name of an empty string {}
# :: is an alias for global namespace
puts "namespace parent     - [namespace parent ::]"

puts "namespace children   - [namespace eval nsA {namespace children}]"
puts "namespace children   - [namespace children nsA]"
puts "namespace children   - [namespace children ::]"

puts "namespace qualifiers -\
  [set nshead [namespace qualifiers ::no::such::namesp]]"
puts "namespace tail       - [set nstail [namespace tail ::no::such::namesp]]"

puts [set my_ns "::${nshead}::$nstail"]
puts [set my_ns [join [list {} $nshead $nstail] ::]]
puts [set my_ns [join [list $nshead $nstail] ::]]

puts "Tcl will treat more than 2 '${cMag}:${cNor}' as just '::'"
puts "\$:::nsA:::::::my_var - $:::nsA:::::::my_var"

puts [string cat $cYel $sep $cNor]

# namespace delete ?NAMESPACE ...?
# 'namespace delete' removes each NAMESPACE along with all it's contents,
# including variables, commands and nested namespaces.
puts "namespace delete nsA - [namespace delete nsA]"
puts "namespace exists nsA - [namespace exists nsA]"
puts "namespace exists nsB - [namespace exists nsB]"

# namespace eval NAMESPACE SCRIPT ?SCRIPT ...?
namespace eval ns1 {
  namespace eval ns2::ns3 {}
  namespace eval ::ns4 {}
}

# namespace inscope NAMESPACE SCRIPT ?ARG ...?
# 'namespace inscope' will not create a namespace if it doesn't exist,
# arguments appended as a proper list, avoiding double substitutions.
namespace eval ns1 {
  proc print_args {args} {
    chan puts stdout [join $args ,]
  }
}

set arg1 {First argument}
set arg2 {$arg1}
# With 'namespace eval' arguments undergo 2 rounds of substitution:
namespace eval ns1 {print_args} $arg1 $arg2
namespace inscope ns1 {print_args} $arg1 $arg2

# namespace code SCRIPT
# 'namespace code' returns a script that can be evaluated in any scope
namespace eval ns1 {
  variable avar {Some value}
  after 100 [namespace code {chan puts stdout $cRed$avar$cNor}]
  after 100 {::namespace inscope ::ns1 {chan puts stdout $avar}}
}
chan puts stdout [namespace eval ns1 {namespace code {chan puts stdout $avar}}]

# Capturing the namespace scope when the callback script is a single command
proc callback {args} {
  tailcall namespace code $args
}

namespace inscope ns1 {
  after 100 [callback chan puts stdout "Callback: $avar"]
}

after 200 {set trigger 1}
vwait trigger
unset trigger

puts [string cat $cBlu $sep $cNor]

# Defining variables in a namespace with 'variable' command
# 'variable' - create and initialize a namespace variable
# variable NAME
# variable ?NAME VALUE...? ?NAME?

# 'var_a' and 'var_b' are created and initialized
# 'var_c' and 'var d' are created but remain undefined
namespace eval nsA {
  variable var_a {abc}
  variable var_b [clock seconds] var_c
  variable var_d
}
puts [set nsA::var_a]
puts [info exists nsA::var_c]

namespace eval nsA {
  set var_e 42
}
puts $::nsA::var_e

# https://wiki.tcl-lang.org/page/Dangers+of+creative+writing
# Creative writing by 'set' command
set version 1.0
namespace eval mypackage {
  set description {My Package}
  set version 2.0
}
puts $::mypackage::description
puts $::version
puts [info exists ::mypackage::version]
# Always explicitly declare namespace variables with 'variable' command!

puts [string cat $cCya $sep $cNor]

# Defining commands in a namespace
# Fully qualified procedure name
namespace eval nsA::nsB {}
proc ::nsA::nsB::demo_a {} {
  return [namespace current]
}
namespace eval nsC {
  proc ::nsA::nsB::demo_b {} {
    return [namespace current]
  }
}
puts "[::nsA::nsB::demo_a], [::nsA::nsB::demo_b]"

# Relative to the current namespace
namespace eval ::nsA {
  proc demo_c {} {
    return [namespace current]
  }
  proc nsB::demo_d {} {
    return [namespace current]
  }
  puts [demo_c]
  puts [nsB::demo_d]
}

# Namespace contexts in procedures
proc demo {} {
  return "Proc in [namespace current]"
}
namespace eval nsA {
  variable my_var "Variable in [namespace current]"
  proc demo {} {
    return "Proc in [namespace current]"
  }
  proc test_proc {} {
    variable my_var
    puts "Calling namespace proc: [demo]"
    puts "Calling global proc: [::demo]"
    puts "Value of my_var = \"$my_var\""
  }
}
nsA::test_proc

puts [string cat $cGre $sep $cNor]

# Variable resolution outside of a procedure
namespace eval nsA {
  variable my_var {nsA variable}
}
namespace eval nsB {
  namespace eval nsC {
    variable my_var {nsB::nsC variable}
  }
  puts $nsC::my_var
  puts $nsA::my_var
}

# Variable resolution in a procedure
set my_var {global variable}
namespace eval nsC {
  variable my_var {nsC variable}
}
namespace eval nsA {
  variable my_var {nsA variable}
  namespace eval nsB {
    variable my_var {::nsA::nsB variable}
  }
}
proc nsA::demo {} {
  variable my_var
  set local_var {local}
  puts "local_var = $local_var"
  puts "my_var = $my_var"
  puts "nsB::my_var = $nsB::my_var"
  puts "nsC::my_var = $nsC::my_var"
}
nsA::demo

puts $sep

# Linking to variables in another namespace
# namespace upvar NAMESPACE ?NSVAR LOCALVAR ...?
# LOCALVAR must not already exist
# Inside the namespace, LOCALVAR is a namespace variable
namespace eval nsC {
  namespace upvar ::nsA::nsB my_var linked_var
}
puts $::nsC::linked_var

# Inside the procedure, LOCALVAR is a local variable
proc demo {} {
  namespace upvar ::nsA my_var linked_var
  puts $linked_var
}
demo

# Relative namespace names are allways resolved in the current namespace
namespace eval nsA {
  namespace eval childNS {
    puts [namespace current]
  }
}

puts [string cat $cRed $sep $cNor]

# Resolving command names:
# 1) The current namespace is checked.
# 2) All namespaces in 'namespace path' are checked in order.
# 3) Global namespace is checked.
# 4) 'namespace unknown' handler is called.
# A command may be defined in namespace, or imported into namespace.

# 'namespace export', 'namespace import', 'namespace forget'
# namespace export ?-clear? ?PATTERN ...?
# namespace import ?-force? ?PATTERN ...?
# namespace forget ?PATTERN ...?
namespace eval nsA {
  proc aproc {} {puts {aproc called}}
  proc bproc {} {puts {bproc called}}
  proc cproc {} {puts {cproc called}}
  namespace export a* b*
}
namespace eval nsB {
  namespace import {::nsA::[ac]*}
}
puts [namespace eval nsA {namespace export}]
puts [namespace eval nsB {namespace import}]
namespace eval nsB {
  aproc
}

namespace eval nsA {
  proc acommand {} {
    puts {acommand called}
  }
}
namespace eval nsB {namespace import {::nsA::[ac]*}}
namespace eval nsB {
  acommand
}

# Imported commands can be exported from importing namespace
namespace eval nsB {
  namespace export aproc
}
namespace eval nsC {
  namespace import ::nsB::aproc
  aproc
}

namespace eval nsB {puts >[string cat $cMag [namespace import] $cNor]<}
namespace eval nsB {namespace forget ::nsA::aproc}
namespace eval nsB {namespace forget acommand}
namespace eval nsB {puts >[namespace import]<}

puts $sep

# namespace path ?NAMESPACELIST?
proc global_proc {} {
  puts {global_proc called}
}
namespace eval nsA {
  proc nsA_proc {} {
    puts {nsA_proc called}
  }
  namespace eval nsB {
    proc nsB_proc {} {
      puts {nsB_proc called}
    }
  }
}

namespace eval nsC {
  namespace path [list ::nsA ::]
  puts "The namespace path is now {[namespace path]}."
  proc nsC_proc {} {
    nsB::nsB_proc
  }
  global_proc
  nsA_proc
  nsC_proc
}

namespace eval nsA {
  proc aproc {} {
    puts {aproc called}
  }
  namespace export aproc
}
namespace eval importer {
  namespace import ::nsA::aproc
}
namespace eval pathfinder {
  namespace path ::nsA
}

namespace eval importer {
  aproc
}
namespace eval pathfinder {
  aproc
}
importer::aproc
puts "importer:   {[info commands importer::*]}"
puts "pathfinder: {[info commands pathfinder::*]}"

namespace eval nsB {
  namespace path ::importer
}
namespace eval nsC {
  namespace path ::pathfinder
}
namespace eval nsB {
  aproc
}
catch {
  namespace eval nsC {
    aproc
  }
} result
puts $result

# Import links to the original command
rename ::nsA::aproc ::nsA::aproc2
namespace eval importer {
  aproc
}
rename ::importer::aproc ::importer::a_better_name
importer::a_better_name

# Path mechanism searches for the command by name in the 'namespace path'
catch {
  namespace eval pathfinder {
    aproc
  }
} result
puts $result

puts $sep

# namespace unknown ?COMMANDPREFIX?
# Unknown command handler is set for each namespace by calling
# 'namespace unknown' command from the context of the namespace.
# COMMANDPREFIX is a list consisting of a command name and optional arguments.
# Unsafe code below (for educational purposes only):
catch {
  namespace eval nsA {
    ls -AFhl [info script]
  }
} result
puts [string cat $cBlu $result $cNor]
namespace eval nsA {
  namespace unknown [list exec -keepnewline --]
}
puts -nonewline [
  namespace eval nsA {
    ls -AFhl [info script]
  }
]
puts $cMag[
  namespace eval nsA {
    namespace unknown
  }
]$cNor

# Unknown command handler is called only from namespace context
catch {
  namespace eval nsB {
    ls [info script]
  }
} result
puts $result
catch {nsA::ls} result
puts $result
# If no unknown command handler is set for a namespace,
# the global handler ::unknown will be called instead.

puts [string cat $cYel $sep $cNor]

namespace eval nsA {
  proc aproc {} {
    puts {aproc called}
  }
  namespace export aproc
}
namespace eval middleman {
  namespace import ::nsA::aproc
  namespace export aproc
}
namespace eval importer {
  namespace import ::middleman::aproc
}
namespace eval pathfinder {
  namespace path ::nsA
}

# namespace which ?-command? ?-variable? NAME
namespace eval importer {
  puts [namespace which -command aproc]
}
namespace eval pathfinder {
  puts [namespace which -command aproc]
}

namespace eval nsA {
  variable avar
  proc demo {} {
    variable avar
    namespace which -variable avar
  }
}
puts [nsA::demo]

# namespace origin NAME

namespace eval importer {
  puts [namespace which -command aproc]
}
namespace eval importer {
  puts [namespace origin aproc]
}
namespace eval pathfinder {
  puts [namespace origin aproc]
}
# 'namespace which' can be used instead of 'info commands'
# unlike 'info commands', 'namespace which' does not parse
# wildcard characters in command name (*, ?, ...)

chan puts stdout [string cat $cRed $sep $cNor]

# Namespace ensembles
# /usr/share/tcltk/tcllib1.21/math/misc.tcl
package require math
namespace eval fib {
  proc nth {n} {
    return [::math::fibonacci $n]
  }
  proc sequence {n} {
    set seq {}
    for {set i 1} {$i <= $n} {incr i} {
      lappend seq [nth $i]
    }
    return $seq
  }
  proc sum {n} {
    return [::tcl::mathop::+ {*}[sequence $n]]
  }
}

puts "::fib::nth 3      = [fib::nth 3]"
puts "::fib::sequence 3 = [fib::sequence 3]"
puts "::fib::sum 3      = [fib::sum 3]"

# namespace ensemble create ?OPTION VALUE?
# When no options are specified, 'namespace ensemble create' creates an
# ensemble command of the same name as the namespace from which it was called.
# The subcommands will be all exported commands from the namespace.
namespace eval fib {
  namespace export *
  namespace ensemble create
}

puts "::fib nth 4       = [fib nth 4]"
puts "::fib sequence 4  = [fib sequence 4]"
puts "::fib sum 4       = [fib sum 4]"

# Give a name to the ensemble command with -command option,
# name must be fully qualified for it to be created in global namespace context.
namespace eval fib {
  namespace ensemble create -command ::fibonacci
}
puts "::fibonacci nth 6 = [fibonacci nth 6]"

# 'namespace ensemble create' has same options as 'namespace ensemble configure'
# namespace ensemble configure COMMAND ?OPTION ?VALUE? ...?
puts [namespace ensemble configure ::fibonacci]
# -namespace is a read-only option
puts [namespace ensemble configure ::fibonacci -namespace]

# Commands in -subcommands list need not to be exported.
# Default is {}, which causes all exported commands to become subcommands.
namespace ensemble configure ::fibonacci -subcommands {nth sum}
puts [fibonacci nth 4]
puts [fibonacci sum 5]
catch {
  fibonacci sequence 3
} result
puts $result

namespace ensemble configure ::fibonacci -subcommands {}
puts [fibonacci sequence 3]

# -map allows to add any command prefix to namespace ensemble command
namespace ensemble configure ::fibonacci -map {
  term ::math::fibonacci
  term4 {::math::fibonacci 4}
} -subcommands {term term4 sequence sum}

puts [fibonacci term 4]
puts [fibonacci term4]

# Unique prefixes for subcommands
puts [fibonacci su 4]
catch {fibonacci s 4} result
puts $result

namespace ensemble configure ::fibonacci -prefixes false
catch {fibonacci su 4} result
puts $result

puts [string cat $cGre $sep $cNor]

namespace eval arith {
  proc + {operand increment} {
    expr {$operand + $increment}
  }
  proc - {operand decrement} {
    expr {$operand - $decrement}
  }
}

# -parameters accepts a list of parameters that appear before the subcommand
# in ensemble. Values of the list are used only to generate error messages.
namespace eval arith {
  namespace export + -
  namespace ensemble create -parameters {operand}
}

puts [arith 3 + 4]
puts [arith 5 - 2]
catch {arith} result
puts $result

catch {arith 2 * 3} result
puts $result

namespace eval arith {
  proc delegator {args} {
    if {[llength $args] != 4} {
      error "Wrong number of arguments: should be \"[lindex $args 0] operand\
        operator operand\""
    }
    return ::tcl::mathop::[lindex $args 2]
  }
}
namespace ensemble configure ::arith -unknown ::arith::delegator
puts "\[arith 2 * 3\] = [arith 2 * 3]"
catch {arith 5 + 7 + 8} result
puts $result
catch {arith 5 * 7 * 8} result
puts $result

puts [string cat $cCya $sep $cNor]

# Updating subcommands on the fly
namespace delete ::arith
proc delegator {args} {
  if {[llength $args] != 4} {
    error "Wrong number of arguments: should be \"[lindex $args 0] operand\
      operator operand\""
  }
  lassign $args cmd - op
  set escaped_op [string map {* \\* ? \\? [ \\[ ] \\] \\ \\\\} $op]
  if {[llength [info commands ::tcl::mathop::$escaped_op]] == 0} then {
    error "Invalid operator \"$op\""
  }
  set map [namespace ensemble configure $cmd -map]
  dict set map $op ::tcl::mathop::$op
  namespace ensemble configure $cmd -map $map
  return {}
}
namespace ensemble create -command arith -map {} -parameters {operand} \
  -unknown [namespace current]::delegator -prefixes false

puts [namespace ensemble configure arith -namespace]
puts "{[namespace ensemble configure arith -map]}"
puts [arith 2 == 3]
puts [arith 2 * 3]
catch {arith 2 = 3} result
puts $result
puts "{[namespace ensemble configure arith -map]}"
puts "{[namespace ensemble configure arith]}"

puts [namespace ensemble exists string]
puts [namespace ensemble exists puts]
puts [namespace ensemble exists nosuchcommand]

puts [string cat $cYel $sep $cNor]

# Nested ensembles
# COMMAND SUBCOMMAND SUBCOMMAND ... ARGUMENTS
namespace eval image::png {
  proc rotate {imagedata degrees} {
    puts {Rotating PNG image.}
  }
  proc resize {imagedata height width} {
    puts {Resizing PNG image.}
  }
  namespace export *
  namespace ensemble create
}

namespace eval image::jpeg {
  proc rotate {imagedata degrees} {
    puts {Rotating JPEG image.}
  }
  proc resize {imagedata width height} {
    puts {Resizing JPEG image.}
  }
  namespace export *
  namespace ensemble create
}

namespace eval image {
  namespace export *
  namespace ensemble create
}

image png rotate {Some binary PNG} 90
image jpeg resize {Some binary JPEG} 640 480

# Nested ensembles from different namespaces
namespace eval audio::mp3 {
  proc normalize {mp3file} {
    puts {Normalizing MP3 file.}
  }
  proc bitrate {mp3file rate} {
    puts {Changing bitrate of MP3 file.}
  }
  namespace ensemble create -prefixes 0 -subcommands {normalize bitrate}
}
namespace eval audio::ogg {
  proc normalize {oggfile} {
    puts {Normalizing OGG file.}
  }
  proc bitrate {oggfile rate} {
    puts {Changing bitrate of OGG file.}
  }
  namespace ensemble create -prefixes 0 -subcommands {normalize bitrate}
}

namespace eval video::mkv {
  proc normalize {mkvfile} {
    puts {Normalizing MKV file.}
  }
  proc convert {mvkfile format} {
    puts {Changing format of MKV file.}
  }
  namespace ensemble create -prefixes 0 -subcommands {normalize convert}
}
namespace eval video::avi {
  proc normalize {avifile} {
    puts {Normalizing AVI file.}
  }
  proc convert {avifile format} {
    puts {Changing format of AVI file.}
  }
  namespace ensemble create -prefixes 0 -subcommands {normalize convert}
}

namespace ensemble create -command multimedia -prefixes 0 -map {
  mp3 audio::mp3
  ogg audio::ogg
  mkv video::mkv
  avi video::avi
}

catch {multimedia} result
puts $result
catch {multimedia 3gp} result
puts $result
catch {multimedia mp3} result
puts $result
catch {multimedia mp3 truncate} result
puts $result
catch {multimedia mp3 normalize} result
puts $result
catch {multimedia mp3 bitrate} result
puts $result
catch {multimedia ogg normalize} result
puts $result
catch {multimedia mkv convert} result
puts $result
catch {multimedia avi normalize} result
puts $result

multimedia mp3 normalize foo.mp3
multimedia mp3 bitrate bar.mp3 128
multimedia ogg normalize foo.ogg
multimedia ogg bitrate bar.ogg 128
multimedia mkv normalize baz.mkv
multimedia mkv convert buz.mkv mp4
multimedia avi normalize baz.avi
multimedia avi convert buz.avi webm
video::avi convert buz.avi webm
video::avi::convert buz.avi webm

puts [namespace ensemble configure audio::mp3]
puts [namespace ensemble configure audio::ogg]
puts [namespace ensemble configure video::mkv]
puts [namespace ensemble configure video::avi]
puts [string cat $cBlu [namespace ensemble configure multimedia] $cNor]

# Command created with 'namespace ensemble create' can be renamed with 'rename'
# command and will remember namespace in which it was created. When renaming it,
# it can be placed into any namespace by providing a fully qualified name.

# namespace eval junk {}
# In this case 'rename' will create namespace '::junk' if it's not already exist
puts [lsort -dictionary [namespace children]]
rename ::multimedia ::junk::mtmd
puts [lsort -dictionary [namespace children]]

junk::mtmd ogg bitrate bar.ogg 128
catch {multimedia ogg bitrate bar.ogg 128} result
puts $result
junk::mtmd mkv convert buz.mkv webm
video::mkv convert buz.mkv webm

puts [string cat $cMag $sep $cNor]

# Adding subcommands to an existing ensemble command
proc dict_get_with_default {dictval key {defval {}}} {
  if {[dict exists $dictval $key]} then {
    return [dict get $dictval $key]
  } else {
    return $defval
  }
}

set map [namespace ensemble configure ::dict -map]
dict set map lookup dict_get_with_default
namespace ensemble configure ::dict -map $map

puts {namespace ensemble configure ::dict -map}
print_dict [namespace ensemble configure ::dict -map]

puts [dict lookup {a 1 b 2 c 3} z NIL]

# set adict {a 1 b 2}
set adict [dict create a item1 b item2]
puts "In dictionary '[dict get $adict]':"
puts "a: [dict lookup $adict a NIL]"
puts "b: [dict lookup $adict b NIL]"
puts "c: [dict lookup $adict c NIL]"

# Indexing lists by name (retrieving fields by name)
set rec {Morgan 18 {College of Linguistics}}
puts "[lindex $rec 0] is [lindex $rec 1]."

# Namespace ensemble is created in the context of the caller via 'uplevel'.
proc record {recname fields} {
  if {[uplevel 1 [list namespace which $recname]] ne {}} then {
    error "Can't create command '$recname':\
      A command of that name already exists."
  }
  set index -1
  set accessor [list ::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      }
      if {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      }
      error {Invalid number of arguments.}
    }
  }]
  set map {}
  foreach field $fields {
    dict set map $field [linsert $accessor end [incr index]]
  }
  uplevel 1 [list namespace ensemble create -command $recname\
    -map $map -parameters rec]
}

# Creating namespace ensemble 'student', which has in -map dictionary each of
# 'name' 'age' 'college' mapped to an anonymous procedure created by 'apply'
# with index as an argument:
# name {::apply {...} 0}, age {::apply {...} 1}, college {::apply {...} 2}
puts [record student {name age college}]
puts "info commands st*: [info commands st*]"
puts [student $rec age]
puts [set rec [student $rec age 19]]
set rec [student $rec age 18]

# Improved 'record' procedure
rename student {}
rename record {}
proc record {recname fields} {
  if {[uplevel 1 [list namespace which $recname]] ne {}} then {
    error "Can't create command '$recname':\
      A command of that name already exists."
  }
  set accessor [list ::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      } elseif {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      } else {
        error {Invalid number of arguments.}
      }
    }
  }]
  set index -1
  set map [dict create]
  foreach field $fields {
    dict set map $field [linsert $accessor end [incr index]]
  }
  uplevel 1 [list namespace ensemble create -command $recname\
    -map $map -parameters rec]
}

puts [record student {name age college}]
puts "info commands st*: [info commands st*]"
puts [student $rec age]
puts [set rec [student $rec age 19]]

puts [record automobile {manufacturer model color}]
puts "info commands auto*: [info commands auto*]"
puts [automobile {Ferrari CaliforniaT red} color]

puts [record tv {id model price warranty info}]
puts "info commands tv*: [info commands tv*]"
puts [tv {T412 Smart 728 {2 years} {48 inch flat screen, smart, 4t}} info]
puts [tv {T412 Smart 728 {2 years} {48 inch flat screen, smart, 4t}} id]
puts [tv {T412 Smart 728 {2 years} {48 inch flat screen, smart, 4t}} warranty]

puts [string cat $cYel $sep $cNor]

# The 'command as an object' implementation
namespace eval ordered_set {
  variable nextid 0
  variable sets [dict create]

  # dict set dictVarName key ?key ...? value
  proc add {id elem} {
    variable sets
    dict set sets $id $elem $elem
    return
  }

  # dict exists dictionary key ?key ...?
  # dict unset dictVarName key ?key ...?
  proc remove {id elem} {
    variable sets
    if {[dict exists $sets $id $elem]} then {
      dict unset sets $id $elem
    }
    return
  }

  # dict keys dictionary ?pattern?
  # dict get dictionary ?key ...?
  proc contents {id} {
    variable sets
    return [dict keys [dict get $sets $id]]
  }
}

# dict unset dictVarName key ?key ...?
proc ordered_set::cleanup {id args} {
  variable sets
  dict unset sets $id
}

# dict set dictVarName key ?key ...? value
# dict create ?key value ...?
proc ordered_set::new {} {
  variable nextid
  variable sets
  set objname "::oset#[incr nextid]"
  dict set sets $nextid [dict create]
  set map [dict create \
    add [list add $nextid] \
    contents [list contents $nextid] \
    remove [list remove $nextid] \
    destroy [list ::rename $objname {}]]

  namespace ensemble create -command $objname -map $map
  trace add command $objname delete [list [namespace current]::cleanup $nextid]
  return $objname
}

puts "$cGre\$oset$cNor - [set oset [ordered_set::new]]"
puts "\[trace info command $cGre$oset$cNor\] - [trace info command $oset]"
$oset add fee
$oset add fie
$oset add fo
puts [$oset contents]
$oset add fie
puts [$oset contents]
$oset remove fee
puts [$oset contents]
$oset destroy
catch {$oset contents} result
puts $result

puts "$cMag\$aset$cNor - [set aset [ordered_set::new]]"
$aset add foo
$aset add bar
$aset add baz
puts [$aset contents]
puts "$cBlu\$bset$cNor - [set bset [ordered_set::new]]"
$bset add hello
$bset add world
puts [$bset contents]
puts "$cYel\$cset$cNor - [set cset [ordered_set::new]]"
$cset add Tcl
$cset add Python
$cset add C
$cset add Lisp
puts [$cset contents]
puts "\$::ordered_set::sets - {$::ordered_set::sets}"
print_dict $::ordered_set::sets
puts "$cMag\$aset$cNor destroy"
$aset destroy
print_dict $::ordered_set::sets
puts "$cBlu\$bset$cNor destroy"
$bset destroy
puts "$cYel\$cset$cNor destroy"
$cset destroy
puts "\$::ordered_set::sets - {$::ordered_set::sets}"

