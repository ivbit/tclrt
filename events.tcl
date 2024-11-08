#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

set sep [string repeat * 70]
set cNor \u001b\[0m
set cRed \u001b\[31m
set cGre \u001b\[32m
set cYel \u001b\[33m
set cBlu \u001b\[34m
set cMag \u001b\[35m
set cCya \u001b\[36m

# Events
# When Tcl enters the 'event loop', it waits for registered events to occur.
# 'vwait' commands are nested, they are NOT running in parallel. 'wish' shell
# and 'Tk' package automatically start the 'event loop' and terminate it when
# all the 'Tk' windows are closed. There is no need to explicitly call 'vwait'
# in the 'Tk' application. Events only work if 'event loop' is running.
# When an 'event handler' is running, the control will not return to 'vwait'
# until an 'event handler' is completed. Another 'vwait' in an 'event handler'
# code may lock the program if the code is improperly implemented.
# vwait VARNAME
# update ?idletasks?
# after MILLISECONDS
# after MILLISECONDS SCRIPT ?SCRIPT ...?
# after idle SCRIPT ?SCRIPT ...?
# after cancel ID
# after cancel ID SCRIPT ?SCRIPT ...?
# after info ?ID?
# interp bgerror INTERPRETER CMDPREFIX
after 1000 [list chan puts {1 second elapsed.}]
after 2000 [list chan puts {2 seconds elapsed.}]
after 3000 [list set ::done 1]
vwait done
chan puts "\$done is \"$done\""

chan puts [string cat $cBlu $sep $cNor]

# 'update' command invokes the 'event loop' 1 time and returns when there are
# no pending events to be processed. 'update idletasks' only processes the idle
# events (tasks). One way to create idle tasks is to use 'after idle' command.
proc handler {} {
  chan puts {Event 0}
  after 0 [list chan puts {Event 1}]
}

after 0 handler
after 1000 [list chan puts {Event 2}]

chan puts ${cRed}update$cNor
chan puts "${cYel}after 0 handler${cNor}"
update

after 0 [list chan puts {After 0}]
after idle [list chan puts {After idle}]

chan puts "${cRed}update idletasks$cNor"
chan puts "${cMag}after idle \[list chan puts {After idle}\]${cNor}"
update idletasks

chan puts "${cRed}vwait TIMER$cNor"
chan puts "${cCya}after 0 \[list chan puts {After 0}\]$cNor
${cBlu}after 1000 \[list chan puts {Event 2}\]$cNor
${cGre}after 2000 \[list set ::TIMER {2 seconds elapsed.}\]$cNor"
after 2000 [list set ::TIMER {2 seconds elapsed.}]
vwait TIMER
chan puts $TIMER
unset TIMER

chan puts $cYel$sep$cNor

# Event handlers always run in the global context.
proc handler {} {
  chan puts "handler level: [info level]"
  set ::done 1
}
proc demo {} {
  chan puts "demo level   : [info level]"
  after 0 handler
  vwait ::done
}
demo

# Sleep
proc sleep {ms} {
  after $ms [list set ::_wait_flag 1]
  vwait ::_wait_flag
}
sleep 1000
chan puts {Slept for 1 second.}

# 'http' package is buggy and sometimes throw random errors.
# 'http' package uses 'fileevent' and coroutines, it is better to avoid using
# 'http' package at all in a script that uses any form of 'event loop'.
package require http
proc http_data_sink {token} {
  set ::status done
}
proc geturl_with_timeout {url ms} {
  after $ms {set ::status timeout}
  set http_token [http::geturl $url -command http_data_sink]
  vwait ::status
  if {$::status eq {timeout}} then {
    http::cleanup $http_token
    error {Operation timed out.}
  }
  set data [http::data $http_token]
  http::cleanup $http_token
  return $data
}

catch {geturl_with_timeout http://old.meteoinfo.ru 10000} result
chan puts $cYel[string range $result 0 20]$cNor
catch {geturl_with_timeout http://old.meteoinfo.ru 10} result
chan puts $cBlu$result$cNor

# Idle events
after idle [list puts {Idle task executed}]
after 0 [list puts {Event handled}]
# Run all pending events and idle tasks
update

# Breaking a long computation into parts, running parts from an 'event loop'
proc background_sum {n {sum 0}} {
  if {$n <= 0} then {
    chan puts "Sum is $sum"
  } else {
    chan puts Calculating...
    incr sum $n
    after 0 [list background_sum [incr n -1] $sum]
  }
}

after 0 background_sum 4
update

chan puts [string cat $cBlu $sep $cNor]

proc idler {{n 2}} {
  chan puts Idle!
  if {$n > 0} then {
    after idle [list idler [incr n -1]]
  }
}
after idle idler
after 0 background_sum 2
update

# Once the 'event loop' starts processing the 'idle task queue', it will
# continue to do so until 'idle task queue' is empty.

# Computation reschedules itself using both 'event queue' and 'idle queue'
proc idler {{n 2}} {
  chan puts Idle!
  if {$n > 0} then {
    after 0 [list after idle [list idler [incr n -1]]]
  }
}
proc background_sum {n {sum 0}} {
  if {$n <= 0} then {
    puts "Sum is $sum"
  } else {
    puts Calculating...
    incr sum $n
    after idle [list after 0 [list background_sum [incr n -1] $sum]]
  }
}

chan puts [string cat $cGre $sep $cNor]
after idle idler
after 0 background_sum 2
update

chan puts [string cat $cMag $sep $cNor]

# Cancelling tasks
set id1 [after 0 chan puts Timer1]
set id2 [after 0 chan puts Timer2]
after cancel $id1
update
# Specify the actual script instead of it's identifier to 'after cancel'
after idle chan puts Timer1
after idle chan puts Timer2
after cancel chan puts Timer1
update

# Querying handlers registered with the 'after' command
after 1000 {chan puts Timer}
after idle {chan puts Idle}
chan puts [after info]
# If ID is specified, 'after info' returns a list with 2 elements: 1st is an
# associated handler script, 2nd is script's type - either 'timer', or 'idle'.
# Timers already been triggered, or canceled are not shown by 'after info'.
foreach id [after info] {
  lassign [after info $id] script type
  chan puts "$id ($type): $script"
  after cancel $id
}

chan puts $cRed$sep$cNor

# Custom background error handling.
# When Tcl detects a background error, it saves information about the error and
# invokes a handler command registered by 'interp bgerror' later as an
# 'event handler'. Before invoking bgerror handler, Tcl restores the
# '$::errorInfo and '$::errorCode' to their values at the time error occurred.
# If several background errors accumulate before bgerror handler is invoked to
# process them, bgerror handler will be invoked once for each error.
# Customizing default handling of background exceptions:
# interp bgerror INTERPRETER CMDPREFIX
# INTERPRETER: an empty string {} refers to the current interpreter.
# CMDPREFIX: a command prefix that will be called with 'error result' and
# 'return options dictionary' (same values captured by the 'catch' command).
proc bghandler {message ropts} {
  chan puts stderr "MyApp error: $message"
  chan puts stderr "Error code : [dict get $ropts -errorcode]"
}
interp bgerror {} bghandler
proc demo {arg} {}
after 0 demo
chan puts "'catch' returned: [catch {update}]"

chan puts $cBlu$sep$cNor

# Using a namespace variable with 'vwait' command
namespace eval example {
  variable v done
  proc wait {delay} {
    variable v
    if {$v ne {waiting}} then {
      set v waiting
      after $delay [namespace code {set v done}]
      vwait [namespace which -variable v]
    }
    return $v
  }
}
chan puts {An error from buggy 'http' package:}
chan puts [example::wait 1000]

