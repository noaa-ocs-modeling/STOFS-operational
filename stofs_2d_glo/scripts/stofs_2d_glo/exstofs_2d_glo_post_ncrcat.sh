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
#                                                                 Jun, 2025   #
#                                                                             #
###############################################################################
# Start of exstofs_2d_glo_post_ncrcat.sh script ----------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_post_ncrcat script"
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
# 2.  Get output files from ${COMOUTrerun}

  if [ -f $COMOUTrerun/${RUN}_ncst.221.nc ]; then
     ln -s ${COMOUTrerun}/${RUN}_ncst.221.nc ncst.221.nc
     ln -s ${COMOUTrerun}/${RUN}_ncst.222.nc ncst.222.nc
     ln -s ${COMOUTrerun}/${RUN}_ncst.225.nc ncst.225.nc
     ln -s ${COMOUTrerun}/${RUN}_fcst1.221.nc fcst1.221.nc
     ln -s ${COMOUTrerun}/${RUN}_fcst1.222.nc fcst1.222.nc
     ln -s ${COMOUTrerun}/${RUN}_fcst1.225.nc fcst1.225.nc
     ln -s ${COMOUTrerun}/${RUN}_fcst2.221.nc fcst2.221.nc
     ln -s ${COMOUTrerun}/${RUN}_fcst2.222.nc fcst2.222.nc
     ln -s ${COMOUTrerun}/${RUN}_fcst2.225.nc fcst2.225.nc
  else
     echo "FATAL ERROR: GFS surface forcing does not exist"
     err_exit
  fi
  
# --------------------------------------------------------------------------- #
# 3.  Execute ncrcat to combine all forcing file 

  ncrcat ncst.221.nc fcst1.221.nc fcst2.221.nc fort.221.nc
  export err=$?; err_chk
  ncrcat ncst.222.nc fcst1.222.nc fcst2.222.nc fort.222.nc
  export err=$?; err_chk
  ncrcat ncst.225.nc fcst1.225.nc fcst2.225.nc fort.225.nc
  export err=$?; err_chk
  if [ $SENDCOM = YES ]; then
     echo "Copying fort.221.nc to   $COMOUT/${RUN}.${cycle}.pressfc.nc"
     cpfs fort.221.nc               $COMOUT/${RUN}.${cycle}.pressfc.nc
     echo "Copying fort.222.nc to   $COMOUT/${RUN}.${cycle}.uvgrd10m.nc"
     cpfs fort.222.nc               $COMOUT/${RUN}.${cycle}.uvgrd10m.nc
     echo "Copying fort.225.nc to   $COMOUT/${RUN}.${cycle}.icec.nc"
     cpfs fort.225.nc               $COMOUT/${RUN}.${cycle}.icec.nc
  fi

  msg="Completing stofs_2d_glo_post_ncrcat script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of exstofs_2d_glo_post_ncrcat.sh script ------------------------------ #
