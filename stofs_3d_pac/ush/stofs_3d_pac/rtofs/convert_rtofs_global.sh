#!/bin/bash
# Usage
# convert_rtofs.sh start_date end_date
# example: convert_rtofs.sh 20110101 20110201
#
# This tool requires nco

#export PATH=/home1/apps/intel19/nco/4.9.7/bin:$PATH
#export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/intel/compilers_and_libraries_2020.1.217/linux/compiler/lib/intel64:/lib64/

#cd /home1/06923/hyu05/work/oper_3D_Pac/rtofs/$1
###cd /sciclone/schism10/hyu05/NOAA_Pacific/rtofs_global_subset/frontera/rtofs/$1
dir_wk=${DATA_prep_rtofs}
cd ${dir_wk}/$1

  yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
  yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}
###start=$(/bin/date --date='1 days ago' +%Y%m%d) #1
###end=$(/bin/date --date='-2 days ago' +%Y%m%d) #-2
start=$(date -d"$yyyymmdd_today -1 days" +%Y%m%d) #1
end=$(date -d"$yyyymmdd_today +2 days" +%Y%m%d) #-2


while [[ $start -le $end ]]
do

#  if [ -f ./outputs/SSH_${start}.nc ]
#  then
#    echo "RTOFS SSH exist!"
#  else

     echo "SSH",$start

    #SSH file
     ncatted -O -a _FillValue,ssh,d,, z_${start}12.nc test_ssh_0.nc
     ncap2 -O -s 'where(ssh>10000) ssh=-30000' test_ssh_0.nc test_ssh_01.nc
     ncap2 -O -S ${dir_wk}/src/oper_script/cvtZ_g.nco test_ssh_01.nc test_ssh_1.nc
     ncrename -v Longitude,xlon -v Latitude,ylat -v MT,time test_ssh_1.nc
     ncap2 -O -s 'time=float(time)' test_ssh_1.nc test_ssh_2.nc
     ncks -O -v surf_el,xlon,ylat,ssh,time test_ssh_2.nc -o test_ssh_final.nc
     mv test_ssh_final.nc outputs/SSH_${start}12.nc
     rm -f ./test_ssh_*.nc
#  fi
#  if [ -f ./outputs/ST_${start}.nc ]
#  then
#    echo "RTOFS ST exist!"
#  else
     echo "ST",$start
    #ST file 
     ncks -A -v temperature t_${start}12.nc s_${start}12.nc
     ncap2 -O -S ${dir_wk}/src/oper_script/cvtST_g.nco s_${start}12.nc test1.nc
     ncrename -v Longitude,xlon -v Latitude,ylat -v MT,time -v Depth,depth test1.nc
     ncap2 -O -s 'time=float(time)' test1.nc test2.nc
     mv test2.nc outputs/ST_${start}12.nc
     rm -f ./test1.nc
#  fi
#  if [ -f ./outputs/UV_${start}.nc ]
#  then
#    echo "RTOFS UV exist!"
#  else
     echo "UV",$start
    #UV file
     ncks -A -v u u_${start}12.nc v_${start}12.nc
     ncap2 -O -S ${dir_wk}/src/oper_script/cvtUV_g.nco v_${start}12.nc test1.nc
     ncrename -v Longitude,xlon -v Latitude,ylat -v MT,time -v Depth,depth test1.nc
     ncrename -v u,water_u -v v,water_v test1.nc
     ncap2 -O -s 'time=float(time)' test1.nc test2.nc
     mv test2.nc outputs/UV_${start}12.nc
     rm -f ./test1.nc
#  fi
#   forward date
     start=$(date -d"$start + 1 day" +"%Y%m%d")
done
