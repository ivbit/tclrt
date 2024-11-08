#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

proc repl {} {
  set command {}
  set prompt {% }
  puts -nonewline stdout $prompt
  flush stdout
  while {[gets stdin line] >= 0} {
    append command "\n$line"
    if {[info complete $command]} then {
      catch {uplevel #0 $command} result
      puts stdout $result
      set command {}
      set prompt {% }
    } else {
      set prompt {(cont)% }
    }
    puts -nonewline stdout $prompt
    flush stdout
  }
}

if {
  [info exists ::argv0] &&
  [file dirname [file normalize [info script]/...]] eq
  [file dirname [file normalize $argv0/...]]
} then {
  repl
}

