

package ifneeded foo 2.2.2 [subst "package provide foo 2.2.2; source -encoding utf-8 [list [file join $dir foo.tcl]]"]

package ifneeded $pkgname $pkgversion \
"[::list package provide $pkgname $pkgversion];[::list source -encoding utf-8 $file]"


