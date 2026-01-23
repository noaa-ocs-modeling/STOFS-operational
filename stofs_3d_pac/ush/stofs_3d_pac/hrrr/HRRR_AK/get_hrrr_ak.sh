#!/bin/bash
#Usage: ./get_hrrr.sh 1 00 , download 00z for 1 days ago
#    HRRR only have 48 hours fcst

#cd /sciclone/schism10/hyu05/NOAA_NWM/oper/sflux/GFS

export iyr=$(/bin/date --date="$1 days ago" +%Y)
export imon=$(/bin/date --date="$1 days ago" +%m)
export iday=$(/bin/date --date="$1 days ago" +%d)
export rmyr=$(/bin/date --date="3 days ago" +%Y)
export rmmon=$(/bin/date --date="3 days ago" +%m)
export rmday=$(/bin/date --date="3 days ago" +%d)
export RMDATE=$(/bin/date --date="3 days ago" +%Y%m%d)


export  DTOOL=curl              # wget or curl
export  CYC=$2

#export  SDATE=20180104$CYC
export  SDATE=$iyr$imon$iday$CYC
#export  LONMIN=-135.
#export  LONMAX=-103.
#export  LATMIN=21.5
#export  LATMAX=53
# LON & LAT is not used here!!! get ALL data
#export  PGBRES=0.25
export  ENDHOUR=48
export  INCBASE=1
export  DATADIR=data/$SDATE

# specify ncl
export NCARG_ROOT="/home1/06923/hyu05/opt/ncl"
export NCARG_LIB="/home1/06923/hyu05/opt/ncl/lib"
export PATH=$NCARG_ROOT/bin:$PATH

#specify nco & lib path
export PATH=/home1/apps/intel19/nco/4.9.7/bin:$PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/intel/compilers_and_libraries_2020.1.217/linux/compiler/lib/intel64:/lib64

if [ -f ./data/hrrr_ak_${SDATE}.nc ] 
then
   echo "hrrr_${SDATE}.nc exist!"
else
   ./download_hrrr_ak.sh
   cd $DATADIR
   ncl_convert2nc p* -e grb
#  ln -sf ../../addT* .
   ln -sf /home1/06923/hyu05/work/oper_3D_Pac/sflux/HRRR_AK/addT* .
   ./addT.sh
   if [ $2 -eq 00 ]
   then
       ncrcat -O t*.nc ../hrrr_ak_${SDATE}.nc
       chmod 644 ../hrrr_ak_${SDATE}.nc
   else
      ncrcat -O t*.nc catall.nc
      a=$2
      b=24
      if [ $a -eq 06 ]
      then
         a=6
      fi
      RESULT=$((${a}00/$b))
      r=0"${RESULT:0:-2}.${RESULT: -2}"
      ncap2 -s "time=time+float($r)" catall.nc ../hrrr_ak_${SDATE}.nc
      chmod 644 ../hrrr_ak_${SDATE}.nc
   fi
   cd -
   rm -rf ./data/$SDATE
fi
#rm 3 days ago files
#rm -f ./data/hrrr_ak_${RMDATE}${CYC}.nc
