#!/bin/bash

### th.nc file
#Prepare files
#cd /home1/06923/hyu05/work/oper_3D_Pac/rtofs/final/3dth
###cd /sciclone/schism10/hyu05/NOAA_Pacific/rtofs_global_subset/frontera/rtofs/final/3dth
dir_wk=${DATA_prep_rtofs}
cd ${dir_wk}/final/3dth
rm -f ./$1_*.nc ./test*nc
cp ../../indian_1/3dth/$1.th.nc ./$1_ind1.th.nc
ncrename -v time_series,time_series_ind1 ./$1_ind1.th.nc
cp ../../indian_2/3dth/$1.th.nc ./$1_ind2.th.nc
ncrename -v time_series,time_series_ind2 ./$1_ind2.th.nc
cp ../../pacific_1/3dth/$1.th.nc ./$1_pac1.th.nc
ncrename -v time_series,time_series_pac1 ./$1_pac1.th.nc
cp ../../pacific_2/3dth/$1.th.nc ./$1_pac2.th.nc
ncrename -v time_series,time_series_pac2 ./$1_pac2.th.nc
cp ../../pacific_3/3dth/$1.th.nc ./$1_pac3.th.nc
ncrename -v time_series,time_series_pac3 ./$1_pac3.th.nc

#Choose arctic as base
cp ../../arctic/3dth/$1.th.nc ./$1_base.th.nc
#ncrename -v time_series,time_series_arc ./$1_arc.th.nc

##sink vars
ncks -v time_series_ind1 -A ./$1_ind1.th.nc ./$1_base.th.nc
ncks -v time_series_ind2 -A ./$1_ind2.th.nc ./$1_base.th.nc
ncks -v time_series_pac1 -A ./$1_pac1.th.nc ./$1_base.th.nc
ncks -v time_series_pac2 -A ./$1_pac2.th.nc ./$1_base.th.nc
ncks -v time_series_pac3 -A ./$1_pac3.th.nc ./$1_base.th.nc

##overwrite base var
#nc4 is not supported with origin file, specify new instead
ncap2 -s "where(time_series_ind1 > -99 ) time_series=time_series_ind1" $1_base.th.nc test0.nc
ncap2 -s "where(time_series_ind2 > -99 ) time_series=time_series_ind2" test0.nc test1.nc
ncap2 -s "where(time_series_pac1 > -99 ) time_series=time_series_pac1" test1.nc test2.nc
ncap2 -s "where(time_series_pac2 > -99 ) time_series=time_series_pac2" test2.nc test3.nc
ncap2 -s "where(time_series_pac3 > -99 ) time_series=time_series_pac3" test3.nc test4.nc

##sink final files
ncks -O -v time_series,time_step,time test4.nc ../outputs/$1.th.nc

