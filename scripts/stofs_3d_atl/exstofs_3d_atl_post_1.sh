#!/bin/bash

#####################################################################################
#  Name: exstofs_3d_atl_post_1.sh                                                     #
#  This script is a postprocessor to create combined hotstart nc file, and          #
#  all the post-model files (that are listed in the STOFS Transition Release        #
#  forms), execpt the 2-D field nc files (which are created exstofs_3d_atl_post_2.sh  #
#                                                                                   #
#  Remarks:                                                                         #
#                                                               September, 2022     #
#####################################################################################

# exstofs_3d_atl_post_processing.sh 

  seton='-xa'
  setoff='+xa'
  set $seton


# ----------------------->

  fn_this_sh="exstofs_3d_atl_post_1"

  echo "${fn_this_sh}.sh began at UTC: " `date `

  echo "module list::"
  module list
  echo; echo


  msg="${fn_this_sh}.sh started at UTC:  `date `"
  echo "$msg"
  postmsg "$jlogfile" "$msg"


  pgmout=${fn_this_sh}.$$


# -----------------------> static files
  fn_station_in=$FIXstofs3d/${RUN}_station.in
  
  cd ${DATA}
  cpreq --remove-destination -f ${fn_station_in} station.in


# -----------------------> check & wait for model run complete 
fn_mirror=outputs/mirror.out
str_model_run_status="Run completed successfully"

max_seconds=$(( 5 * 3600 ))   #  wait for upto 5 hrs
time_sleep_s=600
time_elapsed=0
start_time=$(date +%s)

flag_run_status=1
while [[ ${time_elapsed} -le $max_seconds ]]; do

  flag_run_status=`grep "${str_model_run_status}" ${fn_mirror} >/dev/null; echo $?`

    time_elapsed=$(($(date +%s) - $start_time))

    echo "Elapsed time (sec) =  ${time_elapsed} "
    echo "flag_run_status=${flag_run_status} (0:suceecess)"; echo


    if [[ ${flag_run_status} == 0 ]]; then
        msg="Model run completed. Proceed to post-processing ..."
        echo -e ${msg};  
        echo -e  ${msg} >> $pgmout
        break
    else
        echo "Wait for ${time_sleep_s} more seconds"; echo
        sleep ${time_sleep_s}    # 10min=600s
    fi
done

# ----------------------->

if [[ ${flag_run_status} == 0 ]]; then
    msg=`echo checked mirror.out: SCHISM model run was completed SUCCESSFULLY`
    echo $msg
    echo $msg >> $pgmout


    #sleep 180s     # wait for stofs_3d_atl_create_geopackage.sh


    # ---------------> cp'ed from NCO: prod package (2023/03/16)
    cd ${DATA}
    if [  ! -s done_cp_nc ]; then
        mkdir -p Dir_backup_2d3d
        cpreq -fpa  outputs/{horizontalVelX,horizontalVelY,out2d,salinity,temperature,zCoordinates}*.nc Dir_backup_2d3d

    fi


    # ---------> Update 2d & 3d nc: adding variable attributes
    file_log_attr=log_add_attribute_2d_3d_nc.${cycle}.log
    fn_ush_script_attr=stofs_3d_atl_add_attr_2d_3d_nc.sh

    export pgm="${USHstofs3d}/${fn_ush_script_attr}"
    ${USHstofs3d}/${fn_ush_script_attr} >> ${file_log_attr} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally, WARNING"
       postmsg "$jlogfile" "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
    fi

    echo $msg
    echo


    # ---------> create staout 6-min nc & SHEF file
    file_log_awips=log_create_awips_shef.${cycle}.log
    fn_ush_script_awips=stofs_3d_atl_create_awips_shef.sh
    export pgm="${USHstofs3d}/${fn_ush_script_awips}"
    ${USHstofs3d}/${fn_ush_script_awips} >> ${file_log_awips} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
    fi

    echo $msg
    echo


    # ---------> create AWS/EC2 auto nc files
    file_log_autoval=log_stofs_3d_atl_create_AWS_autoval_nc.${cycle}.log
    fn_ush_script_autoval=stofs_3d_atl_create_AWS_autoval_nc.sh
    export pgm="${USHstofs3d}/${fn_ush_script_autoval}"
    ${USHstofs3d}/${fn_ush_script_autoval} >> ${file_log_autoval} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
    fi

    echo $msg
    echo


    # ---------> create profile netcdf files
    file_log_prof=log_create_sta_profile.${cycle}.log
    fn_ush_script_prof=stofs_3d_atl_create_station_profile_nc.sh
    export pgm="${USHstofs3d}/${fn_ush_script_prof}"
    ${USHstofs3d}/${fn_ush_script_prof} >> ${file_log_prof} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
    fi

    echo $msg
    echo


  #  ---------> Create ADCIRC format water level fields: stofs_3d_atl_create_adcirc_nc.sh
    file_log_adc=log_stofs_3d_atl_create_adcirc_nc.${cycle}.log
    fn_ush_script_adc=stofs_3d_atl_create_adcirc_nc.sh

    export pgm="${USHstofs3d}/${fn_ush_script_adc}"
    ${USHstofs3d}/${fn_ush_script_adc} >> ${file_log_adc} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
    fi

    echo $msg
    echo

   
   # ----------> Create AWIPS grib2 files: conus_east_us & puertori masks
    file_log_grib2=log_create_awips_grib2_${cycle}.log
    fn_ush_script_grib2=stofs_3d_atl_create_awips_grib2.sh

    export pgm="${USHstofs3d}/${fn_ush_script_grib2}"
    ${USHstofs3d}/${fn_ush_script_grib2} >> ${file_log_grib2} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
    fi

    echo $msg
    echo


  # ---------------------------------------> Completed post processing

  msg=" Finished ${fn_this_sh}.sh  SUCCESSFULLY "
  postmsg "$jlogfile" "$msg"

  # cp -p $jlogfile $COMOUT

  chmod -Rf 755 $COMOUT


  echo
  echo $msg at `date`
  echo


else
    
     msg=`echo SCHISM model run did NOT finish successfully: Not Found \"${str_model_run_status}\" in ${fn_mirror}`
     echo -e $msg
     echo -e $msg >> $pgmout

# if [ -s ${fn_mirror} ] && [ -n "${str_model_run_status}" ]; then
fi




