# !/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" ${1+"$@"}

# /bin/sh executes tclsh with arguments, if any.
# If there are no arguments, first argument $1 is unset in sh.
# If first argument $1 is set, 'sh' replaces it with all arguments $@.
# tclsh interprets backslash as continuation of the comment string, sh does not.

# man tclsh

proc fac1 {n} {
  if {$n == 0} {
    return 1
  }
  expr {$n * [fac1 [expr {$n - 1}]]}
}

proc fac2 {n} {
  expr {$n == 0 ? 1 : $n * [fac2 [expr {$n -1}]]}
}

# 'tailcall' avoids using stack
proc fac3 {n {acc 1}} {
  if {$n < 2} {return $acc}
  tailcall fac3 [expr {$n - 1}] [expr {$acc * $n}]
}

proc fac4 {n {acc 1}} {
  if [::tcl::mathop::< $n 2] {return $acc}
  tailcall fac4 [::tcl::mathop::- $n 1] [::tcl::mathop::* $acc $n]
}

proc fac5 {n {acc 1}} {
  if {$n < 2} {return $acc}
  tailcall fac5 [::tcl::mathop::- $n 1] [::tcl::mathop::* $acc $n]
}

proc fac6 {n {acc 1}} {
  if {[::tcl::mathop::< $n 2]} {return $acc}
  tailcall fac6 [::tcl::mathop::- $n 1] [::tcl::mathop::* $acc $n]
}

puts [fac1 50]
puts [fac2 50]
puts [fac3 50]
puts [fac4 50]
puts [fac5 50]
puts [fac6 50]

# 'fac3' has fastest execution, 'fac6' is faster than 'fac4'

# Fibonacci
proc ::fibh {n v1 v2} {
  if {$n == 1} then {
    return $v1
  } else {
    tailcall ::fibh [expr {$n - 1}] [expr {$v1 + $v2}] $v1
  }
}
proc ::fib1 {n} {
  if {$n == 0} then {
    return 0
  } else {
    tailcall ::fibh $n 1 0
  }
}

proc ::fib2 {n} {
  if {$n == 0} then {
    return 0
  } else {
    set prev0 0
    set prev1 1
    for {set i 1} {$i < $n} {incr i} {
      set tmp $prev1
      incr prev1 $prev0
      set prev0 $tmp
    }
    return $prev1
  }
}

chan puts stdout [::fib1 310]
chan puts stdout [::fib2 310]

# '::fib2 1000000' is faster than '::fib1 1000000' by 3 seconds

# Fibonacci with coroutines
proc FibGen {} {
  yield
  set prev 0
  set fib 1
  while 1 {
    yield $fib
    lassign [list $fib [incr fib $prev]] prev fib
  }
}
coroutine fibProd FibGen
set result [list]
for {set i 1} {$i <= 10} {incr i} {
  lappend result $i:\ [fibProd]
}
chan puts stdout [join $result {, }]

