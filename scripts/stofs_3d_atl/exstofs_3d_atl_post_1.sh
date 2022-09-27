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

  echo "${fn_this_sh}.sh began at UTC: " `date -u`

  echo "module list::"
  module list
  echo; echo


  msg="${fn_this_sh}.sh started at UTC:  `date -u`"
  echo "$msg"
  postmsg "$jlogfile" "$msg"


  pgmout=${fn_this_sh}.$$


# -----------------------> static files
  fn_station_in=$FIXstofs3d/${RUN}_station.in
  #fn_station_name=$FIXstofs3d/${RUN}_stanames_profile.txt
  
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

    
    # ---------> merge hotstart files
    cd ${DATA}/outputs/

    idx_time_step_merge_hotstart=576
    fn_merged_hotstart_ftn=hotstart_it\=${idx_time_step_merge_hotstart}.nc
    fn_hotstart_stofs3d_merged_std=${RUN}.${cycle}.hotstart.stofs3d.nc

    ${EXECstofs3d}/stofs_3d_atl_combine_hotstart  -i  ${idx_time_step_merge_hotstart}

    export err=$?
    pgm=${EXECstofs3d}/stofs_3d_atl_combine_hotstart

    if [ $err -eq 0 ]; then
       msg=`echo $pgm  completed normally`
       echo $msg; echo $msg >> $pgmout

       # fn_merged_hotstart_ftn=hotstart_it\=${idx_time_step_merge_hotstart}
       if [ -s ${fn_merged_hotstart_ftn} ]; then
          msg=`echo ${fn_merged_hotstart_ftn}} has been created`;
          echo $msg; echo $msg >> $pgmout

          fn_merged_hotstart_ftn_time_00=${fn_merged_hotstart_ftn}_time_00
          ncap2 -O -s 'time=0.0' ${fn_merged_hotstart_ftn}  ${fn_merged_hotstart_ftn_time_00}

          cpreq -pf ${fn_merged_hotstart_ftn_time_00} ${COMOUT}/${fn_hotstart_stofs3d_merged_std}

       else
         msg=`echo ${fn_merged_hotstart_ftn}} was not created`
         echo $msg; echo $msg >> $pgmout
       fi

    else
       msg=`echo $pgm did not complete normally`
       echo $msg; echo $msg >> $pgmout
    fi



    # ---------> Update 2d & 3d nc: adding variable attributes
    file_log=log_add_attribute_2d_3d_nc.${cycle}.log
    fn_ush_script=stofs_3d_atl_add_attr_2d_3d_nc.sh

    export pgm="${USHstofs3d}/${fn_ush_script}"
    ${USHstofs3d}/${fn_ush_script} >> ${file_log} 2>&1

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
    file_log=log_create_awips_shef.${cycle}.log
    fn_ush_script=stofs_3d_atl_create_awips_shef.sh
    export pgm="${USHstofs3d}/${fn_ush_script}"
    ${USHstofs3d}/${fn_ush_script} >> ${file_log} 2>&1

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
    file_log=log_stofs_3d_atl_create_AWS_autoval_nc.${cycle}.log
    fn_ush_script=stofs_3d_atl_create_AWS_autoval_nc.sh
    export pgm="${USHstofs3d}/${fn_ush_script}"
    ${USHstofs3d}/${fn_ush_script} >> ${file_log} 2>&1

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
    file_log=log_create_sta_profile.${cycle}.log
    fn_ush_script=stofs_3d_atl_create_station_profile_nc.sh
    export pgm="${USHstofs3d}/${fn_ush_script}"
    ${USHstofs3d}/${fn_ush_script} >> ${file_log} 2>&1

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
    file_log=log_stofs_3d_atl_create_adcirc_nc.${cycle}.log
    fn_ush_script=stofs_3d_atl_create_adcirc_nc.sh

    export pgm="${USHstofs3d}/${fn_ush_script}"
    ${USHstofs3d}/${fn_ush_script} >> ${file_log} 2>&1

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
    file_log=log_create_awips_grib2_${cycle}.log  
    fn_ush_script=stofs_3d_atl_create_awips_grib2.sh

    export pgm="${USHstofs3d}/${fn_ush_script}"
    ${USHstofs3d}/${fn_ush_script} >> ${file_log} 2>&1

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




