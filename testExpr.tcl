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

