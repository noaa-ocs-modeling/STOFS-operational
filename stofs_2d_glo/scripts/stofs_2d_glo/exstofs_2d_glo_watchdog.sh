#!/bin/bash
###############################################################################
#                                                                             #
# This script is the watchdog for the STOFS_2D_GLO that copies output         #
# to the rerun directory.                                                     #
#                                                                             #
# Remarks :                                                                   #
#                                                                             #
#                                                                 Jun, 2025   #
#                                                                             #
###############################################################################
# Start of exstofs_2d_glo_watchdog.sh script -------------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_watchdog script"
  echo "$msg"
  postmsg "$msg"

  wndh=3
  nowh=6
  lsth=180

# --------------------------------------------------------------------------- #
# 1.  Set times
# 1.a Set all necessary times
#     YMDH     :  current time cycle in yyyymmddhh format
#     time_beg :  begin time of run (normally, -6 hour hindcast or the most recent restart time)
#     time_now :  current time
#     time_end :  ending time of run ($lsth hour forecast)

  export date=$PDY
  export YMDH=${PDY}${cyc}

  time_now=$YMDH
  time_end=`$NDATE $lsth $YMDH`
# Be patient until the adcprep process has been completed
  sleep 600

# --------------------------------------------------------------------------- #
# 2.  Get the path of the work diretory and copy output files to ${COMOUTrerun}
  
# 2.1 Get tide run output

  if [ $1 = "hottime" ]; then
     if [ -f $COMOUTrerun/${RUN}_${1}.out ]; then
        cpreq $COMOUTrerun/${RUN}_${1}.out ${1}.out
#         tmpd=$(grep -n "${RUN}" ${1}.out | awk '{print $5}')
        tmpd=$(grep -n "work" ${1}.out | awk '{print $5}')
        if grep -q "forecast" ${1}.out; then
           time_hotstart=$(grep [0-9] ${1}.out | awk '{print $2}')
           touts=$(grep [0-9] ${1}.out | awk '{print $3}')
           toutf=$(grep [0-9] ${1}.out | awk '{print $4}')
	   echo $time_hotstart $touts $toutf
        fi

        if [ ! -f $tmpd/fort.61.nc ]; then
	   echo "the files weren't created yet, please wait for until completing adcprep"
	   sleep 120
	fi

        ii=0
        while [ $ii -le 1 ]
        do 
           sleep 420
           cp $tmpd/fort.15    ${COMOUTrerun}/${RUN}_tide.15
           cp $tmpd/fort.61.nc ${COMOUTrerun}/${RUN}_tide.61.nc
           cp $tmpd/fort.63.nc ${COMOUTrerun}/${RUN}_tide.63.nc
           cp $tmpd/fort.68.nc ${COMOUTrerun}/${RUN}_tide.68.nc
           ii=$(($ii+1))
         done
     fi
  fi
  
# 2.2 Get GFS surface forcing run output

  if [ $1 = "retime" ]; then
     if [ -f $COMOUTrerun/${RUN}_${1}.out ]; then
        cpreq $COMOUTrerun/${RUN}_${1}.out ${1}.out
#        tmpd=$(grep -n "${RUN}" ${1}.out | awk '{print $5}')
        tmpd=$(grep -n "work" ${1}.out | awk '{print $5}')
        if grep -q "forecast" ${1}.out; then
           time_restart=$(grep [0-9] ${1}.out | awk '{print $2}')
           touts=$(grep [0-9] ${1}.out | awk '{print $3}')
           toutf=$(grep [0-9] ${1}.out | awk '{print $4}')
           echo $time_restart $touts $toutf
        fi

        if [ ! -f $tmpd/fort.61.nc ]; then
	   echo "the files weren't created yet, please wait for until completing adcprep"
	   sleep 120
	fi

  	ii=0
  	while [ $ii -le 1 ]
        do 
          sleep 420
          cp $tmpd/fort.15    ${COMOUTrerun}/${RUN}_surf.15
          cp $tmpd/fort.61.nc ${COMOUTrerun}/${RUN}_surf.61.nc
          cp $tmpd/fort.62.nc ${COMOUTrerun}/${RUN}_surf.62.nc
          cp $tmpd/fort.63.nc ${COMOUTrerun}/${RUN}_surf.63.nc
          cp $tmpd/fort.64.nc ${COMOUTrerun}/${RUN}_surf.64.nc
          cp $tmpd/maxele.63.nc $COMOUTrerun/${RUN}_maxele.63.nc
          cp $tmpd/maxvel.63.nc $COMOUTrerun/${RUN}_maxvel.63.nc
          cp $tmpd/maxwvel.63.nc $COMOUTrerun/${RUN}_maxwvel.63.nc
          cp $tmpd/fort.68.nc ${COMOUTrerun}/${RUN}_surf.68.nc
          ii=$(($ii+1))
        done
     fi
  fi

  msg="Completing stofs_2d_glo_watchdog script"
  echo "$msg"
  postmsg "$msg"

# End of exstofs_2d_glo_watchdog.sh script --------------------------------- #
