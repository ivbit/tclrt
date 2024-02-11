#! /usr/bin/dash
# Next line reloads the script using tclsh \
exec tclsh "$0" ${1+"$@"}

# The tclreadline package makes the 'GNU readline' available to the Tcl.

# sudo apt install tcl-tclreadline

# Usage:
# tclsh
# source tclReadline.tcl
# OR
# puts the 'if' command from below into .tclshrc, or .wishrc in home directory.

# Non-printable control characters as color control characters must be enclosed
# between literal <C-A> and <C-B> to tell readline the length printable prompt.
if {$tcl_interactive && {tclreadline} ni [package names]} {
  package require tclreadline
  proc ::tclreadline::prompt1 {} {return "\001\033\[1;38;5;28m\002tcl\001\033\[0m\002% "}
  proc ::tclreadline::prompt2 {} {return "\001\033\[38;5;166m\002>\001\033\[0m\002 "}
  set ::tclreadline::historyLength 999
  ::tclreadline::Loop
}

# Files (depending on what interpreter you use):
# .tclshrc file in the HOME directory
# .wishrc file in the HOME directory

# You can access your Tcl command line history using vi or emacs-style
# keystrokes by creating a .inputrc file in your home directory and putting
# a line it it that says "set editing-mode vi" or "set editing-mode emacs".


