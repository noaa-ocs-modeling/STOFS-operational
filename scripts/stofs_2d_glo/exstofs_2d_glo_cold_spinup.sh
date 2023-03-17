#!/bin/bash
###############################################################################
#                                                                             #
# This script is the preprocessor for the STOFS that runs under the ADCIRC    #
# model. This script is run the tidal spin-up for the STOFS.                  #
# It sets some shell script variables for export to child scripts             #
# and copies some generally used files to the work directory.                 #
# After this the actual preprocessing is performed by the following scripts:  #
#                                                                             #
# Remarks :                                                                   #
# - This spin-up runs only at the first operational run, which is             #
#   COLDSTART = YES                                                           #
#                                                                             #
#                                                                 Dec, 2011   #
#                                                                 May, 2016   #
#                                                                 Jun, 2020   #
#                                                                 Apr, 2021   #
#                                                                 JUN, 2022   #
#                                                                             #
###############################################################################
# Start of stofs_2d_glo_cold_spinup.sh.ecf script --------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_cold_spinup scripts"
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

  time_now=$YMDH
  time_end=`$NDATE $lsth $YMDH`

# --------------------------------------------------------------------------- #
# 2.  Copy stofs partmesh, grid, and template files 

  ln -s $FIXstofs/${RUN}_attr fort.13
  ln -s $FIXstofs/${RUN}_grid fort.14
  ln -s $FIXstofs/${RUN}_body fort.24
  ln -s $FIXstofs/${RUN}_rotm fort.rotm
  ln -s $FIXstofs/${RUN}_elev_stat elev_stat.151
  ln -s $FIXstofs/${RUN}_elev_stat vel_stat.151
  cpreq $FIXstofs/${RUN}_prep.15 ${RUN}_fort.15

# 2.b Copy stofs_2d_glo_nod_equi file and tar file

  if [[ -f $COMGES/${RUN}_nod_equi ]]; then
     cpreq $COMGES/${RUN}_nod_equi .
  fi
  if [[ -f $COMGES/${RUN}_${ncpu}.tar.gz ]]; then
     cpreq $COMGES/${RUN}_${ncpu}.tar.gz .
     tar xvzf ${RUN}_${ncpu}.tar.gz
     export err=$?; err_chk
  fi

# --------------------------------------------------------------------------- #
# 3.  Set time and file for tidal spin-up  
# 3.a Set parameters for tidal spin-up input file

  ihot=0
  rnday=$(echo "scale=5; $spinh/24" | bc)
  nout=-5
  touts=0.00000
  toutf=$rnday
  nhstar=5
  nhsinc=1800
  time_beg=`$NDATE -$nowh $time_now`
  time_hotstart=$(echo "$rnday*86400" | bc)

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
      -e "s/rnday/$rnday/g" \
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
     echo "FATAL ERROR: Tidal spin-up input file did not exist"
     err_exit
  else
     echo "Tidal spin-up input file existed"
  fi
          
# --------------------------------------------------------------------------- #
# 4.  Execute stofs_2d_glo_adcprep for tidal spin-up

  export pgm="stofs_2d_glo_adcprep for tidal spin-up"
  . prep_step
  startmsg
  if [[ ! -s ${RUN}_${ncpu}.tar.gz ]]; then
     mpiexec -n 1 -ppn 1 $EXECstofs/${RUN}_adcprep --np $ncpu --partmesh >> $pgmout 2>errfile
     export err=$?; err_chk
     mpiexec -n 1 -ppn 1 $EXECstofs/${RUN}_adcprep --np $ncpu --prepall >> $pgmout 2>errfile
     export err=$?; err_chk
     filelist="partmesh.txt PE*/fort.14 PE*/fort.18 PE*/fort.13 PE*/fort.24 PE*/elev_stat.151 PE*/vel_stat.151"
     tar cvzf ${RUN}_${ncpu}.tar.gz $filelist
     export err=$?; err_chk
     cpfs ${RUN}_${ncpu}.tar.gz $COMGES/.
  else
     mpiexec -n 1 -ppn 1  $EXECstofs/${RUN}_adcprep --np $ncpu --prep15 >> $pgmout 2>errfile
     export err=$?; err_chk
  fi
  
# --------------------------------------------------------------------------- #
# 5.  Execute stofs_2d_glo_padcirc for tidal spin-up

  export pgm="stofs_2d_glo_padcirc for tidal spin-up" 
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
# 6.  Send files to $COM

  hdate=`echo $time_beg | cut -c1-8`
  hcycle=t`echo $time_beg | cut -c9-10`z
  hdir=${COM}/${RUN}.${hdate}

  if [ ! -d $hdir ]; then
     mkdir -p $hdir 
  fi

  if [ `expr $(echo "scale=0; $time_hotstart/($wndh*3600)" | bc) % 2` = 0 ]; then
     cpfs fort.68.nc ${time_beg}.hotstart
     cpfs fort.68.nc ${time_beg}.restart
  else
     cpfs fort.67.nc ${time_beg}.hotstart
     cpfs fort.67.nc ${time_beg}.restart
  fi

  if [ $SENDCOM = YES ]; then
     echo "Copying ${time_beg}.hotstart to $hdir/${RUN}.${hcycle}.hotstart"
     cpfs ${time_beg}.hotstart             $hdir/${RUN}.${hcycle}.hotstart
     echo "Copying ${time_beg}.restart to  $hdir/${RUN}.${hcycle}.restart"
     cpfs ${time_beg}.restart              $hdir/${RUN}.${hcycle}.restart
  fi

  msg="Completing stofs_2d_glo_cold_spinup script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of stofs_2d_glo_cold_spinup.sh.ecf script ----------------------------- #
