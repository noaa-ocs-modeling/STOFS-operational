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

echo 'The script stofs_3d_pac_create_surface_forcing_hrrr.sh started at UTC' `date -u +%Y%m%d%H`


# ---------------------------> directory/file names
  dir_wk=${DATA_prep_hrrr}/
  mkdir -p $dir_wk
  mkdir -p $dir_wk/HRRR_US
  mkdir -p $dir_wk/HRRR_AK
  mkdir -p $dir_wk/HRRR_CB

  cd $dir_wk

  pgmout=pgmout_hrrr.$$

# ---------------------------> copy script to the directory

cp ${USHstofs3d}/hrrr/weight_gfs.nc ./HRRR_CB/.
cp ${USHstofs3d}/hrrr/weight_hrrr_us.nc ./HRRR_CB/.
cp ${USHstofs3d}/hrrr/weight_hrrr_ak.nc ./HRRR_CB/.
cp ${USHstofs3d}/hrrr/stofs_3d_pac_create_surface_forcing_hrrr_ak.sh .
cp ${USHstofs3d}/hrrr/stofs_3d_pac_create_surface_forcing_hrrr_us.sh .  
cp ${USHstofs3d}/hrrr/stofs_3d_pac_create_surface_forcing_hrrr_cb.sh .


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

  ./stofs_3d_pac_create_surface_forcing_hrrr_us.sh
  ./stofs_3d_pac_create_surface_forcing_hrrr_ak.sh
  ./stofs_3d_pac_create_surface_forcing_hrrr_cb.sh




echo
echo "The script stofs_3d_pac_create_surface_forcing_hrrr.sh completed at date/time: " `date`
echo 





