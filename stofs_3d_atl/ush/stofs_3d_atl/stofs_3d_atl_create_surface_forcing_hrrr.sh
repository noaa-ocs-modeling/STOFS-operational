#!/bin/bash

############################################################################
#  Name: stofs_3d_atl_create_surface_forcing_hrrr.sh                       # 
#  This script read the NCEP/HRRR data to create the HRRR based surface    #
#  forcing files, stofs_3d_atl.t12z.hrrr.{air,prc,rad}.nc for the nowcast  # 
#  and forecast simuations.                                                #
#                                                                          #
#  Remarks:                                                                #
#                                                        September, 2022   #
############################################################################

# ---------------------------> Begin ...
set -x

echo 'The script stofs_3d_atl_create_surface_forcing_hrrr.sh started ' 


# ---------------------------> directory/file names
  dir_wk=${DATA_prep_hrrr}/

  mkdir -p $dir_wk
  cd $dir_wk

  pgmout=pgmout_hrrr.$$


# ---------------------------> Global Variables
  fn_nco_update_time_varName=${FIXstofs3d}/stofs_3d_atl_hrrr_input_nco_update_var.nco

  fn_hrrr_rad_schism=sflux_rad_2.0001.nc
  fn_hrrr_rad_date_tag=${RUN}.hrrr.rad.nfcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc
  fn_hrrr_rad_std=${RUN}.${cycle}.hrrr.rad.nc

  fn_hrrr_prc_schism=sflux_prc_2.0001.nc
  fn_hrrr_prc_date_tag=${RUN}.hrrr.prc.nfcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc
  fn_hrrr_prc_std=${RUN}.${cycle}.hrrr.prc.nc

  fn_hrrr_air_schism=sflux_air_2.0001.nc
  fn_hrrr_air_date_tag=${RUN}.hrrr.air.nfcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc
  fn_hrrr_air_std=${RUN}.${cycle}.hrrr.air.nc


# --------------------------> Region of interest
  LONMIN=-98.5
  LONMAX=-49.5
  LATMIN=5.5
  LATMAX=50

 #--------------------------> dates
  yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
  yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}
  

# ------> form the input file lists 
  # yesterday: t11-t23, f01
  list_num_11_23=`seq -f "%02g" 11 1 23`
  
  str_base_prev=${COMINhrrr}/hrrr.${yyyymmdd_prev}/conus
  list_fn_prev=''
  for num_k in $list_num_11_23
  do
    fn_k=${str_base_prev}/hrrr.t${num_k}z.wrfsfcf01.grib2 
    list_fn_prev=${list_fn_prev}' '${fn_k} 
  done

  # today: t00-t11, f01
  list_num_00_11=`seq -f "%02g" 0 1 11`
   
  str_base_today=${COMINhrrr}/hrrr.${yyyymmdd_today}/conus
  list_fn_today_1=''
  for num_k in $list_num_00_11
  do
    fn_k=${str_base_today}/hrrr.t${num_k}z.wrfsfcf01.grib2
    list_fn_today_1=${list_fn_today_1}' '${fn_k}
  done
     
  # today: t12, f01-48
  list_num_01_48=`seq -f "%02g" 1 1 48`
  
  str_base_today=${COMINhrrr}/hrrr.${yyyymmdd_today}/conus
  list_fn_today_2=''
  for num_k in $list_num_01_48
  do
    fn_k=${str_base_today}/hrrr.t12z.wrfsfcf${num_k}.grib2
    list_fn_today_2=${list_fn_today_2}' '${fn_k}
  done

# concatenate dir/file names
 LIST_fn_all="${list_fn_prev} "
 LIST_fn_all+="${list_fn_today_1[@]} "
 LIST_fn_all+="${list_fn_today_2[@]} "


# check file sizes (e.g., 534313765)
 FILESIZE=100000000

 LIST_fn_final=''
 for fn_hrrr_k_sz in $LIST_fn_all
 do
   echo "Processing:: " $fn_hrrr_k_sz

   if [ -s $fn_hrrr_k_sz ]; then
      filesize=`wc -c $fn_hrrr_k_sz | awk '{print $1}' `

      if [ $filesize -ge $FILESIZE ];
      then
         LIST_fn_final+="${fn_hrrr_k_sz} "
      else
         echo "WARNING: " $fn_hrrr_k_sz ": filesize $filesize less than $FILESIZE"
         echo "WARNING: " $fn_hrrr_k_sz ": filesize $filesize less than $FILESIZE"  
      fi

   else
      echo "WARNING: "  $fn_hrrr_k_sz " does not exist"
      echo "WARNING: "  $fn_hrrr_k_sz " does not exist"  
   fi
 done



# -------------------> variables of OI (grb2)
   list_var_oi='TMP:2 m above|RH:2 m above|SPFH:2 m above|MSLMA:mean|PRATE|UGRD:10 m above|VGRD:10 m above|ALBDO:surface|DSWRF:surface|USWRF:surface|DLWRF:surface|ULWRF:surface'

   iyr=`echo ${yyyymmdd_prev} | cut -c1-4`
   imon=`echo ${yyyymmdd_prev} | cut  -c5-6`
   iday=`echo ${yyyymmdd_prev} | cut -c7-8`
   ihr=12


 rm -f HRRR_voi_*

 let cnt=-1
 for fn_hrrr_k in $LIST_fn_all
 do 
   let cnt=$cnt+1

   str_xxx_cnt=`seq -f "%03g" $cnt 1 $cnt`
   echo "Processing($str_xxx_cnt): " $fn_hrrr_k

      ln -sf $fn_hrrr_k HRRR_${str_xxx_cnt}.grb2


      fn_varOI=HRRR_voi_${str_xxx_cnt}.grb2
      $WGRIB2  -s  $fn_hrrr_k  | egrep "$list_var_oi" | $WGRIB2  -i  $fn_hrrr_k  -grib  $fn_varOI  >> $pgmout 2> errfile 
      export err=$?; 

      fn_roi=HRRR_voi_rio_${str_xxx_cnt}.grb2
      $WGRIB2  $fn_varOI  -small_grib ${LONMIN}:${LONMAX} ${LATMIN}:${LATMAX} $fn_roi   >> $pgmout 2> errfile
      export err=$?; 

      fn_0_rnVar_with_xy=HRRR_voi_rio_0rename_with_xy_${str_xxx_cnt}.nc 
      $WGRIB2  $fn_roi -netcdf $fn_0_rnVar_with_xy    >> $pgmout 2> errfile
      export err=$?; 

      fn_0_rnVar=HRRR_voi_rio_0rename_${str_xxx_cnt}.nc
      ncks -CO -x -v y,x $fn_0_rnVar_with_xy  $fn_0_rnVar    >> $pgmout 2> errfile
      export err=$?; 

      fn_1time=HRRR_voi_rio_0rename_1time_${str_xxx_cnt}.nc

      str_time=`echo '"'days since $iyr-$imon-$iday 00:00:00'"'`
      let hr_cnt_since_hr00=${ihr}+${cnt}

      ncap2 -Oh -s "tin=${hr_cnt_since_hr00}"  -s "time@units=$str_time"  -s "time@base_date ={ $iyr, $imon, $iday, 0}" -S $fn_nco_update_time_varName -v ${fn_0_rnVar} ${fn_1time}    >> $pgmout 2> errfile
      export err=$?; 

 done 


  fn_merged_sflux=hrrr_date_${PDYHH_FCAST_BEGIN}_${PDYHH_FCAST_END}.nc
  rm -rf $fn_merged_sflux
  find . -size 0  -exec rm -f {} \;

  ncrcat -O HRRR_voi_rio_0rename_1time_???.nc $fn_merged_sflux
  export err=$?; 



# -----------------------------> ln -s
rm -f sflux_???_2.????.nc 

fn_link_src=${fn_merged_sflux}


FILESIZE_min=1800000000
if [ -f $fn_link_src ]; then

   sz_fn_link_src=`wc -c $fn_link_src | awk '{print $1}'`
   if [ $sz_fn_link_src -ge $FILESIZE_min ]; then

    ln -sf $fn_link_src  ${fn_hrrr_rad_schism}
    ln -sf $fn_link_src  ${fn_hrrr_prc_schism}
    ln -sf $fn_link_src  ${fn_hrrr_air_schism}

    cpreq -pf $fn_link_src ${COMOUTrerun}/${fn_hrrr_rad_std}
    cpreq -pf $fn_link_src ${COMOUTrerun}/${fn_hrrr_prc_std}
    cpreq -pf $fn_link_src ${COMOUTrerun}/${fn_hrrr_air_std}


    echo " sflux/hrrr forcing files: reanmes & copied to COMOUT "

   fi

else
    echo " sflux/hrrr forcing file not created or file size is too small: $fn_link_src "
fi

export err=$?; 


echo
echo "The script stofs_3d_atl_create_surface_forcing_hrrr.sh completed  " 
echo 





