

# The default implementation of 'unknown' behaves as follows.
# It first calls the 'auto_load' library procedure to load the command.
# If this succeeds, it executes original command with its original arguments.
# If the 'auto_load' fails and Tcl is run interactively then 'unknown' calls
# 'auto_execok' to see if there is an executable file by the name command.
# If so, it invokes the Tcl 'exec' command with command and all the arguments.
# If command cannot be auto-executed, 'unknown' checks to see if the command was
# invoked at top-level and outside of any script. If so, then 'unknown' takes
# two additional steps. First, it sees if command has one of the following three
# forms: '!!', '!event', or '^old^new?^?'. If so, then 'unknown' carries out
# history substitution in same way that 'csh' shell would for these constructs.
# Finally, 'unknown' checks to see if command is an unique abbreviation for an
# existing Tcl command. If so, it expands the command name and executes the
# command with the original arguments. If none of the above efforts has been
# able to execute the command, 'unknown' generates an error return. If the
# global variable 'auto_noload' is defined, then the auto-load step is skipped.
# If the global variable 'auto_noexec' is defined the auto-exec step is skipped.
# Under normal circumstances the return value from 'unknown' is the
# return value from the command that was eventually executed. 

proc ::unknown {args} {
  variable ::tcl::UnknownPending
  global auto_noexec auto_noload env tcl_interactive errorInfo errorCode

  if {[info exists errorInfo]} then {
    set savedErrorInfo $errorInfo
  }
  if {[info exists errorCode]} then {
    set savedErrorCode $errorCode
  }

  set name [lindex $args 0]
  if {![info exists auto_noload]} then {
    # Make sure we're not trying to load the same proc twice.
    if {[info exists UnknownPending($name)]} then {
      return -code error\
        "self-referential recursion in \"unknown\" for command \"$name\""
    }
    set UnknownPending($name) pending
    set ret [
      catch {
        auto_load $name [uplevel 1 {::namespace current}]
      } msg opts
    ]
    unset UnknownPending($name)
    if {$ret != 0} then {
      dict append opts -errorinfo "\n    (autoloading \"$name\")"
      return -options $opts $msg
    }
    if {![array size UnknownPending]} then {
      unset UnknownPending
    }
    if {$msg} then {
      if {[info exists savedErrorCode]} then {
        set ::errorCode $savedErrorCode
      } else {
        unset -nocomplain ::errorCode
      }
      if {[info exists savedErrorInfo]} then {
        set errorInfo $savedErrorInfo
      } else {
        unset -nocomplain errorInfo
      }
      set code [
        catch {
          uplevel 1 $args
        } msg opts
      ]
      if {$code == 1} then {
        # Compute stack trace contribution from the 'uplevel'.
        # Note the dependence on how Tcl_AddErrorInfo, etc.
        # construct the stack trace.
        set errInfo [dict get $opts -errorinfo]
        set errCode [dict get $opts -errorcode]
        set cinfo $args
        if {[string bytelength $cinfo] > 150} then {
          set cinfo [string range $cinfo 0 150]
          while {[string bytelength $cinfo] > 150} {
            set cinfo [string range $cinfo 0 end-1]
          }
          append cinfo ...
        }
        set tail "\n    (\"uplevel\" body line 1)\n    invoked\
          from within\n\"uplevel 1 \$args\""
        set expect "$msg\n    while executing\n\"$cinfo\"$tail"
        if {$errInfo eq $expect} then {
          # The stack has only the 'eval' from the expanded command
          # Do not generate any stack trace here.
          dict unset opts -errorinfo
          dict incr opts -level
          return -options $opts $msg
        }
        # Stack trace is nested, trim off just the contribution
        # from the extra 'eval' of $args due to the 'catch' above.
        set last [string last $tail $errInfo]
        if {$last + [string length $tail] != [string length $errInfo]} then {
          # Very likely cannot happen
          return -options $opts $msg
        }
        set errInfo [string range $errInfo 0 $last-1]
        set tail "\"$cinfo\""
        set last [string last $tail $errInfo]
        if {
          $last < 0 ||
          $last + [string length $tail] != [string length $errInfo]
        } then {
          return -code error -errorcode $errCode -errorinfo $errInfo $msg
        }
        set errInfo [string range $errInfo 0 $last-1]
        set tail "\n    invoked from within\n"
        set last [string last $tail $errInfo]
        if {$last + [string length $tail] == [string length $errInfo]} then {
          return -code error -errorcode $errCode\
            -errorinfo [string range $errInfo 0 $last-1] $msg
        }
        set tail "\n    while executing\n"
        set last [string last $tail $errInfo]
        if {$last + [string length $tail] == [string length $errInfo]} then {
          return -code error -errorcode $errCode\
            -errorinfo [string range $errInfo 0 $last-1] $msg
        }
        return -options $opts $msg
      } else {
        dict incr opts -level
        return -options $opts $msg
      }
    }
  }

  if {
    ([info level] == 1) &&
    ([info script] eq {}) &&
    [info exists tcl_interactive] &&
    $tcl_interactive
  } then {
    if {![info exists auto_noexec]} then {
      set new [auto_execok $name]
      if {$new ne {}} then {
        set redir {}
        if {[namespace which -command console] eq {}} then {
          set redir {>&@stdout <@stdin}
        }
        uplevel 1 [
          list ::catch [
            concat exec $redir $new [lrange $args 1 end]
          ] ::tcl::UnknownResult ::tcl::UnknownOptions
        ]
        dict incr ::tcl::UnknownOptions -level
        return -options $::tcl::UnknownOptions $::tcl::UnknownResult
      }
    }
    if {$name eq {!!}} then {
      set newcmd [history event]
    } elseif {[regexp {^!(.+)$} $name -> event]} then {
      set newcmd [history event $event]
    } elseif {[regexp {^\^([^^]*)\^([^^]*)\^?$} $name -> old new]} then {
      set newcmd [history event -1]
      catch {
        regsub -all -- $old $newcmd $new newcmd
      }
    }
    if {[info exists newcmd]} then {
      tclLog $newcmd
      history change $newcmd 0
      uplevel 1 [
        list ::catch $newcmd ::tcl::UnknownResult ::tcl::UnknownOptions
      ]
      dict incr ::tcl::UnknownOptions -level
      return -options $::tcl::UnknownOptions $::tcl::UnknownResult
    }

    set ret [
      catch {
        set candidates [info commands $name*]
      } msg
    ]
    if {$name eq {::}} then {
      set name {}
    }
    if {$ret != 0} then {
      dict append opts\
        -errorinfo "\n    (expanding command prefix \"$name\" in unknown)"
      return -options $opts $msg
    }
    # Filter out bogus matches when '$name' contained
    # a glob-special char (Bug 946952)
    if {$name eq {}} then {
      # Handle empty $name separately due to strangeness
      # in 'string first' (See RFE 1243354)
      set cmds $candidates
    } else {
      set cmds [list]
      foreach x $candidates {
        if {[string first $name $x] == 0} then {
          lappend cmds $x
        }
      }
    }
    if {[llength $cmds] == 1} then {
      uplevel 1 [
        list ::catch [
          lreplace $args 0 0 [lindex $cmds 0]
        ] ::tcl::UnknownResult ::tcl::UnknownOptions
      ]
      dict incr ::tcl::UnknownOptions -level
      return -options $::tcl::UnknownOptions $::tcl::UnknownResult
    }
    if {[llength $cmds]} then {
      return -code error "ambiguous command name \"$name\": [lsort $cmds]"
    }
  }
  return -code error\
    -errorcode [list TCL LOOKUP COMMAND $name] "invalid command name \"$name\""
}

# ######################################################################
# ######################################################################

proc ::auto_execok {name} {
  global auto_execs env

  if {[info exists auto_execs($name)]} then {
    return $auto_execs($name)
  }
  set auto_execs($name) {}
  if {[llength [file split $name]] != 1} then {
    if {[file executable $name] && ![file isdirectory $name]} then {
      set auto_execs($name) [list $name]
    }
    return $auto_execs($name)
  }
  foreach dir [split $env(PATH) :] {
    if {$dir eq {}} then {
      set dir .
    }
    set file [file join $dir $name]
    if {[file executable $file] && ![file isdirectory $file]} then {
      set auto_execs($name) [list $file]
      return $auto_execs($name)
    }
  }
  return {}
}

# ######################################################################

proc ::auto_import {pattern} {
  global auto_index

  # If no namespace is specified, this will be an error case

  if {![string match *::* $pattern]} then {
    return
  }

  set ns [uplevel 1 [list ::namespace current]]
  set patternList [auto_qualify $pattern $ns]

  auto_load_index

  foreach pattern $patternList {
    foreach name [array names auto_index $pattern] {
      if {
        ([namespace which -command $name] eq {}) &&
        ([namespace qualifiers $pattern] eq [namespace qualifiers $name])
      } then {
        namespace eval :: $auto_index($name)
      }
    }
  }
}

# ######################################################################

proc ::auto_load {cmd {namespace {}}} {
  global auto_index auto_path

  if {$namespace eq {}} then {
    set namespace [uplevel 1 [list ::namespace current]]
  }
  set nameList [auto_qualify $cmd $namespace]
  # workaround non canonical auto_index entries that might be around
  # from older auto_mkindex versions
  lappend nameList $cmd
  foreach name $nameList {
    if {[info exists auto_index($name)]} then {
      namespace eval :: $auto_index($name)
      # There's a couple of ways to look for a command of a given
      # name.  One is to use 'info commands $name'
      # Unfortunately, if the name has glob-magic chars in it like *
      # or [], it may not match. For our purposes here, a better
      # route is to use 'namespace which -command $name'
      if {[namespace which -command $name] ne {}} then {
        return 1
      }
    }
  }
  if {![info exists auto_path]} then {
    return 0
  }

  if {![auto_load_index]} then {
    return 0
  }
  foreach name $nameList {
    if {[info exists auto_index($name)]} then {
      namespace eval :: $auto_index($name)
      if {[namespace which -command $name] ne {}} then {
        return 1
      }
    }
  }
  return 0
}

# ######################################################################

proc ::auto_mkindex {dir args} {
  if {[interp issafe]} then {
    error "can't generate index within safe interpreter"
  }

  set oldDir [pwd]
  cd $dir

  append index "# Tcl autoload index file, version 2.0\n"
  append index "# This file is generated by the \"auto_mkindex\" command\n"
  append index "# and sourced to set up indexing information for one or\n"
  append index "# more commands.  Typically each line is a command that\n"
  append index "# sets an element in the auto_index array, where the\n"
  append index "# element name is the name of a command and the value is\n"
  append index "# a script that loads the command.\n\n"
  if {![llength $args]} then {
    set args *.tcl
  }

  auto_mkindex_parser::init
  foreach file [lsort [glob -- {*}$args]] {
    try {
      append index [auto_mkindex_parser::mkindex $file]
    } on error {msg opts} {
      cd $oldDir
      return -options $opts $msg
    }
  }
  auto_mkindex_parser::cleanup

  set fid [open "tclIndex" w]
  chan puts -nonewline $fid $index
  chan close $fid
  cd $oldDir
}

# ######################################################################

proc ::auto_mkindex_old {dir args} {
  set oldDir [pwd]
  cd $dir
  set dir [pwd]
  append index "# Tcl autoload index file, version 2.0\n"
  append index "# This file is generated by the \"auto_mkindex\" command\n"
  append index "# and sourced to set up indexing information for one or\n"
  append index "# more commands.  Typically each line is a command that\n"
  append index "# sets an element in the auto_index array, where the\n"
  append index "# element name is the name of a command and the value is\n"
  append index "# a script that loads the command.\n\n"
  if {![llength $args]} then {
    set args *.tcl
  }
  foreach file [lsort [glob -- {*}$args]] {
    set f {}
    set error [
      catch {
        set f [open $file]
        fconfigure $f -eofchar "\032 {}"
        while {[gets $f line] >= 0} {
          if {[regexp {^proc[   ]+([^   ]*)} $line match procName]} then {
            set procName [lindex [auto_qualify $procName {::}] 0]
            append index "set [list auto_index($procName)]"
            append index " \[list source \[file join \$dir [list $file]\]\]\n"
          }
        }
        close $f
      } msg opts
    ]
    if {$error} then {
      catch {close $f}
      cd $oldDir
      return -options $opts $msg
    }
  }
  set f {}
  set error [
    catch {
      set f [open tclIndex w]
      puts -nonewline $f $index
      close $f
      cd $oldDir
    } msg opts
  ]
  if {$error} then {
    catch {close $f}
    cd $oldDir
    error $msg $info $code
    return -options $opts $msg
  }
}

# ######################################################################

proc ::auto_qualify {cmd namespace} {

  # count separators and clean them up
  # (making sure that foo:::::bar will be treated as foo::bar)
  set n [regsub -all {::+} $cmd :: cmd]

  # Ignore namespace if the name starts with ::
  # Handle special case of only leading ::

  # Before each return case we give an example of which category it is
  # with the following form :
  # (inputCmd, inputNameSpace) -> output

  if {[string match ::* $cmd]} then {
    if {$n > 1} then {
      # (::foo::bar , *) -> ::foo::bar
      return [list $cmd]
    } else {
      # (::global , *) -> global
      return [list [string range $cmd 2 end]]
    }
  }

  # Potentially returning 2 elements to try:
  # (if the current namespace is not the global one)

  if {$n == 0} then {
    if {$namespace eq {::}} then {
      # (nocolons , ::) -> nocolons
      return [list $cmd]
    } else {
      # (nocolons , ::sub) -> ::sub::nocolons nocolons
      return [list ${namespace}::$cmd $cmd]
    }
  } elseif {$namespace eq {::}} then {
    #  (foo::bar , ::) -> ::foo::bar
    return [list ::$cmd]
  } else {
    # (foo::bar , ::sub) -> ::sub::foo::bar ::foo::bar
    return [list ${namespace}::$cmd ::$cmd]
  }
}

# ######################################################################

proc ::auto_reset {} {
  global auto_execs auto_index auto_path
  if {[array exists auto_index]} then {
    foreach cmdName [array names auto_index] {
      set fqcn [namespace which $cmdName]
      if {$fqcn eq {}} then {
        continue
      }
      rename $fqcn {}
    }
  }
  unset -nocomplain auto_execs auto_index ::tcl::auto_oldpath
  if {[catch {llength $auto_path}]} then {
    set auto_path [list [info library]]
  } elseif {[info library] ni $auto_path} then {
    lappend auto_path [info library]
  }
}

# ######################################################################

proc ::tcl_findLibrary {basename version patch initScript enVarName varName} {
  upvar #0 $varName the_library
  global auto_path env tcl_platform

  set dirs {}
  set errors {}

  # The C application may have hardwired a path, which we honor

  if {[info exists the_library] && $the_library ne {}} then {
    lappend dirs $the_library
  } else {
    # Do the canonical search

    # 1. From an environment variable, if it exists.  Placing this first
    #    gives the end-user ultimate control to work-around any bugs, or
    #    to customize.

    if {[info exists env($enVarName)]} then {
      lappend dirs $env($enVarName)
    }

    # 2. In the package script directory registered within the
    #    configuration of the package itself.

    catch {
      lappend dirs [::${basename}::pkgconfig get scriptdir,runtime]
    }

    # 3. Relative to auto_path directories.  This checks relative to the
    # Tcl library as well as allowing loading of libraries added to the
    # auto_path that is not relative to the core library or binary paths.
    foreach d $auto_path {
      lappend dirs [file join $d $basename$version]
      if {
        $tcl_platform(platform) eq {unix} &&
        $tcl_platform(os) eq {Darwin}
      } then {
        # 4. On MacOSX, check the Resources/Scripts subdir too
        lappend dirs [file join $d $basename$version Resources Scripts]
      }
    }

    # 3. Various locations relative to the executable
    # ../lib/foo1.0    (From bin directory in install hierarchy)
    # ../../lib/foo1.0  (From bin/arch directory in install hierarchy)
    # ../library    (From unix directory in build hierarchy)
    #
    # Remaining locations are out of date (when relevant, they ought to be
    # covered by the $::auto_path seach above) and disabled.
    #
    # ../../library    (From unix/arch directory in build hierarchy)
    # ../../foo1.0.1/library
    #    (From unix directory in parallel build hierarchy)
    # ../../../foo1.0.1/library
    #    (From unix/arch directory in parallel build hierarchy)

    set parentDir [file dirname [file dirname [info nameofexecutable]]]
    set grandParentDir [file dirname $parentDir]
    lappend dirs [file join $parentDir lib $basename$version]
    lappend dirs [file join $grandParentDir lib $basename$version]
    lappend dirs [file join $parentDir library]
    if {0} then {
      lappend dirs [file join $grandParentDir library]
      lappend dirs [file join $grandParentDir $basename$patch library]
      lappend dirs [
        file join [file dirname $grandParentDir] $basename$patch library
      ]
    }
  }
  # uniquify $dirs in order
  array set seen {}
  foreach i $dirs {
    # Make sure $i is unique under normalization. Avoid repeated [source].
    if {[interp issafe]} then {
      # Safe interps have no [file normalize].
      set norm $i
    } else {
      set norm [file normalize $i]
    }
    if {[info exists seen($norm)]} then {
      continue
    }
    set seen($norm) {}

    set the_library $i
    set file [file join $i $initScript]

    # source everything when in a safe interpreter because we have a
    # source command, but no file exists command

    if {[interp issafe] || [file exists $file]} then {
      if {![catch {uplevel #0 [list source $file]} msg opts]} then {
        return
      }
      append errors "$file: $msg\n"
      append errors [dict get $opts -errorinfo]\n
    }
  }
  unset -nocomplain the_library
  set msg "Can't find a usable $initScript in the following directories: \n"
  append msg "    $dirs\n\n"
  append msg "$errors\n\n"
  append msg "This probably means that $basename wasn't installed properly.\n"
  error $msg
}

# ######################################################################

proc ::parray {a {pattern *}} {
  upvar 1 $a array
  if {![array exists array]} then {
    return -code error "\"$a\" isn't an array"
  }
  set maxl 0
  set names [lsort [array names array $pattern]]
  foreach name $names {
    if {[string length $name] > $maxl} then {
      set maxl [string length $name]
    }
  }
  set maxl [expr {$maxl + [string length $a] + 2}]
  foreach name $names {
    set nameString [format %s(%s) $a $name]
    chan puts stdout [format "%-*s = %s" $maxl $nameString $array($name)]
  }
}

# ######################################################################
# ######################################################################

# pkg::create
proc ::tcl::Pkg::Create {args} {
  append err(usage) "[lindex [info level 0] 0] "
  append err(usage) {-name packageName -version packageVersion}
  append err(usage) {?-load {filename ?{procs}?}? ... }
  append err(usage) {?-source {filename ?{procs}?}? ...}

  set err(wrongNumArgs) "wrong # args: should be \"$err(usage)\""
  set err(valueMissing) "value for \"%s\" missing: should be \"$err(usage)\""
  set err(unknownOpt)   "unknown option \"%s\": should be \"$err(usage)\""
  set err(noLoadOrSource) {at least one of -load and -source must be given}

  # process arguments
  set len [llength $args]
  if {$len < 6} then {
    error $err(wrongNumArgs)
  }

  # Initialize parameters
  array set opts {-name {} -version {} -source {} -load {}}

  # process parameters
  for {set i 0} {$i < $len} {incr i} {
    set flag [lindex $args $i]
    incr i
    switch -glob -- $flag {
      "-name" -
      "-version" {
        if {$i >= $len} then {
          error [format $err(valueMissing) $flag]
        }
        set opts($flag) [lindex $args $i]
      }
      "-source" -
      "-load" {
        if {$i >= $len} then {
          error [format $err(valueMissing) $flag]
        }
        lappend opts($flag) [lindex $args $i]
      }
      default {
        error [format $err(unknownOpt) [lindex $args $i]]
      }
    }
  }

  # Validate the parameters
  if {![llength $opts(-name)]} then {
    error [format $err(valueMissing) {-name}]
  }
  if {![llength $opts(-version)]} then {
    error [format $err(valueMissing) {-version}]
  }

  if {!([llength $opts(-source)] || [llength $opts(-load)])} then {
    error $err(noLoadOrSource)
  }

  # OK, now everything is good.  Generate the package ifneeded statment.
  set cmdline "package ifneeded $opts(-name) $opts(-version) "

  set cmdList {}
  set lazyFileList {}

  # Handle -load and -source specs
  foreach key {load source} {
    foreach filespec $opts(-$key) {
      lassign $filespec filename proclist

      if { [llength $proclist] == 0 } then {
        set cmd "\[list $key \[file join \$dir [list $filename]\]\]"
        lappend cmdList $cmd
      } else {
        lappend lazyFileList [list $filename $key $proclist]
      }
    }
  }

  if {[llength $lazyFileList]} then {
    lappend cmdList "\[list tclPkgSetup \$dir $opts(-name) $opts(-version) [
      list $lazyFileList]\]"
  }
  append cmdline [join $cmdList "\\n"]
  return $cmdline
}

# ######################################################################

proc ::pkg_mkIndex {args} {
  set usage {"pkg_mkIndex ?-direct? ?-lazy? ?-load pattern? ?-verbose? ?--?\
    dir ?pattern ...?"}

  set argCount [llength $args]
  if {$argCount < 1} then {
    return -code error "wrong # args: should be\n$usage"
  }

  set more {}
  set direct 1
  set doVerbose 0
  set loadPat {}
  for {set idx 0} {$idx < $argCount} {incr idx} {
    set flag [lindex $args $idx]
    switch -glob -- $flag {
      -- {
        # done with the flags
        incr idx
        break
      }
      -verbose {
        set doVerbose 1
      }
      -lazy {
        set direct 0
        append more { -lazy}
      }
      -direct {
        append more { -direct}
      }
      -load {
        incr idx
        set loadPat [lindex $args $idx]
        append more " -load $loadPat"
      }
      -* {
        return -code error "unknown flag $flag: should be\n$usage"
      }
      default {
        # done with the flags
        break
      }
    }
  }

  set dir [lindex $args $idx]
  set patternList [lrange $args [expr {$idx + 1}] end]
  if {![llength $patternList]} then {
    set patternList [list {*.tcl} "*[info sharedlibextension]"]
  }

  try {
    set fileList [glob -directory $dir -tails -types {r f} -- {*}$patternList]
  } on error {msg opt} {
    return -options $opt $msg
  }
  foreach file $fileList {
    # For each file, figure out what commands and packages it provides.
    # To do this, create a child interpreter, load the file into the
    # interpreter, and get a list of the new commands and packages that
    # are defined.

    if {$file eq {pkgIndex.tcl}} then {
      continue
    }

    set c [interp create]

    # Load into the child any packages currently loaded in the parent
    # interpreter that match the -load pattern.

    if {$loadPat ne {}} then {
      if {$doVerbose} then {
        tclLog "currently loaded packages: '[info loaded]'"
        tclLog "trying to load all packages matching $loadPat"
      }
      if {![llength [info loaded]]} then {
        tclLog "warning: no packages are currently loaded, nothing"
        tclLog "can possibly match '$loadPat'"
      }
    }
    foreach pkg [info loaded] {
      if {![string match -nocase $loadPat [lindex $pkg 1]]} then {
        continue
      }
      if {$doVerbose} then {
        tclLog "package [lindex $pkg 1] matches '$loadPat'"
      }
      try {
        load [lindex $pkg 0] [lindex $pkg 1] $c
      } on error err {
        if {$doVerbose} then {
          tclLog "warning: load [
          lindex $pkg 0] [lindex $pkg 1]\nfailed with: $err"
        }
      } on ok {} {
        if {$doVerbose} then {
          tclLog "loaded [lindex $pkg 0] [lindex $pkg 1]"
        }
      }
      if {[lindex $pkg 1] eq {Tk}} then {
        # Withdraw . if Tk was loaded, to avoid showing a window.
        $c eval [list wm withdraw .]
      }
    }

    $c eval {
      # Stub out the package command so packages can require other
      # packages.

      rename package __package_orig
      proc package {what args} {
        switch -- $what {
          require {
            return;    # Ignore transitive requires
          }
          default {
            __package_orig $what {*}$args
          }
        }
      }
      proc tclPkgUnknown args {}
      package unknown tclPkgUnknown

      # Stub out the unknown command so package can call into each other
      # during their initialilzation.

      proc unknown {args} {}

      # Stub out the auto_import mechanism

      proc auto_import {args} {}

      # reserve the ::tcl namespace for support procs and temporary
      # variables.  This might make it awkward to generate a
      # pkgIndex.tcl file for the ::tcl namespace.

      namespace eval ::tcl {
        variable dir    ;# Current directory being processed
        variable file    ;# Current file being processed
        variable direct    ;# -direct flag value
        variable x    ;# Loop variable
        variable debug    ;# For debugging
        variable type    ;# "load" or "source", for -direct
        variable namespaces  ;# Existing namespaces (e.g., ::tcl)
        variable packages  ;# Existing packages (e.g., Tcl)
        variable origCmds  ;# Existing commands
        variable newCmds  ;# Newly created commands
        variable newPkgs {}  ;# Newly created packages
      }
    }

    $c eval [list set ::tcl::dir $dir]
    $c eval [list set ::tcl::file $file]
    $c eval [list set ::tcl::direct $direct]

    # Download needed procedures into the child because we've just deleted
    # the unknown procedure.  This doesn't handle procedures with default
    # arguments.

    foreach p {::tcl::Pkg::CompareExtension} {
      $c eval [list namespace eval [namespace qualifiers $p] {}]
      $c eval [list proc $p [info args $p] [info body $p]]
    }

    try {
      $c eval {
        set ::tcl::debug {loading or sourcing}

        # we need to track command defined by each package even in the
        # -direct case, because they are needed internally by the
        # "partial pkgIndex.tcl" step above.

        proc ::tcl::GetAllNamespaces {{root ::}} {
          set list $root
          foreach ns [namespace children $root] {
            lappend list {*}[::tcl::GetAllNamespaces $ns]
          }
          return $list
        }

        # init the list of existing namespaces, packages, commands

        foreach ::tcl::x [::tcl::GetAllNamespaces] {
          set ::tcl::namespaces($::tcl::x) 1
        }
        foreach ::tcl::x [package names] {
          if {[package provide $::tcl::x] ne {}} then {
            set ::tcl::packages($::tcl::x) 1
          }
        }
        set ::tcl::origCmds [info commands]

        # Try to load the file if it has the shared library extension,
        # otherwise source it.  It's important not to try to load
        # files that aren't shared libraries, because on some systems
        # (like SunOS) the loader will abort the whole application
        # when it gets an error.

        if {
          [::tcl::Pkg::CompareExtension $::tcl::file [
            info sharedlibextension]]
        } then {
          # The "file join ." command below is necessary.  Without
          # it, if the file name has no \'s and we're on UNIX, the
          # load command will invoke the LD_LIBRARY_PATH search
          # mechanism, which could cause the wrong file to be used.

          set ::tcl::debug loading
          load [file join $::tcl::dir $::tcl::file]
          set ::tcl::type load
        } else {
          set ::tcl::debug sourcing
          source [file join $::tcl::dir $::tcl::file]
          set ::tcl::type source
        }

        # As a performance optimization, if we are creating direct
        # load packages, don't bother figuring out the set of commands
        # created by the new packages.  We only need that list for
        # setting up the autoloading used in the non-direct case.
        if {!$::tcl::direct} then {
          # See what new namespaces appeared, and import commands
          # from them.  Only exported commands go into the index.

          foreach ::tcl::x [::tcl::GetAllNamespaces] {
            if {![info exists ::tcl::namespaces($::tcl::x)]} then {
              namespace import -force ${::tcl::x}::*
            }

            # Figure out what commands appeared

            foreach ::tcl::x [info commands] {
              set ::tcl::newCmds($::tcl::x) 1
            }
            foreach ::tcl::x $::tcl::origCmds {
              unset -nocomplain ::tcl::newCmds($::tcl::x)
            }
            foreach ::tcl::x [array names ::tcl::newCmds] {
              # determine which namespace a command comes from

              set ::tcl::abs [namespace origin $::tcl::x]

              # special case so that global names have no
              # leading ::, this is required by the unknown
              # command

              set ::tcl::abs  [lindex [auto_qualify $::tcl::abs ::] 0]

              if {$::tcl::x ne $::tcl::abs} then {
                # Name changed during qualification

                set ::tcl::newCmds($::tcl::abs) 1
                unset ::tcl::newCmds($::tcl::x)
              }
            }
          }
        }

        # Look through the packages that appeared, and if there is a
        # version provided, then record it

        foreach ::tcl::x [package names] {
          if {
            [package provide $::tcl::x] ne {} &&
            ![info exists ::tcl::packages($::tcl::x)]
          } then {
            lappend ::tcl::newPkgs [
              list $::tcl::x [package provide $::tcl::x]
            ]
          }
        }
      }
    } on error msg {
      set what [$c eval set ::tcl::debug]
      if {$doVerbose} then {
        tclLog "warning: error while $what $file: $msg"
      }
    } on ok {} {
      set what [$c eval set ::tcl::debug]
      if {$doVerbose} then {
        tclLog "successful $what of $file"
      }
      set type [$c eval set ::tcl::type]
      set cmds [lsort [$c eval array names ::tcl::newCmds]]
      set pkgs [$c eval set ::tcl::newPkgs]
      if {$doVerbose} then {
        if {!$direct} then {
          tclLog "commands provided were $cmds"
        }
        tclLog "packages provided were $pkgs"
      }
      if {[llength $pkgs] > 1} then {
        tclLog "warning: \"$file\" provides more than one package ($pkgs)"
      }
      foreach pkg $pkgs {
        # cmds is empty/not used in the direct case
        lappend files($pkg) [list $file $type $cmds]
      }

      if {$doVerbose} then {
        tclLog "processed $file"
      }
    }
    interp delete $c
  }

  append index "# Tcl package index file, version 1.1\n"
  append index "# File is generated by the \"pkg_mkIndex$more\" command\n"
  append index "# and sourced either when an application starts up or\n"
  append index "# by a \"package unknown\" script.  It invokes the\n"
  append index "# \"package ifneeded\" command to set up package-related\n"
  append index "# info so that packages will be loaded automatically\n"
  append index "# in response to \"package require\" commands.  When this\n"
  append index "# script is sourced, the variable \$dir must contain the\n"
  append index "# full path name of this file's directory.\n"

  foreach pkg [lsort [array names files]] {
    set cmd {}
    lassign $pkg name version
    lappend cmd ::tcl::Pkg::Create -name $name -version $version
    foreach spec [lsort -index 0 $files($pkg)] {
      foreach {file type procs} $spec {
        if {$direct} then {
          set procs {}
        }
        lappend cmd "-$type" [list $file $procs]
      }
    }
    append index "\n[eval $cmd]"
  }

  set f [open [file join $dir pkgIndex.tcl] w]
  puts $f $index
  close $f
}

# ######################################################################

proc ::tclPkgUnknown {name args} {
  global auto_path env

  if {![info exists auto_path]} then {
    return
  }
  # Cache the auto_path, because it may change while we run through the
  # first set of pkgIndex.tcl files
  set old_path [set use_path $auto_path]
  while {[llength $use_path]} {
    set dir [lindex $use_path end]

    # Make sure we only scan each directory one time.
    if {[info exists tclSeenPath($dir)]} then {
      set use_path [lrange $use_path 0 end-1]
      continue
    }
    set tclSeenPath($dir) 1

    # Get the pkgIndex.tcl files in subdirectories of auto_path directories.
    # - Safe Base interpreters have a restricted "glob" command that
    #   works in this case.
    # - The "catch" was essential when there was no safe glob and every
    #   call in a safe interp failed; it is retained only for corner
    #   cases in which the eventual call to glob returns an error.
    catch {
      foreach file [glob -directory $dir -join -nocomplain  * pkgIndex.tcl] {
        set dir [file dirname $file]
        if {![info exists procdDirs($dir)]} then {
          try {
            source $file
          } trap {POSIX EACCES} {} {
            # $file was not readable; silently ignore
            continue
          } on error msg {
            tclLog "error reading package index file $file: $msg"
          } on ok {} {
            set procdDirs($dir) 1
          }
        }
      }
    }
    set dir [lindex $use_path end]
    if {![info exists procdDirs($dir)]} then {
      set file [file join $dir pkgIndex.tcl]
      # safe interps usually don't have "file exists",
      if {([interp issafe] || [file exists $file])} then {
        try {
          source $file
        } trap {POSIX EACCES} {} {
          # $file was not readable; silently ignore
          continue
        } on error msg {
          tclLog "error reading package index file $file: $msg"
        } on ok {} {
          set procdDirs($dir) 1
        }
      }
    }

    set use_path [lrange $use_path 0 end-1]

    # Check whether any of the index scripts we [source]d above set a new
    # value for $::auto_path.  If so, then find any new directories on the
    # $::auto_path, and lappend them to the $use_path we are working from.
    # This gives index scripts the (arguably unwise) power to expand the
    # index script search path while the search is in progress.
    set index 0
    if {[llength $old_path] == [llength $auto_path]} then {
      foreach dir $auto_path old $old_path {
        if {$dir ne $old} then {
          # This entry in $::auto_path has changed.
          break
        }
        incr index
      }
    }

    # $index now points to the first element of $auto_path that has
    # changed, or the beginning if $auto_path has changed length Scan the
    # new elements of $auto_path for directories to add to $use_path.
    # Don't add directories we've already seen, or ones already on the
    # $use_path.
    foreach dir [lrange $auto_path $index end] {
      if {![info exists tclSeenPath($dir)] && ($dir ni $use_path)} then {
        lappend use_path $dir
      }
    }
    set old_path $auto_path
  }
}


