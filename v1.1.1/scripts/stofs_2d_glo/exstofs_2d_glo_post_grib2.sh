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
# Start of exstofs_2d_glo_post_grib2.sh.ecf script -------------------------- #
# 0.  Preparation
# 0.a Basic modes of operation

  seton='-xa'
  setoff='+xa'
  set $seton

  msg="Starting stofs_2d_glo_post_grib2 script"
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
     cpreq ${COMIN}/${RUN}.${cycle}.points.swl.nc swl.fort.61.nc
     cpreq ${COMIN}/${RUN}.${cycle}.fields.cwl.nc cwl.fort.63.nc
     cpreq ${COMIN}/${RUN}.${cycle}.fields.htp.nc htp.fort.63.nc
     cpreq ${COMIN}/${RUN}.${cycle}.fields.swl.nc swl.fort.63.nc
  fi

  if [[ ! -f cwl.fort.63.nc && ! -f htp.fort.63.nc ]]; then
     echo "FATAL ERROR: cwl.fort.63.nc and htp.fort.63.nc files did not existed"
     err_exit
  else
     echo "cwl.fort.63.nc and htp.fort.63.nc files existed"
  fi
  
# --------------------------------------------------------------------------- #
# 3.  execute stofs_2d_glo_netcdf2shef.sh for all water level
#
  export pgm="stofs_2d_glo_netcdf2shef"
  . prep_step
  startmsg
  for type in cwl htp swl; do
      $EXECstofs/${RUN}_netcdf2shef con $type $YMDH ${type}.fort.61.nc $FIXstofs/${RUN}_msl2mllw >> $pgmout 2>errfile
      export err=$?; err_chk
#      pac_exclude_list="137 140 145 151 153 157 158 162 178" there are no NWS ID
#      for sta in $(seq -f "%03g" 1 136) 138 139 $(seq 141 144) $(seq 146 150) 152; do ! Include Pacific stations for the future upgrade
      for sta in $(seq -f "%03g" 1 128); do
          cat fort.5${sta} >> ${RUN}.${cycle}.points.${type}.shef
      done
#      for sta in $(seq 154 156) $(seq 159 161) $(seq 163 177) $(seq 179 208) $(seq 225 229); do ! Include Pacific stations for the future upgrade
      for sta in $(seq 225 229); do
          cat fort.5${sta} >> ${RUN}.${cycle}.points.${type}.shef
      done
#      for sta in $(seq 559 833); do ! Include additonal NWS ID stations for the future upgrade
#          cat fort.5${sta} >> ${RUN}.${cycle}.points.${type}.shef
#      done
      rm fort.5*
  done
  
# 3.a create awips shef output
  export pgm="makentc"
  . prep_step
  startmsg
  for type in cwl htp swl; do
      sed '1d' ${RUN}.${cycle}.points.${type}.shef > tmp.dat
      if [ ${type} = "cwl" ]; then
         $USHstofs/make_ntc_file.pl SXUS02 KWBM ${YMDH} NONE tmp.dat shef_${RUN}.${cycle}.points.${type}
         export err=$?; err_chk
      elif [ ${type} = "htp" ]; then
         $USHstofs/make_ntc_file.pl SXUS01 KWBM ${YMDH} NONE tmp.dat shef_${RUN}.${cycle}.points.${type}
         export err=$?; err_chk
      else
         $USHstofs/make_ntc_file.pl SXUS03 KWBM ${YMDH} NONE tmp.dat shef_${RUN}.${cycle}.points.${type}
         export err=$?; err_chk
      fi
      rm tmp.dat
  done

  for type in cwl htp swl; do
      if [ $SENDCOM = YES ]; then
         cpfs ${RUN}.${cycle}.points.${type}.shef $COMOUT/.
      fi
      if [ $SENDDBN = YES ]; then
         cpfs shef_${RUN}.${cycle}.points.${type} $COMOUTwmo/.
      fi
  done    
 
# #####################################
# # Distribute stofs products to AWIPS
# #####################################
# 3.b  Distribute STOFS products to AWIPS
  if [ $SENDDBN = YES ]; then
     for type in cwl htp swl
     do
        $DBNROOT/bin/dbn_alert MODEL STOFS_SHEF $job $COMOUT/${RUN}.${cycle}.points.${type}.shef
        export err=$?; err_chk
     done
  fi   
  if [ $SENDDBN_NTC = YES ]; then
     for type in cwl htp swl
     do
        $DBNROOT/bin/dbn_alert NTC_LOW $NET $job $COMOUTwmo/shef_${RUN}.${cycle}.points.${type}
        export err=$?; err_chk
     done
  fi
   
# --------------------------------------------------------------------------- #
# 4.  execute stofs_2d_glo_netcdf2grib.sh for all grid
#
  export pgm="stofs_2d_glo_netcdf2grib"
  . prep_step
  startmsg
  for type in cwl htp swl; do
      if [ -f poescript ]; then
         rm poescript
      fi

      echo "$EXECstofs/${RUN}_netcdf2grib conus $type $YMDH $FIXstofs/${RUN}_conus.east.mask ${type}.fort.63.nc 3000 >> $pgmout.1 2>errfile" >> poescript
      echo "$EXECstofs/${RUN}_netcdf2grib conus $type $YMDH $FIXstofs/${RUN}_conus.west.mask ${type}.fort.63.nc 4000 >> $pgmout.2 2>errfile" >> poescript
      echo "$EXECstofs/${RUN}_netcdf2grib puertori $type $YMDH $FIXstofs/${RUN}_puertori.mask ${type}.fort.63.nc 5000 >> $pgmout.3 2>errfile" >> poescript
      echo "$EXECstofs/${RUN}_netcdf2grib alaska $type $YMDH $FIXstofs/${RUN}_alaska.mask ${type}.fort.63.nc 6000 >> $pgmout.4 2>errfile" >> poescript
      echo "$EXECstofs/${RUN}_netcdf2grib hawaii $type $YMDH $FIXstofs/${RUN}_hawaii.mask ${type}.fort.63.nc 7000 >> $pgmout.5 2>errfile" >> poescript
      echo "$EXECstofs/${RUN}_netcdf2grib guam $type $YMDH $FIXstofs/${RUN}_guam.mask ${type}.fort.63.nc 8000 >> $pgmout.6 2>errfile" >> poescript
      echo "$EXECstofs/${RUN}_netcdf2grib northpacific $type $YMDH $FIXstofs/${RUN}_northpacific.mask ${type}.fort.63.nc 9000 >> $pgmout.7 2>errfile" >> poescript

      chmod 775 poescript
      mpiexec -n 7 -ppn 7 --cpu-bind core cfp poescript
      export err=$?; err_chk
      cat $pgmout.* >> $pgmout

      for fhr in $(seq -f "%03g" 0 180); do
          cat fort.3${fhr} >> ${RUN}.${cycle}.conus.east.f${fhr}.grib2
          cat fort.3${fhr} >> ${RUN}.${cycle}.conus.east.${type}.grib2
          cat fort.4${fhr} >> ${RUN}.${cycle}.conus.west.f${fhr}.grib2
          cat fort.4${fhr} >> ${RUN}.${cycle}.conus.west.${type}.grib2
          cat fort.5${fhr} >> ${RUN}.${cycle}.puertori.f${fhr}.grib2
          cat fort.5${fhr} >> ${RUN}.${cycle}.puertori.${type}.grib2
          cat fort.6${fhr} >> ${RUN}.${cycle}.alaska.f${fhr}.grib2
          cat fort.6${fhr} >> ${RUN}.${cycle}.alaska.${type}.grib2
          cat fort.7${fhr} >> ${RUN}.${cycle}.hawaii.f${fhr}.grib2
          cat fort.7${fhr} >> ${RUN}.${cycle}.hawaii.${type}.grib2
          cat fort.8${fhr} >> ${RUN}.${cycle}.guam.f${fhr}.grib2
          cat fort.8${fhr} >> ${RUN}.${cycle}.guam.${type}.grib2
          cat fort.9${fhr} >> ${RUN}.${cycle}.northpacific.f${fhr}.grib2
          cat fort.9${fhr} >> ${RUN}.${cycle}.northpacific.${type}.grib2
      done
      rm fort.3* fort.4* fort.5* fort.6* fort.7* fort.8* fort.9*
  done
 
# --------------------------------------------------------------------------- #
# 5.  Send output from stofs_2d_glo_netcdf2grib2.sh to COM if requested

  if [ $SENDCOM = YES ]; then
     for grid in conus.east conus.west puertori alaska hawaii guam northpacific; do
         for fhr in $(seq -f "%03g" 0 180); do
             cpfs ${RUN}.${cycle}.${grid}.f${fhr}.grib2    $COMOUT/.
####################################
# Alert stofs grib2 files
#####################################
             if [ $SENDDBN = YES ]; then
                $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job $COMOUT/${RUN}.${cycle}.${grid}.f${fhr}.grib2
                export err=$?; err_chk
             fi
        done
    done
  fi

######################
# Release GEMPAK jobs
#######################
  ecflow_client --event grib2_ready

# --------------------------------------------------------------------------- #
# 6.  Process STOFS products with WMO headers

  export pgm="tocgrib2"
  . prep_step
  startmsg

  for grid in conus.east conus.west puertori alaska hawaii guam northpacific; do
     for type in cwl htp swl; do
         export FORT11=${RUN}.${cycle}.${grid}.${type}.grib2
         export FORT31=" "
         export FORT51=grib2_${RUN}.${cycle}.${grid}.${type}
    
         tocgrib2 < $PARMstofs/grib2_${RUN}_${grid}_${type} >> $pgmout 2> errfile
         err=$?;export err ;err_chk
         echo " error from tocgrib2=",$err
     done
  done

# --------------------------------------------------------------------------- #
# 7. Save and clean up files
# 7.a Send files to com if requested

  if [ $SENDCOM = YES ]; then
     for grid in conus.east conus.west puertori alaska hawaii guam northpacific; do
         for type in cwl htp swl; do
             cpfs ${RUN}.${cycle}.${grid}.${type}.grib2               $COMOUT/.
############################
# Send files to COMOUTwmo
############################
# 7.b Send files to COMOUTwmo if requested
             cpfs grib2_${RUN}.${cycle}.${grid}.${type}            $COMOUTwmo/.
         done
     done
  fi
# ######################################
# # Distribute stofs products to AWIPS
# #####################################
# 7.c  Distribute STOFS products to AWIPS
  if [ $SENDDBN_NTC = "YES" ];then
#      for grid in conus.east conus.west puertori alaska hawaii guam northpacific; do
      for grid in conus.east conus.west puertori alaska hawaii; do
         for type in cwl htp swl; do
              $DBNROOT/bin/dbn_alert NTC_LOW $NET $job $COMOUTwmo/grib2_${RUN}.${cycle}.${grid}.${type}
              export err=$?; err_chk
         done
      done
      # JY - 0527: for grid in guam northpacific; do
      for grid in guam northpacific conus.east conus.west puertori alaska hawaii; do
         for type in cwl htp swl; do
              $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job $COMOUT/${RUN}.${cycle}.${grid}.${type}.grib2
              export err=$?; err_chk
         done
      done
  fi

  msg="Completing stofs_2d_glo_post_grib2 script"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

# End of exstofs_2d_glo_post_grib2.sh.ecf script ---------------------------- #
