# tclrt

"Learning Tcl" from riptutorial

https://riptutorial.com/ebook/tcl

puts "\\x7b \\x7d"

puts "The current date is \[clock format \[clock seconds\] -format "\\"%A %d %B %Y %R\\""\]"

puts "The current date is \[clock format \[clock seconds\] -format "\\"%a %d %b %R\\""\]"

puts "The current time is \[clock format \[clock seconds\] -format %H:%M\]"

clock format \[clock seconds\] -format \{%A %d %B %Y %R\}

clock format \[clock seconds\] -format \{%a %d %b %R\}

clock format \[clock seconds\] -format \{%x %X\} -locale de

clock format \[clock add \[clock seconds\] -3 days\]

join \[lsort \[encoding names\]\] "\\n"

encoding convertto cp1251 $text1

encoding convertfrom cp1251 $text2

encoding system

package require fileutil

fileutil::writeFile $path $content

namespace path \[list ::tcl::mathop ::tcl::mathfunc\]

set num 0; while \{$num ^ 7\} \{puts \[incr num\]\}

set num 0; while \{$num ^ 7\} \{if \{$num & 1\} \{puts "\[incr num\]. Text..."\} else \{puts "\[incr num\]. Paragraph..."\}\}

** \[** 2 3\] 4

expr \{\[string is digit -strict $num\] && $num > 0 && $num <= 85 \|\| \[set num 85\]\}

https://vanderburg.org/old\_pages/Tcl/war/0000.html
