#!/bin/bash

##############################################################################
#  Name: exstofs_3d_atl_now_forecast.sh                                         #
#  This script conducts the nowcast and forecast simulations. It copies the  #
#  run control, tidal, surface, river, open ocean boundary, nudging forcing  #
#  files, and the initial condition restart files to work directory and      #
#  invokes the mpiexe model simulations.                                     #
#                                                                            #
#  Remarks:                                                                  #
#                                                        September, 2022     #
##############################################################################

  seton='-xa'
  setoff='+xa'
  set $seton


# ----------------------->  

  msg="stofs_3d_atl_ncast_forecast.sh started at UTC:  `date -u +%Y%m%d%H`"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

  pgmout=pgmout_now_forecast.$$


  mkdir -p $DATA
  mkdir -p ${DATA}/sflux
  mkdir -p ${DATA}/outputs

  cd ${DATA}

  # mpiexec pschism: augument 
  n_scribes=6


# --------------------------------------------------------------------------- #
# 2.  copy model run static filess, e.g., model grid, station output control files, etc. 

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



start_time=$(date +%s)
max_seconds=$(( 60 * 60 )) # minutes * seconds

time_sleep_s=600


FLAG_all_exist_model_input_files=1
time_elapsed=0
while [[ ${time_elapsed} -le $max_seconds ]]; do

    time_elapsed=$(($(date +%s) - $start_time))

    echo "Elapsed time (sec) =  ${time_elapsed} "

  list_fn_missed_input_forcing=
  list_fn_avail_input_forcing=



# ---------------------------------------> copy param.nml
# ---------------------------------------> copy param.nm
fn_src=${COMOUTrerun}/${RUN}.${cycle}.param.nml
fn_new=param.nml
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)

  #exit 1
else
  cp -p ${fn_src} $DATA/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir"
fi


# ---------------------------------------> copy bctides.in
# ---------------------------------------> copy bctides.in
fn_src=${COMOUTrerun}/${RUN}.${cycle}.bctides.in
fn_new=bctides.in
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} $DATA/${fn_new}
  
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir"
fi


# ---------------------------------------> copy nwm/river forcing
# ---------------------------------------> copy nwm/river forcing
fn_src=${COMOUTrerun}/${RUN}.${cycle}.msource.th
fn_new=msource.th
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
 
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
 
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} $DATA/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir"
fi


fn_src=${COMOUTrerun}/${RUN}.${cycle}.vsource.th
fn_new=vsource.th
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} $DATA/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir"
fi


fn_src=${COMOUTrerun}/${RUN}.${cycle}.vsink.th
fn_new=vsink.th
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} $DATA/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir"
fi


# ---------------------------------------> copy sflux/GFS forcing
# ---------------------------------------> copy sflux/GFS forcing
fn_src=$FIXstofs3d/${RUN}_sflux_inputs.txt
fn_new=sflux_inputs.txt
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} $DATA/sflux/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir"
fi


fn_src=${COMOUTrerun}/${RUN}.${cycle}.gfs.rad.nc
fn_new=sflux_rad_1.0001.nc
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} ${DATA}/sflux/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir: ${fn_new}"
fi


fn_src=${COMOUTrerun}/${RUN}.${cycle}.gfs.prc.nc
fn_new=sflux_prc_1.0001.nc
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} ${DATA}/sflux/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir: ${fn_new}"
fi


fn_src=${COMOUTrerun}/${RUN}.${cycle}.gfs.air.nc
fn_new=sflux_air_1.0001.nc
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} ${DATA}/sflux/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir: ${fn_new}"
fi


# ---------------------------------------> copy sflux/HRRR forcing
# ---------------------------------------> copy sflux/HRRR forcing
fn_src=${COMOUTrerun}/${RUN}.${cycle}.hrrr.rad.nc
fn_new=sflux_rad_2.0001.nc
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  #FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} ${DATA}/sflux/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir: ${fn_new}"
fi


fn_src=${COMOUTrerun}/${RUN}.${cycle}.hrrr.prc.nc
fn_new=sflux_prc_2.0001.nc
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  #FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} ${DATA}/sflux/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir: ${fn_new}"
fi


fn_src=${COMOUTrerun}/${RUN}.${cycle}.hrrr.air.nc
fn_new=sflux_air_2.0001.nc
if [ ! -s $fn_src ]; then
  echo "${fn_src} is not found"
  msg="WARNING: ${fn_src} does not exist, WARNING"
  postmsg "$jlogfile" "$msg"
  
  #FLAG_all_exist_model_input_files=0; 
  list_fn_missed_input_forcing+=(" \n " $fn_src)
  # exit 1

else
  list_fn_avail_input_forcing+=(" \n " $fn_src)

  cp -p ${fn_src} ${DATA}/sflux/${fn_new}
  export err=$?; #err_chk
  echo "${fn_src} is copied into working dir: ${fn_new}"
fi


# ---------------------------------------> copy rtofs/obc_3dth forcing
# ---------------------------------------> copy rtofs/obc_3dth forcing
files_obc_th=(elev2dth.nc tem3dth.nc sal3dth.nc uv3dth.nc)
#temnu.nc salnu.nc)

files_new=(elev2D.th.nc TEM_3D.th.nc SAL_3D.th.nc uv3D.th.nc)

cnt=0
for fn_k in ${files_obc_th[@]}; do
  fn_src_k=${COMOUTrerun}/${RUN}.${cycle}.${fn_k}
  fn_new_k=${files_new[$cnt]}

  echo $fn_src_k, $fn_new_k

  if [ ! -s $fn_src_k ]; then
    echo "${fn_src} is not found"
    msg="WARNING: ${fn_src_k} does not exist, WARNING"
    postmsg "$jlogfile" "$msg"
   
    FLAG_all_exist_model_input_files=0; 
    list_fn_missed_input_forcing+=(" \n " $fn_src_k)
    # exit 1

  else
    list_fn_avail_input_forcing+=(" \n " $fn_src_k)

    cpreq -pf ${fn_src_k} ${DATA}/${fn_new_k}
    export err=$?; #err_chk
    echo "${fn_src_k} is copied into working dir: ${fn_new_k}"
  fi

  cnt=$(expr $cnt + 1)

done


# ---------------------------------------> copy rtofs/nudge forcing
# ---------------------------------------> copy rtofs/nudge forcing
files_nudge=(temnu.nc salnu.nc)

files_new=(TEM_nu.nc SAL_nu.nc)

cnt=0
for fn_k in ${files_nudge[@]}; do
  fn_src_k=${COMOUTrerun}/${RUN}.${cycle}.${fn_k}
  fn_new_k=${files_new[$cnt]}

  echo $fn_src_k, $fn_new_k

  if [ ! -s $fn_src_k ]; then
    echo "${fn_src_k} is not found"
    msg="WARNING: ${fn_src} does not exist, WARNING"
    postmsg "$jlogfile" "$msg"
  
    FLAG_all_exist_model_input_files=0; 
    list_fn_missed_input_forcing+=(" \n " $fn_src_k)
    # exit 1

  else
    list_fn_avail_input_forcing+=(" \n " $fn_src_k)

    cpreq -pf ${fn_src_k} ${DATA}/${fn_new_k}
    export err=$?; #err_chk
    echo "${fn_src_k} is copied into working dir: ${fn_new_k}"
  fi

  cnt=$(expr $cnt + 1)

done


# ---------------------------------------> copy restart/hotstart file
# ---------------------------------------> copy restart/hotstart file
# files saved in the previous day COMOUT/


fn_restart_rerun=${COMOUTrerun}/${RUN}.${cycle}.restart.nc

if [[ $(find ${fn_restart_rerun} -type f -size  +20G 2>/dev/null) ]]; then
    msg="restart.nc:  ${fn_restart_rerun}"
    ln -sf  ${fn_restart_rerun} ${DATA}/hotstart.nc
    # cpreq -pf ${fn_restart_rerun} ${DATA}/hotstart.nc
    
    list_fn_avail_input_forcing+=(" \n " $fn_restart_rerun)
    msg="restart.nc=${fn_restart_rerun}"

else 
    fn_restart_hotstart="${fn_restart_rerun}"
    FLAG_all_exist_model_input_files=0
    list_fn_missed_input_forcing+=(" \n " ${fn_restart_rerun})

    echo -e "\n ${fn_restart_rerun}/hotstart file is not found in ${COMOUTrerun}"
    msg="\n WARNING: None existing: ${COMOUTrerun} - WARNING"

fi


    if [ ${FLAG_all_exist_model_input_files} == 1 ]; then
        echo "Successful: FLAG_all_exist_model_input_files = ${FLAG_all_exist_model_input_files}"; echo
        break
    else
        FLAG_all_exist_model_input_files=1
        echo "Wait for ${time_sleep_s} more seconds"
        sleep ${time_sleep_s}    # 10min=600s
    fi


done    # while [[ ${time_elapsed} -le $max_seconds ]];


echo -e  $msg; echo -e  $msg >> $pgmout
postmsg "$jlogfile" "$msg"



# ---------------------------------------> SCHISM model run
# ---------------------------------------> SCHISM model run
 
  msg=''
  msg+="Before submission of mpiexe pschchism: "
        
  if [ ${FLAG_all_exist_model_input_files} -eq 0 ];then
     msg+="FATAL EORROR:: FLAG_all_exist_model_input_files=${FLAG_all_exist_model_input_files}"
     msg+=`echo ${list_fn_missed_input_forcing[@]}`
     msg+="\n Script run is being stopped at this step, UTM: `date`"

     echo -e  $msg; echo -e  $msg >> $pgmout
     postmsg "$jlogfile" "$msg"

     err_exit

  else
     msg+="All needed files for pschism run are available: FLAG_all_exist_model_input_files=${FLAG_all_exist_model_input_files}; "  	  
      msg+="List of available input/forcing files: "
      msg+=`echo ${list_fn_avail_input_forcing[@]}`

     echo -e  $msg; echo -e  $msg >> $pgmout
     postmsg "$jlogfile" "$msg"

  fi	  


  rm -rf outputs
  mkdir -p outputs

  
  msg="`date` :: Submited - mpiexec -n $NCPU_PBS  --cpu-bind core  ${EXECstofs3d}/pschism $n_scribes"
  echo "${msg}"; echo "$msg" >> "$pgmout"

  mpiexec -n $NCPU_PBS  --cpu-bind core  ${EXECstofs3d}/stofs_3d_atl_pschism  $n_scribes  >> $pgmout 2> errfile

  msg="`date`:: Finished - mpiexec -n $NCPU_PBS  --cpu-bind core  ${EXECstofs3d}/pschism $n_scribes"
  echo "${msg}"; echo "$msg" >> "$pgmout"

  export err=$?
  if [ $err -eq 0 ]; then
      msg=`echo $pgm  completed normally`
      echo -e  $msg; echo -e  $msg >> $pgmout
  else
    msg=`echo $pgm did not complete normally`
    echo -e  $msg; echo -e  $msg >> $pgmout
  fi


  # check outputs/mirror.out
  fn_mirror=outputs/mirror.out
  str_model_run_status="Run completed successfully"

  flag_check_run_status=`grep "Run completed successfully"  outputs/mirror.out 2> error_check_run_status.txt`

  if [ -s ${fn_mirror} ] && [ -n "${flag_check_run_status}" ]; then

    msg=`echo $pgm completed SUCCESSFULLY`
    echo -e  $msg
    echo -e  $msg >> $pgmout 

  else

     msg=`echo $pgm completed UNsuccessfully: Not Found \"${str_model_run_status}\" in ${fn_mirror}`
     echo -e  $msg
     echo -e  $msg >> $pgmout

     export err=9
     err_chk

  fi


msg=" Finished stofs_3d_atl_ncast_forecast.sh SUCCESSFULLY "
postmsg "$jlogfile" "$msg"

#cp -p $jlogfile $COMOUT

echo
echo -e  $msg at `date`
echo 




