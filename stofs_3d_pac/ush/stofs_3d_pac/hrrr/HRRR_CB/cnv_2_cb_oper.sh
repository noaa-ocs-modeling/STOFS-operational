#!/bin/bash
#This script combine GFS,HRRR,HRRR-AK as HRRR-COMBO
#Needs 1 argument to specify date
#Usage: ./cnv_2_cb_oper.sh 0
#On vortex, 1 file took about 15 mins
#On Frontera, 1 file took about 5-8 mins
#Note: nco on Frontera with ver. 4.9.7 has problem for itp
#      Use Mamba nco ver. 5.1.5 to instead 
#      Run this after GFS/HRRR/HRRR_AK files are ready 

#Force to use Mamba
export PATH="/work2/06923/hyu05/frontera/mambaforge/bin:$PATH"

export idate=$(/bin/date --date="$1 days ago" +%Y%m%d)
export rmdate=$(/bin/date --date="3 days ago" +%Y%m%d)
export start=${idate}00


if [ -f ./data/hrrr_comb_${start}.nc ] 
   then
     echo "hrrr_comb_${start}.nc exist!"
else
     echo "rm previous test*nc if exist"
     rm -f ./test*.nc
     # do GFS itp
     echo "GFS itp"
     ncks -d time,0,47 ./GFS/gfs_${start}.nc test1.nc
     ncrename -d lon_0,lon -d lat_0,lat test1.nc
     ncremap -i test1.nc -m weight_gfs.nc -o test1_out.nc 
     ncap2 -s 'lon=float(lon);lat=float(lat)' test1_out.nc
     # do hrrr conus itp & rename
     echo "HRRR itp"
     ncremap -i ./HRRR/hrrr_${start}.nc -m weight_hrrr_us.nc -o test2_out.nc
     ncap2 -s 'lon=float(lon);lat=float(lat)' test2_out.nc
     ncrename -d xgrid_0,lon -d ygrid_0,lat test2_out.nc
     ncrename -v prmsl,prmsl_us -v spfh,spfh_us -v stmp,stmp_us -v uwind,uwind_us -v vwind,vwind_us -v dswrf,dswrf_us -v dlwrf,dlwrf_us -v prate,prate_us test2_out.nc
     #do hrrr ak itp & rename
     echo "HRRR-AK itp"
     ncremap -i ./HRRR_AK/hrrr_ak_${start}.nc -m weight_hrrr_ak.nc -o test3_out.nc
     ncap2 -s 'lon=float(lon);lat=float(lat)' test3_out.nc
     ncrename -d xgrid_0,lon -d ygrid_0,lat test3_out.nc
     ncrename -v prmsl,prmsl_ak -v spfh,spfh_ak -v stmp,stmp_ak -v uwind,uwind_ak -v vwind,vwind_ak -v dswrf,dswrf_ak -v dlwrf,dlwrf_ak -v prate,prate_ak test3_out.nc
     # sink to test1_out.nc
     echo "Sink data as One ncfile"
     ncks -A -v prmsl_us,spfh_us,stmp_us,uwind_us,vwind_us,dswrf_us,dlwrf_us,prate_us test2_out.nc test1_out.nc 
     ncks -A -v prmsl_ak,spfh_ak,stmp_ak,uwind_ak,vwind_ak,dswrf_ak,dlwrf_ak,prate_ak test3_out.nc test1_out.nc 
     # overwrite gfs by us & ak
#    cp test1_out.nc check_out.nc #check nc
     echo "Overwrite field with conus"
     ncap2 -s "where(prmsl_us > 1) prmsl=prmsl_us" test1_out.nc 
     ncap2 -s "where(prmsl_us > 1) spfh=spfh_us" test1_out.nc 
     ncap2 -s "where(prmsl_us > 1) stmp=stmp_us" test1_out.nc 
     ncap2 -s "where(prmsl_us > 1) uwind=uwind_us" test1_out.nc 
     ncap2 -s "where(prmsl_us > 1) vwind=vwind_us" test1_out.nc 
     ncap2 -s "where(prmsl_us > 1) dlwrf=dlwrf_us" test1_out.nc 
     ncap2 -s "where(prmsl_us > 1) dswrf=dswrf_us" test1_out.nc 
     ncap2 -s "where(prmsl_us > 1) prate=prate_us" test1_out.nc 
     echo "Overwrite field with alaska"
     ncap2 -s "where(prmsl_ak > 1) prmsl=prmsl_ak" test1_out.nc 
     ncap2 -s "where(prmsl_ak > 1) spfh=spfh_ak" test1_out.nc 
     ncap2 -s "where(prmsl_ak > 1) stmp=stmp_ak" test1_out.nc 
     ncap2 -s "where(prmsl_ak > 1) uwind=uwind_ak" test1_out.nc 
     ncap2 -s "where(prmsl_ak > 1) vwind=vwind_ak" test1_out.nc 
     ncap2 -s "where(prmsl_ak > 1) dlwrf=dlwrf_ak" test1_out.nc 
     ncap2 -s "where(prmsl_ak > 1) dswrf=dswrf_ak" test1_out.nc 
     ncap2 -s "where(prmsl_ak > 1) prate=prate_ak" test1_out.nc 
     # sink overwrite gfs to data
     echo "Output final ncfile"
     ncks -v prmsl,spfh,stmp,uwind,vwind,dswrf,dlwrf,prate test1_out.nc ./data/hrrr_comb_${start}.nc
     #Clean up
     echo "rm test*nc"
     rm -f ./test*.nc
fi
#Delete old files
#rm -f ./data/hrrr_comb_${rmdate}00.nc
