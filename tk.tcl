#! /bin/sh
# launch \
exec wish "$0" ${1+"$@"}

# https://tkdocs.com/tutorial/firstexample.html

# Install:
# sudo apt install tcl tcllib tcl-dev tk tklib tk-dev

# 1 meter == 3.281 feets

package require Tk

wm title . {Feet to Meters (Tcl)}

grid [ttk::frame .c -padding {3 3 12 12}] -column 0 -row 0 -sticky nwes
grid columnconfigure . 0 -weight 1; grid rowconfigure . 0 -weight 1

grid [ttk::entry .c.feet -width 7 -textvariable feet] -column 2 -row 1 -sticky we
grid [ttk::label .c.meters -textvariable meters] -column 2 -row 2 -sticky we
grid [ttk::button .c.calc -text Calculate -command calculate] -column 3 -row 3 -sticky w

grid [ttk::label .c.flbl -text feet] -column 3 -row 1 -sticky w
grid [ttk::label .c.islbl -text {is equivalent to}] -column 1 -row 2 -sticky e
grid [ttk::label .c.mlbl -text meters] -column 3 -row 2 -sticky w

foreach w [winfo children .c] {grid configure $w -padx 5 -pady 5}
focus .c.feet
bind . <Return> {calculate}

proc calculate {} {  
   if {
     [catch {
       set ::meters [expr {round($::feet * 0.3048 * 10000.0) / 10000.0}]
     }] != 0
   } then {
       set ::meters {}
   }
}

# When command 'package require Tk' loads the 'Tk' package, event loop is
# automatically started. No need for 'vwait' command. When all 'Tk' windows are
# closed, the event loop gets automatically terminated.
# vwait forever

