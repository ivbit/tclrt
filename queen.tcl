#!/usr/bin/tclsh

# https://en.wikipedia.org/wiki/Eight_queens_puzzle
# 8 queens puzzle
# Given an 8x8 chess board, you must place 8 queens on the board so that no two
# queens attack each other. Find a solution SOL for every square of the board.

proc legal {board new} {
  # puts "legal '$board' '$new'"
  set diagonal [llength $board]
  foreach queen $board {
    # Is this queen on the same row or a diagonal of the new one?
    if {
      ($queen == $new) ||
      ($queen == ($new + $diagonal)) ||
      ($queen == ($new - $diagonal))
    } {
      return 0
    }; # if END
    incr diagonal -1
  }; # foreach END
  # No, it's legal
  return 1
}

proc addqueen {board} {
  for {set position 1} {$position <= 8} {incr position} {
    if {[legal $board $position]} {
      if {[llength $board] == 7} {
        puts "SOL $board $position"
      } else {
        # puts $board
        addqueen [concat $board $position]
      }
    }
  }
}

proc main {} {
  addqueen ""
}

main

