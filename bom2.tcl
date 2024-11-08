#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# UTF-8 with BOM (byte-order mark) is used in some text files on MS Windows
# https://en.wikipedia.org/wiki/Byte_order_mark#UTF-8

# WRITING UTF-8 BOM TO FILES:
# Open file in binary mode
set f [open /tmp/bom.txt w+b]
# Write UTF-8 BOM
chan puts -nonewline $f \u00ef\u00bb\u00bf
# Change channel configuration for UTF-8 encoding, MS Windows line terminators
chan configure $f -translation crlf -encoding utf-8
# Write UTF-8 text to the channel
chan puts $f "Some\u2013text\u0021\nMore\u2013text."

# REMOVING UTF-8 BOM FROM FILES:
# Skip first 3 bytes (the UTF-8 BOM)
chan seek $f 3
# Open file in binary mode:
set t [open /tmp/nom.txt wb]
# Change channel configuration for UTF-8 encoding
chan configure $t -translation lf -encoding utf-8
# Copy channels
chan copy $f $t
# Close channels
chan close $f
chan close $t

# In POSIX shell check contents of 2 files:
# file /tmp/?om.txt
# /tmp/bom.txt: Unicode text, UTF-8 (with BOM) text, with CRLF line terminators
# /tmp/nom.txt: Unicode text, UTF-8 text

set c [open "| file [lsort -dictionary [glob /tmp/?om.txt]]"]
chan puts [chan read -nonewline $c]
chan close $c

