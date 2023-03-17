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
#                                                                 Dec, 2011   #
#                                                                 Dec, 2013   #
#                                                                 May, 2016   #
#                                                                 Jun, 2020   #
#                                                                 Apr, 2021   #
#                                                                 Jun, 2022   #
#                                                                             #
###############################################################################
# Start of exstofs_2d_glo_post_ncdiff.sh.ecf script ------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_post_ncdiff script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

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
  export nback=20

  time_now=$YMDH
  time_end=`$NDATE $lsth $YMDH`

# --------------------------------------------------------------------------- #
# 2.  Get output files from ${COMIN}

  if [[ -f $COMIN/${RUN}.${cycle}.points.cwl.nc ]]; then
     cpreq ${COMIN}/${RUN}.${cycle}.points.cwl.nc cwl.fort.61.nc
     cpreq ${COMIN}/${RUN}.${cycle}.points.htp.nc htp.fort.61.nc
     cpreq ${COMIN}/${RUN}.${cycle}.fields.cwl.nc cwl.fort.63.nc
     cpreq ${COMIN}/${RUN}.${cycle}.fields.htp.nc htp.fort.63.nc
  fi

  if [[ ! -f cwl.fort.63.nc && ! -f htp.fort.63.nc ]]; then
     echo "FATAL ERROR: cwl.fort.63.nc and htp.fort.63.nc files did not existed"
     err_exit
  else
     echo "cwl.fort.63.nc and htp.fort.63.nc files existed"
  fi
  
# --------------------------------------------------------------------------- #
# 3.  Execute ncdiff to compute sub-tidal water level

  ncdiff cwl.fort.61.nc htp.fort.61.nc swl.fort.61.nc
  export err=$?; err_chk
  ncdiff -v zeta cwl.fort.63.nc htp.fort.63.nc swl.fort.63.nc
  export err=$?; err_chk
  ncks -A -v x,y cwl.fort.61.nc swl.fort.61.nc
  export err=$?; err_chk
  ncks -A -v x,y cwl.fort.63.nc swl.fort.63.nc
  export err=$?; err_chk
  
  if [ $SENDCOM = YES ]; then
     echo "Copying fort.61.nc to $COMOUT/${RUN}.${cycle}.points.swl.nc"
     cpfs swl.fort.61.nc         $COMOUT/${RUN}.${cycle}.points.swl.nc
     echo "Copying fort.63.nc to $COMOUT/${RUN}.${cycle}.fields.swl.nc"
     cpfs swl.fort.63.nc         $COMOUT/${RUN}.${cycle}.fields.swl.nc
  fi

  if [ $SENDDBN = YES ]; then
     $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job $COMOUT/${RUN}.${cycle}.points.swl.nc
     $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job $COMOUT/${RUN}.${cycle}.fields.swl.nc
  fi

  msg="Completing stofs_2d_glo_post_ncdiff script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of exstofs_2d_glo_post_ncdiff.sh.ecf script --------------------------- #
