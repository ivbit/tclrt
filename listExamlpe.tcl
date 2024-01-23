#!/usr/bin/tclsh

# -bisect implies -sorted; -sorted implies -exact
# -bisect cannot be used with -all and -not
# If the value was found in the list, lsearch returns index where it's found,
# if the value was not found, it will return the position after which the value
# should be inserted into the sorted list, position depends on ordering:
# -increasing and -decreasing options. -increasing is the default.

# The procedure returns a sorted list with inserted value, if the value was not
# found in the list, or the original list, if the value was found.
# The original list must be sorted before using it in sorted_insert procedure.
proc sorted_insert {l val} {
  set pos [lsearch -integer -bisect $l $val]
  if {$pos == -1 || [lindex $l $pos] != $val} {
    return [linsert $l [incr pos] $val]
  } else {
    return $l
  }
}

puts [sorted_insert {10 20 30 40} 30]
puts [sorted_insert {10 20 30 40} 23]

# 'lmap' returns a new list constructed from results of each iteration
puts "lmap"
puts [lmap n {1 2 3 4 5 6 7 8} {
  if {$n == 4} continue
  if {$n == 7} break
  expr {$n * 2}
}]

puts [lmap n {1 2 3 4 5 6 7 8 9} {
  if {$n > 6} break
  if {$n & 1} continue
  expr {$n * 2}
}]

puts [lmap {x y} {A B C D} {n} {1 2 3 4} {
  list $n $x $y
}]

# 'foreach' always returns an empty string ""
puts "foreach"
foreach {v1 v2} {A B C D E F} {v3 v4} {G H I J K} {
  puts "<${v1}>:<${v3}> <${v2}>:<${v4}>"
}

package require struct::list

puts "struct::list equal"
puts [struct::list equal {a b c} {a b c}]
puts [struct::list equal {a b c} {a d c}]

puts "struct::list shuffle"
puts [struct::list shuffle {A B C D E F G}]
puts [struct::list shuffle {A B C D E F G}]
puts [struct::list shuffle {A B C D E F G}]

puts "List permutations"
puts [struct::list permutations {4 7 9}]

struct::list foreachperm perm {a b c} {
  puts $perm
}

