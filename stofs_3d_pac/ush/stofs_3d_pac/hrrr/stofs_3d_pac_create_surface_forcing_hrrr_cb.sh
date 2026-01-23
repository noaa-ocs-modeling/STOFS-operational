#!/bin/bash

############################################################################
#  Name: stofs_3d_pac_create_surface_forcing_hrrr.sh                       # 
#  This script read the NCEP/HRRR data to create the HRRR based surface    #
#  forcing files, stofs_3d_pac.t12z.hrrr.{air,prc,rad}.nc for the nowcast  # 
#  and forecast simuations.                                                #
#                                                                          #
#  Remarks:                                                                #
#                                                        September, 2022   #
############################################################################

# ---------------------------> Begin ...
# set -x

echo 'The script stofs_3d_pac_create_surface_forcing_hrrr_cb.sh started at UTC' `date -u +%Y%m%d%H`


# ---------------------------> directory/file names
  dir_wk=${DATA_prep_hrrr}/
  cd $dir_wk/HRRR_CB


# ---------------------------> copy script to the directory

  pgmout=pgmout_hrrr_cb.$$


# ---------------------------> Global Variables
  fn_nco_update_time_varName=${FIXstofs3d}/stofs_3d_pac_hrrr_input_nco_update_var.nco

  fn_hrrr_rad_schism=sflux_rad_2.0001.nc
  fn_hrrr_rad_date_tag=${RUN}.hrrr.rad.nfcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc
  fn_hrrr_rad_std=${RUN}.${cycle}.hrrr.rad.nc

  fn_hrrr_prc_schism=sflux_prc_2.0001.nc
  fn_hrrr_prc_date_tag=${RUN}.hrrr.prc.nfcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc
  fn_hrrr_prc_std=${RUN}.${cycle}.hrrr.prc.nc

  fn_hrrr_air_schism=sflux_air_2.0001.nc
  fn_hrrr_air_date_tag=${RUN}.hrrr.air.nfcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc
  fn_hrrr_air_std=${RUN}.${cycle}.hrrr.air.nc


# --------------------------> Region of interest, get all alaska data
###  LONMIN=-135.
###  LONMAX=-103.
###  LATMIN=21.5
###  LATMAX=53

# --------------------------> dates
  yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
  yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}
  
# --------------------------> dates

#This script combine GFS,HRRR,HRRR-AK as HRRR-COMBO
#Needs 1 argument to specify date
#Usage: ./cnv_2_cb_oper.sh 0
#On vortex, 1 file took about 15 mins
#On Frontera, 1 file took about 5-8 mins
#Note: nco on Frontera with ver. 4.9.7 has problem for itp
#      Use Mamba nco ver. 5.1.5 to instead 
#      Run this after GFS/HRRR_US/HRRR_AK files are ready 

#Force to use Mamba
###export PATH="/work2/06923/hyu05/frontera/mambaforge/bin:$PATH"

###export idate=$(/bin/date --date="$1 days ago" +%Y%m%d)
###export rmdate=$(/bin/date --date="3 days ago" +%Y%m%d)
###export start=${idate}00


     rm -f ./test*.nc
     # ------------------- do GFS itp
     echo "GFS itp"
     ncks -d time,0,72 ../../gfs/gfs_merge_v1.nc test1.nc
     ncrename -d longitude,lon -d latitude,lat test1.nc
     ###ncrename -d lon_0,lon -d lat_0,lat test1.nc
     ncremap -i test1.nc -m weight_gfs.nc -o test1_out.nc 
     ncap2 -s 'lon=float(lon);lat=float(lat)' test1_out.nc
	cp -rp  test1_out.nc  test1_gfs_out.nc
     # ----------------------- do hrrr conus itp & rename
     echo "HRRR itp"
     ncremap -i ../HRRR_US/sflux_rad_2.0001.nc -m weight_hrrr_us.nc -o test2_out.nc
     ###hrrr_${start}.nc -m weight_hrrr_us.nc -o test2_out.nc
     ncap2 -s 'lon=float(lon);lat=float(lat)' test2_out.nc
     ncrename -d x,lon -d y,lat test2_out.nc
     ncrename -v prmsl,prmsl_us -v spfh,spfh_us -v stmp,stmp_us -v uwind,uwind_us -v vwind,vwind_us -v dswrf,dswrf_us -v dlwrf,dlwrf_us -v prate,prate_us test2_out.nc
	cp -rp  test2_out.nc  test2_hrrr_us_out.nc
     # ------------------ do hrrr ak itp & rename
     echo "HRRR-AK itp"
     ncremap -i ../HRRR_AK/sflux_rad_2.0001.nc -m weight_hrrr_ak.nc -o test3_out.nc
     ncap2 -s 'lon=float(lon);lat=float(lat)' test3_out.nc
     ncrename -d x,lon -d y,lat test3_out.nc
     ncrename -v prmsl,prmsl_ak -v spfh,spfh_ak -v stmp,stmp_ak -v uwind,uwind_ak -v vwind,vwind_ak -v dswrf,dswrf_ak -v dlwrf,dlwrf_ak -v prate,prate_ak test3_out.nc
     	cp -rp  test3_out.nc  test3_hrrr_ak_out.nc
     # ------------- sink to test1_out.nc
     echo "Sink data as One ncfile"
     ncks -A -v prmsl_us,spfh_us,stmp_us,uwind_us,vwind_us,dswrf_us,dlwrf_us,prate_us test2_out.nc test1_out.nc 
     ncks -A -v prmsl_ak,spfh_ak,stmp_ak,uwind_ak,vwind_ak,dswrf_ak,dlwrf_ak,prate_ak test3_out.nc test1_out.nc 
     # ---------------------- overwrite gfs by us & ak
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
     # --------------- sink overwrite gfs to data
     echo "Output final ncfile"
###     ncks -v prmsl,spfh,stmp,uwind,vwind,dswrf,dlwrf,prate test1_out.nc ./data/hrrr_comb_${start}.nc
     ncks -O -v prmsl,spfh,stmp,uwind,vwind,dswrf,dlwrf,prate test1_out.nc ./sflux_rad.0001.nc
     pwd
###     ln -sf ./sflux_rad.0001.nc ../${fn_hrrr_rad_schism}
     echo `pwd`
     echo 'link, check directory'
     ln -sf $dir_wk/HRRR_CB/sflux_rad.0001.nc $dir_wk/${fn_hrrr_rad_schism}
     ln -sf $dir_wk/HRRR_CB/sflux_rad.0001.nc $dir_wk/${fn_hrrr_prc_schism}
     ln -sf $dir_wk/HRRR_CB/sflux_rad.0001.nc $dir_wk/${fn_hrrr_air_schism}
###     ln -sf ./sflux_rad.0001.nc ../${fn_hrrr_air_schism}
     cpreq -pf $dir_wk/HRRR_CB/sflux_rad.0001.nc ${COMOUTrerun}/${fn_hrrr_rad_std}
     cpreq -pf $dir_wk/HRRR_CB/sflux_rad.0001.nc ${COMOUTrerun}/${fn_hrrr_prc_std}
     cpreq -pf $dir_wk/HRRR_CB/sflux_rad.0001.nc ${COMOUTrerun}/${fn_hrrr_air_std}
     #Clean up
     echo "rm test*nc"
     rm ./test1_out.nc
###     rm -f ./test*.nc

#Delete old files
#rm -f ./data/hrrr_comb_${rmdate}00.nc


echo
echo "The script stofs_3d_pac_create_surface_forcing_hrrr_cb.sh completed at date/time: " `date`
echo 

cd ..




