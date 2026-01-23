#!/bin/bash
###############################################################################
#                                                                             #
# This script is the preprocessor for the STOFS that runs under the ADCIRC    #
# model. This script is the tide-only forecast for the STOFS.                 #
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
# Start of exstofs_2d_glo_tide_forecast1.sh script -------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_tide_forecast1 scripts"
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
# 2.  Get hotstart and tide forcing files 

  if [ ! -f $COMOUTrerun/${RUN}_tide.68.nc ]; then
     cpreq $COMOUT/${RUN}.${cycle}.hotstart ${time_now}.hotstart
  else
     cpreq $COMOUTrerun/${RUN}_tide.68.nc   ${time_now}.hotstart
  fi
  cpreq $COMOUTrerun/${RUN}_tide.61.nc   fort.61.nc
  cpreq $COMOUTrerun/${RUN}_tide.63.nc   fort.63.nc

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
# 4.  Set time and file for tide forecast1
# 4.a Set parameters for tide forecast input file

  cpreq $COMOUTrerun/${RUN}_hottime.out  hottime.out
  hotstart=$(grep [0-9]  hottime.out | awk '{print $1}') 
  time_hotstart=$(grep [0-9] hottime.out | awk '{print $2}')
  touts=$(grep [0-9] hottime.out | awk '{print $3}')
  toutf=$(grep [0-9] hottime.out | awk '{print $4}')
  tmpd=$(grep -n "${RUN}" hottime.out | awk '{print $5}')
  echo $hotstart $time_hotstart $touts $toutf $tmpd

  if [ `expr $(echo "scale=0; $time_hotstart/($nowh*3600)" | bc) % 2` = 0 ]; then
     ihot=368
     cpreq ${time_now}.hotstart fort.68.nc
  else
     ihot=367
     cpreq ${time_now}.hotstart fort.67.nc
  fi
 
  fcstd=$(echo "scale=5; ($time_hotstart)/86400" | bc)
  rnday_hotstart=$(echo "scale=5; $fcstd+$lsth/36" | bc)
  nout=3
  nhstar=3
  nhsinc=3600
  time_fcst=$(echo "scale=0; $rnday_hotstart*86400" | bc)
  hotstart=$(($hotstart+1))
  time_hotstart=$(printf "%.0f" "$time_fcst")
  echo $hotstart $time_hotstart $touts $toutf $DATA > hottime.out
  cpfs hottime.out $COMOUTrerun/${RUN}_hottime.out

  cpreq $FIXstofs/${RUN}_tide.15 ${RUN}_fort.15
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
      -e "s/rnday/$rnday_hotstart/g" \
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
     echo "FATAL ERROR: Tide forecast1 input file did not exist"
     err_exit
  else
     echo "Tide forecast1 input file existed"
  fi
    
# --------------------------------------------------------------------------- #
# 5.  Execute stofs_2d_glo_adcprep for tide forecast1

  export pgm="stofs_2d_glo_adcprep for tide forecast1"
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
# 6.  Execute stofs_2d_glo_padcirc for tide forecast1

  export pgm="stofs_2d_glo_padcirc for tide forecast1"
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
 
  if [ `expr $(echo "scale=0; $time_fcst/($nowh*3600)" | bc) % 2` = 0 ]; then
     cpfs fort.68.nc ${RUN}.tide.68.nc
  else
     cpfs fort.67.nc ${RUN}.tide.68.nc
  fi
	      
  if [ $SENDCOM = YES ]; then
     cpfs fort.61.nc         $COMOUTrerun/${RUN}_tide.61.nc
     cpfs fort.63.nc         $COMOUTrerun/${RUN}_tide.63.nc
     cpfs ${RUN}.tide.68.nc  $COMOUTrerun/${RUN}_tide.68.nc
  fi

  msg="Completing stofs_2d_glo_tide_forecast1 script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of exstofs_2d_glo_tide_forecast1.sh script ---------------------------- #
