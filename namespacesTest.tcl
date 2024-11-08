

# student
-map {
  name {::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      }
      if {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      }
      error {Invalid number of arguments.}
    }
  } 0}


  age {::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      }
      if {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      }
      error {Invalid number of arguments.}
    }
  } 1}


  college {::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      }
      if {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      }
      error {Invalid number of arguments.}
    }
  } 2}
}


-namespace :: -parameters rec -prefixes 1 -subcommands {} -unknown {}


# tv
-map {
  id {::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      } elseif {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      } else {
        error {Invalid number of arguments.}
      }
    }
  } 0}
  

  model {::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      } elseif {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      } else {
        error {Invalid number of arguments.}
      }
    }
  } 1}
 

  price {::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      } elseif {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      } else {
        error {Invalid number of arguments.}
      }
    }
  } 2}
 

  warranty {::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      } elseif {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      } else {
        error {Invalid number of arguments.}
      }
    }
  } 3}
 
  info {::apply {
    {index rec args}
    {
      if {[llength $args] == 0} then {
        return [lindex $rec $index]
      } elseif {[llength $args] == 1} then {
        return [lreplace $rec $index $index [lindex $args 0]]
      } else {
        error {Invalid number of arguments.}
      }
    }
  } 4}
}


-namespace :: -parameters rec -prefixes 1 -subcommands {} -unknown {}


