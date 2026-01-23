#!/bin/bash


##############################################################################
#  Name: exstofs_3d_atl_post_2.sh                                            #
#  This script is a postprocessor to create the 2-D field nc files, namely,  #
#  stofs_3d_atl.t12z.????_???.field2d.nc, GeoPackage files and to generate   #
#  the restart file for the Nowcast run of the tomorrow's N/F cycle. The     #
#  The script copies the files to the com directory.                         #
#                                                                            #
#  Remarks:                                                                  #
#                                                        September, 2025     #
##############################################################################

  seton='-xa'
  setoff='+xa'
  set $seton


  cd ${DATA}

# ----------------------->
  fn_this_script=exstofs_3d_atl_post_2

  msg="${fn_this_script}.sh  started "
  echo "$msg"
  postmsg  "$msg"

  pgmout=${fn_this_script}.$$


# -----------------------> static files
#  fn_station_in=$FIXstofs3d/${RUN}_station.in
#  cpreq --remove-destination -f ${fn_station_in} station.in

  cd ${DATA}

  fn_src_nml=${COMOUTrerun}/${RUN}.${cycle}.param.nml
  ln -sf ${fn_src_nml} param.nml


# -----------------------> check & wait for model run complete
fn_mirror=${COMOUT}/outputs_watchdog/mirror.out
str_model_run_status="Run completed successfully"


# ----------------------->

flag_run_status=1
flag_run_status=`grep "${str_model_run_status}" ${fn_mirror} >/dev/null; echo $?`


if [[ ${flag_run_status} == 0 ]]; then    
    msg=`echo checked mirror.out: SCHISM model run was completed SUCCESSFULLY`
    echo $msg
    echo $msg >> $pgmout

     dir_outputs_local=${DATA}/outputs
  
     mkdir -p ${dir_outputs_local}
     cd ${DATA}

     # including: history nc & local_to_global & hotstart_*_576.nc
     #cpreq -fp ${COMOUT}/outputs_watchdog/hotstart_*_576.nc   ${dir_outputs_local}
     #cpreq -fp ${COMOUT}/outputs_watchdog/local_to_global_??????   ${dir_outputs_local}
     #cpreq -fp ${COMOUT}/outputs_2d3d_sta/*  ${dir_outputs_local}

     postmsg "before cp data to post_1 outputs"

     for i in ${COMOUT}/outputs_watchdog/local_to_global*; do
        cpreq  -f  "$i" ${dir_outputs_local};
     done

     cpreq -f ${COMOUT}/outputs_watchdog/{horizontalVelX,horizontalVelY,out2d,salinity,temperature,zCoordinates,verticalVelocity,diffusivity}_*.nc ${dir_outputs_local};
  
     TIME_STEP_restart=576
     cpreq -f ${COMOUT}/outputs_watchdog/hotstart_*_${TIME_STEP_restart}.nc  ${dir_outputs_local};

     postmsg "done cp data to post_1 outputs"

    # ---------> Update 2d & 3d nc: adding variable attributes
    cd ${DATA}; pwd

    file_log_attr=log_add_attribute_2d_3d_nc.${cycle}.log
    fn_ush_script_attr=stofs_3d_atl_add_attr_2d_3d_nc.sh

    export pgm="${USHstofs3d}/${fn_ush_script_attr}"

    file_log=add_attribute_2d_3d_nc.${cycle}
    
    rm -f $DATA/mpmdscript_add_attr

    echo "${USHstofs3d}/${fn_ush_script_attr} 1 > $DATA/${file_log}_1 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 2 > $DATA/${file_log}_2 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 3 > $DATA/${file_log}_3 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 4 > $DATA/${file_log}_4 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 5 > $DATA/${file_log}_5 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 6 > $DATA/${file_log}_6 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 7 > $DATA/${file_log}_7 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 8 > $DATA/${file_log}_8 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 9 > $DATA/${file_log}_9 " >> $DATA/mpmdscript_add_attr
    echo "${USHstofs3d}/${fn_ush_script_attr} 10 > $DATA/${file_log}_10 " >> $DATA/mpmdscript_add_attr

    chmod 775 $DATA/mpmdscript_add_attr
    export MP_PGMMODEL=mpmd
   
    mpiexec -l -np 10 --cpu-bind verbose,core cfp $DATA/mpmdscript_add_attr

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


  rm -f $DATA/mpmdscript_hot_slab2d

  #-----------------------------> merge hotstart files 
   file_log_create_hotstart=stofs_3d_atl_create_merged_hotstart_nc.${cycle}.log
   fn_ush_script_create_hotstart=stofs_3d_atl_create_merged_hotstart_nc.sh

     echo "${USHstofs3d}/${fn_ush_script_create_hotstart}  > $DATA/${file_log_create_hotstart} " >> $DATA/mpmdscript_hot_slab2d


  # ----------------------------> create 2D field files
    file_log_create_2d=log_create_2d_field_nc.${cycle}.log
    fn_ush_script_create_2d=stofs_3d_atl_create_2d_field_nc.sh
    #export pgm="${USHstofs3d}/${fn_ush_script}"

     echo "${USHstofs3d}/${fn_ush_script_create_2d} 1 > $DATA/${file_log_create_2d}_1 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 2 > $DATA/${file_log_create_2d}_2 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 3 > $DATA/${file_log_create_2d}_3 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 4 > $DATA/${file_log_create_2d}_4 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 5 > $DATA/${file_log_create_2d}_5 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 6 > $DATA/${file_log_create_2d}_6 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 7 > $DATA/${file_log_create_2d}_7 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 8 > $DATA/${file_log_create_2d}_8 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 9 > $DATA/${file_log_create_2d}_9 " >> $DATA/mpmdscript_hot_slab2d
     echo "${USHstofs3d}/${fn_ush_script_create_2d} 10 > $DATA/${file_log_create_2d}_10 " >> $DATA/mpmdscript_hot_slab2d


  # ----------------------------> finalize mpmdscript_hot_slab2d
    chmod 775 $DATA/mpmdscript_hot_slab2d
    export MP_PGMMODEL=mpmd

    N_np_hot_slab2d=11
    mpiexec -l -np ${N_np_hot_slab2d}  --cpu-bind verbose,core cfp $DATA/mpmdscript_hot_slab2d


    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of creating hotstart.nc, field_2d  did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       ## cat $DATA/${file_log}*
       err_chk
    else
       msg=" Execution of creating hotstart.nc, field_2d  completed normally"
       postmsg "$jlogfile" "$msg"
       ## cat $DATA/${file_log}*
    fi

    echo $msg
    echo


 # ---------> create GeoPackage files: 

    file_log_geo=log_geopackage.${cycle}.log
    fn_ush_script_geo=stofs_3d_atl_create_geopackage.sh


    export pgm="${USHstofs3d}/${fn_ush_script_geo}"
    ${USHstofs3d}/${fn_ush_script_geo} >> ${DATA}/${file_log_geo} 2>&1

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of $pgm did not complete normally, WARNING"
       postmsg  "$msg"
       ## cat ${DATA}/${file_log_geo}
       #err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg  "$msg"
       ## cat ${DATA}/${file_log_geo}
    fi

    echo $msg
    echo
 


  # ---------------------------------------> Completed post processing

  msg=" Finished ${fn_this_script}.sh  SUCCESSFULLY "
  postmsg  "$msg"


  chmod -Rf 755 $COMOUT


  echo
  echo $msg 
  echo


else
     msg=`echo FATAL ERROR: SCHISM model run did NOT finish successfully: Not Found \"${str_model_run_status}\" in ${fn_mirror}.`

     postmsg $msg
     postmsg $pgmout $msg

     err_exit $msg


# if [ -s ${fn_mirror} ] && [ -n "${str_model_run_status}" ]; then
fi




