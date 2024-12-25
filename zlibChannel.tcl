#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# Channel transformations with 'zlib'
set s [open [info script]]
set t [chan read -nonewline $s]
chan close $s

set c [file tempfile path]
zlib push gzip $c
chan puts $c $t
chan flush $c
chan puts \n[chan configure $c -checksum]\n
chan close $c

set c [open $path]
zlib push gunzip $c
chan puts [chan read -nonewline $c]
chan puts [chan configure $c -checksum]\n
chan close $c
file delete $path

