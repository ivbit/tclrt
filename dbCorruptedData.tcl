#! /bin/sh
# launch \
exec tclsh "$0"

# 'mp3' files must be present in the current directory.
# For this exampe the files named m1.mp3, m2.mp3, m3.mp3, ...
if {[catch {glob *.mp3}]} then {
  chan puts stderr {No MP3 filed found in current directory!}
  exit 1
}

set dbfile msc.db

if {[file exists $dbfile]} then {
  file delete $dbfile
}

# Write blobs
package require sqlite3
sqlite3 db $dbfile
db eval {CREATE TABLE msc(msc blob)}
foreach m [lsort -dictionary [glob *.mp3]] {
  set f [open $m rb]
  set c [chan read -nonewline $f]
  db eval {INSERT INTO msc VALUES(:c)}
  chan close $f
}
db close

# Read blobs
# CORRUPTED DATA
package require sqlite3
file mkdir test
sqlite3 db $dbfile
foreach r {1 2 3 4 5 6} {
  set b [db eval {select msc from msc where rowid = :r}]
  set f [open test/z[incr i].mp3 wb]
  chan puts -nonewline $f $b
  chan close $f
}
db close

chan puts stderr [exec sh -c {for f in *.mp3; do diff -s $f test/z${f#m}; done}]

# END OF SCRIPT

