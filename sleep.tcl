#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# 'after ms' - 'ms' must be an integer giving a time in milliseconds. A negative
# number is treated as 0. The command sleeps for 'ms' milliseconds and then
# returns. While command is sleeping the application does not respond to events.
# A proper 'sleep' command, includes an interlock to prevent nested vwaits.
# namespace import ::_sleep::sleep
# namespace import ::_sleep::*
namespace eval _sleep {
  namespace export sleep sleepm
  variable status {done}
  proc sleep {seconds} {
    variable status
    set seconds [expr {int([string trimleft [string trim $seconds] 0] * 1000)}]
    if {![info exists status] || $status ne {sleeping}} then {
      set status {sleeping}
      after $seconds
      after 0 [namespace code {set status {done}}]
      vwait [namespace which -variable status]
    }
    return $status
  }
  proc sleepm {milliseconds} {
    variable status
    set milliseconds [expr {int([string trimleft [string trim $milliseconds] 0])}]
    if {![info exists status] || $status ne {sleeping}} then {
      set status {sleeping}
      after $milliseconds
      after 0 [namespace code {set status {done}}]
      vwait [namespace which -variable status]
    }
    return $status
  }
}

::_sleep::sleep 1
chan puts stderr {Slept for 1 second.}

