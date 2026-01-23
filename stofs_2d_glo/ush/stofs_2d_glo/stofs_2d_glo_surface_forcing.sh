#!/bin/bash
# --------------------------------------------------------------------------- #
# Script stofs_2d_glo_surface_forcing.sh to compute surface forcing for 
# ADCIRC nws=10 
# --------------------------------------------------------------------------- #
# Start of stofs_2d_glo_surface_forcing.sh script --------------------------- #
# 1.  Set times

  set -x
  export date=$PDY
  export YMDH=${PDY}${cyc}

# --------------------------------------------------------------------------- #
# 1.  Prepare GFS interpolation
# 1.a Run getges.sh for nowcast or copy from GFS directory for forecast

  ymdh=$2
  itn=0
  while [ $ymdh -le $3 ]
  do
#     if [ $ymdh -lt $YMDH ]; then
     if [ $ymdh -le $YMDH ]; then
        ${USHstofs}/${RUN}_getges.sh -t sfgges -v $ymdh -n gfs > getges.out 2> getges.err
        export err=$?; err_chk
        echo "====================="
        echo "DEBUG-ush: cat getges.out"
        cat getges.out
        echo "DEBUG-ush: end cat"
        echo "====================="
	spec_file=`cat getges.out | awk '{ print $1 }'`
        if [ -f $spec_file ]; then
           specfile_ready=yes
           echo "${spec_file} existed"
        else
           specfile_ready=no
           echo "FATAL ERROR: GFS output does not exist, the surface forcing script stops"
           err_exit
        fi
        rm -f getges.out getges.err
     else
        fcsth=`$NHOUR $ymdh $YMDH`
        fcsth3="$(printf "%03d" $(( 10#$fcsth )) )"
        spec_file=${COMINgfs}/gfs.${cycle}.sfcf${fcsth3}.nc
#  check GFS output files available
        until [ -s $spec_file ]; do
            echo "${spec_file} did not exit yet, wait for until file available" 
            sleep 10
        done
        if [ -f $spec_file ]; then
           specfile_ready=yes
           echo "${spec_file} existed"
        else
           specfile_ready=no
           echo "FATAL ERROR: GFS output does not exist, the surface forcing script stops"
           err_exit
        fi
     fi

# --------------------------------------------------------------------------- #
# 2.  Copy GFS grib2 files and extract vairables 

     if [ -f $spec_file ] && [ $specfile_ready = yes ]; then
        ln -s $spec_file swnd.$ymdh
        ncks -v time,grid_xt,lon,grid_yt,lat,pressfc swnd.$ymdh pressfc.${ymdh}.nc
        ncks -v time,grid_xt,lon,grid_yt,lat,ugrd10m,vgrd10m swnd.$ymdh uvgrd10m.${ymdh}.nc
        ncks -v time,grid_xt,lon,grid_yt,lat,icec swnd.$ymdh icec.${ymdh}.nc
        export err=$?; err_chk
     fi
     rm swnd.$ymdh
     
     if [ $1 = "surface3" ]; then
     	ymdh=`$NDATE 3 $ymdh`
     else
     	ymdh=`$NDATE 1 $ymdh`
     fi	
     itn=$(($itn+1))
  done

# 2.a Paste GFS grib2 files to ADCIRC forcing format

  ncecat pressfc.*.nc tmp.221.nc
  export err=$?; err_chk
  ncwa -a time tmp.221.nc fort.221.nc
  export err=$?; err_chk
  ncecat uvgrd10m.*.nc tmp.222.nc
  export err=$?; err_chk
  ncwa -a time tmp.222.nc fort.222.nc
  export err=$?; err_chk
  ncecat icec.*.nc tmp.225.nc
  export err=$?; err_chk
  ncwa -a time tmp.225.nc fort.225.nc
  export err=$?; err_chk
  rm pressfc.*.nc uvgrd10m.*.nc icec.*.nc tmp.*

# End of stofs_2d_glo_surface_foricng.sh script ----------------------------- #
