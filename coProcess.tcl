#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# Using 'dc' calculator as 'co-process'
set c [open |dc r+]
chan configure $c -buffering line -encoding utf-8

chan puts $c {5 6 7 + * p}
chan gets $c result
chan puts stdout $result

chan puts $c {5 6 7}
chan puts $c {+ -}
chan puts $c p
chan gets $c result
chan puts stdout $result

chan close $c

