#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# While command is waiting the application responds to events.
# A proper 'wait' command, includes an interlock to prevent nested vwaits.
# namespace import ::_sleep::swait
# namespace import ::_sleep::*
namespace eval _sleep {
  namespace export swait swaitm
  variable status {done}
  proc swait {seconds} {
    variable status
    set seconds [expr {int([string trimleft [string trim $seconds] 0] * 1000)}]
    if {![info exists status] || $status ne {sleeping}} then {
      set status {sleeping}
      after $seconds [namespace code {set status {done}}]
      vwait [namespace which -variable status]
    }
    return $status
  }
  proc swaitm {milliseconds} {
    variable status
    set milliseconds [expr {int([string trimleft [string trim $milliseconds] 0])}]
    if {![info exists status] || $status ne {sleeping}} then {
      set status {sleeping}
      after $milliseconds [namespace code {set status {done}}]
      vwait [namespace which -variable status]
    }
    return $status
  }
}

::_sleep::swait 1
chan puts stderr {Waited for 1 second.}

