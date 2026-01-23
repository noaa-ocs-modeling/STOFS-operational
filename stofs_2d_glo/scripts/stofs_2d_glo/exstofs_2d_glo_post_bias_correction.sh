#!/bin/bash
###############################################################################
#                                                                             #
# This script is the postprocessor for the STOFS that runs under the ADCIR    #
# model. It sets some shell script variables for export to child scripts      #
# and copies some generally used files to the work directory.                 #
# After this the actual preprocessing is performed by the following scripts:  #
#                                                                             #
# Remarks :                                                                   #
#                                                                             #
#                                                                 Sep, 2023   #
#                                                                 Jun, 2025   #
#                                                                             #
###############################################################################
# Start of exstofs_2d_glo_post_bias_correction.sh script -------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_post_bias_correction script"
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
#     time_beg :  begin time of run (normally, -6 hour hindcast or the most recent restart time)
#     time_now :  current time
#     time_end :  ending time of run ($lsth hour forecast)

  export date=$PDY
  export YMDH=${PDY}${cyc}

  time_beg=`$NDATE -6 $YMDH`
  time_now=$YMDH
  time_end=`$NDATE $lsth $YMDH`

 # 2.  Get output files from ${COMIN}

  if [ -f $COMIN/${RUN}.${cycle}.points.cwl.nc ]; then
     cpreq ${COMIN}/${RUN}.${cycle}.points.cwl.nc fort.61.nc
     cpreq ${COMIN}/${RUN}.${cycle}.points.cwl.noanomaly.nc fort.61.noanomaly.nc
     cpreq ${COMIN}/${RUN}.${cycle}.fields.cwl.nc fort.63.nc
     cpreq ${COMIN}/${RUN}.${cycle}.fields.cwl.maxele.noanomaly.nc .
  fi

  if [ ! -f fort.61.nc ] && [ ! -f fort.63.nc ]; then
     echo "FATAL ERROR: fort.6l.nc and fort.63.nc files did not existed"
     err_exit
  else
     echo "fort.61.nc and fort.63.nc files existed"
  fi
# --------------------------------------------------------------------------- #
# 3.  Compute bias correction for each grids

  ln -s $FIXstofs/cloned_stations.csv .
  ln -s $FIXstofs/extracted_stations.txt .
  mpiexec -n $ncpu -ppn ${PPN} python $USHstofs/bias_correction_mpi_v6_selective.py --date $PDY --no-vtk >> $pgmout 2>errfile
  export err=$?; err_chk
 
# --------------------------------------------------------------------------- #
# 4.  Send files to $COM

  if [ $SENDCOM = YES ]; then
     echo "Copying fort.63.nc to ${RUN}.${cycle}.fields.noanomaly.cwl.nc"
     mv fort.63.nc ${RUN}.${cycle}.fields.noanomaly.cwl.nc
     echo "Copying fort.63.nc to $COMOUT/${RUN}.${cycle}.fields.cwl.nc"
     cpfs levels_with_bias.63.nc         $COMOUT/${RUN}.${cycle}.fields.cwl.nc
     echo "Copying maxele.63.nc to $COMOUT/${RUN}.${cycle}.fields.cwl.maxele.nc"
     cpfs maxele_with_bias.63.nc         $COMOUT/${RUN}.${cycle}.fields.cwl.maxele.nc

     if [ $SENDDBN = YES ]; then
        $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job $COMOUT/${RUN}.${cycle}.fields.cwl.nc
        $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job $COMOUT/${RUN}.${cycle}.fields.noanomaly.cwl.nc
        $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job $COMOUT/${RUN}.${cycle}.fields.maxele.cwl.nc
        $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job $COMOUT/${RUN}.${cycle}.fields.maxele.noanomaly.cwl.nc
     fi
  fi

  msg="Completing stofs_2d_glo_post_bias_correction script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of exstofs_2d_glo_post_bias_correction.sh script --------------------- #
