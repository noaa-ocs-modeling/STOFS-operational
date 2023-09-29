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
# 1.a Define GFS variables

  npp=4
  varname[1]='PRES'
  varname[2]='UGRD'
  varname[3]='VGRD'
  varname[4]='ICEC'
  lev[1]=':surface'
  lev[2]=':10 m above ground'
  lev[3]=':10 m above ground'
  lev[4]=':surface'

# 1.b Run getges.sh for nowcast or copy from GFS directory for forecast

  ymdh=$2
  itn=0
  iext=200
  while [ $ymdh -le $3 ]
  do
     if [ $ymdh -lt $YMDH ]; then
        ${USHstofs}/${RUN}_getges.sh -t sfgges -v $ymdh -n gfs > getges.out
        export err=$?; err_chk
        spec_file=`cat getges.out | awk '{ print $1 }'`
        echo "====================="
        echo "DEBUG-ush: cat getges.out"
        cat getges.out
        echo "DEBUG-ush: end cat"
        echo "====================="
        #rm -f getges.out 
        specfile_ready=yes
     else
        fcsth=`$NHOUR $ymdh $YMDH`
        fcsth3="$(printf "%03d" $(( 10#$fcsth )) )"
        spec_file=${COMINgfs}/gfs.${cycle}.sfluxgrbf${fcsth3}.grib2
        spec_idx=${spec_file}.idx
#  check GFS output files available
        until [ -s $spec_file ] && [ -s $spec_idx ]; do
            echo "${spec_file} did not exit yet, wait for until file available" 
            sleep 10
        done
        if [ -f $spec_file ] && [ -f $spec_idx ]; then
           specfile_ready=yes
        else
           specfile_ready=no
        fi
        echo "${spec_file} existed"
     fi

# --------------------------------------------------------------------------- #
# 2.  Copy GFS grib2 files and extract vairables 

     if [ -f $spec_file ] && [ $specfile_ready = yes ]; then
        cpreq $spec_file swnd.$ymdh
        count=0
        while (( count < $npp ))
        do
           (( count = count + 1 ))
           wgrib2 swnd.$ymdh -s | grep "${varname[count]}${lev[count]}" | wgrib2 -i -order we:ns swnd.$ymdh -text tmp.txt
           export err=$?; err_chk
           if [ -s tmp.txt ]; then
              tail -n +2 tmp.txt > ${ymdh}.${varname[count]}.gfs
           fi	  
        done
        rm -f tmp.txt 
     fi
     rm swnd.$ymdh

# 2.a Paste GFS grib2 files to ADCIRC forcing format

     iextn=$(($iext+3*$itn))
     paste ${ymdh}.${varname[1]}.gfs ${ymdh}.${varname[2]}.gfs ${ymdh}.${varname[3]}.gfs ${ymdh}.${varname[4]}.gfs > fort.$iextn
     export err=$?; err_chk
     ymdh=`$NDATE 3 $ymdh`
     itn=$(($itn+1))
     rm *.gfs
  done

# End of stofs_2d_glo_surface_foricng.sh script ----------------------------- #
