#!/usr/bin/tclsh

#!/mdlsurge/save/bin/tclsh
#-----------------------------------------------------------------------------
# post_etsurge_linux.tcl --
#     This program generates a graph which combines the extra-tropical storm
#   surge with a computed tide, and observations (where available) to create
#   an estimate of the total water level.  It also creates a text file of the
#   same results, and can create status maps for a particular region and date.
#   The observation file archive and the surge archive are updated by seperate
#   code.
#
# 10/2000 Arthur Taylor (RSIS/MDL) Created
#  5/2002 Arthur Taylor (RSIS/MDL) Updated
# 01/2010 Anne W Kramer (Wyle IS) Updated
#
# Notes:
#-----------------------------------------------------------------------------
# Global variables:
#   RAY1(...)   : Variable that holds all data for calculations & output.
#     graph       : Name of main graph to pass to graph widget
#     gdFile      : File to save the graph to.
#     gdFiletype  : Filetype of gdFile.
#     im          : The main current opened gd image.
#     statusList  : The stations for which status is calculated, usually all.
#     txtFile     : Filname of output text file.
#     curAbrev    : Abbreviation for name of current station.
#     Wid         : The Width of the main gd image.
#     Hei         : The Height of the main gd image.
#     begTime     : Start time of data.
#     endTime     : Stop time of data.
#     numHours    : Total hours of data ((end+beg)*24 +1)
#     <hr>        : is hours after begTime.
#     (<hr>,surge): 99.9 or surge.
#     (<hr>,tide) : 99.9 or tide.
#     (<hr>,obs)  : 99.9 or observation.
#     (<hr>,anom) : 99.9 or anom (obs-(surge+tide)).
#     (<hr>,pred) : 99.9 or surge+tide+anom.
#     <stn>       : Station identifier.
#     <tm_pd>     : Time period in hours for status calculation.
#     (<stn>,status<tm_pd>)
#                 : Status (red, yellow, or green) for <stn> and <tm_pd>.
#     anomList    : List of average anomaly paired with station abbreviation.
#     numDays     : Number of days before date given to add results to graph.
#     now         : Date/time passed to the program.
#     cur         : Truncated day & hour for beginning of graph.
#     fcastDelay  : Hours of delay time for forecast.
#     fSurge      : 1 - include surge on graph (default), 0 - do not include.
#     fTide       : 1 - include tide on graph (default), 0 - do not include.
#     fObs        : 1 - include obs. on graph (default), 0 - do not include.
#     fAnom       : 1 - include anomaly on graph (default), 0 - do not include.
#     doAll       : 1 - calculate for all stations, 0 - do not (default).
#     fStat       : 1 - produce status map, 0 - do not, set by user(fMap).
#   
#   user(...)   : Variable that holds all command line input results.
#     mapRegion   : 2 letter abbreviation for status map region.
#     mapCorner   : 2 letter designation for corner of status map for legend.
#     mapIndex    : number for status map region.
#     fMap        : 1 - produce status map, 0 do not (default).
#     output      : 0,3 - graph & text (default), 1 - text only, 2 - graph only.
#     date        : date/time passed to program, default 01/01/2009 00:00:00.
#     stationList : station passed to program, default Bar Harbor, ME.
#     log         : 0 - no log messages (default), 1 - log messages to stdout.
#     
#   src_dir     : Path of the source directory.
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
set cur_dir $::env(HOMEstofs)
set src_dir $::env(DATA); cd $src_dir

# telling where to find packages
#set auto_path [linsert $auto_path 0 ${src_dir}/lib]
set auto_path [linsert $auto_path 0 ${cur_dir}/lib/etss]

# package for halo_clock2
package require clock2

# need to make sure clock2 is loaded
halo_clock2 seconds

# package for graphing capability
package require gd

# package for further graphing capability
package require graph

# package for TideC_stn, used in Get_Tide
package require tide

#set file [file join $src_dir tclsrc archive.tcl]
set file [file join $cur_dir ush stofs_2d_glo archive.tcl]
if {! [file exists $file]} {
  puts "Couldn't find required file '$file'"
  exit
}
source $file

# ------------------------------------------------------------------------------
#  Parsing Command Line Input Arguments
# ------------------------------------------------------------------------------
set user(mapRegion) 0
set user(mapCorner) 0
set user(mapIndex) 0
set user(fMap) 0
set user(output) 0
#set user(date) [halo_clock2 scan "01/01/2009 00:00:00" -gmt true]
#set user(date) [halo_clock2 scan [clock format [clock seconds] -format %D] -gmt true]
set user(date) [halo_clock2 seconds]
set user(now) 0
set user(allStations) 0
#set user(stationList) 2
set user(stationList) ""
set user(log) 0
set user(dateRange) 0
#set user(dateStart) [halo_clock2 scan "01/01/2009 00:00:00" -gmt true]
set user(dateStart) $user(date)
#set user(dateEnd) [halo_clock2 scan "01/01/2009 06:00:00" -gmt true]
set user(dateEnd) [expr $user(dateStart) + 6 * 3600]
set user(f_datum) msl

proc Usage {} {
  global argv0

  puts "NAME"
  puts "     $argv0 - reproduce surge forecast station graphs and text file,
     along with status maps, for a particular date and time\n"
  puts "SYNOPSIS"
  puts "     $argv0 -{option} {input}\n"
  puts "REQUIRES"
  puts "     -s {choice} or -all\n"
  puts "DESCRIPTION"
  puts "     Post_etsurge_linux is designed to reproduce old results from the
     etsurge product.  These results are either station graphs and/or text
     files, or status maps for a region.  The station graphs and text files
     combine the extra-tropical storm surge with a computed tide and 
     observations (if available) to create an estimate of total water level.  
     The status maps are a visual representation of when the total water level
     for a station will reach certain thresholds.  Graph and text output is
     saved in the <datum>/plots/ directory, while the status maps are in the 
     <datum>/maps/ directory.\n"
  puts "     -a, --all            do all stations and all maps."
  puts "     -s, --station '{choice}'"
  puts "          choice for station, can be station index number, station
          abbreviation, or the city, state of the station."
  puts "     -m, --map {region}"
  puts "          create status map for region, no default"
  puts "          region:\n               ne - Northern East Coast
               me - Middle East Coast\n               se - Southern East Coast
               gf - Gulf of Mexico\n               wc - West Coast
               ak - Alaska, West and North\n               ga - Gulf of Alaska"
  puts "" 
  puts "     -d, --date 'MM/DD/YYYY HH:MM:SS'  choice for date (GMT)"
  puts "     -n, --now            use the current time"
  puts "          DEFAULT is for date = NOW, but --now option handles daylight
          savings better."
  puts "" 
  puts "     -g, --graph          include station graph output"
  puts "     -t, --text           include station text output"
  puts "           DEFAULT is for both -g and -t\n"
  puts "     -w, --datum 'mllw,msl,hat'     choice for datum (def=msl)"
  puts "     -l, --log            output log messages to stdout"
  puts "\nVERSION HISTORY\n     Arthur Taylor (RSIS/MDL) 10/2000"
  puts "     Arthur Taylor (RSIS/MDL) Updated 05/2002"
  puts "     Anne Kramer (Wyle/MDL) Updated 01/2010"
  exit
}

if {$argc == 0} {
  Usage
}
for {set i 0} {$i < [llength $argv]} {incr i} {
  set arg [lindex $argv $i]
  if {[string index $arg 0] == "-"} {
    if {($arg == "--help") || ($arg == "-help") || ($arg == "--version") || 
        ($arg == "-V")} {
      Usage
    } elseif {($arg == "--map") || ($arg == "-m")} {
      set user(fMap) 1
      incr i
      set arg [lindex $argv $i]
      set user(mapRegion) $arg
      if {$arg == "ne"} {
        set user(stationList) 1
        set user(mapIndex) 1
        set user(mapCorner) "TL"
      } elseif {$arg == "me"} {
        set user(stationList) 25
        set user(mapIndex) 2
        set user(mapCorner) "BL"
      } elseif {$arg == "se"} {
        set user(stationList) 40
        set user(mapIndex) 3
        set user(mapCorner) "TL"
      } elseif {$arg == "gf"} {
        set user(stationList) 49
        set user(mapIndex) 4
        set user(mapCorner) "BL"
      } elseif {$arg == "wc"} {
        set user(stationList) 64
        set user(mapIndex) 5
        set user(mapCorner) "BL"
      } elseif {$arg == "ak"} {
        set user(stationList) 82
        set user(mapIndex) 6
        set user(mapCorner) "BR"
      } elseif {$arg == "ga"} {
        set user(stationList) 125
        set user(mapIndex) 7
        set user(mapCorner) "TR"
      } else {
        puts "\n*** Status map needs to be entered correctly, please input 
              one of the following after the --map or -m call:"
        puts "\nne - Northern East Coast\nme - Middle East Coast"
        puts "se - Southern East Coast\ngf - Gulf of Mexico"
        puts "wc - West Coast\nak - Alaska, West and North"
        puts "ga - Gulf of Alaska\n\n"
        return
      }
    } elseif {($arg == "--graph") || ($arg == "-g")} {
      if {$user(output) == 0} {set user(output) 2
      } elseif {$user(output) == 1} {set user(output) 3}
      puts "Graphical output included"
    } elseif {($arg == "--text") || ($arg == "-t")} {
      if {$user(output) == 0} {set user(output) 1
      } elseif {$user(output) == 2} {set user(output) 3}
      puts "Textual output included"
    } elseif {($arg == "--datum") || ($arg == "-w")} {
      incr i
      set user(f_datum) [lindex $argv $i]
    } elseif {($arg == "--date") || ($arg == "-d")} {
      incr i
      set arg [lindex $argv $i]
      set user(date) [halo_clock2 scan $arg -gmt true]
      set zone EST
      if {"[halo_clock2 IsDaylightSaving $user(date) -inZone $zone]" == 1} {
        set zone "[string index $zone 0]DT"
      }
      puts "Date chosen as $arg"
      puts [halo_clock2 format $user(date) -format "%D %T" -zone $zone]
    } elseif {($arg == "--now") || ($arg == "-n")} {
      set user(date) [halo_clock2 seconds]
      set zone EST
      if {"[halo_clock2 IsDaylightSaving $user(date) -inZone $zone]" == 1} {
        set zone "[string index $zone 0]DT"
      }
      puts [halo_clock2 format $user(date) -format "%D %T" -zone $zone]
      set user(now) 1
    } elseif {($arg == "--station") || ($arg == "-s")} {
      incr i
      set arg [lindex $argv $i]
      set user(stationList) $arg
      puts "Station chosen is $arg"
    } elseif {($arg == "--all") || ($arg == "-a")} {
      set user(allStations) 1
    } elseif {($arg == "--log") || ($arg == "-l")} {
      set user(log) 1
      puts "Printing log statements to screen"
    } elseif {($arg == "--begin") || ($arg == "-b")} {
      incr i
      set arg [lindex $argv $i]
      set user(dateStart) [halo_clock2 scan $arg -gmt]
      set user(dateRange) 1
    } elseif {($arg == "--end") || ($arg == "-e")} {
      incr i
      set arg [lindex $argv $i]
      set user(dateEnd) [halo_clock2 scan $arg -gmt]
      set user(dateRange) 1
    } else {
      puts "Incompatible argument $arg, please check inputs"
      return
    }
  }
}
if {($user(stationList) == "") && (! $user(allStations))} {
  Usage
}

#*****************************************************************************
# Procedure Update_GD
#
# Purpose: Makes sure that the gd file is finished drawing, closes it, and
#   opens a new image. 
#
# Variables:
#   ray_name   : Name of global array which holds most of the global variables
#
# Returns: image name
#
# History:
#   10/2000 Arthur Taylor created
#
# Notes:
#   updates ray(im)  
#*****************************************************************************
proc Update_GD {ray_name} {
  upvar #0 $ray_name ray
  $ray(graph) configure -destName $ray(im)
  $ray(graph) redraw

  # This is added here specifically to get labels off the graph
  # (but onto the .gif) Must be after $ray(graph) redraw.
  gd text $ray(im) [expr 5] 2 -font g -fill "204 170 0"  -text "Surge"
  gd text $ray(im) [expr 5] 15 -font g -fill "204 170 0" -text "Guidance"

  gd text $ray(im) [expr 5+110] 2 -font g -fill "0 136 221"  -text Tide
  gd text $ray(im) [expr 5+110] 15 -font g -fill "0 136 221" -text Prediction

  gd text $ray(im) [expr 5+110+110] 2 -font g -fill "255 0 0" -text Observation

  gd text $ray(im) [expr 5+110+110+120] 2 -font g -fill "0 204 0" \
        -text "Anomaly"
  gd text $ray(im) [expr 5+110+110+120] 15 -font g -fill "0 204 0" \
        -text "(Obs.-(Tide+Surge))"

  gd text $ray(im) [expr 5+110+110+120+200] 2 -font g -fill "0 0 0" -text "Total Water"
  gd text $ray(im) [expr 5+110+110+120+200] 15 -font g -fill "0 0 0" -text Guidance

  gd close $ray(im) -file $ray(gdFile) -filetype $ray(gdFiletype)
  set ray(im) [gd open -file $ray(gdFile) -filetype $ray(gdFiletype)]
  return $ray(im)
}

#*******************************************************************************
# Procedure Init_Time
#
# Purpose:
#     Initiates beginning and end times for use in Refresh.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   days_before (I) Number of days before ray(now) to get results.
#   days_after (I) Number of days after ray(now) to get predictions.
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Adjusts ray time values and initiates values at 99.9 
#*******************************************************************************
proc Init_Time {ray_name days_before days_after} {
  upvar #0 $ray_name ray

  set ray(begTime) [expr $ray(cur) - $days_before * 24 * 3600.]
  set ray(endTime) [expr $ray(cur) + $days_after * 24 * 3600.]
  set ray(numHours) [expr ($days_after + $days_before) * 24 + 1]
  for {set i 0} {$i < $ray(numHours)} {incr i} {
    set cur [expr $ray(begTime) + $i * 3600.]
    set hr $i
    set ray($hr,surge) 99.9
    set ray($hr,tide) 99.9
    set ray($hr,obs) 99.9
    set ray($hr,anom) 99.9
    set ray($hr,pred) 99.9
  }
}


#*******************************************************************************
# Procedure Get_Tide
#
# Purpose:
#     Read a file which contains the tide data for a particular station.
#
#  Unfortunately a secondary station doesn't have ability to automatically
#  subtract the mllw/msl.  So in that case an adj is passed which can be
#  subtracted.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   tide_stn   (I) The station in question.
#   zone       (I) The time zone for the results
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Sets ray(<hr>,tide)
#*******************************************************************************
proc Get_Tide {ray_name tide_stn zone f_datum adjust1 adjust2} {
  upvar #0 $ray_name ray
  global src_dir
  global cur_dir

  set old_dir NULL
  if {! [file exists [file join [pwd] ft03.dta]]} {
    if {[file exists [file join $src_dir data ft03.dta]]} {
#      set old_dir [pwd]
      set old_dir $src_dir 
      cd [file join $src_dir data]
    } else {
      puts "cannot find ft03.dta file, returning"
      return
    }
  }

  # if the tide number in cron.bnt is negative, this will flag TideC_stn to
  #  perform calculations for a secondary station
  if {$tide_stn < 0} {
    set f_secondary 1
    set tide_stn [expr -1 * $tide_stn]
  } else {
    set f_secondary 0
  }

  # TideC_stn takes data in Local Standard Time (for station) 
  # Flagging for season (-f_seasonal) and if using MLLW (-f_mllw)
  set ans [TideC_stn hourly -station $tide_stn -date \
      [halo_clock2 format $ray(begTime) -format "%Y:%m:%d:%H" -zone $zone] \
      -numHour $ray(numHours) -initHeight 0 -f_seasonal 1 -f_mllw 1 \
      -f_secondary $f_secondary]
#  if {$f_datum == "mllw"} {
#    set ans [TideC_stn hourly -station $tide_stn -date \
#        [halo_clock2 format $ray(begTime) -format "%Y:%m:%d:%H" -zone $zone] \
#        -numHour $ray(numHours) -initHeight 0 -f_seasonal 1 -f_mllw 1 \
#        -f_secondary $f_secondary]
#  } elseif {! $f_secondary} {
#    set ans [TideC_stn hourly -station $tide_stn -date \
#        [halo_clock2 format $ray(begTime) -format "%Y:%m:%d:%H" -zone $zone] \
#        -numHour $ray(numHours) -initHeight 0 -f_seasonal 1 -f_mllw 0 \
#        -f_secondary $f_secondary]
#  } else {
#    # Secondary stations are not computed correctly if the f_mllw is 0.
#    # I believe it subtracts instead of adds.  Set the f_mllw to 1, then
#    # make the adjustment.
#    set ans [TideC_stn hourly -station $tide_stn -date \
#        [halo_clock2 format $ray(begTime) -format "%Y:%m:%d:%H" -zone $zone] \
#        -numHour $ray(numHours) -initHeight 0 -f_seasonal 1 -f_mllw 1 \
#        -f_secondary $f_secondary]
#  }

  if {$old_dir != "NULL"} {
    cd $old_dir
  }

  # ray(cur) holds the valid time for this plot, so it tells us if we are
  # putting the tide in EDT or EST. If EDT, must shift where value are stored.
  set daylight_adj 0
  if {[halo_clock2 IsDaylightSaving $ray(cur) -inZone $zone] == 1} {
    set daylight_adj 1
  }
  set hr $daylight_adj
  foreach tide $ans {
    if {$f_datum == "mllw"} {
      set ray($hr,tide) $tide
    } elseif {$f_datum == "msl"} {
      set ray($hr,tide) [expr $tide + $adjust1]
#      if {$f_secondary} {
#        set ray($hr,tide) [expr $tide + $adjust]
#      } else {
#        set ray($hr,tide) $tide
#      }
    } else {
      set ray($hr,tide) [expr $tide + $adjust2]
    }

    set hr [expr $hr + 1]
  }
}

#*******************************************************************************
# Procedure Get_Anom
#
# Purpose:
#     Calculates the anomaly and ensures the anomaly is reasonable.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   filt_anom  (I) A reasonable anomaly value, dictated by cron.bnt
#                  3ft for Gulf of Mexico, 5ft elsewhere
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Adjusts ray(anomList)
#*******************************************************************************
proc Get_Anom {ray_name filt_anom} {
  upvar #0 $ray_name ray

  # Filter out all obs after (now) for historical plot.
  for {set i 0} {$i < $ray(numHours)} {incr i} {
    set time [expr $ray(begTime) + $i * 3600.]
    set hr $i
    if {$time > $ray(now)} {
      set ray($hr,obs) 99.9
    }
  }


  # Do a filter for "Constant" obs.
  # This filter even with a 6 hour const check fails for Waveland MS.
  # So I am going to try a 9 hour const check.
  set Const_Hour_Check 9

  set cnt 0
  set last 99.9
  set i_start 0
  set marks ""
  for {set i 0} {$i < $ray(numHours)} {incr i} {
    set hr $i
    set cur $ray($hr,obs)

    if {$cur != 99.9} {
      set num_match 1
      for {set j [expr int($i + 1)]} {$j < $ray(numHours)} {incr j} {
        set test_hr [expr int($j)]
        set test $ray($test_hr,obs)
        # Checking for constant values - if the observations vary by less than
        # 0.08ft, then counting toward being a constant patch in the obs.
        # If not, then moving on.
        if {($test <= [expr $cur + .08]) && ($test >= [expr $cur - .08])} {
          incr num_match
        } else {
          break
        }
      }
      if {$num_match >= $Const_Hour_Check} {
        # mark every hour's worth of the constant observation patch
        lappend marks "$hr $num_match"
      }
    }
  }
  # Setting the constant sections of observations to the bad flag of 99.9
  foreach point $marks {
    set hr [lindex $point 0]
    set num_match [lindex $point 1]
    for {set i 0} {$i < $num_match} {incr i} {
      set ray([expr $hr + $i],obs) 99.9
    }
  }
  
  # Now to calculate the anomaly.  The anomaly needs at least 12 values over
  # the 5 day period before the average anomaly can be trusted.  The anomaly
  # also needs to be in a "reasonable" range (3ft for Gulf of Mexico, 5ft
  # otherwise).  Anomaly is in reference to 0, rather than in reference to the
  # average anomaly.
  #
  # setting up the values for calculating the average anomaly
  set tot_anom 0
  set anom_cnt 0
  set ray(last_obsTime) -1
  set last_obsHr 0
#  set f_fixObs 0
  for {set i 0} {$i < $ray(numHours)} {incr i} {
    set time [expr $ray(begTime) + $i * 3600.]
    set hr $i

#    if {$ray(now) == $time} {
#      set f_fixObs 1
#    }
#    if {$f_fixObs} {
#      set ray($hr,obs) 99.9
#    }

    if {($ray($hr,surge) != 99.9) && ($ray($hr,tide) != 99.9) && ($ray($hr,obs) != 99.9)} {
      set anom [expr $ray($hr,obs) - ($ray($hr,tide) + $ray($hr,surge))]
      # testing for reasonable anomaly
      if {[expr abs($anom)] < $filt_anom} {
        set ray($hr,anom) $anom
        set tot_anom [expr $tot_anom + $anom]
        incr anom_cnt
      } else {
        set ray($hr,obs) 99.9
      }
    }
    if {$ray($hr,obs) < 99} {
      set ray(last_obsTime) $time
      set last_obsHr $hr
      if {$anom_cnt > 0} {
        set last_anomValue $anom
      } else {
        set last_anomValue 0
      }
    }
  }
  # If there are at least 12 good values of the anomaly, set the hourly anomaly
  # and the anomaly value in anomList to the average of the total anomaly from
  # above.  Otherwise, set the hourly anomaly to 0 for later calculations, and
  # then flag as a bad value in anomList with the value of 99.
  if {$anom_cnt >= 12} {
    set avg [expr $tot_anom/$anom_cnt]
  } else {
    set avg 99
  }
  for {set hr 0} {$hr < $ray(numHours)} {incr hr} {
    if {$hr > $last_obsHr} {
      if {$ray($hr,anom) == 99.9} {
        if {$avg == 99} {
          set ray($hr,anom) 0
        } elseif {$hr < [expr $last_obsHr + 12]} {
          set ray($hr,anom) [expr $last_anomValue + ($avg - $last_anomValue) * ($hr - $last_obsHr) / 12.]
        } else {
          set ray($hr,anom) $avg
        }
      }
    }
  }
  lappend ray(anomList) [format "%6s,%7.3f" $ray(curAbrev) $avg]
}

#*******************************************************************************
# Procedure Get_Pred
#
# Purpose:
#     Sets predicted total water for Calc_Status.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#
# Returns: 99.9 if surge, tide or anom not correct.
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Sets ray(<hr>,pred)
#*******************************************************************************
proc Get_Pred {ray_name} {
  upvar #0 $ray_name ray

  # loop runs for all values of time in case ray(last_obsTime) is still set -1
  for {set i 0} {$i < $ray(numHours)} {incr i} {
    set time [expr $ray(begTime) + $i * 3600.]
    set hr $i
    if {$time > $ray(last_obsTime)} {
      if {($ray($hr,surge) != 99.9) && ($ray($hr,tide) != 99.9) && ($ray($hr,anom) != 99.9)} {
        set ray($hr,pred) [expr $ray($hr,surge) + $ray($hr,tide) + $ray($hr,anom)]
      } else {
        set ray($hr,pred) 99.9
      }
    }
  }
}

#*******************************************************************************
# Procedure Create_Plot
#
# Purpose:
#     Combine the lists that we have already read in, and plot them
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   title      (I) title for graph, full name of station.
#   display_days (I) number of days to display before the current time
#   MLLW       (I) mean low-low water
#   MSL        (I) mean sea level
#   MHHW       (I) mean high-high water
#   zone       (I) time zone of the station
#   HAT        (I) highest astronomical tide
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Adjusts ray(anom), and ray(pred)
#*******************************************************************************
proc Create_Plot {ray_name title display_days mllw msl mhhw zone mat f_datum} {
  upvar #0 $ray_name ray
  
  # setting up lists for saving the values
  set surge ""
  set tide ""
  set anom ""
  set obs ""
  set pred ""
  set anom_pred ""
  # plotting flag
  set f_obs 0

  # start loop for values of time greater than the current time less the
  # total time before the current time to be displayed
  for {set i [expr int([expr ceil(($ray(cur) - $ray(begTime) - $display_days * 3600 * 24.) / 3600.)])]} {$i < $ray(numHours)} {incr i} {
    set time [expr $ray(begTime) + $i * 3600.]
    set hr $i
    # only record surge, tide and pred if not flagged as bad
    if {$ray($hr,surge) != 99.9} {
      lappend surge [list $time $ray($hr,surge)]
    }
    if {$ray($hr,tide) != 99.9} {
      lappend tide [list $time $ray($hr,tide)]
    }
    if {$ray($hr,pred) != 99.9} {
      lappend pred [list $time $ray($hr,pred)]
    }
    # if obs flagged as bad, save as a bad value but do not plot 
    if {$ray($hr,obs) != 99.9} {
      lappend obs [list $time $ray($hr,obs)]
      set f_obs 1 
    } else {
      lappend obs [list $time 99]
    }
    # if anom is good, save as either observed or predicted anomaly depending
    # on whether it was before or after the last observation time.
    # if anom is bad and before last observation time, save as bad value.
    if {$ray($hr,anom) != 99.9} {
      if {$time <= $ray(last_obsTime)} {
        lappend anom [list $time $ray($hr,anom)]
      } else {
        lappend anom_pred [list $time $ray($hr,anom)]
      }
    } else {
      if {$time <= $ray(last_obsTime)} {
        lappend anom [list $time 99]
      }
    }
  }
  
  # make anom_pred a little less dense.
  set new_anom_pred ""
  for {set i 0} {$i < [llength $anom_pred]} {incr i 2} {
    lappend new_anom_pred [lindex $anom_pred $i]
  }
  lappend new_anom_pred [lindex $anom_pred [expr [llength $anom_pred] -1]]
 
  # begin plotting
  $ray(graph) configure -title $title \
        -min_x [expr $ray(cur) - $display_days * 24 * 3600.] \
        -zone $zone -XLabel "Time ($zone)"
  catch {$ray(graph) delete plot}

  # plotting mean sea level (MSL), mean high high water (MHHW) and Highest
  # astronomical tide (HAT)
  set mean_clr "#ff0000"

# -labelLoc [list 6 -8] -- X Y?
  if {$f_datum == "mllw"} {
    $ray(graph) add horz [list [list $ray(now) [expr $mhhw - $mllw]]] -label MHHW \
          -fill $mean_clr -tag plot -labelLoc [list 24 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $mat - $mllw]]] -label HAT \
          -fill $mean_clr -tag plot -labelLoc [list 34 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $msl - $mllw]]] -label MSL \
          -fill $mean_clr -tag plot -labelLoc [list 34 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $mllw - $mllw]]] -label MLLW \
          -fill $mean_clr -tag plot -labelLoc [list 24 -8]
  } elseif {$f_datum == "msl"} {
    $ray(graph) add horz [list [list $ray(now) [expr $mhhw - $msl]]] -label MHHW \
          -fill $mean_clr -tag plot -labelLoc [list 24 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $mat - $msl]]] -label HAT \
          -fill $mean_clr -tag plot -labelLoc [list 34 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $msl - $msl]]] -label MSL \
          -fill $mean_clr -tag plot -labelLoc [list 34 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $mllw - $msl]]] -label MLLW \
          -fill $mean_clr -tag plot -labelLoc [list 24 -8]
  } elseif {$f_datum == "mhhw"} {
    $ray(graph) add horz [list [list $ray(now) [expr $mhhw - $mhhw]]] -label MHHW \
          -fill $mean_clr -tag plot -labelLoc [list 24 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $mat - $mhhw]]] -label HAT \
          -fill $mean_clr -tag plot -labelLoc [list 34 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $msl - $mhhw]]] -label MSL \
          -fill $mean_clr -tag plot -labelLoc [list 34 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $mllw - $mhhw]]] -label MLLW \
          -fill $mean_clr -tag plot -labelLoc [list 24 -8]
  } else {
    $ray(graph) add horz [list [list $ray(now) [expr $mhhw - $mat]]] -label MHHW \
          -fill $mean_clr -tag plot -labelLoc [list 24 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $mat - $mat]]] -label HAT \
          -fill $mean_clr -tag plot -labelLoc [list 34 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $msl - $mat]]] -label MSL \
          -fill $mean_clr -tag plot -labelLoc [list 34 -8]
    $ray(graph) add horz [list [list $ray(now) [expr $mllw - $mat]]] -label MLLW \
          -fill $mean_clr -tag plot -labelLoc [list 24 -8]
  }

  # adding other curves to graph
  set srge_clr "#ccaa00" 
  if {$ray(fSurge) == 1} {
    if {$surge != ""} {
      $ray(graph) add curve $surge -fill $srge_clr -label NULL -width 2 -tag plot
    }
  }
#  set tide_clr "#00cc00"
  set tide_clr "#0088dd"
  if {$ray(fTide) == 1} {
    if {$tide != ""} {
      $ray(graph) add curve $tide -fill $tide_clr -label NULL -width 2 -tag plot
    }
  }
  set obs_clr "#ff0000"
  if {$ray(fObs) == 1} {
    if {$f_obs == 1} {
      $ray(graph) add point-curve $obs -fill $obs_clr -outline $obs_clr \
            -label NULL -width 2 -tag plot -NullValue 99
    }
  }
  set pred_clr "#000000"
  if {$ray(fObs) == 1} {
    if {$pred != ""} {
      $ray(graph) add point-curve $pred -fill $pred_clr -outline $pred_clr \
            -label NULL -width 2 -dash true -tag plot
    }
  }
#  set anom_clr "#0088dd"
  set anom_clr "#00cc00"
  if {$ray(fAnom) == 1} {
    if {$anom != ""} {
      $ray(graph) add curve $anom -fill $anom_clr -label NULL -width 2 -tag plot \
            -NullValue 99
    }
    if {$new_anom_pred != ""} { 
      $ray(graph) add curve $new_anom_pred -fill $anom_clr -label NULL -width 2 -tag plot -dash true
    }
  }

  # calling Update_GD to ensure that the file is finished drawing, and closed
  set ray(im) [Update_GD $ray_name]
}

#*******************************************************************************
# Procedure Output_Text
#
# Purpose:
#     Creates text file of results.
#
# Variables:(I=input)(O=output)
#   ray_name     (I) Global array to store the data in.
#   display_days (I) The number of days to display data.
#   title        (I) Full name of the station to be put in the text file title.
#   HAT          (I) Highest Astronomical Tide. 
#
# Returns: Text file of results.
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Does not adjust ray
#*******************************************************************************
proc Output_Text {ray_name display_days title mat f_datum} {
  upvar #0 $ray_name ray

  set fp [open $ray(txt_file) w]
  set fpan [open $ray(anom_file) w]
  if {$f_datum == "mllw"} {
    puts $fp "#$title : [halo_clock2 format $ray(now) -format "%D %T" -gmt true] GMT (units in feet MLLW)"
  } elseif {$f_datum == "msl"} {
    puts $fp "#$title : [halo_clock2 format $ray(now) -format "%D %T" -gmt true] GMT (units in feet MSL)"
  } else {
    puts $fp "#$title : [halo_clock2 format $ray(now) -format "%D %T" -gmt true] GMT (units in feet HAT)"
  }
  puts $fp "#Date(GMT), Surge,   Tide,    Obs,   Fcst,   Anom, Comment"
  puts $fp "#------------------------------------------------------------"
  
  # time value to begin outputting text results
  set start [expr $ray(cur) - $display_days * 24 * 3600.]

  # f_max: flag used to track when to label a max or a min for total water level
  # 0 - no good value for total water level
  # 1 - max
  # -1 - min
  # 2 - only 1 value for total water level
  set f_max 0
  # number to compare to next total water level to determine f_max 
  set big 99.9
  # flag to output a new full label after the last observation time
  set f_label 0
  
  # looping through all times to find trend of total water level
  for {set i 0} {$i < $ray(numHours)} {incr i} {
    set time [expr $ray(begTime) + $i * 3600.]
    set hr $i
    if {$f_max == 0} {
      if {$ray($hr,obs) != 99.9} {
        set big $ray($hr,obs)
        set f_max 2
      } elseif {$ray($hr,pred) != 99.9} {
        set big $ray($hr,pred)
        set f_max 2
      }
    } elseif {$f_max == 2} {
      if {$ray($hr,obs) != 99.9} {
        if {$big < $ray($hr,obs)} {
          set f_max 1
        } else {
          set f_max -1
        }
        set big $ray($hr,obs)
      } elseif {$ray($hr,pred) != 99.9} {
        if {$big < $ray($hr,pred)} {
          set f_max 1
        } else {
          set f_max -1
        }
        set big $ray($hr,pred)
      }
    }
    # if it is before start of text output, still establish which trend the
    # total water level is following
    if {$time < $start} {
      if {$f_max == 1} {
        if {$ray($hr,obs) != 99.9} {
          if {$big > $ray($hr,obs)} {
            set f_max -1
          }
          set big $ray($hr,obs)
        } elseif {$ray($hr,pred) != 99.9} {
          if {$big > $ray($hr,pred)} {
            set f_max -1
          }
          set big $ray($hr,pred)
        }
      } elseif {$f_max == -1} {
        if {$ray($hr,obs) != 99.9} {
          if {$big < $ray($hr,obs)} {
            set f_max 1
          }
          set big $ray($hr,obs)
        } elseif {$ray($hr,pred) != 99.9} {
          if {$big < $ray($hr,pred)} {
            set f_max 1
          }
          set big $ray($hr,pred)
        }
      }
    # now after start of text output, check values for max and min total water
    # level, and print values
    } else {
      if {$time != $start} {
        if {$f_max == 1} {
          if {$ray($hr,obs) != 99.9} {
            if {$big > $ray($hr,obs)} {
              puts -nonewline $fp "  (max)"
              set f_max -1
            }
            set big $ray($hr,obs)
          } elseif {$ray($hr,pred) != 99.9} {
            if {$big > $ray($hr,pred)} {
              puts -nonewline $fp "  (max)"
              set f_max -1
            }
            set big $ray($hr,pred)
          }
        } elseif {$f_max == -1} {
          if {$ray($hr,obs) != 99.9} {
            if {$big < $ray($hr,obs)} {
              puts -nonewline $fp "  (min)"
              set f_max 1
            }
            set big $ray($hr,obs)
          } elseif {$ray($hr,pred) != 99.9} {
            if {$big < $ray($hr,pred)} {
              puts -nonewline $fp "  (min)"
              set f_max 1
            }
            set big $ray($hr,pred)
          }
        }
        puts $fp ""
      }
      # inserts a new label after the last observation time is printed
      if {$f_label == 1} {
        puts $fp "#------------------------------------------------------------"
        puts $fp "#Date(GMT), Surge,   Tide,    Obs,   Fcst,   Anom, Comment"
        puts $fp "#------------------------------------------------------------"
        set f_label 0
      }
      # printing values on one line, including total water level
#      puts -nonewline $fp "[halo_clock2 format $time -format "%m/%d %H" -gmt true]Z,\
#          [format "%7.2f" $ray($hr,surge)],[format "%7.2f" $ray($hr,tide)],\
#          [format "%7.2f" $ray($hr,obs)],[format "%7.2f" $ray($hr,pred)],\
#          [format "%7.2f" $ray($hr,anom)],"
      puts -nonewline $fp [halo_clock2 format $time -format "%m/%d %H" -gmt true]Z,
      puts -nonewline $fp [format "%7.2f" $ray($hr,surge)],
      puts -nonewline $fp [format "%7.2f" $ray($hr,tide)],
      puts -nonewline $fp [format "%7.2f" $ray($hr,obs)],
      puts -nonewline $fp [format "%7.2f" $ray($hr,pred)],
      puts -nonewline $fp [format "%7.2f" $ray($hr,anom)],
      if {($ray($hr,obs) != 99.9) && ($ray($hr,obs) > $mat)} {
        puts -nonewline $fp " [format "%5.2f" [expr $ray($hr,obs) - $mat]] ft above HAT"
      }
      if {($ray($hr,pred) != 99.9) && ($ray($hr,pred) > $mat)} {
        puts -nonewline $fp " [format "%5.2f" [expr $ray($hr,pred) - $mat]] ft above HAT"
      }
      if {$ray(last_obsTime) == $time} {
        set f_label 1
      }
#-------- anomaly only
      if {$ray($hr,anom) == 99.9} {
	 set ray($hr,anom) 0.00
      }
#        puts $fpan $ray(curAbrev)\ [halo_clock2 format $time -format "%Y%m%d%H" -gmt true]\ [format "%7.2f" $ray($hr,anom)]
#        puts $fpan [halo_clock2 format $time -format "%Y%m%d%H" -gmt true]\ [format "%7.2f" $ray($hr,anom)]
        puts $fpan $hr\ [format "%7.2f" [expr $ray($hr,anom) * 0.3048]]\ [halo_clock2 format $time -format "%Y%m%d%H" -gmt true]
#        puts $ray(curAbrev)\ [halo_clock2 format $time -format "%Y%m%d%H" -gmt true]\ [format "%7.2f" $ray($hr,anom)]
#-------- anomaly only
    }
  }
  puts $fp ""
  close $fp
  close $fpan
}

#*******************************************************************************
# Procedure Refresh
#
# Purpose:
#     Creates the graph and/or text file for a given station and date.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   obs_stn    (I) station to be passed to Read_ObsFile
#   tide_stn   (I) station to be passed to Get_Tide
#   surge_file (I) filename for Read_StormSurge 
#   title      (I) full name of the station
#   arch_surge (I) name of archived station data file
#   temp_file  (I) name of temporary file to be passed to Read_ObsFile
#   days_before (I) number of days to read before specified date/time
#   arch_obs   (I) archived observation file for station
#   display_days (I) number of days to display
#   mllw       (I) mean lower low water for station from cron.bnt, passed to
#                  Create_Plot, Output_Text and Get_Tide 
#   msl        (I) mean sea level for station, used by Get_Tide & Create_Plot
#   mhhw       (I) mean higher high water for station, used by Create_Plot 
#   zone       (I) timezone for station and date
#   mat        (I) max. astronomical tide for station
#   filt_anom  (I) reasonable value for anomaly for station
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#    01/2010 Anne W Kramer modified
#
# Notes:
#   Adjusts ray
#*******************************************************************************
proc Refresh {ray_name obs_stn tide_stn surge_file title \
              arch_surge temp_file days_before arch_obs display_days \
              mllw msl mhhw zone mat filt_anom} {
  global user
  upvar #0 $ray_name ray

  # Calculate "cur" based on now 
  set cur [expr $ray(now) - ($ray(fcastDelay) * 3600)]
  set cur_date [halo_clock2 format $cur -format "%D" -gmt true]
  set cur_hour [halo_clock2 format $cur -format "%H" -gmt true]
  # truncating to correct model run time for output
  if {($cur_hour >= 0) && ($cur_hour < 6)} {
    set cur_hour 0
  } elseif {($cur_hour >= 6) && ($cur_hour < 12)} {
    set cur_hour 6
  } elseif {($cur_hour >= 12) && ($cur_hour < 18)} {
    set cur_hour 12
  } else {
    set cur_hour 18
  }
  set ray(cur) [halo_clock2 scan "$cur_date $cur_hour:00" -gmt true]
  $ray(graph) add vert [list [list $ray(cur) 0]] -label NULL -fill #ff00ff

  # Init begTime/endTime, including number of days after current time to use,
  # and init ray elements to 99.9
  set days_after 4
  Init_Time $ray_name $days_before $days_after

  # getting surge values from archived data, this function exists in archive.tcl
  Read_ArchSurge $ray_name $arch_surge

  Get_Tide $ray_name $tide_stn $zone $user(f_datum) [expr $mllw - $msl] [expr $mllw - $mat]

  # will only print if user(log) present
  Log "Have Read surge and computed tide... Get obs?"
 

  # getting observations from archived station data, function in archive.tcl
  set ap [open $temp_file w]
  if {$user(f_datum) == "mllw"} {
     Read_ArchObs $ray_name $arch_obs $ap 0
  } elseif {$user(f_datum) == "msl"} {
     Read_ArchObs $ray_name $arch_obs $ap [expr $mllw - $msl]
  } else {
     Read_ArchObs $ray_name $arch_obs $ap [expr $mllw - $mat]
  }
  close $ap
  
  # will only print if user(log) set
  Log "Finished Reading obs"
  
  Get_Anom $ray_name $filt_anom
  Get_Pred $ray_name

  set hr [format "%.0f" [halo_clock2 format $ray(now) -format "%I" -zone $zone].0]

  if {($user(output) == 0) || ($user(output) == 3)} {
    Create_Plot $ray_name "$title :\
        [halo_clock2 format $ray(now) -format "%D $hr:%M %p" -zone $zone] $zone" \
        $display_days $mllw $msl $mhhw $zone $mat $user(f_datum)
    Log "Finished Creating plot"
    Output_Text $ray_name $display_days $title [expr $mat -$mllw] $user(f_datum)
  } elseif {($user(output) == 1)} {
    Output_Text $ray_name $display_days $title [expr $mat -$mllw] $user(f_datum)
  } elseif {($user(output) == 2)} {
    Create_Plot $ray_name "$title : [halo_clock2 format $ray(now) -format "%D $hr:%M %p" -zone $zone] $zone" \
        $display_days $mllw $msl $mhhw $zone $mat $user(f_datum)
    Log "Finished Creating plot" 
  }
}

proc myMax {lst} {
  if {[catch {eval tcl::mathfunc::max $lst} max]} {
    # Handle the case when tcl doesn't have the mathfunc
    set max [lindex $lst 0]
    foreach elem $lst {
      if {$elem > $max} { 
        set max $elem
      }
    }
  }
  return $max
}


#*******************************************************************************
# Procedure Calc_Status
#
# Purpose:
#     Calculates status values for status maps per station and time interval.
#
# Variables:(I=input)(O=output)
#   ray_name     (I) Global array to store the data in.
#   stn          (I) The station for the calculations.
#   yellow       (I) Threshold water value for yellow flag.
#   red          (I) Threshold water value for red flag.
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Adjusts ray(status+(many options))
#*******************************************************************************
proc Calc_Status {ray_name stn yellow red} {
  upvar #0 $ray_name ray

  # set all initially to green
  set ray($stn,status_0_48) green
  set ray($stn,status12) green
  set ray($stn,status_0_96) green
  set ray($stn,status24) green
  set ray($stn,status48) green
  set ray($stn,status72) green
  set ray($stn,status96) green

  set pred ""
  set f_obs 0
  for {set i 0} {$i < $ray(numHours)} {incr i} {
    set time [expr $ray(begTime) + $i * 3600.] 
    set hr $i
    if {$time > $ray(now)} {
      lappend pred $ray($hr,pred)
    }
    if {$ray($hr,obs) != 99.9} {
      set f_obs 1
    }
  }
  if {$f_obs == 1} {
    # Has observations, no need to x out the station.
    set ray($stn,fLine) 0
  } else {
    # Doesn't have observations, Need to x out the station.
    set ray($stn,fLine) 1
  }

  set hr_0_12 [lrange $pred 0 12]
  set max_0_12 [myMax $hr_0_12]
  if {($max_0_12 >= $red) && ($max_0_12 != 99.9)} {
    set ray($stn,status12) red
    set ray($stn,status_0_48) red
    set ray($stn,status_0_96) red
  } elseif {($max_0_12 >= $yellow) && ($max_0_12 != 99.9)} {
    set ray($stn,status12) yellow
    set ray($stn,status_0_48) yellow
    set ray($stn,status_0_96) yellow
  }
  set hr_12_24 [lrange $pred 12 24]
  set max_12_24 [myMax $hr_12_24]
  if {($max_12_24 >= $red) && ($max_12_24 != 99.9)} {
    set ray($stn,status24) red
    if {$ray($stn,status_0_48) != "red"} {
      set ray($stn,status_0_48) red
    }
    if {$ray($stn,status_0_96) != "red"} { 
      set ray($stn,status_0_96) red
    }
  } elseif {($max_12_24 >= $yellow) && ($max_12_24 != 99.9)} {
    set ray($stn,status24) yellow
    if {($ray($stn,status_0_48) != "yellow") && ($ray($stn,status_0_48) != "red")} { 
      set ray($stn,status_0_48) yellow
    }
    if {($ray($stn,status_0_96) != "yellow") && ($ray($stn,status_0_96) != "red")} {
      set ray($stn,status_0_96) yellow
    } 
  }
  set hr_24_48 [lrange $pred 24 48]
  set max_24_48 [myMax $hr_24_48]
  if {($max_24_48 >= $red) && ($max_24_48 != 99.9)} {
    set ray($stn,status48) red
    if {$ray($stn,status_0_48) != "red"} {
      set ray($stn,status_0_48) red 
    } 
    if {$ray($stn,status_0_96) != "red"} {
      set ray($stn,status_0_96) red 
    } 
  } elseif {($max_24_48 >= $yellow) && ($max_24_48 != 99.9)} {
    set ray($stn,status48) yellow
    if {($ray($stn,status_0_48) != "yellow") && ($ray($stn,status_0_48) != "red")} {   
      set ray($stn,status_0_48) yellow 
    } 
    if {($ray($stn,status_0_96) != "yellow") && ($ray($stn,status_0_96) != "red")} {
      set ray($stn,status_0_96) yellow 
    }
  }
  set hr_48_72 [lrange $pred 48 72]
  set max_48_72 [myMax $hr_48_72]
  if {($max_48_72 >= $red) && ($max_48_72 != 99.9)} {
    set ray($stn,status72) red
    if {$ray($stn,status_0_96) != "red"} {
      set ray($stn,status_0_96) red
    }  
  } elseif {($max_48_72 >= $yellow) && ($max_48_72 != 99.9)} {
    set ray($stn,status72) yellow
    if {($ray($stn,status_0_96) != "yellow") && ($ray($stn,status_0_96) != "red")} {
      set ray($stn,status_0_96) yellow
    }   
  }  
  set hr_72_96 [lrange $pred 72 96]
  set max_72_96 [myMax $hr_72_96]
  if {($max_72_96 >= $red) && ($max_72_96 != 99.9)} {
    set ray($stn,status96) red
    if {$ray($stn,status_0_96) != "red"} {
      set ray($stn,status_0_96) red
    }
  } elseif {($max_72_96 >= $yellow) && ($max_72_96 != 99.9)} {
    set ray($stn,status96) yellow
    if {($ray($stn,status_0_96) != "yellow") && ($ray($stn,status_0_96) != "red")} {
      set ray($stn,status_0_96) yellow
    }
  }

  if {[lsearch $ray(statusList) $stn] == -1} {
    lappend ray(statusList) $stn
  }
}

#*******************************************************************************
# Procedure Draw_Status
#
# Purpose:
#     Draws the status for each station within the specified map.
#
# Variables:(I=input)(O=output)
#   ray_name     (I) Global array to store the data in.
#   filename     (I) name of file for station pre-knowns (cron.bnt) 
#   src_file     (I) blank surge map image file
#   dst_file     (I) filename for finished surge map image
#   status_type  (I) specification of status map duration
#   which        (I) index number of status map for legend placement
#   box_wid      (I) width of station box image in pixels
#   zone         (I) timezone for map and given date/time 
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#    01/2010 Anne W Kramer modified
#
# Notes:
#   Does not adjust ray, adds status period and date to status map legends.
#*******************************************************************************
proc Draw_Status {ray_name filename src_file dst_file status_type box_wid zone} {
  upvar #0 $ray_name ray
  global user

  file copy -force $src_file $dst_file
  set im [gd open -file $dst_file -filetype gif]

  if {"[halo_clock2 IsDaylightSaving $ray(now) -inZone $zone]" == 1} {
    set zone "[string index $zone 0]DT"
  }

  # bottom left
  # setting up where the labels on the maps will be placed
  set label_begin 103
  set label_height 548
  if {$user(mapCorner) == "BL"} {
    if {$status_type == "status_0_48"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-48" -fill "0 0 0"
    } elseif {$status_type == "status12"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-12" -fill "0 0 0"
    } elseif {$status_type == "status24"} {
      gd text $im $label_begin $label_height -font m -text "12-24" -fill "0 0 0"
    } elseif {$status_type == "status48"} {
      gd text $im $label_begin $label_height -font m -text "24-48" -fill "0 0 0"
    } elseif {$status_type == "status72"} {
      gd text $im $label_begin $label_height -font m -text "48-72" -fill "0 0 0"
    } elseif {$status_type == "status96"} {
      gd text $im $label_begin $label_height -font m -text "72-96" -fill "0 0 0"
    } elseif {$status_type == "status_0_96"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-96" -fill "0 0 0"
    }
    set hr [format "%.0f" [halo_clock2 format $ray(now) -format "%I" -zone $zone].0]
    gd text $im [expr $label_begin - 93] [expr $label_height + 31] -font m -fill "0 0 0" \
          -text "[halo_clock2 format $ray(now) -format "%m/%d/%Y $hr:%M %p" -zone $zone] $zone"

  # bottom right
  # changing where labels on map will begin, same height as previous
  } elseif {$user(mapCorner) == "BR"} {
    set label_begin 538
    if {$status_type == "status_0_48"} { 
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-48" -fill "0 0 0"
    } elseif {$status_type == "status12"} { 
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-12" -fill "0 0 0"
    } elseif {$status_type == "status24"} { 
      gd text $im $label_begin $label_height -font m -text "12-24" -fill "0 0 0"
    } elseif {$status_type == "status48"} { 
      gd text $im $label_begin $label_height -font m -text "24-48" -fill "0 0 0"
    } elseif {$status_type == "status72"} { 
      gd text $im $label_begin $label_height -font m -text "48-72" -fill "0 0 0"
    } elseif {$status_type == "status96"} { 
      gd text $im $label_begin $label_height -font m -text "72-96" -fill "0 0 0"
    } elseif {$status_type == "status_0_96"} { 
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-96" -fill "0 0 0"
    } 
    set hr [format "%.0f" [halo_clock2 format $ray(now) -format "%I" -zone $zone].0]
    gd text $im [expr $label_begin - 86] [expr $label_height + 31] -font m -fill "0 0 0" \
          -text "[halo_clock2 format $ray(now) -format "%m/%d/%Y $hr:%M %p" -zone $zone] $zone"
  
  # top right
  # changing label positioning again
  } elseif {$user(mapCorner) == "TR"} {
    set label_height 124
    set label_begin 538 
    if {$status_type == "status_0_48"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-48" -fill "0 0 0"
    } elseif {$status_type == "status12"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-12" -fill "0 0 0"
    } elseif {$status_type == "status24"} {
      gd text $im $label_begin $label_height -font m -text "12-24" -fill "0 0 0"
    } elseif {$status_type == "status48"} {
      gd text $im $label_begin $label_height -font m -text "24-48" -fill "0 0 0"
    } elseif {$status_type == "status72"} {
      gd text $im $label_begin $label_height -font m -text "48-72" -fill "0 0 0"
    } elseif {$status_type == "status96"} {
      gd text $im $label_begin $label_height -font m -text "72-96" -fill "0 0 0"
    } elseif {$status_type == "status_0_96"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-96" -fill "0 0 0"
    } 
    set hr [format "%.0f" [halo_clock2 format $ray(now) -format "%I" -zone $zone].0]
    gd text $im [expr $label_begin - 86] [expr $label_height + 30] -font m -fill "0 0 0" \
          -text "[halo_clock2 format $ray(now) -format "%m/%d/%Y $hr:%M %p" -zone $zone] $zone"

  # top Left
  # label position needs to be moved to the left
  } elseif {$user(mapCorner) == "TL"} {
    set label_begin 103
    set label_height 124
    if {$status_type == "status_0_48"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-48" -fill "0 0 0"
    } elseif {$status_type == "status12"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-12" -fill "0 0 0"
    } elseif {$status_type == "status24"} {
      gd text $im $label_begin $label_height -font m -text "12-24" -fill "0 0 0"
    } elseif {$status_type == "status48"} {
      gd text $im $label_begin $label_height -font m -text "24-48" -fill "0 0 0"
    } elseif {$status_type == "status72"} {
      gd text $im $label_begin $label_height -font m -text "48-72" -fill "0 0 0"
    } elseif {$status_type == "status96"} {
      gd text $im $label_begin $label_height -font m -text "72-96" -fill "0 0 0"
    } elseif {$status_type == "status_0_96"} {
      gd text $im [expr $label_begin + 4] $label_height -font m -text "0-96" -fill "0 0 0"
    }
    set hr [format "%.0f" [halo_clock2 format $ray(now) -format "%I" -zone $zone].0]
    gd text $im [expr $label_begin - 93] [expr $label_height + 30] -font m -fill "0 0 0" \
          -text "[halo_clock2 format $ray(now) -format "%m/%d/%Y $hr:%M %p" -zone $zone] $zone"
  }

  # after setting up the label on the map, have to find stations and fill in
  # their color on the map
  set fp [open $filename r]
  gets $fp line
  while {[gets $fp line] > 0} {
    set line [split $line :]
    if {[string index [string trim [lindex $line 0]] 0] != "#"} {
      set stn [lindex $line 1]
      # See if we are supposed to draw this station on this map.
      set map_num [split [lindex $line 15] ,]
      set map_ind [lsearch $map_num $user(mapIndex)]
      if {$map_ind != -1} {
        set point [split [lindex $line [expr 10 + $map_ind]] ,]
        set x [lindex $point 0]
        set y [lindex $point 1]
        if {[lsearch $ray(statusList) $stn] != -1} {
          if {$ray($stn,$status_type) == "red"} {
            gd polygon $im [expr $x - $box_wid] [expr $y - $box_wid] [expr $x - $box_wid] \
                  [expr $y + $box_wid] [expr $x + $box_wid] [expr $y + $box_wid] [expr $x + $box_wid] \
                  [expr $y - $box_wid] -fill "255 0 0" -outline "0 0 0"
          } elseif {$ray($stn,$status_type) == "yellow"} {
            gd polygon $im [expr $x - $box_wid] [expr $y - $box_wid] [expr $x - $box_wid] \
                  [expr $y + $box_wid] [expr $x + $box_wid] [expr $y + $box_wid] [expr $x + $box_wid] \
                  [expr $y - $box_wid] -fill "255 255 0" -outline "0 0 0"
          } else {
            gd polygon $im [expr $x - $box_wid] [expr $y - $box_wid] [expr $x - $box_wid] \
                  [expr $y + $box_wid] [expr $x + $box_wid] [expr $y + $box_wid] [expr $x + $box_wid] \
                  [expr $y - $box_wid] -fill "0 255 0" -outline "0 0 0"
          }
          # adding in drawing the line when there are no obs AWK
          if {$ray($stn,fLine) == 1} {
#            gd line $im [expr $x - $box_wid -1] [expr $y + $box_wid +1] [expr $x + $box_wid +1] [expr $y - $box_wid -1] -fill "255 255 255" -width 4
            gd line $im [expr $x - $box_wid +1] [expr $y + $box_wid] [expr $x + $box_wid] [expr $y - $box_wid +1] -fill "0 0 0" -width 2
            gd line $im [expr $x + $box_wid] [expr $y + $box_wid] [expr $x - $box_wid +1] [expr $y - $box_wid +1] -fill "0 0 0" -width 2
          }
        }
      }
    }
  }
  close $fp
  gd close $im -file $dst_file -filetype gif
}

#*******************************************************************************
# Procedure Status_Maps
#
# Purpose:
#     Calls Draw_Status for all default time durations for the specified region
#
# Variables:(I=input)(O=output)
#   ray_name     (I) Global array to store the data in.
#   filename     (I) name of file for station configuration values (cron.bnt)
#
# Returns: list of destination files passed to Draw_Status 
#
# History:
#    10/2000 Arthur Taylor created
#    01/2010 Anne W Kramer modified
#
# Notes:
#   Does not adjust ray
#*******************************************************************************
proc Status_Maps {ray_name filename} {
  upvar #0 $ray_name ray
  global src_dir
  global cur_dir
  global user

  set box_width 5
  set ans_list ""
  set datum $user(f_datum)
  foreach {i j k} [list 0 48 "status_0_48" 0 12 "status12" 12 24 "status24" 24 48 "status48" 48 72 "status72" 72 96 "status96" 0 96 "status_0_96"] {
    if {$user(mapRegion) == "ne"} {
      set dst_file [file join $src_dir $datum maps ne$i-$j.gif]
      Draw_Status $ray_name $filename [file join $src_dir data nesurge2.gif] $dst_file $k $box_width EST
      lappend ans_list $dst_file
    } elseif {$user(mapRegion) == "me"} {
      set dst_file [file join $src_dir $datum maps me$i-$j.gif]
      Draw_Status $ray_name $filename [file join $src_dir data mesurge2.gif] $dst_file $k $box_width EST
      lappend ans_list $dst_file
    } elseif {$user(mapRegion) == "se"} {
      set dst_file [file join $src_dir $datum maps se$i-$j.gif]
      Draw_Status $ray_name $filename [file join $src_dir data sesurge2.gif] $dst_file $k $box_width EST
      lappend ans_list $dst_file
    } elseif {$user(mapRegion) == "gf"} {
      set dst_file [file join $src_dir $datum maps gf$i-$j.gif]
      Draw_Status $ray_name $filename [file join $src_dir data gfsurge2.gif] $dst_file $k $box_width CST
      lappend ans_list $dst_file
    } elseif {$user(mapRegion) == "wc"} {
      set dst_file [file join $src_dir $datum maps wc$i-$j.gif]
      Draw_Status $ray_name $filename [file join $src_dir data wcsurge2.gif] $dst_file $k $box_width PST
      lappend ans_list $dst_file
    } elseif {$user(mapRegion) == "ak"} {
      set dst_file [file join $src_dir $datum maps ak$i-$j.gif]
      Draw_Status $ray_name $filename [file join $src_dir data aksurge3.gif] $dst_file $k $box_width YST
      lappend ans_list $dst_file
    } elseif {$user(mapRegion) == "ga"} {
      set dst_file [file join $src_dir $datum maps ga$i-$j.gif]
      Draw_Status $ray_name $filename [file join $src_dir data gasurge2.gif] $dst_file $k $box_width YST
      lappend ans_list $dst_file
    }
  }
  return $ans_list
}

#*******************************************************************************
# Procedure Log
#
# Purpose:
#     Prints the specified date followed by a message.
#
# Variables:(I=input)(O=output)
#   msg          (I) Message to be printed to stdout.
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#    01/2010 Anne W Kramer modified
#
# Notes:
#   Does not adjust ray
#*******************************************************************************
proc Log {msg} {
  global src_dir
  global user
  if {$user(log)} {
    puts -nonewline [halo_clock2 format $user(date) -format "%Y %m %d %T" -gmt true]
    puts ": $msg"
  }
}

#*******************************************************************************
# Procedure Main_Init
#
# Purpose:
#     Initializes certain graph values stored in ray.
#
# Variables:(I=input)(O=output)
#   ray_name     (I) Global array to store the data in.
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#    01/2010 Anne W Kramer modified
#
# Notes:
#   Adjusts ray graph values
#*******************************************************************************
proc Main_Init {ray_name datum} {
  global src_dir
  global cur_dir
  upvar #0 $ray_name ray

  # default values
  set ray(numDays) 1.5
  set ray(fcastDelay) 3
  set ray(fSurge) 1
  set ray(fTide) 1
  set ray(fObs) 1
  set ray(fAnom) 1
#  set ray(doAll) 0    moving to main part of program

  set ray(gdFile) [file join $src_dir default.gif]
  set ray(txt_file) [file join $src_dir default.txt]
  set ray(anom_file) [file join $src_dir default.txt]
  set ray(gdFiletype) gif
  set ray(im) ""
  set ray(statusList) ""
  set ray(anomList) ""
  set ray(Wid) 660
  set ray(Hei) 420
  set ray(im) [gd open -width $ray(Wid) -height $ray(Hei)  \
        -background "255 255 255"]
  set ray(graph) .graph
# -YAxisVert 1 -- Y axis with rotated text
# -YLabelAnchor n -- Anchor Y axis to north (s - south, c - center)
# -Width_YLabel 25 -- Width of area for Y labels.
# -uplf "2 32" -- Upper left corner of black box.
# -lwrt "[expr $ray(Wid) -1] [expr $ray(Hei) -1]"
  halo_GraphInit $ray(graph) -destName $ray(im) -destType gd \
        -uplf "-1 32" -lwrt "[expr $ray(Wid) -0] [expr $ray(Hei) -0]" -fontHeight 12 \
        -font "-family Times -size 8 -weight bold" -gridDash [expr 1*1+1*2] \
        -X_time 1 -Xincr 10800. -Half_Xincr 3600. \
        -XLabIncr 4 -XFormat "%G" -XFormat2 "%G\n%a %m/%d" -XFormat2Incr 1 \
        -Height_XLabel 35 -grid_x 43200. -grid_xColor #777777 \
        -Yincr 1 -YLabIncr 1 -grid_y 1 -nearest_y 1 -YLabel "Feet relative to $datum" -YAxisVert 1 \
        -YLabelAnchor c \
        -Width_YLabel 43 -YFormat "%.0lf" -grid_yColor #777777 -LabelAnchor nw
  # adding x-axis
  $ray(graph) add vert [list [list $ray(now) 0]] -label NULL -fill #ff00ff
  # adding y-axis
#  $ray(graph) add horz [list [list $ray(now) 0]] -label MLLW \
#        -fill #ff0000 -labelLoc [list 6 -8]
}

#*******************************************************************************
# Procedure Main
#
# Purpose:
#     Main function of program, loops through multiple stations if status map
#         is required.
#
# Variables:(I=input)(O=output)
#   ray_name     (I) Global array to store the data in.
#
# Returns: All specified files.
#
# History:
#    10/2000 Arthur Taylor created
#    01/2010 Anne W Kramer modified
#
# Notes:
#   Adjusts many parts of ray
#*******************************************************************************
proc Main {ray_name} {
  global src_dir
  global cur_dir
  upvar #0 $ray_name ray
  global user
  
#  set ray(now) $user(date)
  set ray(fStat) $user(fMap)

  set datum [string toupper $user(f_datum)]
  Main_Init $ray_name $datum
  set fp [open [file join $src_dir data cron.bnt] r]
  gets $fp line
  # first time through while loop....
  # ray(im) is opened once in Main_Init
  set first 0
  set station_cnt 0
  while {[gets $fp line] > 0} {
    set line [split $line :]
    if {[string index [string trim [lindex $line 0]] 0] != "#"} {
      if {($ray(doAll)) || ([string tolower [string trim $user(stationList)]] == [lindex $line 1]) || ([string toupper [string trim $user(stationList)]] == [lindex $line 2]) || ([string toupper [string trim $user(stationList)]]  == [string toupper [lindex $line 7]]) || ($user(stationList) == $station_cnt) || ([lsearch [split [lindex $line 15] ,] $user(mapIndex)] != -1)} {
        if {$first != 0} {
          set ray(im) [gd open -width $ray(Wid) -height $ray(Hei) -background "255 255 255"]
        }
        set first 1
        set timeStamp [halo_clock2 format $ray(now) -format "%y%m%d%H" -gmt true]
        # removing timestamp for running "now"
        set datum $user(f_datum)
        if {$user(now)} {
          set ray(gdFile) [file join $src_dir $datum plots [lindex $line 1].gif]
          set ray(txt_file) [file join $src_dir $datum plots [lindex $line 1].txt]
          set ray(anom_file) [file join $src_dir $datum plots [lindex $line 1].anom]
        } else {
          set ray(gdFile) [file join $src_dir $datum plots [lindex $line 1]_$timeStamp.gif]
          set ray(txt_file) [file join $src_dir $datum plots [lindex $line 1]_$timeStamp.txt]
          set ray(anom_file) [file join $src_dir $datum plots [lindex $line 1]_$timeStamp.anom]
        }
        set ray(curAbrev) [lindex $line 1]
        set zone [lindex $line 16]

        if {"[halo_clock2 IsDaylightSaving $ray(now) -inZone $zone]" == 1} {
          set zone "[string index $zone 0]DT"
        }

        set mllw [lindex $line 12]
        set msl [lindex $line 13]
        set mhhw [lindex $line 14]
        set mat [lindex [split [lindex $line 17] #] 0]
        set filt_anom [lindex $line 18]
        set DaysToRead 5
        if {$ray(numDays) > $DaysToRead} {
          set DaysToRead $ray(numDays)
        }
        Refresh $ray_name [lindex $line 3] [lindex $line 4] \
              [lindex $line 5] [lindex $line 7] \
              [file join $src_dir database [lindex $line 1].ss] \
              [file join $src_dir temp.txt] \
              $DaysToRead [file join $src_dir database [lindex $line 1].obs] \
              $ray(numDays) $mllw $msl $mhhw $zone $mat $filt_anom
        if {($ray(fStat) != 0) || $user(allStations)} {
          if {$user(f_datum) == "mllw"} {
            Calc_Status $ray_name [lindex $line 1] [expr ($mhhw - $mllw)] [expr ($mat - $mllw)]
          } elseif {$user(f_datum) == "msl"} {
            Calc_Status $ray_name [lindex $line 1] [expr ($mhhw - $msl)] [expr ($mat - $msl)]
          } else {
            Calc_Status $ray_name [lindex $line 1] [expr ($mhhw - $mat)] [expr ($mat - $mat)]
          }  
        }
      }
      incr station_cnt
    }
  }
  close $fp
#  if {($ray(doAll)) || ($ray(fStat))} {
#
#    set anomlist ""
#    if {[file exists [file join $src_dir anom.txt]]} {
#      set fp [open [file join $src_dir anom.txt] r]
#      while {[gets $fp line] >= 0 } {
#        lappend anomlist $line
#      }
#      close $fp
#    }
#    if {$anomlist != ""} {
#      set newlist ""
#      lappend newlist "[lindex $anomlist 0],[halo_clock2 format $ray(now) -format "%D" -gmt true]"
#      for {set i 0} {$i < [llength $anomlist]} {incr i} {
#        lappend newlist "[lindex $anomlist [expr $i +1]],[lindex [split [lindex $ray(anomList) $i] ,] 1]"
#      }
#      set anomlist $newlist
#    } else {
#      set anomlist ""
#      lappend anomlist ",[halo_clock2 format $ray(now) -format "%D" -gmt true]"
#      foreach line $ray(anomList) {
#        lappend anomlist $line
#      }
#    }
#    set fp [open [file join $src_dir anom.txt] w]
#    foreach line $anomlist {
#      puts $fp $line
#    }
#    close $fp
#  }
  if {$user(allStations)} {
    set map [list "ne" "me" "se" "gf" "wc" "ak" "ga"]
    set corner [list "TL" "BL" "TL" "BL" "BL" "BR" "TR"]
    for {set i 0} {$i < 7} {incr i} {
      set user(mapRegion) [lindex $map $i]
      set user(mapCorner) [lindex $corner $i]
      set user(mapIndex) [expr $i + 1]
puts "Calling Status_Maps [lindex $map $i] $user(mapRegion) $user(mapCorner)"
      Status_Maps $ray_name [file join $src_dir data cron.bnt]
    }
  } elseif {$ray(fStat) != 0} {
    Status_Maps $ray_name [file join $src_dir data cron.bnt]
  }
  set ray(now) "[halo_clock2 format $ray(now) -format "%D %T" -gmt true] UTC"
  update
  return
}


#-----------------------------------------------------------------------------
# Done with Procs, start program.
#-----------------------------------------------------------------------------

set ray_name RAY1
catch {unset $ray_name}
set RAY1(graph) .test1.graph
set RAY1(doAll) 0

# looping for multiple dates
set j 0
if {$user(dateRange)} {
  if {($user(dateStart) != 0) && ($user(dateEnd) != 0) && \
      ($user(dateEnd) > $user(dateStart))} {
    set RAY1(now) $user(dateStart)
    while {$RAY1(now) < $user(dateEnd)} {
      # 6 is for the 6hr time increment, may set to user choice later
      # changing to 12 for Hassan request
      set RAY1(now) [expr $user(dateStart) + $j * 12 * 3600]
      set user(date) $RAY1(now)
      Main $ray_name
      # have to reset RAY1(now) to correct format for comparison in while loop
      set RAY1(now) [expr $user(dateStart) + $j * 12 * 3600]
      incr j
    }
  } else {
    puts "        date begin and date end incompatible or incorrectly defined,
        please re-enter."
    return
  }
# all stations & maps
} elseif {$user(allStations)} {
  set RAY1(now) $user(date)
  set RAY1(doAll) 1
  Main $ray_name
} else {
  set RAY1(now) $user(date)
  Main $ray_name
}
