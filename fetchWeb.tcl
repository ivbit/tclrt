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
proc fetch_webpage {host url} {
  set fp [socket $host 80]
  puts stdout [chan configure $fp]
  puts $fp "GET $url HTTP/1.0"
  puts $fp {}
  flush $fp

  while {[gets $fp line] >= 0} {
    puts stdout $line
  }
  close $fp
}

fetch_webpage old.meteoinfo.ru /forecasts5000/russia/moscow-area/moscow

# chan configure $fp:
  # -blocking 1 -buffering full -buffersize 4096 -encoding utf-8
  # -eofchar {{} {}} -translation {auto crlf}
  # -peername {193.7.160.227 meteoinfo.ru 80}
  # -sockname {10.73.164.249 10.73.164.249 38753}

# Manual conversion not needed in this case:
# puts stdout [encoding convertfrom utf-8 $line]
# Conversion from and to utf-8 is done automatically in '$fp' channel.

