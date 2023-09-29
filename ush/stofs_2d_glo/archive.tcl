# file modified 03/2010 AWK to reflect removal of CRON in calling program
proc Read_ArchSurge {ray_name arch_file} {
  upvar #0 $ray_name ray

  set last_time -1
  if {[file exists $arch_file]} {
    set start $ray(begTime)
    set fp [open $arch_file r]
    while {[gets $fp line] > 0} {
      set time [format "%.1f" [halo_clock2 scan "[string range $line 53 65]:00" -gmt true]]
      if {(($time >= $start) && ($time <= $ray(cur)))} {
        set last_time $time
        set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
        set ss [string range $line 69 71]
        if {$ss == "***"} {
          set ss 99.9
        } else {
          set ss [expr $ss / 10.]
        }              
        set ray($tm_hr,surge) $ss 
        if {[string length $line] == 216} {
           # It is a 48 hour forecast
           for {set i 1} {$i <= 48} {incr i} {
              set ss string range $line [expr 72 + -3 + 3*$i] [expr 72 + -1 + 3*$i]]
              if {$ss == "***"} {
                 set ss 99.9
              } else {
                 set ss [expr $ss / 10.]
              }              
              set tm [expr $time + $i * 3600.]
              set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
              set ray($tm_hr,surge) $ss
           }
        } elseif {[string length $line] == 360} {
           # It is a 96 hour forecast
           for {set i 1} {$i <= 96} {incr i} {
              set ss [string range $line [expr 72 + -3 + 3*$i] [expr 72 + -1 + 3*$i]]
              if {$ss == "***"} {
                 set ss 99.9
              } else {
                 set ss [expr $ss / 10.]
              }              
              set tm [expr $time + $i * 3600.]
              set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
              set ray($tm_hr,surge) $ss
           }
        } else {
           puts "Unrecognized forecast length"
        }

#        gets $fp line
#        for {set i 1} {$i <= 24} {incr i} {
#          set ss [expr [string range $line [expr -3 + 3*$i] [expr -1 + 3*$i]] / 10.]
#          set tm [expr $time + $i * 3600.]
#          set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
#          set ray($tm_hr,surge) $ss
#        }
#        gets $fp line
#        for {set i 1} {$i <= 24} {incr i} {
#          set ss [expr [string range $line [expr -3 + 3*$i] [expr -1 + 3*$i]] / 10.]
#          set tm [expr $time + $i * 3600. + 86400.]
#          set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
#          set ray($tm_hr,surge) $ss
#        }
      } else {
#        gets $fp line
#        gets $fp line
      }
    }
    close $fp
  }
  return $last_time
}

proc Write_ArchSurge {ray_name arch_file line1 line2 line3 line4 line5 temp_file} {
  #
  # Note: open with "a" starts after a norton-editor End-of-file
  #   use dos-edit to view what is actually going on.
  #   dos-edit allows one to get rid of End-of-file char.
  #
  set fp [open $arch_file a]
#  puts $fp $line1
#  puts $fp $line2
#  puts $fp $line3
  puts $fp "$line1$line2$line3$line4$line5"
  close $fp
}

# Read in old Archived Observations.
# Store Observations that are earlier than the day of start in ap, close archFile.
proc Read_ArchObs {ray_name archFile ap adjust} {
  upvar #0 $ray_name ray

  set start $ray(begTime)
  set last_time -1
  if {[file exists $archFile]} {
    set fp [open $archFile r]
    set valid 0
    set reRead 0

    # Skip header line.
    gets $fp line
    while {[gets $fp line] >= 0} {
      if {[llength $line] != 25} { continue }
      set time [format "%.1f" [halo_clock2 scan [lindex $line 0] -gmt true]]
      for {set i 1} {$i <= 24} {incr i} {
        if {[lindex $line $i] != ""} {
          set tm [expr $time + ($i -1) * 3600.]
          if {$tm >= $start} {
            set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
            set ray($tm_hr,obs) [expr [lindex $line $i] + $adjust]
            if {$valid == 0} {
              set reRead 1
              set valid 1
            }
          }
        }
      }
      # This is so that the first part of the line is stored in memory.
      if {$reRead == 1} {
        for {set i 1} {$i <= 24} {incr i} {
          if {[lindex $line $i] != ""} {
            set tm [expr $time + ($i -1) * 3600.]
            set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
            set ray($tm_hr,obs) [expr [lindex $line $i] + $adjust]
          }
        }
      }
      # Store it in the ap file.
      if {$valid == 0} {
        # make sure line is long enough...
        while {[llength $line] < 25} {
          lappend line [format "%6.2f" 99.9]
        }
        # Write line.
        puts -nonewline $ap "[lindex $line 0] "
        for {set i 1} {$i <= 24} {incr i} {
          puts -nonewline $ap "[format "%6.2f" [lindex $line $i]] "
        }
        puts $ap ""
        # Done Write line.
        set last_time [expr $time + 23 * 3600.]
      }
    }
    close $fp
  }
  return $last_time
}

proc Write_ArchObs {ray_name ap last_time} {
  upvar #0 $ray_name ray

  set time [expr $last_time + 3600.]
  while {$time <= $ray(now)} {
# Create line
    set date [halo_clock2 format $time -format "%D" -gmt true]
    set line ""
    lappend line $date
    for {set i 0} {$i < 24} {incr i} {

      set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
      if {$time <= $ray(now) && [info exists ray($tm_hr,obs)]} {
        if {[catch {format "%6.2f" $ray($tm_hr,obs)} ans]} {
          set ans [format "%6.2f" 99.9]
        }
        lappend line $ans
      } else {
        lappend line [format "%6.2f" 99.9]
      }
      set time [expr $time + 3600.]
    }
# Write line.
    puts -nonewline $ap "[lindex $line 0] "
    for {set i 1} {$i <= 24} {incr i} {
      puts -nonewline $ap "[format "%6.2f" [lindex $line $i]] "
    }
    puts $ap ""
  }
}
