#!/bin/bash
#This script sink global with specify index for 12z start operation
#cd /home1/06923/hyu05/work/oper_3D_Pac/rtofs/$1
###cd /sciclone/schism10/hyu05/NOAA_Pacific/rtofs_global_subset/frontera/rtofs/$1
dir_wk=${DATA_prep_rtofs}
cd ${dir_wk}/$1

  yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
  yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}
###idate0=$(/bin/date --date='0 days ago' +%Y%m%d)
idate0=${yyyymmdd_today}

###SSH
for ((iday=-1;iday<=2; iday=iday+1))
    do
      idate=$(date -d"$idate0 + $iday day" +"%Y%m%d")
      #echo SSH $idate
      ncks -O -d X,$2,$3 -d Y,$4,$5 ../global/outputs/z_${idate}12.nc -o z_${idate}12.nc
done

###3D vars
ofn=("t" "s" "u" "v")
for ((iday=-1;iday<=3; iday=iday+1))
    do
      idate=$(date -d"$idate0 + $iday day" +"%Y%m%d")
      for str in ${ofn[@]};
          do
          #echo ${str}_${idate}00
          ncks -O -d X,$2,$3 -d Y,$4,$5 ../global/outputs/${str}_${idate}00.nc -o ${str}_${idate}00.nc
      done
done
#derive 12z
for ((iday=-1;iday<=2; iday=iday+1))
    do
      idate1=$(date -d"$idate0 + $iday day" +"%Y%m%d")
      iday2=`expr $iday + 1`
      idate2=$(date -d"$idate0 + $iday2 day" +"%Y%m%d")
      for str in ${ofn[@]};
          do
          #echo ${str} ${idate1} ${idate2}
          ncra -O ${str}_${idate1}00.nc ${str}_${idate2}00.nc ${str}_${idate1}12.nc
      done
done
