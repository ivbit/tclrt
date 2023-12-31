#!/usr/bin/tclsh

# tclsh sample.tcl
# with curly braces, variable substitution is performed by expr
set x 1
set sum [expr {$x + 2 + 3 + 4 + 5}]; # $x is not substituted before passing the parameter to expr;
                                     # expr substitutes 1 for $x while evaluating the expression
puts "The sum of the numbers 1..5 is $sum."; # sum is 15

