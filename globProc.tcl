#! /usr/bin/dash
# Next line reloads the script using tclsh \
exec tclsh "$0" ${1+"$@"}

# https://wiki.tcl-lang.org/page/glob

# List the directory tree under any given root, giving the full path name of
# all descendants. TODO: rewrite this proc using 'tailcall', fix behavior with
# symbolic directory links, make the proc skip directories with insufficient
# permissions to read and execute.
proc listTree {rootdir_} {
  # Precondition: rootdir_ is valid path 
  set currentnodes [glob -nocomplain -directory $rootdir_ -types d *]
  if {![llength $currentnodes]} {
    # Base case: the current dir is a leaf, write out the leaf 
    puts $rootdir_
    return
  } else {
    # Write out the current node 
    puts $rootdir_
    # Recurse over all dirs at this level
    foreach node $currentnodes {
      listTree $node
    }
  }
}

listTree /dev

# This procedure will quickly find the first instance of a file in a given path.
proc findfile {dir fname} {
  if {[llength [set x [glob -nocomplain -directory $dir $fname]]]} {
    return [lindex $x 0]
  } else {
    foreach i [glob -nocomplain -type d -directory $dir *] {
      if {$i != $dir && [llength [set x [findfile $i $fname]]]} {
        return $x
      }
    }
  }
}

puts [string cat "\n" [findfile /dev null] "\n"]

