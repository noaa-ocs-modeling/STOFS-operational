#!/bin/bash

dir_wk=${DATA_prep_rtofs}
#cd /home1/06923/hyu05/work/oper_3D_Pac/rtofs/$1
###cd /sciclone/schism10/hyu05/NOAA_Pacific/rtofs_global_subset/frontera/rtofs/$1
echo "$pwd"
#echo "${dir_wk}/$1"

#cd ${dir_wk}/$1

#Clean previous check for rtofs link
./sinkRTOFS_now.sh $1 $2 $3 $4 $5
./convert_rtofs_global.sh $1
rm -f ./?_*.nc
