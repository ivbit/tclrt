

# Expample of multiplatform packaging using 'platform' package
apply {
  {package_name dir} {
    set filename $package_name[info sharedlibextension]
    set ident [platform::identify]
    set subdirs [list $ident \
      [platform::generic] \
      {*}[platform::patterns $ident]]
    foreach subdir $subdirs {
      set path [file join $dir $subdir $filename]
      if {[file exists $path]} then {
        package ifneeded $package_name 1.0 [list load $path]
        return
      }
    }
  }
} binpkg $dir


