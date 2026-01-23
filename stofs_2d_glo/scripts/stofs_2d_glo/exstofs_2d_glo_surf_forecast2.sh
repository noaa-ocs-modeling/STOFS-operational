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
#                                                                 Jun, 2025   #
#                                                                             #
###############################################################################
# Start of stofs_2d_glo_surf_forecast2.sh script ---------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_surf_forecast2 scripts"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

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
# 2.  Get restart and surface forcing files

  if [ ! -f $COMOUTrerun/${RUN}_surf.68.nc ]; then
     cpreq $COMOUT/${RUN}.${cycle}.restart ${time_now}.restart
  else
     cpreq $COMOUTrerun/${RUN}_surf.68.nc  ${time_now}.restart
  fi
  cpreq $COMOUTrerun/${RUN}_surf.61.nc          fort.61.nc
  cpreq $COMOUTrerun/${RUN}_surf.61.nc          fort.61.nc
  cpreq $COMOUTrerun/${RUN}_surf.62.nc          fort.62.nc
  cpreq $COMOUTrerun/${RUN}_surf.63.nc          fort.63.nc
  cpreq $COMOUTrerun/${RUN}_surf.64.nc          fort.64.nc
  cpreq $COMOUTrerun/${RUN}_maxele.63.nc        maxele.63.nc
  cpreq $COMOUTrerun/${RUN}_maxvel.63.nc        maxvel.63.nc
  cpreq $COMOUTrerun/${RUN}_maxwvel.63.nc       maxwvel.63.nc

# --------------------------------------------------------------------------- #
# 3.  Copy stofs_2d_glo partmesh, grid, and template files 

  ln -s $FIXstofs/${RUN}_attr fort.13
  ln -s $FIXstofs/${RUN}_grid fort.14
  ln -s $FIXstofs/${RUN}_met  fort.22
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
# 4.  Set time and file for surface forcing forecast2
# 4.a Set parameters for surface forcing forecast2 input file

  cpreq $COMOUTrerun/${RUN}_retime.out retime.out
  restart=$(grep [0-9]  retime.out | awk '{print $1}')         
  time_restart=$(grep [0-9] retime.out | awk '{print $2}')     
  touts=$(grep [0-9] retime.out | awk '{print $3}')             
  toutf=$(grep [0-9] retime.out | awk '{print $4}')             
  tmpd=$(grep -n "${RUN}" retime.out | awk '{print $5}')
  echo $restart $time_restart $touts $toutf $tmpd                   

# 4.b Get surface forcing files for forecast2

  winc=10800
  if [ -f $COMOUTrerun/${RUN}_fcst2.221.nc ]; then
     ln -s ${COMOUTrerun}/${RUN}_fcst2.221.nc fort.221.nc
     ln -s ${COMOUTrerun}/${RUN}_fcst2.222.nc fort.222.nc
     ln -s ${COMOUTrerun}/${RUN}_fcst2.225.nc fort.225.nc
  else
     echo "FATAL ERROR: GFS surface forcing does not exist"
     err_exit
  fi

  if [ `expr $(echo "scale=0; $time_restart/($nowh*3600)" | bc) % 2` = 0 ]; then
     ihot=368
     cpreq ${time_now}.restart fort.68.nc
  else
     ihot=367
     cpreq ${time_now}.restart fort.67.nc
  fi

  fcstd=$(echo "scale=5; $time_restart/86400" | bc)
  rnday_restart=$(echo "scale=5; $fcstd+$lsth/72" | bc)
  nout=3
  nhstar=3
  nhsinc=7200
  time_fcst=$(echo "scale=5; $rnday_restart*86400" | bc)
  restart=$(($restart+1))
  time_restart=$(printf "%.0f" "$time_fcst")
  echo $restart $time_restart $touts $toutf $DATA > retime.out 
  cpfs retime.out $COMOUTrerun/${RUN}_retime.out

  cpreq $FIXstofs/${RUN}_surf.15 ${RUN}_fort.15
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
     echo "FATAL ERROR: Surface frocing forecast2 input file did not exist"
     err_exit
  else
     echo "Surface forcing forecast2 input file existed"
  fi

# --------------------------------------------------------------------------- #
# 5.  Execute stofs_2d_glo_adcprep for surface forcing forecast2

  export pgm="stofs_2d_glo_adcprep for surface forcing forecast2"
  . prep_step
  startmsg
  if [ ! -s ${RUN}_${ncpu}.tar.gz ]; then
     mpiexec -n 1 -ppn 1 adcprep --np $ncpu --partmesh >> $pgmout 2>errfile
     export err=$?; err_chk
     mpiexec -n 1 -ppn 1 adcprep --np $ncpu --prepall >> $pgmout 2>errfile
     export err=$?; err_chk
     filelist="partmesh.txt PE*/fort.14 PE*/fort.18 PE*/fort.13 PE*/fort.24 PE*/elev_stat.151 PE*/vel_stat.151"
     tar cvzf ${RUN}_${ncpu}.tar.gz $filelist
     export err=$?; err_chk
     cpfs ${RUN}_${ncpu}.tar.gz $COMGES/.
  else
     mpiexec -n 1 -ppn 1 adcprep --np $ncpu --prep15 >> $pgmout 2>errfile
     export err=$?; err_chk
  fi

# --------------------------------------------------------------------------- #
# 6.  Execute stofs_2d_glo_padcirc for surface frocing forecast2 

  export pgm="stofs_2d_glo_padcirc for surface frocing forecast2"
  . prep_step
  startmsg
  mpiexec -n $ncpu -ppn ${PPN} --cpu-bind core padcirc >> $pgmout 2>adcirc.err
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
     cpfs fort.68.nc ${RUN}.surf.68.nc
  else
     cpfs fort.67.nc ${RUN}.surf.68.nc
  fi

  if [ $SENDCOM = YES ]; then
     echo "Copying fort.61.nc to    $COMOUT/${RUN}.${cycle}.points.cwl.nc"
     cpfs fort.61.nc                $COMOUT/${RUN}.${cycle}.points.cwl.nc
     echo "Copying fort.61.nc as    $COMOUT/${RUN}.${cycle}.points.cwl.noanomaly.nc"
     cpfs fort.61.nc                $COMOUT/${RUN}.${cycle}.points.cwl.noanomaly.nc
     echo "Copying fort.62.nc to    $COMOUT/${RUN}.${cycle}.points.cwl.vel.nc"
     cpfs fort.62.nc                $COMOUT/${RUN}.${cycle}.points.cwl.vel.nc
     echo "Copying fort.63.nc to    $COMOUT/${RUN}.${cycle}.fields.cwl.nc"
     cpfs fort.63.nc                $COMOUT/${RUN}.${cycle}.fields.cwl.nc
     echo "Copying fort.63.nc as    $COMOUT/${RUN}.${cycle}.fields.cwl.noanomaly.nc"
     cpfs fort.63.nc                $COMOUT/${RUN}.${cycle}.fields.cwl.noanomaly.nc
     echo "Copying fort.64.nc to    $COMOUT/${RUN}.${cycle}.fields.cwl.vel.nc"
     cpfs fort.64.nc                $COMOUT/${RUN}.${cycle}.fields.cwl.vel.nc
     echo "Copying maxele.63.nc to  $COMOUT/${RUN}.${cycle}.fields.cwl.maxele.nc"
     cpfs maxele.63.nc              $COMOUT/${RUN}.${cycle}.fields.cwl.maxele.nc
     echo "Copying maxele.63.nc as  $COMOUT/${RUN}.${cycle}.fields.cwl.maxele.noanomaly.nc"
     cpfs maxele.63.nc              $COMOUT/${RUN}.${cycle}.fields.cwl.maxele.noanomaly.nc
     echo "Copying maxvel.63.nc to  $COMOUT/${RUN}.${cycle}.fields.cwl.maxvel.nc"
     cpfs maxvel.63.nc              $COMOUT/${RUN}.${cycle}.fields.cwl.maxvel.nc
     echo "Copying maxwvel.63.nc to $COMOUT/${RUN}.${cycle}.fields.cwl.maxwvel.nc"
     cpfs maxwvel.63.nc             $COMOUT/${RUN}.${cycle}.fields.cwl.maxwvel.nc
  fi

  msg="Completing stofs_2d_glo_surf_forecast2 script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of stofs_2d_glo_surf_forecast2.sh script --------------------------------- #
