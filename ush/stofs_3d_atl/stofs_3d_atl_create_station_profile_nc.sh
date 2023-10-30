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
# set -x

  echo " stofs_3d_atl_create_profile_2d_nc.sh began at UTC: "

  pgmout=pgmout_stofs3d_create_profile_2d_nc.$$
  rm -f $pgmout

  cd ${DATA}


# ------------------> check file existence
  # list_day_no=(1 2 3)
  list_day_no=(1 2 3 4 5 6 7 8 9 10)

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
# export PDYHH_FCAST_BEGIN=$PDYHH
# export PDYHH_FCAST_END=$($NDATE 48 $PDYHH)
# export PDYHH_NCAST_BEGIN=$($NDATE -24 $PDYHH)


   fn_nco_xg_navd=${FIXstofs3d}/stofs_3d_atl_sta_cwl_xgeoid_to_navd.nco

   # nowcast
   fn_sta_profile_ncast_std=${RUN}.${cycle}.ncast.station.profile.nc
   fn_sta_profile_ncast_date_tag=${RUN}.station.profile.ncast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc

     stack_start=1
     stack_end=2
     dir_output=results
     yyyymmdd_hh_ref=${PDYHH_NCAST_BEGIN:0:4}-${PDYHH_NCAST_BEGIN:4:2}-${PDYHH_NCAST_BEGIN:6:2}-${cyc}



     python ${PYstofs3d}/get_stations_profile.py --date ${yyyymmdd_hh_ref}  --stack_start  ${stack_start}  --stack_end  ${stack_end}  --output_dir  ${dir_output}  >> $pgmout 2> errfile

     cp -paf ${dir_output}/stofs_stations_forecast.nc ${dir_output}/stofs_stations_nowcast.nc_original
       # nco: sample, zeta(:,32)=zeta(:,32)-float(-0.29341)
       ncap2 -O  -F -S ${fn_nco_xg_navd} ${dir_output}/stofs_stations_nowcast.nc_original ${dir_output}/stofs_stations_nowcast.nc

     mv ${dir_output}/stofs_stations_nowcast.nc  ${dir_output}/${fn_sta_profile_ncast_std}  

     # archive
     export err=$?

        if [ $err -eq 0 ]; then

           cpreq -pf ${dir_output}/${fn_sta_profile_ncast_std}  ${COMOUT}/${fn_sta_profile_ncast_std}
           #cpreq -pf ${dir_output}/${fn_sta_profile_ncast_std}  ${COMOUT}/${fn_sta_profile_ncast_date_tag}

           msg="Creation/Archiving of ${dir_output}/${fn_sta_profile_ncast_std} was successfully created"
           echo $msg; echo $msg >> $pgmout

           if [ $SENDDBN = YES ]; then
              $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job ${COMOUT}/${fn_sta_profile_ncast_std}
              export err=$?; err_chk
           fi

        else
           msg="Creation/Archiving of ${dir_output}/${fn_sta_profile_ncast_std} failed"
           echo $msg; echo $msg >> $pgmout
        fi
          
   # forecast
   fn_sta_profile_fcast_std=${RUN}.${cycle}.fcast.station.profile.nc
   fn_sta_profile_fcast_date_tag=${RUN}.station.profile.fcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc

     # stack_start=2
     # stack_end=3
       stack_start=3
       stack_end=10

     dir_output=results
     yyyymmdd_hh_ref=${PDYHH_FCAST_BEGIN:0:4}-${PDYHH_FCAST_BEGIN:4:2}-${PDYHH_FCAST_BEGIN:6:2}-${cyc}


     python ${PYstofs3d}/get_stations_profile.py --date ${yyyymmdd_hh_ref}  --stack_start  ${stack_start}  --stack_end  ${stack_end}  --output_dir  ${dir_output}  >> $pgmout 2> errfile

     cp -paf ${dir_output}/stofs_stations_forecast.nc ${dir_output}/stofs_stations_forecast.nc_original
       ncap2 -O  -F -S ${fn_nco_xg_navd} ${dir_output}/stofs_stations_forecast.nc_original ${dir_output}/stofs_stations_forecast.nc
     
     mv ${dir_output}/stofs_stations_forecast.nc  ${dir_output}/${fn_sta_profile_fcast_std}
    
          
 
    # archive
     export err=$?

        if [ $err -eq 0 ]; then

           cpreq -pf ${dir_output}/${fn_sta_profile_fcast_std}  ${COMOUT}/${fn_sta_profile_fcast_std}
           #cpreq -pf ${dir_output}/${fn_sta_profile_fcast_std}  ${COMOUT}/${fn_sta_profile_fcast_date_tag}

           msg="Creation/Archiving of ${dir_output}/${fn_sta_profile_fcast_std} was successfully created"
           echo $msg; echo $msg >> $pgmout

           if [ $SENDDBN = YES ]; then
              $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job ${COMOUT}/${fn_sta_profile_fcast_std}
              export err=$?; err_chk
           fi

        else
           msg="Creation/Archiving of ${dir_output}/${fn_sta_profile_fcast_std} failed"
           echo $msg; echo $msg >> $pgmout
        fi



export err=$?; #err_chk  

echo 
echo "stofs_3d_atl_create_profile_2d_nc.sh  completed "
echo 


