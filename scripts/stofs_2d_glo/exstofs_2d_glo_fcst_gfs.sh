#!/bin/bash
###############################################################################
#                                                                             #
# This script is the preprocessor for making surface forcing from GFS         #
# It sets some shell script variables for export to child scripts             #
# and copies some generally used files to the work directory.                 #
# After this the actual preprocessing is performed by the following scripts:  #
#                                                                             #
# Remarks :                                                                   #
#                                                                 Sep, 2023   #
#                                                                             #
###############################################################################
# Start of stofs_2d_glo_fcst_gfs.sh script ---------------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_fcst_gfs scripts"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

  spinh=162
  wndh=3
  nowh=6
  lsth=180

# --------------------------------------------------------------------------- #
# 1.  Set times
# 1.a Set all necessary times
#     YMDH     :  current time cycle in yyyymmddhh format
#     time_beg :  begin time of run (normally, -6 hour nowcast or the most recent hotstart time)
#     time_now :  current time
#     time_end :  ending time of run ($lsth hour forecast)

  export date=$PDY
  export YMDH=${PDY}${cyc}

  time_now=$YMDH
  time_060=`$NDATE 60 $YMDH`
  time_120=`$NDATE 120 $YMDH`
  time_end=`$NDATE $lsth $YMDH`

# --------------------------------------------------------------------------- #
# 2.  Run the stofs_2d_glo_surface_forcing.sh for forecast
date
  if [ -f $COMOUTrerun/${RUN}_fcst.22 ]; then
      echo "Copy nowcast fort.22 file"
      cpreq $COMOUTrerun/${RUN}_fcst.22 fort.22
  else
      echo "There is no nowcast fort.22 file"
  fi

  if [ ! -f $COMOUTrerun/${RUN}_fcst0.200 ]; then
     export pgm="stofs_2d_glo_surface_forching.sh for forecast0"
     . prep_step
     startmsg
     mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface1" "$time_now" "$time_060" >> $pgmout 2>errfile
     export err=$?; err_chk
   
     if [ -e "$pgmout" ] ; then
        echo "${RUN}_surface_forcing.sh nowcast standout log - for "$time_now" "$time_60hours":"
        cat $pgmout
        echo "${RUN}_surface_forcing.sh nowcast errfile log:"
        cat ./errfile
        echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh forecast0"
     fi
     for fhr in $(seq -f "%02g" 0 60 ); do
         cpfs fort.2${fhr} $COMOUTrerun/${RUN}_fcst0.2${fhr}
     done
     cat fort.2?? >> fort.22
     rm fort.2??
  else
     echo "surface forcing files for forecast0 are already existed"
  fi
date
  if [ ! -f $COMOUTrerun/${RUN}_fcst1.200 ]; then
     export pgm="stofs_2d_glo_surface_forching.sh for forecast1"
     . prep_step
     startmsg
     mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface1" "$time_060" "$time_120" >> $pgmout 2>errfile
     export err=$?; err_chk
   
     if [ -e "$pgmout" ] ; then
        echo "${RUN}_surface_forcing.sh nowcast standout log - for "$time_60hours" "$time_120hours":"
        cat $pgmout
        echo "${RUN}_surface_forcing.sh nowcast errfile log:"
        cat ./errfile
        echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh forecast1"
     fi
     for fhr in $(seq -f "%02g" 0 60 ); do
         cpfs fort.2${fhr} $COMOUTrerun/${RUN}_fcst1.2${fhr}
     done
     cat fort.2?? >> fort.22
     rm fort.2??
  else
     echo "surface forcing files for forecast1 are already existed"
  fi
date
  if [ ! -f $COMOUTrerun/${RUN}_fcst2.200 ]; then
     export pgm="stofs_2d_glo_surface_forching.sh for forecast2"
     . prep_step
     startmsg
     mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface3" "$time_120" "$time_end" >> $pgmout 2>errfile
     export err=$?; err_chk
   
     if [ -e "$pgmout" ] ; then
        echo "${RUN}_surface_forcing.sh nowcast standout log - for "$time_120" "$time_end":"
        cat $pgmout
        echo "${RUN}_surface_forcing.sh nowcast errfile log:"
        cat ./errfile
        echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh forecast2"
     fi
     for fhr in $(seq -f "%02g" 0 3 60); do
         cpfs fort.2${fhr} $COMOUTrerun/${RUN}_fcst2.2${fhr}
     done
     cat fort.2?? >> fort.22
     rm fort.2??
  else
     echo "surface forcing files for forecast2 are already existed"
  fi

  if [ $SENDCOM = YES ]; then
     echo "Copying fort.22 to $COMOUT/${RUN}.${cycle}.surface.forcing"
     cpfs fort.22             $COMOUT/${RUN}.${cycle}.surface.forcing
  fi
date
  msg="Completing stofs_2d_glo_fcst_gfs script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of stofs_2d_glo_fcst_gfs.sh script ------------------------------------ #
