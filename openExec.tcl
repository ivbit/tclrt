#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# 'VIM.gz' has contents of '.vimrc'
set pline [open {| zcat VIM.gz | grep abbr | sort -u}]
# 'pid fileID' returns a list of all process identifiers in a pipeline
exec ps -fp [pid $pline] >@ stdout
chan puts stdout [string repeat * 80]
chan puts stdout [chan read -nonewline $pline]
chan close $pline

