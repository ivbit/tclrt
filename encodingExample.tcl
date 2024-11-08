#! /bin/sh
# Launch 'tclsh': \
exec tclsh "$0" ${1+"$@"}

puts "\u00e9 and \u0065\u0301"
puts "\x55\x6e\x69\u0063\u006f\u0064\U00000065"
# Tcl has it's own internal representation of Unicode code points.
# Some operations require converting to and from a specific encoding.
# Even though system encoding is utf-8, Tcl still requires conversion in this case:
puts "encoding system: [encoding system]"
puts [binary encode base64 [encoding convertto utf-8 {Как дела?}]]
puts [encoding convertfrom utf-8 [binary decode base64 {0JrQsNC6INC00LXQu9CwPw==}]]

# 'binary' is an encoding alias to 'iso8859-1'
# Tcl 9.0.0 'chan configure -encoding':
# Unknown encoding 'binary': no longer supported.
# Use either '-translation binary' or '-encoding iso8859-1'
# File opened in 'binary mode' in Tcl 9.0.0:
# -blocking 1 -buffering full -buffersize 4096 -encoding iso8859-1 -eofchar {} -profile strict -translation lf

# In shell:
# printf '%s' 'Как дела?' | base64
# printf '%s' '0JrQsNC6INC00LXQu9CwPw==' | base64 -d; printf '\n'
#
# In interactive tclsh (call external 'printf' command):
# Tcl silently converts a string to system encoding before passing it to an
# external program, that's why triple quoting is needed (parser, encoder, eval).
# printf {{{%s}}} {{{Как дела?}}} | base64
# printf {{{%s}}} "{{Как дела?}}" | base64
# printf {{{%s}}} Как\\\\ дела? | base64
# printf {{{%s}}} {{{0JrQsNC6INC00LXQu9CwPw==}}} | base64 -d; puts {}


