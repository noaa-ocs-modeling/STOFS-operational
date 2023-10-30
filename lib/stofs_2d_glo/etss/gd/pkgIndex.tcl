# Tcl package index file, version 1.0
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

global tcl_platform
if {$tcl_platform(platform)=="windows"} {
  package ifneeded gd 0.1.0.3 \
    [list tclPkgSetup $dir gd 0.1.0.3 {{libgdtcl.dll load { \
         gd \
     }}}]
} else {
  package ifneeded gd 0.1.0.3 \
    [list tclPkgSetup $dir gd 0.1.0.3 {{libgdtcl.so load { \
         gd \
     }}}]
}