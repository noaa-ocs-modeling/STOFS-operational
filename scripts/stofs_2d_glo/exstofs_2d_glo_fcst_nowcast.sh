#!/bin/bash
###############################################################################
#                                                                             #
# This script is the preprocessor for the STOFS that runs under the ADCIRC    #
# model. This script is the surface forcing nowcast for the STOFS.            #
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
# Start of stofs_2d_glo_fcst_nowcast.sh.ecf script -------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_fcst_nowcast scripts"
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
  time_end=`$NDATE $lsth $YMDH`

# --------------------------------------------------------------------------- #
# 2.  Get restart time and file 

  if [ COLDSTART = NO ]; then
     if [[ ! -f $COMGES/${RUN}_nod_equi || ! -f $COMGES/${RUN}_${ncpu}.tar.gz ]]; then
        echo "FATAL ERROR: There are no tidal spin-up files, Please restart with COLDSTART=YES"
        err_exit
     fi
  fi

  $USHstofs/${RUN}_multistart.sh "restart" >> $pgmout 2>errfile
  export err=$?; err_chk
  ymdh=`head ${RUN}_multistart.out | awk '{ print $1 }'`
  rm ${RUN}_multistart.out
  
  time_beg=$ymdh
  rdate=`echo $ymdh | cut -c1-8`
  rcyc=`echo $ymdh | cut -c9-10`
  rdir=$COM/${RUN}.${rdate}
  rfile=${RUN}.t${rcyc}z.restart

  if [ -d $rdir ]; then
     if [ -f $rdir/$rfile ]; then
        cpreq $rdir/$rfile ${time_beg}.restart
	if [ $cyc = "00" ]; then
           if [ ! -f $COMIN/database.tar.gz ]; then
              cpreq $rdir/database.tar.gz $COMIN/.
	   fi
        fi
     fi
  fi

# --------------------------------------------------------------------------- #
# 3.  Copy stofs_2d_glo partmesh, grid, and template files 

  ln -s $FIXstofs/${RUN}_attr fort.13
  ln -s $FIXstofs/${RUN}_grid fort.14
  ln -s $FIXstofs/${RUN}_body fort.24
  ln -s $FIXstofs/${RUN}_rotm fort.rotm
  ln -s $FIXstofs/${RUN}_elev_stat elev_stat.151
  ln -s $FIXstofs/${RUN}_elev_stat vel_stat.151

# 3.a Copy stofs.2d_glo_nod_equi file and tar file

  if [ -f $COMGES/${RUN}_nod_equi ]; then
     cpreq $COMGES/${RUN}_nod_equi .
  fi
  if [ -f $COMGES/${RUN}_${ncpu}.tar.gz ]; then
     cpreq $COMGES/${RUN}_${ncpu}.tar.gz .
     tar xvzf ${RUN}_${ncpu}.tar.gz
     export err=$?; err_chk
  fi

# --------------------------------------------------------------------------- #
# 4.  Set time and file for surface forcing nowcast
# 4.a Set parameters for surface forcing nowcast input file

  ncdump -v time ${time_beg}.restart > restart.out
  export err=$?; err_chk
  time_restart=$(grep 'time = [0-9]' restart.out | awk '{print $3}')
  rm restart.out

# 4.b Create surface forcing for nowcast

  export pgm="stofs_2d_glo_surface_forching.sh for nowcast"
  . prep_step
  startmsg
  mpiexec -n 1 -ppn 1 $USHstofs/${RUN}_surface_forcing.sh "surface1" "$time_beg" "$time_now" >> $pgmout 2>errfile
  export err=$?; err_chk

  if [ -e "$pgmout" ] ; then
     echo "${RUN}_surface_forcing.sh nowcast standout log - for "$time_beg" "$time_now":"
     cat $pgmout
     echo "${RUN}_surface_forcing.sh nowcast errfile log:"
     cat ./errfile
     echo "Done concatenating $pgmout and errfile for ${RUN}_surface_forcing.sh nowcast"
  fi

  if [ `expr $(echo "scale=0; $time_restart/($wndh*3600)" | bc) % 2` = 0 ]; then
     ihot=568
     cpreq ${time_beg}.restart fort.68.nc
  else
     ihot=567
     cpreq ${time_beg}.restart fort.67.nc
  fi

  ncsth=`$NHOUR $time_now $time_beg`
  ncstd=$(echo "scale=5; ($time_restart+$ncsth*3600)/86400" | bc)
  rnday=$(echo "scale=5; $ncstd+$lsth/24" | bc)
  winc=3600
  nout=-5
  touts=$(echo "scale=5; $rnday-($nowh+$lsth)/24" | bc)
  toutf=$rnday
  nhstar=5
  nhsinc=1800
  time_ncst=$(echo "scale=0; $ncstd*86400" | bc)
  restart=0
  time_restart=$(printf "%.0f" "$time_ncst")
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
      -e "s/rnday/$ncstd/g" \
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
     echo "FATAL ERROR: Surface frocing nowcast input file did not exist"
     err_exit
  else
     echo "Surface forcing nowcast input file existed"
  fi

# --------------------------------------------------------------------------- #
# 5.  Execute stofs_2d_glo_adcprep for surface forcing nowcast

  export pgm="stofs_2d_glo_adcprep for surface forcing nowcast"
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
# 6.  Execute stofs_2d_glo_padcirc for surface frocing nowcast

  export pgm="stofs_2d_glo_padcirc for surface frocing nowcast"
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

  if [ `expr $(echo "scale=0; $time_ncst/($wndh*3600)" | bc) % 2` = 0 ]; then
     cpfs fort.68.nc ${time_now}.restart
  else
     cpfs fort.67.nc ${time_now}.restart
  fi

  if [ $SENDCOM = YES ]; then
     cpfs retime.out                      $COMOUTrerun/${RUN}_retime.out	
     cat fort.2?? >> fort.22
     cpfs fort.22                         $COMOUTrerun/${RUN}_fcst.22
     cpfs fort.61.nc                      $COMOUTrerun/${RUN}_fcst.61.nc
     cpfs fort.62.nc                      $COMOUTrerun/${RUN}_fcst.62.nc
     cpfs fort.63.nc                      $COMOUTrerun/${RUN}_fcst.63.nc
     cpfs fort.64.nc                      $COMOUTrerun/${RUN}_fcst.64.nc
     cpfs maxele.63.nc                    $COMOUTrerun/${RUN}_maxele.63.nc
     cpfs maxvel.63.nc                    $COMOUTrerun/${RUN}_maxvel.63.nc
     cpfs maxwvel.63.nc                   $COMOUTrerun/${RUN}_maxwvel.63.nc
     echo "Copying ${time_now}.restart to $COMOUT/${RUN}.${cycle}.restart"
     cpfs ${time_now}.restart             $COMOUT/${RUN}.${cycle}.restart
  fi

  msg="Completing stofs_2d_glo_fcst_nowcast script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of stofs_2d_glo_fcst_nowcast.sh.ecf script ---------------------------- #
