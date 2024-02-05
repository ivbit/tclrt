#! /usr/bin/tclsh

# encoding system
# utf-8

proc fetch_webpage {host url} {
  set fp [socket $host 80]
  puts $fp "GET $url HTTP/1.0"
  puts $fp {}
  flush $fp

  while {[gets $fp line] >= 0} {
    puts stdout $line
  }
  close $fp
}

fetch_webpage old.meteoinfo.ru /forecasts5000/russia/moscow-area/moscow

