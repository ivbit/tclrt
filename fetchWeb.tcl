#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# Strings in Tcl are sequences of Unicode code points in range from U+0000 to
# U+FFFF. A character may map to more than one sequence of Unicode code points:
# puts "\u00e9 and \u0065\u0301"
# Tcl has it's own internal representation of Unicode code points and in most
# cases automatically converts strings between system encoding and internal
# representation. Some data (from base64 encoded strings, for example) needs
# to be converted manually using 'encoding convertfrom' command:
# binary encode base64 [encoding convertto utf-8 {Как Ваше здоровье?}]
# in POSIX shell:
# printf '%s' '0JrQsNC6INCS0LDRiNC1INC30LTQvtGA0L7QstGM0LU/' | base64 -d
# encoding convertfrom utf-8 [binary decode base64 {0K8g0YHQtdCx0Y8g0YfRg9Cy0YHRgtCy0YPRjiwg0L3QviDQv9C70L7RhdC+Lg==}]

# Linux:
# encoding system
# utf-8
# Windows:
# encoding system
# cp1251

# 'socket' does conversion from utf-8 automatically
proc fetchWebpage {host url} {
  set fp [socket $host 80]
  chan puts stdout [chan configure $fp]
  chan puts $fp "GET $url HTTP/1.0"
  chan puts $fp {}
  chan flush $fp

  while {[chan gets $fp line] >= 0} {
    chan puts stdout $line
  }
  chan close $fp
}

fetchWebpage old.meteoinfo.ru http://old.meteoinfo.ru/forecasts5000/russia/moscow-area/moscow

# chan configure $fp:
  # -blocking 1 -buffering full -buffersize 4096 -encoding utf-8
  # -eofchar {{} {}} -translation {auto crlf}
  # -peername {193.7.160.227 meteoinfo.ru 80}
  # -sockname {10.73.164.249 10.73.164.249 38753}

# Manual conversion not needed in this case:
# puts stdout [encoding convertfrom utf-8 $line]
# Conversion from and to utf-8 is done automatically in '$fp' channel.

chan puts \n\u001b\[33m[string repeat * 80]\u001b\[0m\n

set httpReq "GET http://www.example.com HTTP/1.1\n"

set so [socket www.example.com 80]
chan configure $so -encoding utf-8 -translation crlf -buffering line

chan puts $so $httpReq
chan close $so write

chan puts [chan read $so]
chan close $so

chan puts \n\u001b\[34m[string repeat * 80]\u001b\[0m\n

# Connect asynchronously
proc OnRead {so} {
  variable done
  set s [chan read $so]
  if {[string length $s] == 0} then {
    if {[chan eof $so]} then {
      chan configure $so -blocking 1
      chan close $so
      set done 1
    }
    return
  }
  chan puts stdout $s
}

proc OnWrite {so} {
  chan puts $so "GET http://www.example.com HTTP/1.1\n"
  chan event $so writable {}
  chan close $so write
}

set so [socket -async www.example.com 80]
chan configure $so -blocking 0 -encoding utf-8 -translation crlf -buffering line
chan event $so readable [list OnRead $so]
chan event $so writable [list OnWrite $so]
vwait ::done

