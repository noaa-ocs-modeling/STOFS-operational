package require http 2.0
#*****************************************************************************
# http::copy() --
#
# PURPOSE
#    Teaches http library how to copy a URL to a file. (see "my_http.tcl")
#
# ARGUMENTS
#        url = Web site to copy from
#       file = File to copy to
# f_progress = Flag to say whether we should output a progress bar.
#      chunk = Amount to copy at one time (8192 is default)
#
# RETURNS void
#
# HISTORY
#  9/2003 Arthur Taylor (MDL/RSIS): Created.
#
# NOTES
#*****************************************************************************
namespace eval http {
  proc SetProxy {proxy port} {
    variable http
    if {($proxy != "") && ($port != "")} {
      set http(-proxyhost) $proxy
      set http(-proxyport) $port
    } else {
      set http(-proxyhost) ""
      set http(-proxyport) ""
    }
  }

  proc copy { url file {f_progress 0} {chunk 8192}} {
    set out [open $file w]
    if {$f_progress} {
       puts -nonewline stderr "$file: "
       if {[catch {geturl $url -channel $out -progress ::http::Progress \
                  -blocksize $chunk} token]} {
        puts "Error Geturl $file : Message $token"
        close $out ; return 1
      }
    # This ends the line started by http::Progress
      puts stderr ""
    } else {
      if {[catch {geturl $url -channel $out \
                 -blocksize $chunk} token]} {
        puts "Error Geturl $file : Message $token"
        close $out ; return 1
      }
    }
    close $out
    if {[http::status $token] == "timeout"} {
      puts "timeout: $file"
      return 1
    }
    return 0
  }

  proc Progress {args} {
    puts -nonewline stderr . ; flush stderr
  }
}

proc Get_Anonymous_Surge2 {ray_name} {
  puts "This is already done by the code that massaged the ESTOFS data into ETSS format."
  puts "Don't grab more data into the /model folder."

#  upvar #0 $ray_name ray
#  global src_dir
#
#  set now [halo_clock2 seconds]
#  set now [expr floor (($now - 4*3600) / (3600*6)) * (3600*6)]
#
#  set date [halo_clock2 format $now -format "%Y%m%d" -zone GMT]
#  set hr [halo_clock2 format $now -format "%H" -zone GMT]
#  if {$hr >= 18} {
#    set hr 18
#  } elseif {$hr >= 12} {
#    set hr 12
#  } elseif {$hr >= 6} {
#    set hr [format "%02d" 6]
#  } else {
#    set hr [format "%02d" 0]
#  }
#
#  set localList [list $src_dir/model/ssec.txt \
#                      $src_dir/model/ssgm.txt \
#                      $src_dir/model/sswc.txt \
#                      $src_dir/model/ssar.txt \
#                      $src_dir/model/ssak.txt \
#                      $src_dir/model/ssga.txt]
###########
# Set f_localCopy to 1 if we are on same machine as ETSS output.
###########
  # Can't set this true unless we are on production machine
  # Takes time for dev machine to sync
#  set f_localCopy 0
#
#
#  if {$f_localCopy} {
#    set srcList [list /com/gfs/prod/gfs.$date/mdlsurge.[format "%02d%1s" $hr "e"] \
#        /com/gfs/prod/gfs.$date/mdlsurge.[format "%02d%1s" $hr "g"] \
#        /com/gfs/prod/gfs.$date/mdlsurge.[format "%02d%1s" $hr "w"] \
#        /com/gfs/prod/gfs.$date/mdlsurge.[format "%02d%1s" $hr "z"] \
#        /com/gfs/prod/gfs.$date/mdlsurge.[format "%02d%1s" $hr "a"] \
#        /com/gfs/prod/gfs.$date/mdlsurge.[format "%02d%1s" $hr "k"]] 
#  } else {
#    set srcList [list http://weather.noaa.gov/pub/SL.us008001/DF.anf/DC.etss/DS.ssec/RD.$date/cy.$hr.txt \
#                      http://weather.noaa.gov/pub/SL.us008001/DF.anf/DC.etss/DS.ssgm/RD.$date/cy.$hr.txt \
#                      http://weather.noaa.gov/pub/SL.us008001/DF.anf/DC.etss/DS.sswc/RD.$date/cy.$hr.txt \
#                      http://weather.noaa.gov/pub/SL.us008001/DF.anf/DC.etss/DS.ssar/RD.$date/cy.$hr.txt \
#                      http://weather.noaa.gov/pub/SL.us008001/DF.anf/DC.etss/DS.ssak/RD.$date/cy.$hr.txt \
#                      http://weather.noaa.gov/pub/SL.us008001/DF.anf/DC.etss/DS.ssga/RD.$date/cy.$hr.txt]
#  }
#  for {set i 0} {$i < 6} {incr i} {
#    set src [lindex $srcList $i]
#    set local [lindex $localList $i]
#    puts "Getting $src => $local"
#    if {$f_localCopy} {
#      file copy -force $src $local
#    } else {
#      if {[http::copy $src $local 1 20480] != 0} {
#        puts "  Couldn't 'get' $src."
#        file delete -force $local
#      }
#    }
#  }
  return 1
}
