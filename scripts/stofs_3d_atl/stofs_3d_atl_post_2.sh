#!/bin/bash

##############################################################################
#  Name: stofs_3d_atl_post_2.sh                                              #
#  This script is a postprocessor to create the 2-D field nc files, namely,  #
#  stofs_3d_atl.t12z.????_???.field2d.nc and copies the files to the com     #
#  directory                                                                 #
#                                                                            #
#  Remarks:                                                                  #
#                                                        September, 2022     #
##############################################################################

  seton='-xa'
  setoff='+xa'
  set $seton

# -----------------------> Setup to delay (waiting for post_1.sh)
# set sleep to wait for stofs_3d_atl_post_1.sh to finish add_attr.sh
  sleep 300s

# ----------------------->
  fn_this_script=stofs_3d_atl_post_2

  msg="${fn_this_script}.sh  started at UTC: `date -u `"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

  pgmout=${fn_this_script}.$$

  cd ${DATA}


# -----------------------> static files
  fn_station_in=$FIXstofs3d/${RUN}_station.in
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
  

if [[ ${flag_run_status} == 0 ]]; then    
    msg=`echo checked mirror.out: SCHISM model run was completed SUCCESSFULLY`
    echo $msg
    echo $msg >> $pgmout


    # ---------> create 2D field files
    file_log=log_create_2d_field_nc.${cycle}.log
    fn_ush_script=stofs_3d_atl_create_2d_field_nc.sh
    export pgm="${USHstofs3d}/${fn_ush_script}"
    
    ${USHstofs3d}/${fn_ush_script} 1 >> ${file_log}_1 2>&1   &
    ${USHstofs3d}/${fn_ush_script} 2 >> ${file_log}_2 2>&1   &
    ${USHstofs3d}/${fn_ush_script} 3 >> ${file_log}_3 2>&1   &

    wait
    
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

  msg=" Finished ${fn_this_script}.sh  SUCCESSFULLY "
  postmsg "$jlogfile" "$msg"

  #cpreq -p $jlogfile $COMOUT

  chmod -Rf 755 $COMOUT


  echo
  echo $msg at `date`
  echo


else
     msg=`echo SCHISM model run did NOT finish successfully: Not Found \"${str_model_run_status}\" in ${fn_mirror}`
     echo $msg
     echo $msg >> $pgmout

# if [ -s ${fn_mirror} ] && [ -n "${str_model_run_status}" ]; then
fi




