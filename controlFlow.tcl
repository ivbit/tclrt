#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

set sep [string repeat * 80]
set foo {$bar}
set bar {Hello world!}
eval puts $foo

puts $sep

puts [info script]

puts $sep

# if expr1 ?then? body1 elseif expr2 ?then? body2 elseif ... ?else? ?bodyN?
# 'if' conditional: evaluates expression the same way as 'expr' command
set i 0

if {$i > 0} then {
  puts "$i is positive"
} elseif {$i < 0} then {
  puts "$i is negative"
} else {
  puts "$i is zero"
}
# 'then' and 'esle' are optional (can be used for better readability)
if {$i>0} {
  puts "$i is positive"
} elseif {$i<0} {
  puts "$i is negative"
} {
  puts "$i is zero"
}

# switch ?options? string pattern body ?pattern body ...?
# switch ?options? string {pattern body ?pattern body ...?}
# options: -- -exact -glob -nocase -regexp
# extra options to use with -regexp: -matchvar -indexvar
set img bmp

switch $img png {
  puts "PNG: file.$img"
} jpg - jpeg {
  puts "JPEG: file.$img"
} gif {
  puts "GIF: file.$img"
} default {
  puts "Wrong format \"$img\""
}

switch $img {
  png { puts "PNG: file.$img" }
  jpg -
  jpeg { puts "JPEG: file.$img" }
  gif { puts "GIF: file.$img" }
  default { puts "Wrong format \"$img\"" }
}

proc print_weekday {when} {
  set day [switch $when {
    today {clock seconds}
    tomorrow {clock add [clock seconds] 1 day}
    yesterday {clock add [clock seconds] -1 day}
    default {error "Don't understand \"$when\"."}
  }]
  puts [clock format $day -format %A]
}
print_weekday today

# Order of patterns is important in case of http and https
set url {https://www.example.com}

set port [switch -glob -nocase -- $url {
  http://* {string cat 80}
  https://* {string cat 443}
  ftp://* {string cat 21}
  default {string cat {Unknown URL type}}
}]
puts "PORT: $port"

proc connect_url {url} {
  switch -regexp -nocase -matchvar connection -- $url {
    {\Ahttp://([-_%:.[:alnum:]]*)\Z} {
      puts "Connecting to [lindex $connection 1] on port 80"
    }
    {\Ahttps://([-_%:.[:alnum:]]*)\Z} {
      puts "Connecting to [lindex $connection 1] on port 443"
    }
    default {error "Unknown protocol"}
  }
}
connect_url $url

set v { hello world Tcl}
switch -regexp -matchvar m -- $v {
{\A\s+(.*)\Z} {}
{\A\S+\s+(.*)\Z} {}
{\A\S+()\Z} {}
default {}
}
puts $m
puts "->[lindex $m 1]<-"

puts $sep

# while test body
set i 0
while {$i ^ 5} {
  puts -nonewline "i is [incr i 1]; "
}
puts {}

set i 5
while {$i ^ 0} {
  puts -nonewline "i is [incr i -1]; "
}
puts {}

proc sumw {n} {
  if {$n < 0} { error "$n is negative" }
  set sum 0
  while {$n > 0} {
    incr sum $n
    incr n -1
  }
  return $sum
}
puts [sumw 30]

# for start test next body
proc sumf {n} {
  for {set sum 0} {$n > 0} {incr n -1} {
    incr sum $n
  }
  return $sum
}
puts [sumf 30]

# 'break' can be used inside both 'body' and 'next',
# 'continue' can be used inside 'body'
for {set i 1} {$i < 10} {
  incr i
  if {$i == 5} {break}
} {
  if {$i == 2} {continue}
  puts -nonewline "$i "
}
puts {}

# 'break' - abort looping command
for {set i 0} {$i < 10} {incr i} {
  if {$i > 4} {
    break
  }
  puts -nonewline "i is $i; "
}
puts {}

# 'continue' - skip to the next iteration of a loop
for {set i 0} {$i < 10} {incr i} {
  if {$i & 1} {
    continue
  }
  puts -nonewline "i is $i; "
}
puts {}

for {set i 0} {$i < 10} {incr i} {
  if {!($i & 1)} {
    continue
  }
  puts -nonewline "i is $i; "
}
puts {}


