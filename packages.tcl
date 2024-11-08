#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

set sep [string cat \u001b\[33m [string repeat * 70] \u001b\[0m]
set cNor \u001b\[0m
set cRed \u001b\[31m
set cGre \u001b\[32m
set cYel \u001b\[33m
set cBlu \u001b\[34m
set cMag \u001b\[35m
set cCya \u001b\[36m

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

puts "Tcl library - $tcl_library"
puts "Tcl library - [info library]"

# auto_load COMMANDNAME
# 'auto_load' searches in $auto_path for files named 'tclIndex'
# Example:
# /usr/share/tcltk/tcl8.6/tclIndex
# /usr/share/tcltk/tk8.6/tclIndex
puts "$cBlu\$auto_path$cNor:\n[join $auto_path \n]"
parray auto_index {[hp][ai][rs]*}
# auto_mkindex DIR ?GLOBPAT ...?
# 'auto_mkindex' has problems with procedure names containing wildcards *, ? ...
# Execute another program
# set auto_execs(cmdname) path_to_my_command
set auto_index(echo) {proc echo {args} {chan puts stdout $args}}
set auto_index(eche) {proc eche {args} {chan puts stderr $args}}
echo hello world hello universe
eche Tcl is a Tool command language

# package vcompare VERA VERB
# a = -2, b = -1
# 'package vcompare' returns -1, 0, 1 depending on whether VERA < = > VERB
puts "package vcompare   8.6 8.6b22           : [package vcompare 8.6 8.6b22]"

# package vsatisfies VER REQ ?REQ ...?
# 'package vsatisfies' returns 1 if VER meets at least one of the requirements
# MIN-MAX    version must be at least MIN and less than MAX
puts "package vsatisfies 8.6.6 8.5-8.7        : [package vsatisfies 8.6.6 8.5-8.7]"
# MIN-       version must be at least MIN
puts "package vsatisfies 8.6 8-               : [package vsatisfies 8.6 8-]"
puts "package vsatisfies 9 8-                 : [package vsatisfies 9 8-]"
# MIN        version must be at least MIN. Upper limit is next major version.
puts "package vsatisfies 8.5 8.7              : [package vsatisfies 8.5 8.7]"
puts "package vsatisfies 8.7 8.7              : [package vsatisfies 8.7 8.7]"
puts "package vsatisfies 8.6 8                : [package vsatisfies 8.6 8]"
puts "package vsatisfies 9 8                  : [package vsatisfies 9 8]"
puts "package vsatisfies 8.6 8.2              : [package vsatisfies 8.6 8.2]"
puts "package vsatisfies 8.6.13 8.6.2         : [package vsatisfies 8.6.13 8.6.2]"

# Exclude 8.6.1 version
if {[package vsatisfies [info patchlevel] 8-8.6.1 8.6.2]} then {
  puts "package vsatisfies [info patchlevel] 8-8.6.1 8.6.2 : 1"
} else {
  puts {Unsupported version.}
}

# package names
# Make a list of all known packages by attempting to load non-existent package
catch {package require nosuchpackage}
# puts [lsort -dictionary [package names]]

# package versions
puts "package versions http: [package versions http]"

# Installing packages:
# 1. sudo apt install PACKAGE
# 2. teacup install PACKAGE - only for ActiveState Tcl distribution
# 3. Follow package installation instructions for packages not in OS repository

# Searching for libraries
# 'auto_load' seaches for 'tclIndex' files in path in '$auto_path' variable,
# 'package require' searches for 'pkgIndex.tcl' files in '$auto_path' variable.
# When a Tcl interpreter is created, '$auto_path' is initialized with:
# 1) Value of 'TCLLIBPATH' environment variable: parsed as a list of directories
# 2) Value of '$tcl_library'
# 3) The parent directory of the directory in '$tcl_library'
# 4) Directories listed in '$tcl_pkgPath' variable, if it exists
puts "$cBlu\$tcl_pkgPath$cNor:\n[join $tcl_pkgPath \n]"
# Tcl evaluates 'pkgIndex.tcl' files in directories listed in '$auto_path'.
# 'pkgIndex.tcl' files add package names and versions into a package index db.
# This package search process does not search for module-based packages.

puts $sep

# package require NAME ?REQ ...?
# package require -exact NAME VERSION
# package require NAME VERSION-VERSION
puts [package require http]
puts [package require http 2-]
catch {package require -exact http 2.9} result
puts $result
# Tcl implementation itself pesents a package interface
puts [package require Tcl 8-8.6.1 8.6.2]

# 'package require' loads package only in the current interpreter
puts [package require http]
puts [set ip [interp create]]
puts [$ip eval {package require http 1}]
puts [interp alias {} geturlv1 $ip http::geturl]

# package prefer ?stable|latest?
# 'stable' is a no-op, the mode is not changed
# At startup the mode is set to 'stable', unless 'TCL_PKG_PREFER_LATEST' is set.
# TCL_PKG_PREFER_LATEST= tclsh
puts "package prefer: [package prefer]"
puts "package prefer stable: [package prefer stable]"
puts "package prefer latest: [package prefer latest]"
puts "package prefer stable: [package prefer stable]"

# Checking if package is loaded
# package present ?-exact? NAME REQ ?REQ ...?
catch {package present math} result
puts $result
package require math
puts [package present math]

puts $sep

# Creating packages
# package provide NAME ?VERSION?
# If version is not specified, 'package provide' returns the version number of
# loaded package, or an empty string if package is not loaded.
if {[package provide Tk] eq {}} then {
  puts {Package Tk is not loaded.}
}

# package ifneeded NAME VER ?SCRIPT?
# If SCRIPT is not provided, 'package ifneeded' returns the script that was
# previously registered for loading the package.
# To find the location of a package:
puts [package ifneeded fileutil [package require fileutil]]
# Before evaluating 'pkgIndex.tcl' file, Tcl sets the variable '$dir' to
# the path of the directory containing the 'pkgIndex.tcl' file.

# Tcl includes a comand 'pkg_mkIndex' that creates 'pkgIndex.tcl' and a related
# command 'pkg::create'. It's better to create 'pkgIndex.tcl' manually.
# All 'pkgIndex.tcl' files are read and evaluated during Tcl's package search.
# 'TCLLIBPATH' environment variable can be used to add custom directories to
# '$auto_path': TCLLIBPATH=/tmp tclsh
# Auto-loader and package-loader search directories in '$auto_path',
# package-loader also searches all the subdirectories of those directories.
lappend auto_path [file dirname [file normalize [info script]]]
puts "$cBlu\$auto_path$cNor:\n[join $auto_path \n]"
puts "package require sequences: [package require sequences]"
puts [package ifneeded sequences 1.0]
parray auto_index ::seq::*
puts [seq::arith_term 2 4 7]
puts [seq::geom_term 2 4 7]

# 'pkgIndex.tcl' may contain multiple 'package ifneeded' commands:
# /usr/share/tcltk/tcllib1.21/struct/pkgIndex.tcl
# /usr/share/tcltk/tcllib1.21/struct/struct.tcl
# /usr/share/tcltk/tcllib1.21/struct/list.tcl

puts $sep

# Load binary extensions
# load ?-global? ?-lazy? ?--? PATH ?INITNAME? ?INTERP?
# Linux: .so; Windows: .dll
puts "info sharedlibextension: [info sharedlibextension]"
puts "load myext[info sharedlibextension]"
set dir /tmp
package ifneeded binpkg 1.0 [
  list load [
    file join $dir binpkg[info sharedlibextension]
  ] [string totitle binpkg]
]
puts [package ifneeded binpkg 1.0]
puts {package ifneeded binpkg 1.0 {load /tmp/binpkg.so Binpkg}}

puts $sep

# Modules
# Changes in Tcl/Tk 8.5.2: Tcl modules must now be in the 'utf-8' encoding.
# Invoked command: source -encoding utf-8 path_to_module_dir/sequences-1.0.tm
# Tcl module is stored as a single file containing a Tcl script. The name of
# the file must be package name followed by a '-' character, followed by the 
# package verson and '.tm' extension. Name must match the regular expression:
# \A[_[:alpha:]][_:[:alnum:]]*-[[:digit:]].*\.tm\Z
puts [regexp {\A[_[:alpha:]][_:[:alnum:]]*-[[:digit:]].*\.tm\Z} http-2.9.8.tm]
# Uppercase characters should not be used in module names (OS compatibility).
# '::' in module name is treated specially during module search process.
tcl::tm::path add [file normalize [file dirname [info script]]]
puts [string cat $cBlu {Module search path:} $cNor]
puts [join [::tcl::tm::path list] \n]
# tcl::tm::path list
# tcl::tm::path add ?DIR ...?
# tcl::tm::roots DIR
# tcl::tm::path remove ?DIR ...?
puts {If module requires a minimal Tcl version of 8.5, place it in one of:}
puts [file normalize [file join [info library] .. tcl8 site-tcl]]
puts [file normalize [file join [info library] .. tcl8 8.5]]

puts $sep

# Creating modules
# '::' in package name act as directory separators, in the directory where this
# script is located there is 'sequences' directory with file 'sequences-1.0.tm'
# 'sequences::sequences' means 'sequences/sequences'. Module search path is
# [file dirname [info script]]/sequences/sequences-*
# Module version is extracted from name of the module file: 1.0 in this case.
package require sequences::sequences 1.0
puts [package ifneeded sequences::sequences 1.0]
puts [seq::arith_term 2 4 7]
puts [seq::geom_term 2 4 7]

# Including binary data in Tcl module file can be done after 'Ctrl-Z' character:
# https://core.tcl-lang.org/tips/doc/trunk/tip/189.md
# https://wiki.tcl-lang.org/page/Another+Tcl+module+maker
# https://core.tcl-lang.org/tips/doc/trunk/tip/190.md

puts $sep

# Multiplatform packaging
puts "package require platform : [package require platform]"
# 3 commands: identify, generic, patterns
puts "platform::identify       : [platform::identify]"
puts "platform::generic        : [platform::generic]"
puts "platform::patterns \[platform::identify\] :\n[
  join [platform::patterns [platform::identify]] \n
]"

# Get info about different Tcl shell installed on the same PC
puts "package require platform::shell : [package require platform::shell]"
# platform::shell::identify; platform::shell::generic; platform::shell::platform
puts [platform::shell::identify [info nameofexecutable]]
puts [platform::shell::generic [info nameofexecutable]]
puts [platform::shell::platform [info nameofexecutable]]
puts $tcl_platform(platform)

puts $sep

# Package configuration
# Each package can provide custom 'pkgconfig' procedure inside it's namespace.
# 'pkgconfig' must accept at least 2 commands: 'list' and 'get'.
puts [string cat $cBlu {tcl::pkgconfig list} $cNor]
puts [join [lsort -dictionary [tcl::pkgconfig list]] \n]
puts "${cBlu}tcl::pkgconfig get optimized${cNor}: [
  tcl::pkgconfig get optimized]"


