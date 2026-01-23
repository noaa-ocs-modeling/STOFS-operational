#!/bin/bash
#$1 is folder

#cd /home1/06923/hyu05/work/oper_3D_Pac/rtofs/src/oper_script
###cd /sciclone/schism10/hyu05/NOAA_Pacific/rtofs_global_subset/frontera/rtofs/src/oper_script
dir_wk=${DATA_prep_rtofs}
cd ${dir_wk}/src/oper_script
./link.sh $1
#cd /home1/06923/hyu05/work/oper_3D_Pac/rtofs/$1/3dth
###cd /sciclone/schism10/hyu05/NOAA_Pacific/rtofs_global_subset/frontera/rtofs/$1/3dth
cd ${dir_wk}/$1/3dth
ln -sf ../SSH_1.nc .
ln -sf ../TS_1.nc .
ln -sf ../UV_1.nc .
###./gen_3Dth_from_hycom.exe &
${EXECstofs3d}/stofs_3d_pac_gen_3Dth_from_hycom_new 
#cd /home1/06923/hyu05/work/oper_3D_Pac/rtofs/$1/nudge
###cd /sciclone/schism10/hyu05/NOAA_Pacific/rtofs_global_subset/frontera/rtofs/$1/nudge
cd ${dir_wk}/$1/nudge
ln -sf ../SSH_1.nc .
ln -sf ../TS_1.nc .
ln -sf ../UV_1.nc .
###./gen_nudge_from_hycom &
${EXECstofs3d}/stofs_3d_pac_gen_nudge_from_hycom 
wait

