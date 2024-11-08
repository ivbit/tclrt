#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

proc sep {} {
  chan puts \n\u001b\[33m[string repeat * 70]\u001b\[0m\n
}

# SQLite3 is available as a binary package:
# package require sqlite3
# https://www.sqlite.org/tclsqlite.html

chan puts \nhttps://www.sqlite.org/tclsqlite.html\n

package require sqlite3

if {[file exists ./testdb]} then {file delete ./testdb}

# dbcmd  eval  ?-withoutnulls?  sql   ?array-name?  ?script?
sqlite3 db1 ./testdb
db1 eval {CREATE TABLE t1(a int, b text)}
db1 eval {INSERT INTO t1 VALUES(1,'hello')}
db1 eval {INSERT INTO t1 VALUES(2,'goodbye')}
db1 eval {INSERT INTO t1 VALUES(3,'howdy!')}
set x [db1 eval {SELECT * FROM t1 ORDER BY a}]
chan puts $x\n

# Process the results of a query 1 row at a time
db1 eval {SELECT * FROM t1 ORDER BY a} values {
  parray values
  chan puts {}
}

# Array variable name is ommited, 'db1 eval' uses variables instead
db1 eval {SELECT * FROM t1 ORDER BY a} {
  chan puts "a=$a b=$b"
}

sep

# Insert a variable's value into SQL string (can't be used with column names):
# $ - value inserted as a string if it has string representations, or as BLOB.
# @ - value inserted as a BLOB if it has bytearray representation.
# : - same as $, but Tcl will never expand :variable, unlike $variable.
# If the variable does not exist, a NULL value is used.
set bigstring {Hello!}
db1 eval {INSERT INTO t1 VALUES(5,$bigstring)}
db1 eval {INSERT INTO t1 VALUES(6,@bigstring)}
db1 eval {INSERT INTO t1 VALUES(7,:bigstring)}

# Empty string instead of array name
db1 eval {SELECT a, b, typeof(b) as type FROM t1 ORDER BY a} {} {
  chan puts "a=$a b=$b\t$type"
}

# Closing the database connection 'db1 close', or delte the command 'db1'
db1 close
# rename db1 {}

sep

# dbcmd transaction ?transaction-type? script
# 'transaction-type': deferred, exclusive or immediate. The default is deferred.

# dbcmd config
sqlite3 db2 ./testdb
chan puts [db2 config]\n
# Maximum security:
db2 config trusted_schema 0
db2 config dqs_dml 0
db2 config dqs_ddl 0
db2 config defensive 1
db2 config load_extension 0
chan puts [db2 config]

sep

# Keep a log of all SQL operations: db trace cmdprefix
proc dbtrace {sqlQuery} {
  variable dbLog
  append dbLog $sqlQuery\n
}
db2 trace dbtrace

# The "copy" method copies data from a file into a table.
# dbcmd copy conflict-algorithm table-name file-name ?column-sep? ?null-ind?
# 'conflict-algorithm': rollback, abort, fail, ignore, or replace.

# The "exists" method is similar to "eval" and "onecolumn", but always return
# a boolean "true", if 1, or more rows are returned, otherwise returns "false".
# Test for existence of rows in a table:
set record 1
if {[db2 exists {SELECT b FROM t1 WHERE a=:record}]} then {
  chan puts "The record \"$record\" exists."
} else {
  chan puts {No such record.}
}

sep

# The "function" method reqisters new SQL functions with the SQLite3 engine.
# The "script" is a Tcl command prefix.
# dbcmd function sql-name ?options? script
db2 function myHex -deterministic -directonly {format 0x%X}
db2 eval {INSERT INTO t1 VALUES(100,'New!')}
db2 eval {INSERT INTO t1 VALUES(200,myHex(200))}
chan puts [db2 eval {SELECT myHex(a),b from t1}]

# The "onecolumn" method is like "eval", but returns 1st column of the 1st row.
chan puts "onecolumn method: [db2 onecolumn {SELECT * from t1}]"

# The "changes" and "total_changes" methods
chan puts [db2 exists {DELETE FROM t1 WHERE a = 5 OR a = 7}]
chan puts "Deleted [db2 changes] rows."
chan puts [db2 eval {SELECT rowid,b,typeof(b) FROM t1}]
chan puts "Total changes in current connection: [db2 total_changes]."

sep

# Throw an error if a SQL statement contains a parameter that does not match
# any global Tcl variable, using "bind_fallback" method. Default: insert NULL.
proc bind_error {nm} {
  error "No such variable: $nm"
}
db2 bind_fallback bind_error
catch {db2 eval {SELECT * from t1 WHERE $nosuchvar = 2}} result
chan puts $result

# The "collate" method
proc nocase_compare {a b} {
  return [string compare [string tolower $a] [string tolower $b]]
}
db2 collate NOCASE nocase_compare

# Read from a preexisting BLOB in database.
# dbcmd incrblob ?-readonly? ?db? table column rowid
# Parameter "db" is not the filename that contains the database, but rather the
# symbolic name of the database. For attached databases, this is the name that
# appears after the AS keyword in the ATTACH statement. For the main database
# file, the database name is "main". For TEMP tables, database name is "temp".
chan puts [set blob [db2 incrblob main t1 b 5]]
chan puts "BLOB contents are: [chan read $blob]"
chan close $blob

# Write to a preexisting BLOB in database. This method may only modify the
# contents of the BLOB, it's not possible to increase the size of the BLOB.
chan puts [set blob [db2 incrblob main t1 b 5]]
chan seek $blob 2
chan puts -nonewline $blob FOO
chan close $blob

# Symbolic name of the database is optional:
chan puts [set blob [db2 incrblob t1 b 5]]
chan puts "BLOB contents are: [chan read $blob]"
chan close $blob

# Numeric error code from the most recent SQLite3 operation
chan puts [db2 errorcode]

sep

# Remove the trace
db2 trace {}

chan puts [db2 eval {SELECT b FROM t1 WHERE b LIKE 'h%'}]\n
chan puts "rowid\ta\tb\ttypeof(b)"
db2 eval {SELECT rowid, a, b, typeof(b) FROM t1} values {
  # chan puts stdout [join $values(*) \t]
  foreach {k1 k2 k3 k4} $values(*) {
    chan puts stdout "$values($k1)\t$values($k2)\t$values($k3)\t$values($k4)"
  }
}

# Print the log of SQL operations, collected by a trace callback.
chan puts \nLog:\n$dbLog

db2 close

