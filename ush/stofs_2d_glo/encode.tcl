#
# This script simply reads all .txt files in verif, and
# packs them together into one file, removing redundancies.
#
# 10/23/2001 Arthur.
#

package require clock2

#-----------------------------------------------------------------------------
# This proc Reads in a text file of the format that is exported
# by the extra-tropical cron job, and stores the relavent data in the
# given ray.
#-----------------------------------------------------------------------------
proc ReadFile {ray_name file} {
  upvar #0 $ray_name ray

  set fp [open $file r]
  gets $fp line
  set header [string trim [join [lrange [split $line :] 1 end] :]]
  set ray(DateStamp) [halo_clock2 scan "[lindex $header 0] [lindex $header 1] [lindex $header 2]"]
  set Year [halo_clock2 format $ray(DateStamp) -format "%Y" -zone GMT]
  set Month [halo_clock2 format $ray(DateStamp) -format "%M" -zone GMT]
# Skip next 2 lines (comments)
  gets $fp line
  gets $fp line
  set lineNum 0
  while {[gets $fp line] >= 0} {
    if {[string index $line 0] != "#"} {
      set md [split [lindex $line 0] /]
      set month [string trimleft [lindex $md 0] 0]
      set Month [string trimleft $Month 0]
#      set month [format "%.0f" [lindex $md 0]]
#      set Month [format "%.0f" $Month]
      set deltMon [expr {$month - $Month}]
#
# Check if date is 12/29 and DateStamp 1/2/2002   : DeltMon = 11
# Also  if date is 1/1   and DateStamp 12/29/2001 : DeltMon = -11
#
      if {$deltMon > 2} {
        set year [expr {$Year - 1}]
      } elseif {$deltMon < -2} {
        set year [expr {$Year + 1}]
      } else {
        set year $Year
      }
      set day [lindex $md 1]
      set hr [string range [lindex $line 1] 0 1]
      set time [halo_clock2 scan "$month/$day/$year $hr:00:00" -zone GMT]
      if {$lineNum == 0} {
        set ray(firstTime) $time
      }
      set line [split $line ,]
      set obs [string trim [lindex $line 3]]
      set pred [string trim [lindex $line 4]]
      set anom [string trim [lindex $line 5]]
      if {$anom > 99.8} {
        set type P
      } elseif {$obs > 99.8} {
        set type F
      } else {
        set type P
      }
      if {$type == "P"} {
        set ray($lineNum) [list P [expr {($time - $ray(firstTime)) / 3600.}] \
                                  [string trim [lindex $line 1]] \
                                  [string trim [lindex $line 2]] \
                                  $obs]
      } else {
        set ray($lineNum) [list F [expr {($time - $ray(firstTime)) / 3600.}] \
                                  [string trim [lindex $line 1]] \
                                  [string trim [lindex $line 2]] \
                                  $pred]
      }
      incr lineNum
    }
  }
  close $fp
  set ray(lastLine) $lineNum
}

#-----------------------------------------------------------------------------
# This proc Creates a text files that is as close to the format generated
# by the extra-tropical cron job as possible, given the values in the given
# ray.
#-----------------------------------------------------------------------------
proc WriteFile {ray_name file} {
  upvar #0 $ray_name ray
  set fp [open $file w]
  puts $fp "#$ray(name) : [halo_clock2 format $ray(DateStamp) \
             -format "%D %T GMT" -zone GMT] (units in MLLW ft)"
  puts $fp "#Date(GMT), Surge,   Tide,    Obs,   Pred,   Anom, Comment"
  puts $fp "#------------------------------------------------------------"
  if {[string toupper [lindex $ray(0) 0]] == "F"} {
    set f_inPast 0
  } else {
    set f_inPast 1
  }
  for {set i 0} {$i < $ray(lastLine)} {incr i} {
    if {$f_inPast} {
      if {[string toupper [lindex $ray($i) 0]] != "P"} {
        puts $fp "#------------------------------------------------------------"
        puts $fp "#Date(GMT), Surge,   Tide,    Obs,   Pred,   Anom, Comment"
        puts $fp "#------------------------------------------------------------"
        set f_inPast 0
      }
    }
    set time [expr {$ray(firstTime) + ([lindex $ray($i) 1]) * 3600.}]
    set surge [lindex $ray($i) 2]
    set tide [lindex $ray($i) 3]
    set obs [lindex $ray($i) 4]
    puts -nonewline $fp "[halo_clock2 format $time -format "%m/%d %HZ" -zone GMT],"
    puts -nonewline $fp "[format "%7.2f" $surge],"
    puts -nonewline $fp "[format "%7.2f" $tide],"
    if {[string toupper [lindex $ray($i) 0]] == "P"} {
      puts -nonewline $fp "[format "%7.2f" $obs],"
      puts -nonewline $fp "[format "%7.2f" 99.9],"
    } else {
      puts -nonewline $fp "[format "%7.2f" 99.9],"
      puts -nonewline $fp "[format "%7.2f" $obs],"
    }
    if {$obs == "99.9"} {
      set anom $obs
    } else {
      set anom [expr {round (($obs - ($surge + $tide)) * 100.) / 100.}]
    }
    puts $fp "[format "%7.2f" $anom],"
  }
#  puts $fp $ray(name)
#  puts $fp $ray(DateStamp)
#  puts $fp $ray(firstTime)
#  puts $fp $ray(lastLine)
#  for {set j 0} {$j < $ray(lastLine)} {incr j} {
#    puts $fp $ray($j)
#  }
  close $fp
}

#-----------------------------------------------------------------------------
# This proc Adds a record to the archive pointed to by fp.  The file pointer
# is assumed to be opened and configured binary.  This proc just adds
# the next set of data (as determined by the passed in ray) to the already
# opened archive as determined by the
#-----------------------------------------------------------------------------
proc StoreArch {ray_name fp} {
  global tcl_platform
  upvar #0 $ray_name ray

  if {$tcl_platform(byteOrder)=="littleEndian"} {
    puts -nonewline $fp [binary format A7d1d1s1 $ray(name) \
                         $ray(DateStamp) $ray(firstTime) $ray(lastLine)]
    for {set i 0} {$i < $ray(lastLine)} {incr i} {
      puts -nonewline $fp [binary format a1c1s1s1s1 [lindex $ray($i) 0] \
            [expr {round ([lindex $ray($i) 1])}] \
            [expr {round ([lindex $ray($i) 2] * 100)}] \
            [expr {round ([lindex $ray($i) 3] * 100)}] \
            [expr {round ([lindex $ray($i) 4] * 100)}]]
    }
  }
}

#-----------------------------------------------------------------------------
# This proc Reads a record from the archive pointed to by fp.  The file
# pointer is assumed to be opened and configured binary.
#-----------------------------------------------------------------------------
proc ReadArch {ray_name fp} {
  global tcl_platform
  upvar #0 $ray_name ray

  if {$tcl_platform(byteOrder)=="littleEndian"} {
    binary scan [read $fp 25] A7d1d1s1 ray(name) ray(DateStamp) \
                                       ray(firstTime) ray(lastLine)
    for {set i 0} {$i < $ray(lastLine)} {incr i} {
      binary scan [read $fp 8] a1c1s1s1s1 type hr surge tide obs
      set ray($i) [list $type $hr [expr {$surge/100.}] \
                        [expr {$tide/100.}] [expr {$obs/100.}]]
    }
  }
}

#-----------------------------------------------------------------------------
# This proc Controls the encoding of the done directory, and can be called
# by the cron job.
#-----------------------------------------------------------------------------
proc Encode {DataDir ArchDir} {
  global ray
  set list [glob -nocomplain [file join $DataDir *.txt]]
  set list2 ""
  foreach elem $list {
    if {[string range [string tolower [file rootname [file tail $elem]]] 0 1] != "ss"} {
      lappend list2 $elem
    }
  }

  set now [halo_clock2 seconds]
  set arcFile h[halo_clock2 format $now -format "%H" -zone GMT].arc
  set arcDir a[halo_clock2 format $now -format "%y%m%d" -zone GMT]
  if {! [file isdirectory [file join $ArchDir $arcDir]]} {
    file mkdir [file join $ArchDir $arcDir]
  }
  set fp [open [file join $ArchDir $arcDir $arcFile] w]
  fconfigure $fp -translation binary
  puts -nonewline $fp [binary format s1 [llength $list2]]

  foreach file $list2 {
    catch {unset ray}
    set ray(name) [string tolower [file rootname [file tail $file]]]
    ReadFile ray $file
    StoreArch ray $fp
  }

  close $fp
}

#-----------------------------------------------------------------------------
# This proc Extracts data from the archive... It is provided so that if one
# ever uses this archived data, they have a way of reading it.
#-----------------------------------------------------------------------------
proc Extract {arch OutDir} {
  global ray
  set fp [open $arch r]
  fconfigure $fp -translation binary
  binary scan [read $fp 2] s1 numFile
  for {set i 0} {$i < $numFile} {incr i} {
    catch {unset ray}
    ReadArch ray $fp
    WriteFile ray [file join $OutDir $ray(name).txt]
  }
  close $fp
}

#
# Following was mainly for testing purposes, but could be useful in the
# future.
#
# Encode d:/cron/verif d:/cron/verif
#
# set now [halo_clock2 seconds]
# set arcFile h[halo_clock2 format $now -format "%H" -zone GMT].arc
# set arcDir a[halo_clock2 format $now -format "%y%m%d" -zone GMT]
# Extract [file join d:/cron/verif $arcDir $arcFile] d:/cron/verif/test
#
