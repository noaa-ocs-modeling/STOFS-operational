#!/bin/bash

################################################################################
#  Name: stofs_3d_atl_create_station_profile_nc.sh                             #
#  This script reads the 3-D field files (see details in the STOFS Transition  #
#  Release Form) to create the station profile nc files,                       #
#    stofs_3d_atl.t12z.{ncast,fcast}.station.profile.nc                        #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2022   #
################################################################################


# ---------------------------> Begin ...
set -x

  echo " stofs_3d_atl_create_profile_2d_nc.sh began at UTC: "

  pgmout=pgmout_stofs3d_create_profile_2d_nc.$$
  rm -f $pgmout

  cd ${DATA}


# ------------------> check file existence

  # ${stack_start}  --stack_end  ${stack_end}

  stack_no_oi=$1

  stack_start=${stack_no_oi}
  stack_end=${stack_no_oi}

  list_day_no=(${stack_no_oi})

  list_fn_base=(horizontalVelX  horizontalVelY  out2d  salinity  temperature  zCoordinates)


  echo "In stofs_3d_atl_create_profile_2d_nc.sh: checking file existence: "
 
  num_missing_files=0
  for k_no in ${list_day_no[@]};  
  do
   
    for k_fn in ${list_fn_base[@]}; 
    do

       fn_k=outputs/${k_fn}_${k_no}.nc
       if [ -s ${fn_k} ]; then
          echo "checked: ${fn_k} exists"
       
       else
          num_missing_files=`expr ${num_missing_files} + 1`
          echo "checked: ${fn_k} does NOT exist; number of missing files=${num_missing_files}" 
       fi
    done

  done


# ------------------> create station profile data

   #fn_sta_profile_fcast_std=${RUN}.${cycle}.fcast.station.profile.nc
   #fn_sta_profile_fcast_date_tag=${RUN}.station.profile.fcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc


     # dir_output=results
     # yyyymmdd_hh_ref=${PDYHH_FCAST_BEGIN:0:4}-${PDYHH_FCAST_BEGIN:4:2}-${PDYHH_FCAST_BEGIN:6:2}-${cyc}


     dir_output=dir_profile
     mkdir -p ${DATA}/${dir_output}

     ln -sf $FIXstofs3d/${RUN}_vgrid.in  vgrid.in
     ln -sf $FIXstofs3d/${RUN}_hgrid.gr3  hgrid.gr3
     ln -sf $FIXstofs3d/${RUN}_station.in  station.in


     #yyyymmdd_hh_ref=${PDYHH_FCAST_BEGIN:0:4}-${PDYHH_FCAST_BEGIN:4:2}-${PDYHH_FCAST_BEGIN:6:2}-${cyc}
     yyyymmdd_hh_ref=${PDYHH_NCAST_BEGIN:0:4}-${PDYHH_NCAST_BEGIN:4:2}-${PDYHH_NCAST_BEGIN:6:2}-${cyc}


     fn_sta_profile=stofs_stations_profile_${stack_start}_${stack_end}.nc
     rm -rf ${dir_output}/${fn_sta_profile}*

     python ${PYstofs3d}/get_stations_profile.py --date ${yyyymmdd_hh_ref}  --stack_start  ${stack_start}  --stack_end  ${stack_end}  --output_dir  ${dir_output}  >> $pgmout 2> errfile_${stack_start}_${stack_end}


    # fn_nco_xg_navd=${FIXstofs3d}/stofs_3d_atl_sta_cwl_xgeoid_to_navd.nco    
    fn_nco_xg_msl=${FIXstofs3d}/stofs_3d_atl_sta_cwl_xgeoid_to_msl.nco

    cp -pf ${dir_output}/$fn_sta_profile  ${dir_output}/${fn_sta_profile}_ori
    ncap2 -O  -F -S ${fn_nco_xg_msl} ${dir_output}/${fn_sta_profile}_ori  ${dir_output}/${fn_sta_profile}    


    ## cp -paf ${dir_output}/stofs_stations_forecast.nc ${dir_output}/stofs_stations_forecast.nc_original
    ##   ncap2 -O  -F -S ${fn_nco_xg_navd} ${dir_output}/stofs_stations_forecast.nc_original ${dir_output}/stofs_stations_forecast.nc
    ##  mv ${dir_output}/stofs_stations_forecast.nc  ${dir_output}/${fn_sta_profile_fcast_std}
    

     export err=$?

        if [ $err -eq 0 ]; then

           #cpreq -pf ${dir_output}/${fn_sta_profile_fcast_std}  ${COMOUT}/${fn_sta_profile_fcast_std}

           msg="Creating stofs_stations_profile_${stack_start}_${stack_end}.nc  was successfully created"
           echo $msg; echo $msg >> $pgmout

           #  if [ $SENDDBN = YES ]; then
           #   $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job ${COMOUT}/${fn_sta_profile_fcast_std}
           #   export err=$?; err_chk
           #  fi

        else
           msg="Creation/Archiving of ${dir_output}/${fn_sta_profile} failed"
           echo $msg; echo $msg >> $pgmout
        fi


export err=$?;

echo 
echo "stofs_3d_atl_create_profile_2d_nc.sh  completed "
echo 


