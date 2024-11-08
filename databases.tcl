#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

set sep \u001b\[33m[string repeat * 70]\u001b\[0m

proc print_list {l} {
  chan puts [join $l \n]
}

proc print_dict {dict args} {
  if {[llength $args] == 0} then {
    set names [lsort -dict [dict keys $dict]]
  } else {
    set names [list]
    foreach pattern $args {
      lappend names {*}[lsort -dict [dict keys $dict $pattern]]
    }
  }
  set maxl 0
  foreach name $names {
    expr {
      [string length $name] > $maxl &&
      [set maxl [string length $name]]
    }
  }
  incr maxl 2
  set lines [list]
  foreach name $names {
    lappend lines [format {%-*s = %s} $maxl $name [dict get $dict $name]]
  }
  chan puts stdout [join $lines \n]
}

# SQLite3 is also available as a binary package:
# package require sqlite3
# https://www.sqlite.org/tclsqlite.html

package require tdbc::sqlite3

# TclOO classes tdbc::connection, tdbc::statement, tdbc::resultset
# A database connection is represented by an object tdbc::connection
# tdbc::sqlite3::connection create OBJNAME FILENAME ?-OPTION VALUE ...?
# A connection to SQLite3 database is created by passing the path to a SQLite3
# database file to the 'tdbc::sqlite3::connection' command. Curren directory:
# tdbc::sqlite3::connection create db my-database.sqlite3
# The object 'db' was created, representing the database connection. Invoke
# methods on this object to operate on the database.

# Create in-memory SQLite3 database with token ':memory:'
# Method 'new' generates random connection object's name
chan puts [set dbconn [tdbc::sqlite3::connection new :memory:]]

# Common connection options: -encoding, -isolation, -timeout, readonly
# Retrieve configuration
chan puts [$dbconn configure]
$dbconn configure -encoding utf-8

# Releasing connection resources
# This will also close and release resuorces related to tdbc::statement and
# tdbc::resultset objects created through the connection.
# $dbconn close

# Executing SQL
# Preparing a statement
# DBCONN prepare SQL
chan puts [
  set stmt [
    $dbconn prepare {
      CREATE TABLE Accounts (
        Name text,
        AcctNo text NOT NULL PRIMARY KEY,
        Balance double
      )
    }
  ]
]

# Executing prepared statement
chan puts [set res [$stmt execute]]
# 'execute' method returns a tdbc::resultset object
# Free the resources when objects are no longer required, closing statement
# automatically closes any contained resultset objects.
$stmt close

# Insertions and queries
chan puts [
  set stmt [
    $dbconn prepare {
      INSERT INTO Accounts (Name, AcctNo, Balance)
      VALUES ('Tom', 'A001', 100.00)
    }
  ]
]

chan puts [$stmt execute]

$stmt close

# Bound variables - :varname (values from variables, or dictionary)
chan puts [
  set stmt [
    $dbconn prepare {
      INSERT INTO Accounts (Name, AcctNo, Balance)
      VALUES (:name, :acctno, :balance)
    }
  ]
]

foreach {name acctno balance} {
  Rick  A002 200.00
  Harry A003 300.00
} {chan puts [$stmt execute]}

# Prepared statement can be executed multiple times with different values
# Order of elements does not matter
chan puts [$stmt execute {acctno A004 name Moe balance 100.00}]

# Bound variable configuraton
# STMT paramtype NAME ?DIRECTION? TYPE ?PRECISION? ?SCALE?
# DIRECTION: in, out, inout
# TYPE, PRECISION, SCALE: type, precision, scale column attributes
# Not required by SQLite3
$stmt paramtype balance in double
# Return the configuration - 'params' method
print_dict [$stmt params]

# Closing prepared statement: STMT close
$stmt close

# Retrieving data from result sets
chan puts [
  set stmt [$dbconn prepare {SELECT Name, Balance from Accounts}]
]

chan puts [set res [$stmt execute]]

# Result set is a table, 'tdbc::resultset columns' return column names
chan puts [$res columns]
chan puts "Number of rows: [$res rowcount]"

# Retrieving data RESULTSET nextlist|nextdict|nextrow
# RESULTSET nextlist VAR
# RESULTSET nextdict VAR
# RESULTSET nextrow ?-as lists|dicts? VAR
# Methods return 1 or 0, if there are no more rows
chan puts [$res nextlist val]
chan puts $val
while {[$res nextdict val]} {
  chan puts $val
}

# Multiple result sets: RESULTSET nextresults
# Presence of multiple result sets may be detected with 'nextresults' method.
# This method must be called after 'nextlist', or 'nextdict' returns 0.
chan puts [$res nextresults]

# Releasing result sets
$res close

chan puts $sep

# Convenience wrappers for retrieval
# RESULTSET allrows ?-as lists|dicts? ?-columnsvariable COLVAR?
# STATEMENT allrows ?-as lists|dicts? ?-columnsvariable COLVAR? ?--? ?DICT?
# DBCONN allrows ?-as lists|dicts? ?-columnsvariable COLVAR? ?--? SQL ?DICT?

# Without 'allrows'.
set query_values [dict create amount 200]
set stmt [$dbconn prepare {
  SELECT Name From Accounts WHERE Balance >= :amount
}]
set rows {}
try {
  set res [$stmt execute $query_values]
  try {
    while {[$res nextdict row]} {
      lappend rows $row
    }
  } finally {
    $res close
  }
} finally {
  $stmt close
}
print_list $rows

chan puts $sep

# The same query using 'allrows' method of 'tdbc::resultset' object.
# Returns rows as dictionaries by default.
set stmt [$dbconn prepare {
  SELECT Name FROM Accounts WHERE Balance >= :amount
}]
set rows {}
try {
  set res [$stmt execute $query_values]
  try {
    set rows [$res allrows]
  } finally {
    $res close
  }
} finally {
  $stmt close
}
print_list $rows

chan puts $sep

# 'allrows' method of the 'tdbc::statement' object
set rows {}
set stmt [$dbconn prepare {
  SELECT Name FROM Accounts WHERE Balance >= :amount
}]
try {
  set rows [$stmt allrows $query_values]
} finally {
  $stmt close
}
print_list $rows

chan puts $sep

# 'allrows' method of the database connection
set rows [$dbconn allrows {
  SELECT Name FROM Accounts WHERE Balance >= :amount
} $query_values]
print_list $rows

chan puts $sep

# '-as' and '-columnsvariable'
set rows [$dbconn allrows -as lists -columnsvariable cols {
  SELECT Name, Balance FROM Accounts WHERE Balance >= :amount
} $query_values]
chan puts $cols
print_list $rows

chan puts $sep

# Iterating over result sets: 'foreach'
# 'foreach' executes a given script for every row in the result set.
# RESULTSET foreach ?-as lists|dicts? ?-columnsvariable COLVAR? ?--? VAR SCRIPT
# STATEMENT foreach ?-as lists|dicts? ?-columnsvariable COLVAR? ?--? VAR ?DICT? SCRIPT
# DBCONN foreach ?-as lists|dicts? ?-columnsvariable COLVAR? ?--? VAR SQL ?DICT? SCRIPT
# 'foreach' iterates over all rows in the result set, assigns the value of the
# row to the variable VAR, and evaluates the SCRIPT for each row.
$dbconn foreach row {
  SELECT Name FROM Accounts WHERE Balance >= :amount
} $query_values {
  chan puts $row
}

chan puts $sep

# Database transactions
# 'transaction' method of 'tdbc::connection'
# DBCONN transaction SCRIPT
# Transaction is committed if return code is one of: ok, return, break, continue
set transfer {from "Tom" to "Rick" amount 50}
  catch {
  $dbconn transaction {
    $dbconn allrows -as lists -- {
      UPDATE Accounts
      SET Balance = Balance - :amount
      WHERE Name = :from
    } $transfer

    chan puts "Within transaction: [$dbconn allrows -as lists -- {
      SELECT Name, Balance FROM Accounts WHERE Name = :from
    } $transfer]"

    error {Something went wrong!}
    
    $dbconn allrows -as lists -- {
      UPDATE Accounts
      SET Balance = Balance + :amount
      WHERE Name = :to
    } $transfer
  }
} result
chan puts $result

# Transaction was aborted by an error exception
chan puts [
  $dbconn allrows -as lists -- {
    SELECT Name, Balance FROM Accounts WHERE Name = :from
  } $transfer
]

chan puts $sep

# DBCONN begintransaction
# DBCONN commit
# DBCONN rollback
set transfer {from {Tom} to {Rick} amount 50}
$dbconn begintransaction
$dbconn allrows -as lists -- {
  UPDATE Accounts
  SET Balance = Balance - :amount
  WHERE Name = :from
} $transfer

chan puts "Within transaction: [$dbconn allrows -as lists -- {
  SELECT Name, Balance FROM Accounts WHERE Name = :from
} $transfer]"

if {[catch {
  error {Something went wrong}
  $dbconn allrows -as lists -- {
    UPDATE Accounts
    SET Balance = Balance + :amount
    WHERE Name = :to
  } $transfer
}]} then {
  $dbconn rollback
  chan puts {On error, rollback the transaction.}
} else {
  $dbconn commit
}

chan puts [$dbconn allrows -as lists -- {
  SELECT Name, Balance FROM Accounts WHERE Name = :from
} $transfer]

chan puts $sep

# Handling NULL values
# To write NULL to a table column, pass a dictionary containing bound variables
# for all keys except those with value of NULL.
$dbconn allrows {
  INSERT INTO Accounts (Name, AcctNo, Balance) VALUES (:name, :acctno, :balance)
} {name Curly acctno C007}

# To retrieve data containing NULL, use one of the forms that returns rows as
# dictionaries. If a value is NULL, the key will not be present in the result.
# 'tdbc::resultset::nextdict' method can be used to retrieve NULLs.
chan puts "Balance is NULL:\n[
  $dbconn allrows {SELECT Name,Balance,AcctNo FROM Accounts WHERE Name='Curly'}
]"
# The result when 'list' format is used
chan puts "List format and NULL:\n[
  $dbconn allrows -as lists {
    SELECT Name, Balance, AcctNo FROM Accounts WHERE Name = 'Curly'
  }
]"

chan puts $sep

# Stored procedures
# DBCONN preparecall CALL
# The syntax of the stored procedure call:
# ?RESULTVAR =? STOREDPROCNAME (? arg, ...?)
# Result is a tdbc::statement object.

# Enumerating objects, objects that are currently open within a connection:
chan puts [$dbconn statements]
chan puts [$dbconn resultsets]

# Introspecting tables
# DBCONN tables ?SQLPAT?
chan puts [$dbconn tables]
# SQL pattern syntax
chan puts [$dbconn tables A%]

# Introspecting columns
# DBCONN columns TABLE ?SQLPAT?
print_dict [$dbconn columns Accounts]

chan puts $sep

print_dict [$dbconn columns Accounts Bal%]

chan puts $sep

# Introspecting keys
# DBCONN primarykeys TABLE
# DBCONN foreignkeys ?-primary TABLE? ?-foreigh TABLE?
chan puts [$dbconn primarykeys Accounts]

# ODBC utilities
package require tdbc::odbc
# Installed ODBC drivers on the system:
print_dict [tdbc::odbc::drivers]
# Configured ODBC data sources on the system:
print_dict [tdbc::odbc::datasources]
print_dict [tdbc::odbc::datasources -user]
print_dict [tdbc::odbc::datasources -system]
# Management of ODBC data sources
# tdbc::odbc::datasource SUBCMD DRIVER ?KEYWORD=VALUE?
# Data source is specified by a DSN entry in the list of keywords.

chan puts {$dbconn close}
$dbconn close

