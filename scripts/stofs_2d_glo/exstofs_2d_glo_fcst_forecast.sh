#!/bin/bash
###############################################################################
#                                                                             #
# This script is the preprocessor for the STOFS that runs under the ADCIRC    #
# model. This script is the surface forcing forecast for the STOFS.           #
# It sets some shell script variables for export to child scripts             #
# and copies some generally used files to the work directory.                 #
# After this the actual preprocessing is performed by the following scripts:  #
#                                                                             #
# Remarks :                                                                   #
#                                                                             #
#                                                                 Dec, 2011   #
#                                                                 May, 2016   #
#                                                                 Jun, 2020   #
#                                                                 Apr, 2021   #
#                                                                 Jun, 2022   #
#                                                                 Sep, 2023   #
#                                                                             #
###############################################################################
# Start of stofs_2d_glo_fcst_forecast.sh.ecf script ------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_fcst_forecast scripts"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

  spinh=162
  wndh=3
  nowh=6
  lsth=180
  export ncpu=$NCPU

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
  time_060=`$NDATE 60 $YMDH`
  time_120=`$NDATE 120 $YMDH`
  time_end=`$NDATE $lsth $YMDH`

# --------------------------------------------------------------------------- #
# 2.  Get restart and fcst files

  if [ ! -f $COMOUTrerun/${RUN}_fcst.68.nc ]; then
     cpreq $COMOUT/${RUN}.${cycle}.restart ${time_now}.restart
  else
     cpreq $COMOUTrerun/${RUN}_fcst.68.nc  ${time_now}.restart
  fi
  cpreq $COMOUTrerun/${RUN}_fcst.22             fort.22
  cpreq $COMOUTrerun/${RUN}_fcst.61.nc 		fort.61.nc
  cpreq $COMOUTrerun/${RUN}_fcst.62.nc 		fort.62.nc
  cpreq $COMOUTrerun/${RUN}_fcst.63.nc 		fort.63.nc
  cpreq $COMOUTrerun/${RUN}_fcst.64.nc 		fort.64.nc
  if [ -f $COMOUTrerun/${RUN}_maxele.63.nc ]; then
     cpreq $COMOUTrerun/${RUN}_maxele.63.nc 	maxele.63.nc
     cpreq $COMOUTrerun/${RUN}_maxvel.63.nc 	maxvel.63.nc
     cpreq $COMOUTrerun/${RUN}_maxwvel.63.nc 	maxwvel.63.nc
  fi

# --------------------------------------------------------------------------- #
# 3.  Copy stofs_2d_glo partmesh, grid, and template files 

  ln -s $FIXstofs/${RUN}_attr fort.13
  ln -s $FIXstofs/${RUN}_grid fort.14
  ln -s $FIXstofs/${RUN}_body fort.24
  ln -s $FIXstofs/${RUN}_rotm fort.rotm
  ln -s $FIXstofs/${RUN}_elev_stat elev_stat.151
  ln -s $FIXstofs/${RUN}_elev_stat vel_stat.151

# 3.a Copy stofs_2d_glo_nod_equi file and tar file

  if [ -f $COMGES/${RUN}_nod_equi ]; then
     cpreq $COMGES/${RUN}_nod_equi .
  fi
  if [ -f $COMGES/${RUN}_${ncpu}.tar.gz ]; then
     cpreq $COMGES/${RUN}_${ncpu}.tar.gz .
     tar xvzf ${RUN}_${ncpu}.tar.gz
     export err=$?; err_chk
  fi

# --------------------------------------------------------------------------- #
# 4.  Set time and file for surface forcing forecast
# 4.a Set parameters for surface forcing forecast input file

  cpreq $COMOUTrerun/${RUN}_retime.out retime.out
  restart=$(grep [0-9]  retime.out | awk '{print $1}')         
  time_restart=$(grep [0-9] retime.out | awk '{print $2}')     
  touts=$(grep [0-9] retime.out | awk '{print $3}')             
  toutf=$(grep [0-9] retime.out | awk '{print $4}')             
  echo $restart $time_restart $touts $toutf                    

  while [ $restart -le 2 ]; 
  do
     if [ $restart -gt 0 ]; then
        cpreq $COMOUTrerun/${RUN}_retime.out 	retime.out
        restart=$(grep [0-9]  retime.out | awk '{print $1}')
        time_restart=$(grep [0-9] retime.out | awk '{print $2}')
        touts=$(grep [0-9] retime.out | awk '{print $3}')
        toutf=$(grep [0-9] retime.out | awk '{print $4}')
        echo $restart $time_restart $touts $toutf                    
        cpreq $COMOUTrerun/${RUN}_fcst.68.nc    ${time_now}.restart
        cpreq $COMOUTrerun/${RUN}_fcst.61.nc 	fort.61.nc
        cpreq $COMOUTrerun/${RUN}_fcst.62.nc 	fort.62.nc
        cpreq $COMOUTrerun/${RUN}_fcst.63.nc 	fort.63.nc
        cpreq $COMOUTrerun/${RUN}_fcst.64.nc 	fort.64.nc
        cpreq $COMOUTrerun/${RUN}_maxele.63.nc 	maxele.63.nc
        cpreq $COMOUTrerun/${RUN}_maxvel.63.nc 	maxvel.63.nc
        cpreq $COMOUTrerun/${RUN}_maxwvel.63.nc	maxwvel.63.nc
        cpreq $COMOUTrerun/${RUN}_fcst.22       fort.22
     fi

# 4.b Create surface forcing files for forecast

     if [ $restart = 0 ]; then
        winc=3600
        export pgm="stofs_2d_glo_surface_forching.sh for forecast${restart}"
        . prep_step
        startmsg
        mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface1" "$time_now" "$time_060" >> $pgmout 2>errfile
        export err=$?; err_chk
        if [ -e "$pgmout" ] ; then
	        echo "${RUN}_surface_forcing.sh nowcast standout log - for "$time_now" "$time_060":"
	           cat $pgmout
	           echo "${RUN}_surface_forcing.sh nowcast errfile log:"
	        cat ./errfile
             echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh forecast0"
        fi
     elif [ $restart = 1 ]; then
          winc=3600
          export pgm="stofs_2d_glo_surface_forching.sh for forecast${restart}"
          . prep_step
          startmsg
          mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface1" "$time_060" "$time_120" >> $pgmout 2>errfile
          export err=$?; err_chk
          if [ -e "$pgmout" ] ; then
	     echo "${RUN}_surface_forcing.sh nowcast standout log - for "$time_060" "$time_120":"
	     cat $pgmout
	     echo "${RUN}_surface_forcing.sh nowcast errfile log:"
	     cat ./errfile
             echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh forecast0"
         fi
     else
         winc=10800
         export pgm="stofs_2d_glo_surface_forching.sh for forecast${restart}"
        . prep_step
        startmsg
        mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface3" "$time_120" "$time_end" >> $pgmout 2>errfile
        export err=$?; err_chk
        if [ -e "$pgmout" ] ; then
	   echo "${RUN}_surface_forcing.sh nowcast standout log - for "$time_120" "$time_end":"
	   cat $pgmout
	   echo "${RUN}_surface_forcing.sh nowcast errfile log:"
	   cat ./errfile
           echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh forecast0"
        fi
     fi

     if [ `expr $(echo "scale=0; $time_restart/($nowh*3600)" | bc) % 2` = 0 ]; then
        ihot=568
        cpreq ${time_now}.restart fort.68.nc
     else
        ihot=567
        cpreq ${time_now}.restart fort.67.nc
     fi
   
     fcstd=$(echo "scale=5; $time_restart/86400" | bc)
     rnday_restart=$(echo "scale=5; $fcstd+$lsth/72" | bc)
     nout=5
     nhstar=5
     nhsinc=3600
     time_fcst=$(echo "scale=5; $rnday_restart*86400" | bc)
     restart=$(($restart+1))
     time_restart=$(printf "%.0f" "$time_fcst")
     echo $restart $time_restart $touts $toutf > retime.out 

     cpreq $FIXstofs/${RUN}_fcst.15 ${RUN}_fort.15
     exec 5<&0 < ${RUN}_nod_equi
         read hh dd mm yyyy
         mm=$(printf "%02d" $mm)
         dd=$(printf "%02d" $dd)
         hh=$(printf "%02d" $hh)
         read con1 fft1 facet1
         read con2 fft2 facet2
         read con3 fft3 facet3
         read con4 fft4 facet4
         read con5 fft5 facet5
         read con6 fft6 facet6
         read con7 fft7 facet7
         read con8 fft8 facet8
   
     sed -e "s/cycle/$time_now/g" \
         -e "s/ihot/$ihot/g" \
         -e "s/winc/$winc/g" \
         -e "s/rnday/$rnday_restart/g" \
         -e "s/fft1/$fft1/g" -e "s/facet1/$facet1/g" \
         -e "s/fft2/$fft2/g" -e "s/facet2/$facet2/g" \
         -e "s/fft3/$fft3/g" -e "s/facet3/$facet3/g" \
         -e "s/fft4/$fft4/g" -e "s/facet4/$facet4/g" \
         -e "s/fft5/$fft5/g" -e "s/facet5/$facet5/g" \
         -e "s/fft6/$fft6/g" -e "s/facet6/$facet6/g" \
         -e "s/fft7/$fft7/g" -e "s/facet7/$facet7/g" \
         -e "s/fft8/$fft8/g" -e "s/facet8/$facet8/g" \
         -e "s/nout/$nout/g" \
         -e "s/touts/$touts/g" -e "s/toutf/$toutf/g" \
         -e "s/nhstar/$nhstar/g" -e "s/nhsinc/$nhsinc/g" \
         -e "s/hh/$hh/g" -e "s/dd/$dd/g" \
         -e "s/mm/$mm/g" -e "s/yyyy/$yyyy/g" \
                   ${RUN}_fort.15 | \
     sed -n "/DUMMY/!p" > fort.15
     rm ${RUN}_fort.15
   
     if [ ! -f fort.15 ]; then
        echo "FATAL ERROR: Surface frocing forecast input file did not exist"
        err_exit
     else
        echo "Surface forcing forecast input file existed"
     fi

# --------------------------------------------------------------------------- #
# 5.  Execute stofs_2d_glo_adcprep for surface forcing forecast 

     export pgm="stofs_2d_glo_adcprep for surface forcing forecast${restart}"
     . prep_step
     startmsg
     if [ ! -s ${RUN}_${ncpu}.tar.gz ]; then
        mpiexec -n 1 -ppn 1 $EXECstofs/${RUN}_adcprep --np $ncpu --partmesh >> $pgmout 2>errfile
        export err=$?; err_chk
        mpiexec -n 1 -ppn 1 $EXECstofs/${RUN}_adcprep --np $ncpu --prepall >> $pgmout 2>errfile
        export err=$?; err_chk
        filelist="partmesh.txt PE*/fort.14 PE*/fort.18 PE*/fort.13 PE*/fort.24 PE*/elev_stat.151 PE*/vel_stat.151"
        tar cvzf ${RUN}_${ncpu}.tar.gz $filelist
        export err=$?; err_chk
        cpfs ${RUN}_${ncpu}.tar.gz $COMGES/.
     else
        mpiexec -n 1 -ppn 1 $EXECstofs/${RUN}_adcprep --np $ncpu --prep15 >> $pgmout 2>errfile
        export err=$?; err_chk
     fi

# --------------------------------------------------------------------------- #
# 6.  Execute stofs_2d_glo_padcirc for surface frocing forecast 

     export pgm="stofs_2d_glo_padcirc for surface frocing forecast${restart}"
     . prep_step
     startmsg
     mpiexec -n $ncpu -ppn 127 --cpu-bind core $EXECstofs/${RUN}_padcirc >> $pgmout 2>adcirc.err
     export err=$?; err_chk
     if [[ -n $(grep 'ADCIRC stopping' adcirc.err) || -n $(grep 'ADCIRC Terminating' adcirc.err) ]]; then
        echo "FATAL ERROR: ADCIRC_RUN crashed and terminated"
        err_exit
     else
        echo "ADCIRC_RUN completed normally"
     fi

# --------------------------------------------------------------------------- #
# 7.  Send files to $COM

     if [ `expr $(echo "scale=0; $time_restart/($nowh*3600)" | bc) % 2` = 0 ]; then
        cpfs fort.68.nc ${RUN}.fcst.68.nc
     else
        cpfs fort.67.nc ${RUN}.fcst.68.nc
     fi
  
     if [ $SENDCOM = YES ]; then
	if [ $restart -lt 3 ]; then
           cpfs retime.out  		  $COMOUTrerun/${RUN}_retime.out
	   cat fort.2?? >> fort.22
	   rm fort.2??
           cpfs fort.22                   $COMOUTrerun/${RUN}_fcst.22
           cpfs fort.61.nc                $COMOUTrerun/${RUN}_fcst.61.nc
           cpfs fort.62.nc                $COMOUTrerun/${RUN}_fcst.62.nc
           cpfs fort.63.nc                $COMOUTrerun/${RUN}_fcst.63.nc
           cpfs fort.64.nc                $COMOUTrerun/${RUN}_fcst.64.nc
           cpfs maxele.63.nc              $COMOUTrerun/${RUN}_maxele.63.nc
           cpfs maxvel.63.nc              $COMOUTrerun/${RUN}_maxvel.63.nc
           cpfs maxwvel.63.nc             $COMOUTrerun/${RUN}_maxwvel.63.nc
           cpfs ${RUN}.fcst.68.nc         $COMOUTrerun/${RUN}_fcst.68.nc
        else 
	   cat fort.2?? >> fort.22
	   rm fort.2??
           echo "Copying fort.22 to	  $COMOUT/${RUN}.${cycle}.surface.forcing"
	   cpfs fort.22             	  $COMOUT/${RUN}.${cycle}.surface.forcing
           echo "Copying fort.61.nc to    $COMOUT/${RUN}.${cycle}.points.cwl.nc"
           cpfs fort.61.nc                $COMOUT/${RUN}.${cycle}.points.cwl.nc
           echo "Copying fort.61.nc to    $COMOUT/${RUN}.${cycle}.points.cwl.nc"
           cpfs fort.61.nc                $COMOUT/${RUN}.${cycle}.points.cwl.noanomaly.nc
           echo "Copying fort.62.nc to    $COMOUT/${RUN}.${cycle}.points.cwl.vel.nc"
           cpfs fort.62.nc                $COMOUT/${RUN}.${cycle}.points.cwl.vel.nc
           echo "Copying fort.63.nc to    $COMOUT/${RUN}.${cycle}.fields.cwl.nc"
           cpfs fort.63.nc                $COMOUT/${RUN}.${cycle}.fields.cwl.nc 
           echo "Copying fort.64.nc to    $COMOUT/${RUN}.${cycle}.fields.cwl.vel.nc"
           cpfs fort.64.nc                $COMOUT/${RUN}.${cycle}.fields.cwl.vel.nc
           echo "Copying maxele.63.nc to  $COMOUT/${RUN}.${cycle}.fields.cwl.maxele.nc"
           cpfs maxele.63.nc              $COMOUT/${RUN}.${cycle}.fields.cwl.maxele.nc
           echo "Copying maxvel.63.nc to  $COMOUT/${RUN}.${cycle}.fields.cwl.maxvel.nc"
           cpfs maxvel.63.nc              $COMOUT/${RUN}.${cycle}.fields.cwl.maxvel.nc
           echo "Copying maxwvel.63.nc to $COMOUT/${RUN}.${cycle}.fields.cwl.maxwvel.nc"
           cpfs maxwvel.63.nc             $COMOUT/${RUN}.${cycle}.fields.cwl.maxwvel.nc
        fi
    fi
  done  

  msg="Completing stofs_2d_glo_fcst_forecast script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of stofs_2d_glo_fcst_forecast.sh.ecf script ----------------------------- #
