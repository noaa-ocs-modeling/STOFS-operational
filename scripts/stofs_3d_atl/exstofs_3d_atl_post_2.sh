#!/bin/bash

##############################################################################
#  Name: exstofs_3d_atl_post_2.sh                                              #
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
# set sleep to wait for exstofs_3d_atl_post_1.sh to finish add_attr.sh
#  sleep 300s

# ----------------------->
  fn_this_script=exstofs_3d_atl_post_2

  msg="${fn_this_script}.sh  started at UTC: `date -u `"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

  pgmout=${fn_this_script}.$$

  cd ${DATA}

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



   MMDD_ANNUAL_UPDATE_RESTART_FILE=0105
   MMDD_FCAST_BEGIN=${PDYHH_FCAST_BEGIN:4:4} 
    
   if [[ ${MMDD_FCAST_BEGIN} == ${MMDD_ANNUAL_UPDATE_RESTART_FILE} ]]; then
      ecflow_client --event run_temp_salt_restart
   fi


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




