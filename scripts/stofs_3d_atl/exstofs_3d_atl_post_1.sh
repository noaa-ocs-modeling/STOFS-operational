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

max_seconds=$(( 900 ))   #  wait for upto 15 min
time_sleep_s=300
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


    # ---------> backup schims native files
    cd ${DATA}
    if [  ! -s done_cp_nc ]; then 
	mkdir -p Dir_backup_2d3d
	cpreq -f  outputs/{horizontalVelX,horizontalVelY,out2d,salinity,temperature,zCoordinates}*.nc Dir_backup_2d3d
	echo done > done_cp_nc
    fi	
    
    # ---------> Update 2d & 3d nc: adding variable attributes
    file_log=log_add_attribute_2d_3d_nc.${cycle}.log
    fn_ush_script=stofs_3d_atl_add_attr_2d_3d_nc.sh

    cpreq -f Dir_backup_2d3d/*nc outputs/


    export pgm="${USHstofs3d}/${fn_ush_script}"
    ${USHstofs3d}/${fn_ush_script} >> ${file_log} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally, WARNING"
       postmsg "$jlogfile" "$msg"
       cat ${file_log}
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
       cat ${file_log}
    fi

    echo $msg
    echo


    # ---------> create 2D field files
    file_log=log_create_2d_field_nc.${cycle}.log
    fn_ush_script=stofs_3d_atl_create_2d_field_nc.sh
    export pgm="${USHstofs3d}/${fn_ush_script}"
    
    rm -f $DATA/mpmdscript
    echo "${USHstofs3d}/${fn_ush_script} 1 > $DATA/${file_log}_1 " >> $DATA/mpmdscript
    echo "${USHstofs3d}/${fn_ush_script} 2 > $DATA/${file_log}_2 " >> $DATA/mpmdscript 
    echo "${USHstofs3d}/${fn_ush_script} 3 > $DATA/${file_log}_3 " >> $DATA/mpmdscript  

    chmod 775 $DATA/mpmdscript
    export MP_PGMMODEL=mpmd
    mpiexec -l -np 3 --cpu-bind verbose,core cfp $DATA/mpmdscript 

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       cat $DATA/${file_log}*
       err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
       cat $DATA/${file_log}*
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
       cat ${file_log}
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
       cat ${file_log}
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
       cat ${file_log}
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
       cat ${file_log}
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
       cat ${file_log}
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
       cat ${file_log}
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
       cat ${file_log}
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
       cat ${file_log}
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
       cat ${file_log}
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
       cat ${file_log}
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




