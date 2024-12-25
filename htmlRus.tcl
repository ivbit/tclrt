#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# Replace all cyrillic and other special characters with numeric HTML entities
set src [file normalize ./src.html]
set dst [file normalize /tmp/dst.html]

set lst {
  1040 1041 1042 1043 1044 1045 1025 1046 1047 1048 1049 1050 1051 1052 1053
  1054 1055 1056 1057 1058 1059 1060 1061 1062 1063 1064 1065 1066 1067 1068
  1069 1070 1071 1072 1073 1074 1075 1076 1077 1105 1078 1079 1080 1081 1082
  1083 1084 1085 1086 1087 1088 1089 1090 1091 1092 1093 1094 1095 1096 1097
  1098 1099 1100 1101 1102 1103 171 187 8222 8220 8221 8216 8217 9001 9002 169
  8471 174 8482 8470 8592 8594 10229 10230 167 182 176 8242 8243 8364 8381 8212
  8211 8722 8226 9500 9492 9472 160 8209 173
}

foreach itm $lst {
  append map "\\u[format %04x $itm] &#$itm; "
}

set s [open $src]
set d [open $dst w]

while {[chan gets $s line] >= 0} {
  chan puts $d [string map $map $line]
}

chan close $s
chan close $d

