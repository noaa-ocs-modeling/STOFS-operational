#!/usr/bin/tclsh

#!/mdlsurge/save/bin/tclsh

#-----------------------------------------------------------------------------
# cron.tcl --
#     This program generates a graph which combines the extra-tropical storm
#   surge with a computed tide, and observations (where available) to create
#   an estimate of the total water level.
#     It then attempts to ftp the resulting graph, associated text file,
#   and color coded map to www.nws.noaa.gov/mdl/etsurge.
#
# 10/2000 Arthur Taylor (RSIS/MDL) Created
#  5/2002 Arthur Taylor (RSIS/MDL) Updated
#
# Notes:
#-----------------------------------------------------------------------------
# Global variables:
#   RAY1(...)
#     tl          : Toplevel to use when using cronshow.tcl
#     graph       : Name of main graph to pass to graph widget
#     gd_file     : File to save the graph to.
#     gd_filetype : Filetype of gd_file.
#     im          : The main current opened gd image.
#     statusList  : The stations for which I have calculated the status.
#                   Usually all stations...
#     Backup,list : The files for which we updated the Storm Surge...
#                   hence we need to "backup" these files on the web server.
#     got_surge   : Flag to say if we downloaded the surge files from the IBM
#
#     Wid         : The Width of the main gd image
#     Hei         : The Height of the main gd image
#     Beg_Time    : Start time of data
#     End_Time    : Stop time of data
#     Num_Hours   : Total hours of data ((end+beg)*24 +1)
#     <hr>        : is hours after Beg_Time.
#     (<hr>,surge): 99.9 or surge
#     (<hr>,tide): tide
#     (<hr>,obs): observation
#     (<hr>,anom): anom (obs-(surge+tide))
#     (<hr>,pred): surge+tide+anom
#
#     surge       : List of (time surge) pairs
#     tide_surge  : List of (time (surge+tide)) pairs
#     tide        : List of (time tide) pairs
#     obs         : List of (time obs) pairs
#     anom        : List of (time (obs-(surge+tide)) pairs
#     pred        : List of (time (surge+tide+anom))
#     now         : Time the program was sourced.
#     min_time    : Minimum Time to plot
#     max_time    : Maximum Time to plot
#   src_dir     : Path of the source directory.
#   CronShow    : 0 if no cronshow.tcl, 1 if cronshow.tcl
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Set-Up Packages and source helper files...
#-----------------------------------------------------------------------------
set cur_dir [file dirname [info script]]
set src_dir [file dirname [info script]]
#if {[file pathtype $src_dir] != "absolute"} {
#  set cur_dir [pwd] ;  cd $src_dir
#  set src_dir [pwd] ;  cd $cur_dir
#}
set cur_dir $::env(HOMEstofs); cd $src_dir
set src_dir $::env(DATA); cd $src_dir

# might not need this path but it is nice to include it 
#set auto_path [linsert $auto_path 0 ${src_dir}/lib]
set auto_path [linsert $auto_path 0 ${cur_dir}/lib/etss]

package require clock2
halo_clock2 seconds

foreach script [list ftp_lib.tcl getdata.tcl archive.tcl] {
#  set file [file join $src_dir tclsrc $script]
  set file [file join $cur_dir ush stofs_2d_glo $script]
  if {! [file exists $file]} {
    puts "Couldn't find required file '$file'"
    exit
  }
  source $file
}

#########################################################################

proc Init_Time {ray_name days_before days_after} {
  upvar #0 $ray_name ray
  set ray(begTime) [expr $ray(cur) - $days_before*24*3600.]
  set ray(endTime) [expr $ray(cur) + $days_after*24*3600.]
  set ray(numHours) [expr ($days_after + $days_before) * 24 +1]
  for {set i 0} {$i < $ray(numHours)} {incr i} {
    set cur [expr $ray(begTime) + $i * 3600.]
    set tm_hr [expr int (($cur- $ray(begTime)) / 3600.)]
    set ray($tm_hr,surge) 99.9
    set ray($tm_hr,obs) 99.9
  }
}


#*******************************************************************************
# Procedure Read_StormSurge
#
# Purpose:
#     Read a storm surge file looking for a particular station.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   file       (I) The storm surge file in question.
#   name       (I) Name of the station.
#   month      (I) The month the storm surge file is valid for
#   year       (I) The year the storm surge file is valid for
#
# Returns: -1 if it didn't find the station.
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Adjusts ray(surge)
#*******************************************************************************
proc Read_StormSurge {ray_name arch_file file month year name temp_file} {
  upvar #0 $ray_name ray

  set last_time [Read_ArchSurge $ray_name $arch_file]

  set fp [open $file r]
  gets $fp line
  set day  [string range [lindex $line 2] 0 1]
  set hour [string range [lindex $line 2] 2 3]
  set time [format "%.1f" [halo_clock2 scan "$month/$day/$year $hour:00:00" -gmt true]]

  # If the following is true, then we need to Update the Archive file.
  # else we are done.


  if {$time > $last_time} {

    lappend ray(Backup,list) [file tail [file rootname $arch_file]]

    set name [string tolower $name]

    # Remove , before STATE
    set name2 [string trim $name]
    set len [string length $name2]
    set name2 "[string range $name 0 [expr $len -5]][string range $name [expr $len -3] end]"

    while {[gets $fp line] >= 0} {
      set lower [string tolower $line]
      if {[string first $name2 $lower] != -1} {
        set ss [string range $line 69 71]
        if {$ss == "***"} {
          set ss 99.9
        } else { 
          set ss [expr $ss / 10.]
        }
        set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
        set ray($tm_hr,surge) $ss

    # For storage in New ArchSurge
        set date [halo_clock2 format $time -format "%m/%d/%Y %H" -gmt true]
#        set line1 "[string range $line 0 52]$date[string range $line 66 end]"
        set line1 " \"[string toupper $name]\"[string range $line [expr 3 + [string length $name]] 52]$date[string range $line 66 end]"

        gets $fp line
    # For storage in New ArchSurge
        set line2 $line
        for {set i 1} {$i <= 24} {incr i} {
          set ss [string range $line [expr -3 + 3*$i] [expr -1 + 3*$i]]
          if {$ss == "***"} {
            set ss 99.9
          } else {
            set ss [expr $ss / 10.]
          }
          set tm [expr $time + $i * 3600.]
          set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
          set ray($tm_hr,surge) $ss
        }

        gets $fp line
    # For storage in New ArchSurge
        set line3 $line
        for {set i 1} {$i <= 24} {incr i} {
          set ss [string range $line [expr -3 + 3*$i] [expr -1 + 3*$i]]
          if {$ss == "***"} {
            set ss 99.9
          } else {
            set ss [expr $ss / 10.]
          }
          set tm [expr $time + $i * 3600. + 86400.]
          set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
          set ray($tm_hr,surge) $ss
        }

        gets $fp line
        set line4 $line
        for {set i 1} {$i <= 24} {incr i} {
          set ss [string range $line [expr -3 + 3*$i] [expr -1 + 3*$i]]
          if {$ss == "***"} {
            set ss 99.9
          } else {
            set ss [expr $ss / 10.]
          }
          set tm [expr $time + $i * 3600. + 2 * 86400.]
          set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
          set ray($tm_hr,surge) $ss
        }

        gets $fp line
        set line5 $line
        for {set i 1} {$i <= 24} {incr i} {
          set ss [string range $line [expr -3 + 3*$i] [expr -1 + 3*$i]]
          if {$ss == "***"} {
            set ss 99.9
          } else {
            set ss [expr $ss / 10.]
          }
          set tm [expr $time + $i * 3600. + 3 * 86400.]
          set tm_hr [expr int (($tm - $ray(begTime)) / 3600.)]
          set ray($tm_hr,surge) $ss
        }

        Write_ArchSurge $ray_name $arch_file $line1 $line2 $line3 $line4 $line5 $temp_file
        close $fp
        return 0
      }
    }
    puts "Didn't find $name"
    close $fp
    return -1

  } else {
    close $fp
    return 0
  }
}

#*******************************************************************************
# Procedure Strip_Line
#
# Purpose:
#     Strips a line from an html document, saving only the data that is
#   in a <pre> ... </pre> block
#
# Variables:(I=input)(O=output)
#   fp2        (I) open file pointer to a file to send the results to.
#   line       (I) current line we are working on.
#   f_pre      (I) (1/0) if in or out of <pre> block (0 not in, 1 in)
#
# Returns: f_pre (1/0) if in or out of <pre> block
#
# History:
#    10/2000 Arthur Taylor created
#*******************************************************************************
proc Strip_Line {fp2 line f_pre} {
  set lower [string tolower $line]
  if {$f_pre == 0} {
    set index [string first <pre> $lower]
    if {$index != -1} {
      incr index 5
      set line [string range $line $index end]
if {[string index $line 0] == "<"} {
  set ans [string first > $line]
  if {$ans != -1} {
    incr ans 1
    set line [string range $line $ans end]
  }
}
      set f_pre 1
      return [Strip_Line $fp2 $line $f_pre]
    } else {
      return $f_pre
    }
  } else {
    set index [string first </pre> $lower]
    if {$index != -1} {
      set line2 [string range $line 0 [expr $index -1]]
      puts $fp2 $line2
      incr index 6
      set line [string range $line $index end]
      set f_pre 0
      return [Strip_Line $fp2 $line $f_pre]
    } else {
      puts $fp2 $line
      return $f_pre
    }
  }
}

#*******************************************************************************
# Procedure Strip_Html
#
# Purpose:
#     Sends an html document through Strip_Line generating a second file
#   that contains only the data that is in a <pre> ... </pre> block. (allows
#   multiple <pre> blocks (and <pre> doesn't have to start the line).
#
# Variables:(I=input)(O=output)
#   file1      (I) file to read from.
#   file2      (I) file to write to.
#
# Returns:
#
# History:
#    10/2000 Arthur Taylor created
#*******************************************************************************
proc Strip_Html {file1 file2} {
  set f_pre 0
  set fp [open $file1 r]
  set fp2 [open $file2 w]
  while {[gets $fp line] >= 0} {
    set f_pre [Strip_Line $fp2 $line $f_pre]
  }
  close $fp2
  close $fp
}

#*******************************************************************************
# Procedure Read_ObsFile
#
# Purpose:
#     Read a file that contains a stations observations, for tide values,
#   and observation values.  (File was obtained by downloading it as a html
#   document, and stripping out stuff outside of <pre></pre> blocks.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   obsFile    (I) The file to read the observations from.
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Adjusts ray(obs)
#*******************************************************************************
proc Read_ObsFile {ray_name obsFile archFile temp_file days_before mllw msl} {
  upvar #0 $ray_name ray

  set ap [open $temp_file w]
  puts $ap "Header line must be in .obs file"
  # The 0 is so we leave the observations in MLLW.
  set last_time [Read_ArchObs $ray_name $archFile $ap 0]

# Read in the observations.
  if {$obsFile == "NULL"} {
    close $ap
    return
  }
  set fp [open $obsFile r]
  gets $fp line
  set unknown ""
  set first_time -1
  while {[gets $fp line] >= 0} {
    set dateTime [lindex [split $line ,] 0]
    set date [split [lindex $dateTime 0] -]
    set date [join [list [lindex $date 1] [lindex $date 2] [lindex $date 0]] /]
    if {! [catch {halo_clock2 scan "$date [lindex $dateTime 1]:00 GMT"} time]} {
      set time [format "%.1f" $time]
      set cur_MinSec [halo_clock2 format $time -format "%M%S"]
      if {$cur_MinSec == "0000"} {
        set obs [lindex [split $line ,] 1]
        set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
        if {$first_time == -1} {
          set first_time $time   
        }
        if {($obs < 99) && ($obs > -99)} {
          set ray($tm_hr,obs) $obs
        } else {
          set ray($tm_hr,obs) 99.9
          lappend unknown $tm_hr
        }
      } elseif {$cur_MinSec == "0600"} {
        set time [expr $time - 6*60.]
        set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
        set obs [lindex [split $line ,] 1]
        if {($obs < 99) && ($obs > -99)} {
          set unknownRay($tm_hr,2) $obs
        } else {
          set unknownRay($tm_hr,2) 99.9
        }
      } elseif {$cur_MinSec == "5400"} {
        set time [expr $time + 6*60.]
        set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
        set obs [lindex [split $line ,] 1]
        if {($obs < 99) && ($obs > -99)} {
          set unknownRay($tm_hr,3) $obs
        } else {
          set unknownRay($tm_hr,3) 99.9
        }
      }
    }
  }


##  while {[gets $fp line] >= 0} {
##    set line [string trim $line]
### Changed following from 81 to 88 on 7/8/2005 due to tides online adding a
### column (humidity).  Reason for 81 or 88 is if file becomes corrupt.
### Decided to go with 100.
##    if {([string length $line] < 100) && ([llength $line] > 10)} {
##      set nameZone [lindex $line 2]
##      set nameZoneLength [string length $nameZone] 
##      if {$nameZone == "AKST"} {
##        set zone YST
##      } elseif {$nameZone == "AKDT"} {
##        set zone YDT
##      } elseif {$nameZoneLength == 4} {
##        set zone "[string range [string toupper [lindex $line 2]] 1 2]T"
##      } else {
##        set zone "[string range [string toupper [lindex $line 2]] 0 1]T"
##      }
##      if {! [catch {halo_clock2 scan "[lindex $line 0] [lindex $line 1] $zone"} time]} {
##        set time [format "%.1f" $time]
##        set cur_MinSec [halo_clock2 format $time -format "%M%S" -gmt true]
##        if {$cur_MinSec == "0000"} {
##          set obs [string range $line 31 37] ;# Not [lindex $line 4] because of -5.71-10.60 case
##          set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
##          if {$first_time == -1} {
##            set first_time $time
##          }
##          if {($obs < 99) && ($obs > -99)} {
##            set ray($tm_hr,obs) $obs
##          } else {
##            set ray($tm_hr,obs) 99.9
##            lappend unknown $tm_hr
##          }
##        } elseif {$cur_MinSec == "0600"} {
##          set time [expr $time - 6*60.]
##          set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
##          set obs [string range $line 31 37] ;# Not [lindex $line 4] because of -5.71-10.60 case
##          if {($obs < 99) && ($obs > -99)} {
##            set unknownRay($tm_hr,2) $obs
##          } else {
##            set unknownRay($tm_hr,2) 99.9
##          }
##        } elseif {$cur_MinSec == "5400"} {
##          set time [expr $time + 6*60.]
##          set tm_hr [expr int (($time - $ray(begTime)) / 3600.)]
##          set obs [string range $line 31 37] ;# Not [lindex $line 4] because of -5.71-10.60 case
##          if {($obs < 99) && ($obs > -99)} {
##            set unknownRay($tm_hr,3) $obs
##          } else {
##            set unknownRay($tm_hr,3) 99.9
##          }
##        }
##      }
##    }
##  }
  foreach tm_hr $unknown {
    if {[info exists unknownRay($tm_hr,2)] && [info exists unknownRay($tm_hr,3)]} {
      if {($unknownRay($tm_hr,2) != 99.9) && ($unknownRay($tm_hr,3) != 99.9)} {
        set ray($tm_hr,obs) [expr ($unknownRay($tm_hr,2) + $unknownRay($tm_hr,3)) / 2.]
      }
    }
  }
  catch {unset unknownRay}
  close $fp
#Store the new observations.
  if {$last_time == -1} {
    if {$first_time != -1} {
      # First time might not be on the 00 hour
      set first_time [halo_clock2 scan "[halo_clock2 format $first_time -format "%D" -gmt true] 00" -gmt true]
      set last_time [expr $first_time - 3600]
    }
  }

  if {$last_time != -1} {
    Write_ArchObs $ray_name $ap $last_time
  }
  close $ap
  file copy -force $temp_file $archFile
  file delete $temp_file
}

proc Refresh {ray_name surge_stn obs_stn tide_stn surge_file surge_flag title \
              arch_surge temp_file temp2_file days_before arch_obs display_days \
              mllw msl mhhw zone mat filt_anom} {
  global src_dir
  upvar #0 $ray_name ray

  if {$surge_flag == 1} {
    if {$ray(got_surge) == 0} {
      puts "Getting Anonymous Surge2"
      if {[Get_Anonymous_Surge2 $ray_name] != 1} {
        Log "had problems getting EtSurge data"
        puts "had problems getting EtSurge data"
      }
      set ray(got_surge) 1
      update
      Log "Got data EtSurge"
    }
    if {! [info exists ray(cur)]} {
      puts "reading surge file"
      set fp [open [file join $src_dir model $surge_file] r]
      gets $fp line
      close $fp

      set day  [string range [lindex $line 2] 0 1]
      set hour [string range [lindex $line 2] 2 3]
      puts "Hour: $hour :Day :$day"
      # Start at current time, and go backward in 24 hour steps until day/hour
      # match day/hour from storm surge file.
      set cur $ray(now)
      set cur_day [halo_clock2 format $cur -format "%d" -gmt true]

      while {$cur_day != $day} {
        set cur [expr $cur - 86400.0]
        set cur_day [halo_clock2 format $cur -format "%d" -gmt true]
      }
      set temp [halo_clock2 format $cur -format "%D" -gmt true]
      set ray(cur) [halo_clock2 scan "$temp $hour:00" -gmt true]
    }
  } 
  # Init Beg_time/End_time, and init ray elements to 99.9
  Init_Time $ray_name $days_before 4

  set ray(min_time) ""
  set ray(max_time) ""

  # Need month year..
  set month [halo_clock2 format $ray(cur) -format "%m" -gmt true]
  set year [halo_clock2 format $ray(cur) -format "%Y" -gmt true]
  Read_StormSurge $ray_name $arch_surge [file join $src_dir model $surge_file] $month $year $surge_stn $temp_file

  Log "Have Read surge.. Get obs?"

  if {($obs_stn != "") && ([string index $obs_stn 0] != "?")} {
    set obs_stn ""
  }
  if {$obs_stn != ""} {
#    set ans [http::copy "http://tidesonline.nos.noaa.gov/data_read.shtml$obs_stn" $temp_file 0 20480]
#    catch {exec wget --no-check-certificate "http://tidesonline.nos.noaa.gov/data_read.shtml$obs_stn" -O foo}
    set startDate [clock format [expr [clock seconds] - 5*24*3600] -format "%Y%m%d %H:%M"]
    set endDate [clock format [clock seconds] -format "%Y%m%d %H:%M"]
    set stn [lindex [split [lindex [split $obs_stn =] 1] +] 0]
    #catch {exec wget --no-check-certificate "https://tidesandcurrents.noaa.gov/api/datagetter?product=water_level&application=NOS.COOPS.TAC.WL&begin_date=$startDate&end_date=$endDate&datum=MLLW&station=$stn&time_zone=gmt&units=english&interval=&format=csv" -O $temp_file}
#   copy obs from dcom
    file copy -force $src_dir/database/$stn.csv $temp_file

    set ans 0
    update
  }
  Log "Got obs"
  if {($obs_stn != "") && ([file size $temp_file] > 10000)} {
    #
    # Problem1: HTML code has 2 pre only one /pre
    # Problem2: The number of char on a line can increase without warning.
    #
#    Strip_Html $temp_file $temp2_file
#    update
#    Strip_Html $temp2_file $temp_file
#    update
    Read_ObsFile $ray_name $temp_file $arch_obs $temp2_file $days_before $mllw $msl
  } else {
    Read_ObsFile $ray_name NULL $arch_obs $temp_file $days_before $mllw $msl
  }
  update
}

proc Log {msg} {
  global src_dir
  set fp [open [file join $src_dir log database.log] "a"]
  puts -nonewline $fp [halo_clock2 format [halo_clock2 seconds] -format "%D %T" -gmt false]
  puts $fp ": $msg"
  close $fp
}

proc Main_Init {ray_name} {
  global src_dir
  upvar #0 $ray_name ray

  set ray(txt_file) [file join $src_dir default.txt]
  set ray(Backup,list) ""
  set ray(got_surge) 0
}

proc Main {ray_name} {
  global src_dir
  upvar #0 $ray_name ray

  set ray(now) [halo_clock2 seconds]

  Log "Starting [clock clicks]"
  Main_Init $ray_name

  set fp [open [file join $src_dir data cron.bnt] r]
  gets $fp line
  set txtlist ""
  while {[gets $fp line] > 0} {
    puts "Starting line $line"
    set line [split $line :]
    if {[string index [string trim [lindex $line 0]] 0] != "#"} {
      Log "Working with $line"
      set ray(txt_file) [file join $src_dir model [lindex $line 1].txt]
      set ray(cur_abrev) [lindex $line 1]
      set zone [lindex $line 16]
      if {("[halo_clock2 IsDaylightSaving $ray(now) -inZone $zone]" == 1) && ($zone != "HST")} {
        set zone "[string index $zone 0]DT"
      }
      set mllw [lindex $line 12]
      set msl [lindex $line 13]
      set mhhw [lindex $line 14]
      set mat [lindex [split [lindex $line 17] #] 0]
      set filt_anom [lindex $line 18]
      Refresh $ray_name [lindex $line 2] [lindex $line 3] [lindex $line 4] \
            [lindex $line 5] [lindex $line 6] [lindex $line 7] \
            [file join $src_dir database [lindex $line 1].ss] \
            [file join $src_dir temp.txt] \
            [file join $src_dir temp2.txt] 5 \
            [file join $src_dir database [lindex $line 1].obs] \
            1.5 $mllw $msl $mhhw $zone $mat $filt_anom
      update   ;# so it is in the background.

      lappend txtlist [lindex $line 1].txt
    }
  }
  close $fp
  puts "" 
  return
}

#-----------------------------------------------------------------------------
# Done with Procs, start program.
#-----------------------------------------------------------------------------

set ray_name RAY1
catch {unset $ray_name}

Main $ray_name
