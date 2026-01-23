#!/bin/bash

##############################################################################
#  Name: exstofs_3d_atl_now_forecast.sh                                      #
#  This script conducts the nowcast and forecast simulations. It copies the  #
#  run control, tidal, surface, river, open ocean boundary, nudging forcing  #
#  files, and the initial condition restart files to work directory and      #
#  invokes the mpiexe model simulations.                                     #
#                                                                            #
#  Remarks:                                                                  #
#                                                        September, 2025     #
##############################################################################

  seton='-xa'
  #setoff='+xa'
  set $seton


# ----------------------->  

  msg="stofs_3d_atl_ncast_forecast.sh started"
  echo "$msg"
  postmsg  "$msg"

  pgmout=pgmout_now_forecast.$$


  echo " In NF script: DATA=${DATA}"
  echo 

  mkdir -p $DATA
  mkdir -p ${DATA}/sflux
  mkdir -p ${DATA}/outputs

  cd ${DATA}

  # mpiexec pschism: augument 
    n_scribes=8


# --------------------------------------------------------------------------- #
#  copy model run static filess, e.g., model grid, station output control files, etc. 

ln -sf $FIXstofs3d/${RUN}_windrot_geo2proj.gr3  windrot_geo2proj.gr3
ln -sf $FIXstofs3d/${RUN}_watertype.gr3  watertype.gr3
ln -sf $FIXstofs3d/${RUN}_vgrid.in  vgrid.in
ln -sf $FIXstofs3d/${RUN}_tvd.prop  tvd.prop
ln -sf $FIXstofs3d/${RUN}_station.in  station.in
ln -sf $FIXstofs3d/${RUN}_shapiro.gr3  shapiro.gr3
ln -sf $FIXstofs3d/${RUN}_hgrid.ll  hgrid.ll
ln -sf $FIXstofs3d/${RUN}_hgrid.gr3  hgrid.gr3
ln -sf $FIXstofs3d/${RUN}_drag.gr3  drag.gr3
ln -sf $FIXstofs3d/${RUN}_diffmin.gr3  diffmin.gr3
ln -sf $FIXstofs3d/${RUN}_diffmax.gr3  diffmax.gr3
ln -sf $FIXstofs3d/${RUN}_albedo.gr3  albedo.gr3

ln -sf $FIXstofs3d/${RUN}_river_source_sink.in source_sink.in

ln -sf $FIXstofs3d/${RUN}_tem_nudge.gr3  TEM_nudge.gr3
ln -sf $FIXstofs3d/${RUN}_sal_nudge.gr3  SAL_nudge.gr3

ln -sf $FIXstofs3d/${RUN}_partition.prop partition.prop
  # Check/create partition.prop to match with PBS: nproc
    $USHstofs3d/stofs_3d_atl_create_partition_prop.sh   
    
    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of stofs_3d_atl_create_partition_prop.sh did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       err_chk
    else
       msg=" Execution of stofs_3d_atl_create_partition_prop.sh  completed normally"
       postmsg "$jlogfile" "$msg"
    fi 
       
    echo $msg
    echo 



# ---------------------------------------------->>  prepare forcing data 
  FLAG_all_exist_model_input_files=1

  list_fn_missed_input_forcing=
  list_fn_avail_input_forcing=

# ---------------------------------------> copy param.nml
# ---------------------------------------> copy param.nml

if [ 1 -eq 1 ]; then
  fn_src_nml=${COMOUTrerun}/${RUN}.${cycle}.param.nml
  fn_new_nml=param.nml
  if [ ! -s $fn_src_nml ]; then
     echo "${fn_src_nml} is not found"
     msg="WARNING: ${fn_src_nml} does not exist, WARNING"
     postmsg  "$msg"
  
     FLAG_all_exist_model_input_files=0; 
     list_fn_missed_input_forcing+=(" \n " $fn_src_nml)
     # exit 1
  else
     cp -p ${fn_src_nml} $DATA/${fn_new_nml}
     export err=$?; #err_chk
     echo "${fn_src_nml} is copied into working dir"
  fi
fi


# ---------------------------------------> copy bctides.in
# ---------------------------------------> copy bctides.in
fn_src_tide=${COMOUTrerun}/${RUN}.${cycle}.bctides.in
fn_new_tide=bctides.in
if [ ! -s $fn_src_tide ]; then
  echo "${fn_src_tide} is not found"
  msg="WARNING: ${fn_src_tide} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_tide)

  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_tide)

  cp -p ${fn_src_tide} $DATA/${fn_new_tide}

  export err=$?; #err_chk
  echo "${fn_src_tide} is copied into working dir"
fi


# ---------------------------------------> copy nwm/river forcing
# ---------------------------------------> copy nwm/river forcing
fn_src_msource=${COMOUTrerun}/${RUN}.${cycle}.msource.th
fn_new_msource=msource.th
if [ ! -s $fn_src_msource ]; then
  echo "${fn_src_msource} is not found"
  msg="WARNING: ${fn_src_msource} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_msource)

  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_msource)

  cp -p ${fn_src_msource} $DATA/${fn_new_msource}
  export err=$?; #err_chk
  echo "${fn_src_msource} is copied into working dir"
fi


fn_src_vsink=${COMOUTrerun}/${RUN}.${cycle}.vsink.th
fn_new_vsink=vsink.th
if [ ! -s $fn_src_vsink ]; then
  echo "${fn_src_vsink} is not found"
  msg="WARNING: ${fn_src_vsink} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_vsink)

  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_vsink)

  cp -p ${fn_src_vsink} $DATA/${fn_new_vsink}
  export err=$?; #err_chk
  echo "${fn_src_vsink} is copied into working dir"
fi


fn_src_vsource=${COMOUTrerun}/${RUN}.${cycle}.vsource.th
fn_new_vsource=vsource.th
if [ ! -s $fn_src_vsource ]; then
  echo "${fn_src_vsource} is not found"
  msg="WARNING: ${fn_src_vsource} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_vsource)

  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_vsource)

  cp -p ${fn_src_vsource} $DATA/${fn_new_vsource}
  export err=$?; #err_chk
  echo "${fn_src_vsource} is copied into working dir"
fi



# ---------------------------------------> copy St. Lawrence River/river forcing
# ---------------------------------------> copy St. Lawrence River/river forcing
fn_src_flux=${COMOUTrerun}/${RUN}.${cycle}.riv.obs.flux.th
fn_new_flux=flux.th
if [ ! -s $fn_src_flux ]; then
  echo "${fn_src_flux} is not found"
  msg="WARNING: ${fn_src_flux} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_flux)

  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_flux)

  cp -p ${fn_src_flux} $DATA/${fn_new_flux}
  export err=$?; #err_chk
  echo "${fn_src_flux} is copied into working dir"
fi


fn_src_TEM=${COMOUTrerun}/${RUN}.${cycle}.riv.obs.tem_1.th
fn_new_TEM=TEM_1.th
if [ ! -s $fn_src_TEM ]; then
  echo "${fn_src_TEM} is not found"
  msg="WARNING: ${fn_src_TEM} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_TEM)

  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_TEM)

  cp -p ${fn_src_TEM} $DATA/${fn_new_TEM}
  export err=$?; #err_chk
  echo "${fn_src_TEM} is copied into working dir"
fi



# ---------------------------------------> copy sflux/GFS forcing
# ---------------------------------------> copy sflux/GFS forcing
fn_src_input=$FIXstofs3d/${RUN}_sflux_inputs.txt
fn_new_input=sflux_inputs.txt
if [ ! -s $fn_src_input ]; then
  echo "${fn_src_input} is not found"
  msg="WARNING: ${fn_src_input} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_input)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_input)

  cp -p ${fn_src_input} $DATA/sflux/${fn_new_input}
  export err=$?; #err_chk
  echo "${fn_src_input} is copied into working dir"
fi


fn_src_gfs_rad=${COMOUTrerun}/${RUN}.${cycle}.gfs.rad.nc
fn_new_gfs_rad=sflux_rad_1.1.nc
if [ ! -s $fn_src_gfs_rad ]; then
  echo -e "${fn_src_gfs_rad} is not found"
  msg="WARNING: ${fn_src_gfs_rad} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_gfs_rad)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_gfs_rad)

  cp -p ${fn_src_gfs_rad} ${DATA}/sflux/${fn_new_gfs_rad}
  export err=$?; #err_chk
  echo -e "${fn_src_gfs_rad} is copied into working dir: ${fn_new_gfs_rad}"
fi


fn_src_gfs_prc=${COMOUTrerun}/${RUN}.${cycle}.gfs.prc.nc
fn_new_gfs_prc=sflux_prc_1.1.nc
if [ ! -s $fn_src_gfs_prc ]; then
  echo "${fn_src_gfs_prc} is not found"
  msg="WARNING: ${fn_src_gfs_prc} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_gfs_prc)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_gfs_prc)

  cp -p ${fn_src_gfs_prc} ${DATA}/sflux/${fn_new_gfs_prc}
  export err=$?; #err_chk
  echo "${fn_src_gfs_prc} is copied into working dir: ${fn_new_gfs_prc}"
fi


fn_src_gfs_air=${COMOUTrerun}/${RUN}.${cycle}.gfs.air.nc
fn_new_gfs_air=sflux_air_1.1.nc
if [ ! -s $fn_src_gfs_air ]; then
  echo "${fn_src_gfs_air} is not found"
  msg="WARNING: ${fn_src_gfs_air} does not exist, WARNING"
  postmsg  "$msg"

  FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_gfs_air)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_gfs_air)

  cp -p ${fn_src_gfs_air} ${DATA}/sflux/${fn_new_gfs_air}
  export err=$?; #err_chk
  echo "${fn_src_gfs_air} is copied into working dir: ${fn_new_gfs_air}"
fi


# ---------------------------------------> copy sflux/HRRR forcing
# ---------------------------------------> copy sflux/HRRR forcing
fn_src_hrrr_rad=${COMOUTrerun}/${RUN}.${cycle}.hrrr.rad.nc
fn_new_hrrr_rad=sflux_rad_2.1.nc
if [ ! -s $fn_src_hrrr_rad ]; then
  echo "${fn_src_hrrr_rad} is not found"
  msg="WARNING: ${fn_src_hrrr_rad} does not exist, WARNING"
  postmsg  "$msg"

  #FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_hrrr_rad)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_hrrr_rad)

  cp -p ${fn_src_hrrr_rad} ${DATA}/sflux/${fn_new_hrrr_rad}
  export err=$?; #err_chk
  echo "${fn_src_hrrr_rad} is copied into working dir: ${fn_new_hrrr_rad}"
fi


fn_src_hrrr_prc=${COMOUTrerun}/${RUN}.${cycle}.hrrr.prc.nc
fn_new_hrrr_prc=sflux_prc_2.1.nc
if [ ! -s $fn_src_hrrr_prc ]; then
  echo "${fn_src_hrrr_prc} is not found"
  msg="WARNING: ${fn_src_hrrr_prc} does not exist, WARNING"
  postmsg  "$msg"

  #FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_hrrr_prc)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_hrrr_prc)

  cp -p ${fn_src_hrrr_prc} ${DATA}/sflux/${fn_new_hrrr_prc}
  export err=$?; #err_chk
  echo "${fn_src_hrrr_prc} is copied into working dir: ${fn_new_hrrr_prc}"
fi


fn_src_hrrr_air=${COMOUTrerun}/${RUN}.${cycle}.hrrr.air.nc
fn_new_hrrr_air=sflux_air_2.1.nc
if [ ! -s $fn_src_hrrr_air ]; then
  echo "${fn_src_hrrr_air} is not found"
  msg="WARNING: ${fn_src_hrrr_air} does not exist, WARNING"
  postmsg  "$msg"

  #FLAG_all_exist_model_input_files=0;
  list_fn_missed_input_forcing+=(" \n " $fn_src_hrrr_air)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src_hrrr_air)

  cp -p ${fn_src_hrrr_air} ${DATA}/sflux/${fn_new_hrrr_air}
  export err=$?; #err_chk
  echo "${fn_src_hrrr_air} is copied into working dir: ${fn_new_hrrr_air}"
fi


# ---------------------------------------> copy rtofs/obc_3dth forcing
# ---------------------------------------> copy rtofs/obc_3dth forcing
files_obc_th=(elev2dth.nc tem3dth.nc sal3dth.nc uv3dth.nc)
#temnu.nc salnu.nc)

files_new_rtofs_th=(elev2D.th.nc TEM_3D.th.nc SAL_3D.th.nc uv3D.th.nc)

cnt=0
for fn_k in ${files_obc_th[@]}; do
  fn_src_rtofs_th_k=${COMOUTrerun}/${RUN}.${cycle}.${fn_k}
  fn_new_rtofs_th_k=${files_new_rtofs_th[$cnt]}

  echo $fn_src_rtofs_th_k, $fn_new_rtofs_th_k

  if [ ! -s $fn_src_rtofs_th_k ]; then
    echo "${fn_src_rtofs_th} is not found"
    msg="WARNING: ${fn_src_rtofs_th_k} does not exist, WARNING"
    postmsg  "$msg"

    FLAG_all_exist_model_input_files=0;
    list_fn_missed_input_forcing+=(" \n " $fn_src_rtofs_th_k)
    # exit 1

  else
    list_fn_avail_input_forcing+=(" \n " $fn_src_rtofs_th_k)

    cpreq -pf ${fn_src_rtofs_th_k} ${DATA}/${fn_new_rtofs_th_k}
    export err=$?; #err_chk
    echo "${fn_src_rtofs_th_k} is copied into working dir: ${fn_new_rtofs_th_k}"
  fi

  cnt=$(expr $cnt + 1)

done


# ---------------------------------------> copy rtofs/nudge forcing
# ---------------------------------------> copy rtofs/nudge forcing
files_nudge=(temnu.nc salnu.nc)

files_new_rtofs_nu=(TEM_nu.nc SAL_nu.nc)

cnt=0
for fn_k in ${files_nudge[@]}; do
  fn_src_rtofs_nu_k=${COMOUTrerun}/${RUN}.${cycle}.${fn_k}
  fn_new_rtofs_nu_k=${files_new_rtofs_nu[$cnt]}

  echo $fn_src_rtofs_nu_k, $fn_new_rtofs_nu_k

  if [ ! -s $fn_src_rtofs_nu_k ]; then
    echo "${fn_src_rtofs_nu_k} is not found"
    msg="WARNING: ${fn_src_rtofs_nu} does not exist, WARNING"
    postmsg  "$msg"

    FLAG_all_exist_model_input_files=0;
    list_fn_missed_input_forcing+=(" \n " $fn_src_rtofs_nu_k)
    # exit 1

  else
    list_fn_avail_input_forcing+=(" \n " $fn_src_rtofs_nu_k)

    cpreq -pf ${fn_src_rtofs_nu_k} ${DATA}/${fn_new_rtofs_nu_k}
    export err=$?; #err_chk
    echo "${fn_src_rtofs_nu_k} is copied into working dir: ${fn_new_rtofs_nu_k}"
  fi

  cnt=$(expr $cnt + 1)

done


# =======================================> Hot restart or cold restart
  
  msg="\n Begin: ${SCRIstofs3d}/exstofs_3d_atl_hot_restart_prep.sh \n"
  echo -e  $msg; echo -e  $msg >> $pgmout

  ${SCRIstofs3d}/exstofs_3d_atl_hot_restart_prep.sh   >> $pgmout 2>>  errfile 

  export err=$?
  if [ $err -eq 0 ]; then
      msg="\n  End: ${SCRIstofs3d}/exstofs_3d_atl_hot_restart_prep.sh  completed normally \n"
      echo -e  $msg; echo -e  $msg >> $pgmout
  else
    msg=`echo ${SCRIstofs3d}/exstofs_3d_atl_hot_restart_prep.sh  did not complete normally`
    echo -e  $msg; echo -e  $msg >> $pgmout
  fi


cd ${DATA}
# exstofs_3d_atl_hot_restart_prep.sh prep hotstart.nc (cold or merged post crash)
if [[ $(find  -L hotstart.nc -type f -size  +20G 2>/dev/null) ]]; then
    msg="restart.nc:  ${fn_restart_rerun}"
    
    list_fn_avail_input_forcing+=(" \n " $fn_restart_rerun)
    msg="Valid: restart.nc=./hotstart.nc: checked \n"

else 
    fn_restart_hotstart="${fn_restart_rerun}"
    FLAG_all_exist_model_input_files=0
    list_fn_missed_input_forcing+=(" \n " ${fn_restart_rerun})

    echo -e "\n ${fn_restart_rerun}/hotstart file is not found in ${COMOUTrerun}"
    msg="\n WARNING: None existing: ${COMOUTrerun} - WARNING"

fi


# =======================================> Conclude availability of full suite of needed files
    if [ ${FLAG_all_exist_model_input_files} == 1 ]; then
        echo "Successful: FLAG_all_exist_model_input_files = ${FLAG_all_exist_model_input_files}"; echo

    fi


echo -e  $msg; echo -e  $msg >> $pgmout
postmsg  "$msg"



# ---------------------------------------> SCHISM model run
# ---------------------------------------> SCHISM model run
 
  msg=''
  msg+="Before submission of mpiexe pschchism: "
        
if [ ${FLAG_all_exist_model_input_files} -eq 0 ];then
     msg+="FATAL EORROR:: FLAG_all_exist_model_input_files=${FLAG_all_exist_model_input_files}"
     msg+=`echo -e ${list_fn_missed_input_forcing[@]}`
     msg+="\n Script run is being stopped at this step"

     echo -e  $msg; echo -e  $msg >> $pgmout
     postmsg  "$msg"

     err_exit

else
     msg+="All needed files for pschism run are available: FLAG_all_exist_model_input_files=${FLAG_all_exist_model_input_files}; "  	  
      msg+="List of available input/forcing files: "
      msg+=`echo -e ${list_fn_avail_input_forcing[@]}`

     echo -e  $msg; echo -e  $msg >> $pgmout
     postmsg  "$msg"

  
  msg=" Submited - mpiexec -n $NCPU_PBS  --cpu-bind core  pschism_WCOSS2_VL $n_scribes"
  echo "${msg}"; echo "$msg" >> "$pgmout"


  # setup 'static' upper level dir
    cd ${DATA}
    mkdir -p outputs

    dir_current=`pwd | awk -F'/' '{print $NF}'`

    # archive NF_dir_name in COMOUT/rerun
    dir_NF_run_outputs=${DATA}/outputs
    echo "dir_NF_run_outputs=${dir_NF_run_outputs}"

    
    fn_dir_NF_run_outputs=file_one_line_dir_NF_run_outputs
    fn_dir_NF_run_outputs_full_path=${COMOUT}/rerun/${fn_dir_NF_run_outputs}

    # get 
       rm -f ${COMOUT}/rerun/${fn_dir_NF_run_outputs}_previous
       mv ${COMOUT}/rerun/${fn_dir_NF_run_outputs} ${COMOUT}/rerun/${fn_dir_NF_run_outputs}_previous

       str_pid_JOBS_NF_run_dir_NF_wk="${pid_JOBS_NF_run}  ${dir_NF_run_outputs}"
       echo ${str_pid_JOBS_NF_run_dir_NF_wk} > ${COMOUT}/rerun/${fn_dir_NF_run_outputs} 


  # N/F model run:      
  # mpiexec -n $NCPU_PBS  --cpu-bind core  pschism_WCOSS2_VL  $n_scribes  >> $pgmout 2>>  errfile

 
    echo
    echo pschism_WCOSS2_VL=${EXECstofs3d}/stofs_3d_atl_pschism
    echo
    mpiexec -n $NCPU_PBS  --cpu-bind core  ${EXECstofs3d}/stofs_3d_atl_pschism  $n_scribes  >> $pgmout 2>>  errfile


  # (2024/02/21) mpiexec -n $NCPU_PBS  --cpu-bind core  ${EXECstofs3d}/stofs_3d_atl_pschism  $n_scribes  >> $pgmout 2>>  errfile


  mv {COMOUT}/rerun/${fn_dir_NF_run_outputs} {COMOUT}/rerun/${fn_dir_NF_run_outputs}_most_recent

  

  export err=$?
  if [ $err -eq 0 ]; then
      msg=`echo $pgm  completed normally`
      echo -e  $msg; echo -e  $msg >> $pgmout
  else
    msg=`echo $pgm did not complete normally`
    echo -e  $msg; echo -e  $msg >> $pgmout
  fi

  msg="Finished - mpiexec -n $NCPU_PBS  --cpu-bind core  pschism_WCOSS2_VL $n_scribes"
  echo "${msg}"; echo "$msg" >> "$pgmout"

  sleep 180s

  # check outputs/mirror.out
  fn_mirror=outputs/mirror.out
  str_model_run_status="Run completed successfully"

  flag_check_run_status=`grep "Run completed successfully"  outputs/mirror.out 2> error_check_run_status.txt`

  if [ -s ${fn_mirror} ] && [ -n "${flag_check_run_status}" ]; then

    cpreq ${fn_mirror} ${COMOUTrerun}/mirror.out_nfcast_script_cp     
  

                 cd ${DATA}

                 TIME_STEP_FNL=2880
                 cpreq -f  outputs/hotstart_*_${TIME_STEP_FNL}.nc  ${COMOUT}/outputs_watchdog/
                  
                 cpreq -f  outputs/staout_*  ${COMOUT}/outputs_watchdog/
                 cpreq -f  outputs/staout_1  ${COMOUT}/


                 CNT_hist_nc_FNL=10 
                 cpreq -f  outputs/{horizontalVelX,horizontalVelY,out2d,salinity,temperature,zCoordinates,verticalVelocity,diffusivity}_${CNT_hist_nc_FNL}.nc  ${COMOUT}/outputs_watchdog/

                 cpreq -f  outputs/mirror.out  ${COMOUT}/outputs_watchdog/
              

    msg=`echo $pgm completed SUCCESSFULLY`
    echo -e  $msg
    echo -e  $msg >> $pgmout 

  else
     msg=`echo $pgm completed UNsuccessfully: Not Found \"${str_model_run_status}\" in ${fn_mirror}`
     echo -e  $msg
     echo -e  $msg >> $pgmout

  fi


  msg=" Finished stofs_3d_atl_ncast_forecast.sh SUCCESSFULLY "
  postmsg  "$msg"


  echo
  echo -e  $msg 
  echo 


fi


