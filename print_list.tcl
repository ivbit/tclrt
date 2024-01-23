#!/usr/bin/tclsh

set alphaindexes [list a 1 b 2 c 3 d 4 e 5 f 6]
foreach { key num } $alphaindexes {
  puts "key:${key} num:$num"
}

proc print_list { the_list } {
  foreach { key } $the_list {
    puts "$key"
  }
}

puts "\ntcl::pkgconfig"
# puts [join [tcl::pkgconfig list] "\n"]
print_list [tcl::pkgconfig list]

puts -nonewline "\nlibdir,runtime: "
puts [tcl::pkgconfig get "libdir,runtime"]

puts -nonewline "bindir,runtime: "
puts [tcl::pkgconfig get "bindir,runtime"]

puts -nonewline "scriptdir,runtime: "
puts [tcl::pkgconfig get "scriptdir,runtime"]

puts -nonewline "includedir,runtime: "
puts [tcl::pkgconfig get "includedir,runtime"]

puts -nonewline "docdir,runtime: "
puts [tcl::pkgconfig get "docdir,runtime"]

