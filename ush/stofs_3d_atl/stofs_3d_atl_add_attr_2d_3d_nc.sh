#!/bin/bash

#################################################################################
#  Name: stofs_3d_atl_add_attr_2d_3d_nc.sh                                      #
#  This script adds the meta data attributes the NetCDF variables in SCHISM     #
#  output files with their names containing any strings in {out2d,temperature,  #
#  salinity,horizontalVelX,horizontalVelY,zCoordinates}.                        #
#                                                                               #
#  Remarks:                                                                     #
#    This script was originally developed by the SCHISM team in VIMS.           # 
#                                              May, 2023               September, 2022   #
#################################################################################


# ---------------------------> Begin ...
# set -x

  fn_this_sh="stofs_3d_atl_add_attr_2d_3d_nc.sh"

  echo " ${fn_this_sh} began"  
 
  pgmout=`pwd`/log_${fn_this_sh}.$$
  rm -f $pgmout

  msg="In ${fn_this_sh}:: begins ... " 
  echo $msg >> $pgmout
  

# ---------------------------> Global Variables
  fn_mask_land_bnd=${FIXstofs3d}/stofs_3d_atl_mask_land_ocean_bnd_out2d.nc


# -------------------------->
  cd ${DATA}/outputs
  
  msg="Found nc files: `ls {out2d,horizontalVel?,salinity,temperature,zCoordinates}_?.nc`"
  echo ${msg}; echo $msg >> $pgmout   
  echo 


# ---------------------------> add attributes

cd ${DATA}; pwd


myr=`cat param.nml | grep start_year | cut -d'=' -f2 | awk '{print $1}'`
mmon=`cat param.nml | grep start_month | cut -d'=' -f2 | awk '{print $1}'`
mday=`cat param.nml | grep start_day | cut -d'=' -f2 | awk '{print $1}'`
mhr=`cat param.nml | grep start_hour | cut -d'=' -f2 | cut -d'!' -f1 | awk '{print $1}'`
utchr=`cat param.nml | grep utc_start | cut -d'=' -f2 | cut -d'!' -f1 | awk '{print $1}'`
echo "Adding time attribute:" $myr $mmon $mday $mhr $utchr

 outfn=("out2d" "temperature" "salinity" "horizontalVelX" "horizontalVelY" "zCoordinates")


ict=1
#for ((iday=1;iday>=-1; iday=iday-1))
#for ((iday=1;iday>=-3; iday=iday-1))
for ((iday=1;iday>=-9; iday=iday-1))

  do
     for str in ${outfn[@]};
        do
        if [ -f ./outputs/${str}_${ict}.nc ]
           then
#            echo ${str}_${ict}.nc
#            echo $myr $mmon $mday $mhr $utchr

            echo "Processing -  add attributes: "  ${str}_${ict}.nc
            ls -l  outputs/${str}_${ict}.nc; 


           #Add time string for all nc files
           ncatted  -a units,time,o,c,"seconds since ${myr}-${mmon}-${mday} ${mhr}:00:00 +${utchr}" -a base_date,time,o,c,"${myr} ${mmon} ${mday} ${mhr} ${utchr}" ./outputs/${str}_${ict}.nc
           
	   #Add out2d vars info
           if [ $str == "out2d" ]
              then
              ncatted  -a units,elevation,o,c,"m" -a data_horizontal_center,elevation,o,c,"node" -a data_vertical_center,elevation,o,c,"full" -a mesh,elevation,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc

              ncatted -a long_name,elevation,o,c,"water surface elevation above xgeoid20b" ./outputs/${str}_${ict}.nc

              ncatted  -a units,windSpeedX,o,c,"m/s" -a data_horizontal_center,windSpeedX,o,c,"node" -a data_vertical_center,windSpeedX,o,c,"full" -a mesh,windSpeedX,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc
              ncatted  -a units,windSpeedY,o,c,"m/s" -a data_horizontal_center,windSpeedY,o,c,"node" -a data_vertical_center,windSpeedY,o,c,"full" -a mesh,windSpeedY,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc

  # Fei: apply obc wl offset
  #  fn_non_offset=${fn_ori}_non_offset
  #  mv ${fn_ori} ${fn_non_offset}
  # 
  #  ncap2 -O -S ${fn_nco_offset_wl_3dth}  ${fn_non_offset}  ${fn_ori} 

              fn_with_mask=./outputs/${str}_${ict}.nc
              fn_non_mask=./outputs/${str}_${ict}.nc_non_mask
              mv ${fn_with_mask}  ${fn_non_mask}

              ncks -A -v idmask ${fn_mask_land_bnd} ${fn_non_mask}
              ncap2 -s 'where(idmask==1) elevation=float(-99999.)' ${fn_non_mask} ${fn_with_mask}
              ncatted -O -a missing_value,elevation,a,f,-99999. ${fn_with_mask} 

           fi

	   #Add temperature info
           if [ $str == "temperature" ]
              then
              ncatted  -a units,$str,o,c,"Degree C" -a data_horizontal_center,$str,o,c,"node" -a data_vertical_center,$str,o,c,"full" -a mesh,$str,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc
           fi
           #Add salinity info
           if [ $str == "salinity" ]
              then
              ncatted  -a units,$str,o,c,"PSU" -a data_horizontal_center,$str,o,c,"node" -a data_vertical_center,$str,o,c,"full" -a mesh,$str,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc
           fi
           #Add horizontalVelX info
           if [ $str == "horizontalVelX" ]
              then
              ncatted  -a units,$str,o,c,"m/s" -a data_horizontal_center,$str,o,c,"node" -a data_vertical_center,$str,o,c,"full" -a mesh,$str,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc
           fi
           #Add horizontalVelY info
           if [ $str == "horizontalVelY" ]
              then
              ncatted  -a units,$str,o,c,"m/s" -a data_horizontal_center,$str,o,c,"node" -a data_vertical_center,$str,o,c,"full" -a mesh,$str,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc
           fi
           #Add zCoordinates info
           if [ $str == "zCoordinates" ]
              then
              ncatted  -a units,$str,o,c,"m" -a data_horizontal_center,$str,o,c,"node" -a data_vertical_center,$str,o,c,"full" -a mesh,$str,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc
           fi
        fi
     done
     ict=$((${ict}+1))
done


# ------------------> archive
    fn_prefix=${RUN}.${cycle}.fields

    # outfn=("out2d" "temperature" "salinity" "horizontalVelX" "horizontalVelY" "zCoordinates")
    list_var=("out2d" "temperature" "salinity" "horizontalVelX" "horizontalVelY" "zCoordinates")


    #list_day_n_f=(1 2 3 4 5 6 7 8 9 10)
    #list_n_f=(nowcast forecast_day1 forecast_day2 forecast_day3 forecast_day4)
    
    list_file_cnt=(1 2 3 4 5 6 7 8 9 10)
    list_file_nf_hr=(n001_012 n013_024 f001_012 f013_024 f025_036 f037_048 f049_060 f061_072 f073_084 f085_096)


    cd ${DATA}/outputs

    file_size_cr=100000000

    let cnt=-1 
    for k_d in ${list_file_cnt[@]}
    do
  
      let cnt=$cnt+1
      str_n_f_k=${list_file_nf_hr[${cnt}]}
 
      for var_k in ${list_var[@]} 
      do
         fn_k_src=${var_k}_${k_d}.nc
         fn_k_std=${fn_prefix}.${var_k}_${str_n_f_k}.nc

         echo $fn_k_src; echo $fn_k_std; echo 

         if [ -f ${fn_k_src} ]; then
            sz_fn_link_src=`wc -c ${fn_k_src} | awk '{print $1}'`

            if [ $sz_fn_link_src -ge ${file_size_cr} ]; then
               cpreq -pf ${fn_k_src} ${COMOUT}/${fn_k_std}
            
	       if [ $SENDDBN = YES ] && [ ${var_k} = out2d ]; then
                 $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job ${COMOUT}/${fn_k_std}
                 export err=$?; err_chk
               fi 
	    
	    fi

            echo "${fn_k_std} is created"         

         else
           echo "${fn_k_src}/${fn_k_std} NOT created or file size is too small"

         fi

      done

    done


#    export err=$?
#    if [ $err -eq 0 ]; then
#      cp -pf ${fn_shef_merged} ${COMOUT}

#      msg="Creation/Archiving of ${fn_this_sh} was successfully created"
#      echo $msg; echo $msg >> $pgmout

#      else
#        mstofs="Creation/Archiving of ${dir_output}/${fn_this_sh} failed"
#        echo $msg; echo $msg >> $pgmout
#    fi

#    export err=$?; #err_chk

echo 
echo "${fn_this_sh} completed "
echo 








