#!/bin/bash
###############################################################################
#                                                                             #
# This script is the preprocessor for making surface forcing from GFS         #                                                                   
# It sets some shell script variables for export to child scripts             #
# and copies some generally used files to the work directory.                 #
# After this the actual preprocessing is performed by the following scripts:  #
#                                                                             #
# Remarks :                                                                   #
#                                                                 Jun, 2025   #
#                                                                             #
###############################################################################
# Start of exstofs_2d_glo_gfs.sh script ------------------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_gfs scripts"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

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
  export nback=20

  time_now=$YMDH
  time_120=`$NDATE 120 $YMDH`
  time_end=`$NDATE $lsth $YMDH`

  if [ $1 = "ncst" ]; then
     $USHstofs/${RUN}_multistart.sh "restart" >> $pgmout 2>errfile
     export err=$?; err_chk
     ymdh=`head ${RUN}_multistart.out | awk '{ print $1 }'`
     rm ${RUN}_multistart.out
     time_beg=$ymdh
     echo $time_beg
  fi

# --------------------------------------------------------------------------- #
# 2.  Run the stofs_2d_glo_surface_forcing.sh for nowcast

  if [ $1 = "ncst" ]; then
     if [ ! -f $COMOUTrerun/${RUN}_$1.221.nc ]; then
        export pgm="stofs_2d_glo_surface_forching.sh for nowcast"
        . prep_step
        startmsg
        mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface1" "$time_beg" "$time_now" >> $pgmout 2>errfile
        export err=$?; err_chk
   
        if [ -e "$pgmout" ] ; then
           echo "${RUN}_surface_forcing.sh nowcast standout log - for "$time_beg" "$time_now""
           cat $pgmout
           echo "${RUN}_surface_forcing.sh nowcast errfile log"
           cat ./errfile
           echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh nowcast"
        fi

        if [ $SENDCOM = YES ]; then
           cpfs fort.221.nc  $COMOUTrerun/${RUN}_$1.221.nc
           cpfs fort.222.nc  $COMOUTrerun/${RUN}_$1.222.nc
           cpfs fort.225.nc  $COMOUTrerun/${RUN}_$1.225.nc
        fi
     else
        echo "surface forcing files for gfs.ncst is already existed"
     fi

# --------------------------------------------------------------------------- #
# 3.  Run the stofs_2d_glo_surface_forcing.sh for forecast

  elif [ $1 = "fcst1" ]; then
       if [ ! -f $COMOUTrerun/${RUN}_$1.221.nc ]; then
          export pgm="stofs_2d_glo_surface_forching.sh for forecast1"
          . prep_step
          startmsg
          mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface1" "$time_now" "$time_120" >> $pgmout 2>errfile
          export err=$?; err_chk
        
          if [ -e "$pgmout" ] ; then
             echo "${RUN}_surface_forcing.sh forecast standout log - for "$time_now" "$time_120""
             cat $pgmout
             echo "${RUN}_surface_forcing.sh forecast errfile log"
             cat ./errfile
             echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh forecast1"
          fi

          if [ $SENDCOM = YES ]; then
             cpfs fort.221.nc  $COMOUTrerun/${RUN}_$1.221.nc
             cpfs fort.222.nc  $COMOUTrerun/${RUN}_$1.222.nc
             cpfs fort.225.nc  $COMOUTrerun/${RUN}_$1.225.nc
          fi
       else
          echo "surface forcing files for gfs.fcst1 is already existed"
       fi
  else
       if [ ! -f $COMOUTrerun/${RUN}_$1.221.nc ]; then
          export pgm="stofs_2d_glo_surface_forching.sh for forecast2"
          . prep_step
          startmsg
          mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface3" "$time_120" "$time_end" >> $pgmout 2>errfile
          export err=$?; err_chk
        
          if [ -e "$pgmout" ] ; then
             echo "${RUN}_surface_forcing.sh forecast standout log - for "$time_120" "$time_end""
             cat $pgmout
             echo "${RUN}_surface_forcing.sh forccast errfile log"
             cat ./errfile
             echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh forecast2"
          fi

          if [ $SENDCOM = YES ]; then
             cpfs fort.221.nc  $COMOUTrerun/${RUN}_$1.221.nc
             cpfs fort.222.nc  $COMOUTrerun/${RUN}_$1.222.nc
             cpfs fort.225.nc  $COMOUTrerun/${RUN}_$1.225.nc
          fi
       else
          echo "surface forcing files for gfs.fcst2 is already existed"
       fi
  fi

  msg="Completing stofs_2d_glo_gfs script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of exstofs_2d_glo_gfs.sh script --------------------------------------- #
