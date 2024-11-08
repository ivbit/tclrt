#! /usr/bin/tclsh

set sep [string repeat * 8]

# Executes only 001, 002, 003
expr {
  [puts {Expr 001}; string cat 1] &&
  [puts {Expr 002}; string cat 1] &&
  [puts {Expr 003}; string cat 1] ||
  [puts {Expr 004}; string cat 1] &&
  [puts {Expr 005}; string cat 1] ||
  [puts {Expr 006}; string cat 1]
}

puts $sep

# Executes only 010, 040, 050
expr {
  [puts {Expr 010}; string cat 0] &&
  [puts {Expr 020}; string cat 1] &&
  [puts {Expr 030}; string cat 1] ||
  [puts {Expr 040}; string cat 1] &&
  [puts {Expr 050}; string cat 1] ||
  [puts {Expr 060}; string cat 1]
}

puts $sep

# Executes 100, 400, 600
expr {
  [puts {Expr 100}; string cat 0] &&
  [puts {Expr 200}; string cat 1] &&
  [puts {Expr 300}; string cat 1] ||
  [puts {Expr 400}; string cat 0] &&
  [puts {Expr 500}; string cat 1] ||
  [puts {Expr 600}; string cat 1]
}

# If 'expr' has more than 1 argument, the arguments need to be grouped with '{}'
# to allow Tcl to byte-compile the expression. This will greatly increase
# performance. Example: 'expr {2 + 3 * 5 / 7}'.
# If 'expr' has just 1 single argument, then '{}' not needed, adding them will
# slow down the execution a little bit because Tcl parser needs to process them.
# Example: 'expr 2+3*5/7'.
# The same rules apply to 'if', 'while' and 'for' commands.
# 'while 1' is faster than 'while {1}', 'if 0' is faster than 'if {0}',
# 'for {set i 0} 1 {incr i}' is faster than 'for {set i 0} {1} {incr i}'.
# 'expr' is faster than '::tcl::mathop::' and '::tcl::mathfunc::' commands.
# 'if {[string is integer $i]}' is faster than 'if [string is integer $i]'.
# 'expr {$i*3*5*6*3*6*7/3}' is faster than 'expr $i*3*5*6*3*6*7/3'.
# 'expr {2 + 3}' is faster than 'expr 2\ +\ 3'.
# 'expr 2+3' is faster than 'expr {2+3}'.
# Conclusion: if 'expr' has a single argument which does not contain any spaces,
# variable references, or bracketed commands, the '{}' are not needed;
# if 'expr' has multiple arguments, or an argument contains spaces, variable
# references, or bracketed commands, then '{}' will greatly improve performance.


