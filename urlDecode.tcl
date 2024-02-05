#!/usr/bin/tclsh

proc urlDecode {str} {
  set specialMap {{[} {%5B} {]} {%5D}}
  set seqRE {%([0-9a-fA-F]{2})}
  set replacement {[format {%c} [scan {\1} {%2x}]]}
  set modStr [regsub -all $seqRE [string map $specialMap $str] $replacement]
  return [encoding convertfrom utf-8 [subst -nobackslashes -novariables $modStr]]
}

puts [urlDecode {http%3A%2F%2Fexample.com%2Flogin%3Fregister}]
puts [urlDecode {https%3A%2F%2Fgoogle.com%2Fsearch%3Fnew}]
puts [urlDecode {https%3A%2F%2Fweather.com%2Flocation%3Fd[3421.77259]}]
puts [urlDecode {https%3A%2F%2Fsomething.com%2Fpurchase%3Fitem%3Dcount%26n%3Dm}]

