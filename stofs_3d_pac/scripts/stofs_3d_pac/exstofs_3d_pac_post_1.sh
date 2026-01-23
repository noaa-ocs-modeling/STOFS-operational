#!/bin/bash

#####################################################################################
#  Name: exstofs_3d_pac_post_1.sh                                                     #
#  This script is a postprocessor to create combined hotstart nc file, and          #
#  all the post-model files (that are listed in the STOFS Transition Release        #
#  forms), execpt the 2-D field nc files (which are created exstofs_3d_pac_post_2.sh  #
#                                                                                   #
#  Remarks:                                                                         #
#                                                               September, 2022     #
#####################################################################################

# exstofs_3d_pac_post_processing.sh 

#  seton='-xa'
  setoff='+xa'
#  set $seton


  cd ${DATA}


# ----------------------->

  fn_this_sh="exstofs_3d_pac_post_1"


  echo "module list::"
  module list
  echo; echo


  msg="${fn_this_sh}.sh started "
  echo "$msg"
  postmsg  "$msg"


  pgmout=${fn_this_sh}.$$

  msg=" Bgein  ${fn_this_sh}.sh " 
  postmsg  "$msg"



# -----------------------> static files
  fn_station_in=$FIXstofs3d/${RUN}_station.in
  
  cd ${DATA}
  
  cpreq --remove-destination -f ${fn_station_in} station.in
  
  fn_src_nml=${COMOUTrerun}/${RUN}.${cycle}.param.nml
  # fn_src_nml=${COMOUTrerun}/${RUN}.${cycle}.param.nml_10_rnday_50
  ln -sf ${fn_src_nml} param.nml


# -----------------------> check & wait for model run complete 
#fn_mirror=outputs/mirror.out
#fn_mirror=${COMOUT}/outputs_2d3d_sta/mirror.out
#fn_mirror=${COMOUT}/outputs_hotstart/mirror.out
 fn_mirror=${COMOUT}/outputs_watchdog/mirror.out

str_model_run_status="Run completed successfully"

#time_sleep_s=60
#flag_run_status=1

if [[ 0 -eq 1 ]]; then  # (2024/12/16)  following Bugzilla: Bug 1571 - Improve the outputs/mirror.out checking in stofs_3d_pac_post_1/2 jobs

   cnt=0
   while [[ $cnt -le 10 ]]; do

   flag_run_status=`grep "${str_model_run_status}" ${fn_mirror} >/dev/null; echo $?`

     time_elapsed=$(( ${cnt} * ${time_sleep_s} ))

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
	cnt=$(( ${cnt} + 1 ))
     fi
   done # while 

fi ## if [[ 0 -eq 1 ]]; then


# ----------------------->

flag_run_status=1
flag_run_status=`grep "${str_model_run_status}" ${fn_mirror} >/dev/null; echo $?`

if [[ ${flag_run_status} == 0 ]]; then
    msg=`echo checked mirror.out: SCHISM model run was completed SUCCESSFULLY`
    echo $msg
    echo $msg >> $pgmout


    #sleep 180s     # wait for stofs_3d_pac_create_geopackage.sh

    # ---------------> cp'ed from NCO: prod package (2023/03/16)
#if [ 0 -eq 1]; then
#    cd ${DATA}
#    if [  ! -s done_cp_nc ]; then
#        mkdir -p Dir_backup_2d3d
#        cpreq -fpa  outputs/{horizontalVelX,horizontalVelY,out2d,salinity,temperature,zCoordinates,verticalVelocity,diffusivity}*.nc Dir_backup_2d3d
#    fi
#fi

    #{zy, (2024/1/16)
     dir_outputs_local=${DATA}/outputs
  
     mkdir -p ${dir_outputs_local}
     cd ${DATA}

     # cpreq -fpr ${COMOUT}/outputs_2d3d_sta/* ${dir_outputs_local}
     # cpreq -fpr ${COMOUT}/outputs_watchdog/* ${dir_outputs_local}

     echo "date/time before cp data to post_1 outputs: `date`"
     
     #for i in ${COMOUT}/outputs_watchdog/local_to_global*; do
     #   #cpreq -pf "$i" ${dir_outputs_local}; 
     #   cpreq  -f  "$i" ${dir_outputs_local};
     #done

     cpreq -f ${COMOUT}/outputs_watchdog/{horizontalVelX,horizontalVelY,out2d,salinity,temperature,zCoordinates,verticalVelocity,diffusivity}_*.nc ${dir_outputs_local};
     cpreq -f ${COMOUT}/outputs_watchdog/staout_* ${dir_outputs_local}

     #TIME_STEP_restart=576
     #cpreq -f ${COMOUT}/outputs_watchdog/hotstart_*_${TIME_STEP_restart}.nc  ${dir_outputs_local};

     echo "date/time when done cp data to post_1 outputs: `date`"

     # Following is done in watchdog.sh
     # including: history nc & local_to_global & hotstart_*_576.nc
     # cpreq -fp ${COMOUT}/outputs_hotstart/hotstart_*_576.nc   ${dir_outputs_local}
     # cpreq -fp ${COMOUT}/outputs_hotstart/local_to_global_??????   ${dir_outputs_local}

    #zy}


    # ---------> Update 2d & 3d nc: adding variable attributes
    cd ${DATA}; pwd

    file_log_attr=log_add_attribute_2d_3d_nc.${cycle}.log
    fn_ush_script_attr=stofs_3d_pac_add_attr_2d_3d_nc.sh

    export pgm="${USHstofs3d}/${fn_ush_script_attr}"

    file_log=add_attribute_2d_3d_nc.${cycle}
    
    rm -f $DATA/mpmdscript_add_attr

    echo "${USHstofs3d}/${fn_ush_script_attr} 1 > $DATA/${file_log}_1 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 2 > $DATA/${file_log}_2 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 3 > $DATA/${file_log}_3 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 4 > $DATA/${file_log}_4 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 5 > $DATA/${file_log}_5 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 6 > $DATA/${file_log}_6 " >> $DATA/mpmdscript_add_attr

    chmod 775 $DATA/mpmdscript_add_attr
    export MP_PGMMODEL=mpmd

    mpiexec -l -np 6 --cpu-bind verbose,core cfp $DATA/mpmdscript_add_attr

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally, WARNING"
       postmsg  "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg  "$msg"
    fi

    echo $msg
    echo



###if [ 0 -eq 1 ]; then    

    # ---------> create staout 6-min nc & SHEF file
    cd ${DATA}; pwd

    file_log_awips=log_create_awips_shef.${cycle}.log
    fn_ush_script_awips=stofs_3d_pac_create_awips_shef.sh
    export pgm="${USHstofs3d}/${fn_ush_script_awips}"
    ${USHstofs3d}/${fn_ush_script_awips} >> ${file_log_awips} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg  "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg  "$msg"
    fi

    echo $msg
    echo


    # ---------> create AWS/EC2 auto nc files
    cd ${DATA}; pwd

    file_log_autoval=log_stofs_3d_pac_create_AWS_autoval_nc.${cycle}.log
    fn_ush_script_autoval=stofs_3d_pac_create_AWS_autoval_nc.sh
    export pgm="${USHstofs3d}/${fn_ush_script_autoval}"
    ${USHstofs3d}/${fn_ush_script_autoval} >> ${file_log_autoval} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg  "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg  "$msg"
    fi

    echo $msg
    echo


###fi # if [ 0 -eq 1 ]; then


    # ---------> create profile netcdf files

    cd ${DATA}; pwd

    file_log_prof=log_create_sta_profile.${cycle}.log
    fn_ush_script_prof=stofs_3d_pac_create_station_profile_nc.sh
    export pgm="${USHstofs3d}/${fn_ush_script_prof}"
    
    file_log_prof_mpi=create_sta_profile.${cycle}
    
  
    dir_wk_profile=dir_profile 
    mkdir -p ${DATA}/${dir_wk_sta_prfile}

    # ncast
      postmsg "profile: begin ncast python, `date`"

      file_mpmd_prof_ncast=mpmdscript_sta_prof_ncast
      rm -f $DATA/${file_mpmd_prof_ncast}

      list_stack=(1 2)
      for stack_no_k in ${list_stack[@]}
      do
         echo "${USHstofs3d}/${fn_ush_script_prof} ${stack_no_k} > $DATA/${file_log_prof_mpi}_${stack_no_k} " >> $DATA/${file_mpmd_prof_ncast}
      done

      chmod 775 $DATA/${file_mpmd_prof_ncast}
      export MP_PGMMODEL=mpmd
      mpiexec -l -n 2 --cpu-bind verbose,core cfp $DATA/${file_mpmd_prof_ncast}

      postmsg "profile: done ncast python, `date`"

    # fcast
    # vgrid.npz from ncast

      postmsg "profile: begin fcast python, `date`"

      file_mpmd_prof_fcast=mpmdscript_sta_prof_fcast
      rm -f $DATA/${file_mpmd_prof_fcast}
                                
      list_stack=(3 4 5 6)
      for stack_no_k in ${list_stack[@]}
      do
         echo "${USHstofs3d}/${fn_ush_script_prof} ${stack_no_k} > $DATA/${file_log_prof_mpi}_${stack_no_k} " >> $DATA/${file_mpmd_prof_fcast}
      done

      chmod 775 $DATA/${file_mpmd_prof_fcast}
      export MP_PGMMODEL=mpmd
      mpiexec -l -n 4 --cpu-bind verbose,core cfp $DATA/${file_mpmd_prof_fcast}
      
      postmsg "profile: end fcast python, `date`"
    
    cd ${dir_wk_profile}

    fn_sta_profile_ncast_std=${RUN}.${cycle}.ncast.station.profile.nc
    rm -f ${fn_sta_profile_ncast_std}

    str_f=stofs_stations_profile   
    ncrcat -C ${str_f}_1_1.nc ${str_f}_2_2.nc  ${fn_sta_profile_ncast_std}
    cpreq -pf ${fn_sta_profile_ncast_std}  ${COMOUT}/${fn_sta_profile_ncast_std}

    fn_sta_profile_fcast_std=${RUN}.${cycle}.fcast.station.profile.nc
    rm -f ${fn_sta_profile_fcast_std}
    
    str_f=stofs_stations_profile
    ncrcat -C ${str_f}_3_3.nc ${str_f}_4_4.nc ${str_f}_5_5.nc ${str_f}_6_6.nc  ${fn_sta_profile_fcast_std}
    cpreq -pf ${fn_sta_profile_fcast_std}  ${COMOUT}/${fn_sta_profile_fcast_std}

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg  "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg  "$msg"
    fi

    echo $msg
    postmsg "`date` : $msg"
    echo



  #  ---------> Create ADCIRC format water level fields: stofs_3d_pac_create_adcirc_nc.sh
    cd ${DATA}; pwd

    file_log_adc=log_stofs_3d_pac_create_adcirc_nc.${cycle}.log
    fn_ush_script_adc=stofs_3d_pac_create_adcirc_nc.sh

    ## list_num=(1 2 3 4 5 6 7 8 9 10)
    #  list_num=($1)  

    export pgm="${USHstofs3d}/${fn_ush_script_adc}"

    file_log_adc_mpi=log_adc.${cycle}_mpi
    file_mpmd_adc_mpi=mpmdscript_adc
    
    rm -f $DATA/${file_mpmd_adc_mpi}

    #list_stack=(1 2 3 4 5 6 7 8 9 10)
    #for stack_no_k in ${list_stack[@]}
    #do
    #  echo "${USHstofs3d}/${fn_ush_script_adc} ${stack_no_k} > $DATA/${file_log_adc_mpi}_${stack_no_k} " >> $DATA/${file_mpmd_adc_mpi}   
    #done

    echo "${USHstofs3d}/${fn_ush_script_adc} 1 2 1 > $DATA/${file_log_adc_mpi}_1_2 " >> $DATA/${file_mpmd_adc_mpi}
    echo "${USHstofs3d}/${fn_ush_script_adc} 3 4 2 > $DATA/${file_log_adc_mpi}_3_4 " >> $DATA/${file_mpmd_adc_mpi}
    echo "${USHstofs3d}/${fn_ush_script_adc} 5 6 3 > $DATA/${file_log_adc_mpi}_5_6 " >> $DATA/${file_mpmd_adc_mpi}

    chmod 775 $DATA/${file_mpmd_adc_mpi}
    export MP_PGMMODEL=mpmd
    # mpiexec -l -np 10 --cpu-bind verbose,core cfp $DATA/${file_mpmd_adc_mpi}
    mpiexec -l -np 3 --cpu-bind verbose,core cfp $DATA/${file_mpmd_adc_mpi}


    #export pgm="${USHstofs3d}/${fn_ush_script_adc}"
    #${USHstofs3d}/${fn_ush_script_adc} >> ${file_log_adc} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg  "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg  "$msg"
    fi

    echo $msg
    echo

   
   # ----------> Create AWIPS grib2 files: conus_east_us & puertori masks
    cd ${DATA}; pwd

    file_log_grib2=log_create_awips_grib2_${cycle}.log
    fn_ush_script_grib2=stofs_3d_pac_create_awips_grib2.sh

    export pgm="${USHstofs3d}/${fn_ush_script_grib2}"
    ${USHstofs3d}/${fn_ush_script_grib2} >> ${file_log_grib2} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally - WARNING"
       postmsg  "$msg"
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg  "$msg"
    fi

    echo $msg
    echo



  # ---------------------------------------> Completed post processing

  msg=" Finished ${fn_this_sh}.sh  SUCCESSFULLY "
  postmsg  "$msg"


  chmod -Rf 755 $COMOUT


  echo
  echo $msg 
  echo


else
    
     msg=`echo FATAL ERROR: SCHISM model run did NOT finish successfully: Not Found \"${str_model_run_status}\" in ${fn_mirror}.`
  
     #echo -e $msg
     #echo -e $msg >> $pgmout

     postmsg $msg
     postmsg $pgmout $msg

     err_exit $msg   

# if [ -s ${fn_mirror} ] && [ -n "${str_model_run_status}" ]; then
fi




