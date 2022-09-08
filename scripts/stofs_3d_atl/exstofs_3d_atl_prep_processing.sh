#!/bin/bash 

##############################################################################
#  Name: exstofs_3d_atl_prep_processing.sh                                      #
#  This script prepares the files needed by the nowcast and forecast         #
#  simulations, which includes the run control, tidal, river, surface, ope   #
#  ocean boundary, nudging forcings, and the initial condition restart       #
#  files                                                                     #
#                                                                            #
#  Remarks:                                                                  #
#                                                        September, 2022     #
##############################################################################


  seton='-xa'
  setoff='+xa'
  set $setoff

  fn_this_script="exstofs_3d_atl_prep_processing.sh"

  msg="Starting script: STOFS3D prepare model control & forcing files"
  echo "$msg"
  postmsg "$jlogfile" "$msg"


  echo "module list in ${fn_this_script}"
  module list
  echo; echo

 
  # flag to control the type of restart file
  # FLAG_RESTART_RTOFS= 0: use stofs3D hotstart.nc; 1: only use RTOFS; 2: combined RTOFS restart & STOFS3D hotstart

  # ----------> define rtofs rst date
   MMDD_ANNUAL_UPDATE_RESTART_FILE=0105
   MMDD_FCAST_BEGIN=${PDYHH_FCAST_BEGIN:4:4} 
    
   FLAG_RESTART_RTOFS=0  
   if [[ ${MMDD_FCAST_BEGIN} == ${MMDD_ANNUAL_UPDATE_RESTART_FILE} ]]; then
      FLAG_RESTART_RTOFS=1
   fi

    msg="FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}; MMDD_ANNUAL_UPDATE_RESTART_FILE=${MMDD_ANNUAL_UPDATE_RESTART_FILE}; PDYHH_FCAST_BEGIN=${PDYHH_FCAST_BEGIN}"
    echo "$msg"; postmsg "$jlogfile" "$msg"      
    echo "FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}"; echo 

   echo "In ${fn_this_script}: FLAG_RESTART_RTOFS = " ${FLAG_RESTART_RTOFS}
   echo
  
  mkdir -p ${DATA}
  cd $DATA

# ----------------------------------------> Static files
# copy/ln  model run static filess, e.g., model grid, station output control files, etc. 

ln -sf $FIXstofs3d/${RUN}_windrot_geo2proj.gr3  windrot_geo2proj.gr3
ln -sf $FIXstofs3d/${RUN}_watertype.gr3  watertype.gr3
ln -sf $FIXstofs3d/${RUN}_vgrid.in  vgrid.in
ln -sf $FIXstofs3d/${RUN}_tvd.prop  tvd.prop
ln -sf $FIXstofs3d/${RUN}_tem_nudge.gr3  TEM_nudge.gr3
ln -sf $FIXstofs3d/${RUN}_station.in  station.in
ln -sf $FIXstofs3d/${RUN}_river_source_sink.in  source_sink.in
ln -sf $FIXstofs3d/${RUN}_shapiro.gr3  shapiro.gr3
ln -sf $FIXstofs3d/${RUN}_sal_nudge.gr3  SAL_nudge.gr3
ln -sf $FIXstofs3d/${RUN}_param.nml_6globaloutput param.nml_template 
ln -sf $FIXstofs3d/${RUN}_river_msource.th  msource.th
ln -sf $FIXstofs3d/${RUN}_hrrr_sflux_template.nc  hrrr_sflux_template.nc
ln -sf $FIXstofs3d/${RUN}_hgrid.ll  hgrid.ll
ln -sf $FIXstofs3d/${RUN}_hgrid.gr3  hgrid.gr3
ln -sf $FIXstofs3d/${RUN}_estuary.gr3  estuary.gr3
ln -sf $FIXstofs3d/${RUN}_drag.gr3  drag.gr3
ln -sf $FIXstofs3d/${RUN}_diffmin.gr3  diffmin.gr3
ln -sf $FIXstofs3d/${RUN}_diffmax.gr3  diffmax.gr3
ln -sf $FIXstofs3d/${RUN}_bctides.in_template  bctides.in_template
ln -sf $FIXstofs3d/${RUN}_albedo.gr3  albedo.gr3
ln -sf $FIXstofs3d/${RUN}_partition.prop  partition.prop



# ---------------------------------------> create param.nml
# ---------------------------------------> create param.nm
file_log=log_create_param_nml.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_atl_create_param_nml.sh"
${USHstofs3d}/stofs_3d_atl_create_param_nml.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg "$jlogfile" "$msg"
   # #err_chk
else
	   msg=" Execution of $pgm completed normally"
	   postmsg "$jlogfile" "$msg"
fi

echo $msg
echo 

# ---------------------------------------> create bctides.in
# ---------------------------------------> create bctides.in
file_log=log_create_bctides.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_atl_create_bctides_in.sh"
${USHstofs3d}/stofs_3d_atl_create_bctides_in.sh >> ${file_log} 2>&1  


export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg "$jlogfile" "$msg"
   # #err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
fi

echo $msg
echo


# ---------------------------------------> create nwm/river forcing
# ---------------------------------------> create nwm/river forcing

file_log=log_create_river_forcing_nwm.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_atl_create_river_forcing_nwm.sh"
${USHstofs3d}/stofs_3d_atl_create_river_forcing_nwm.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg "$jlogfile" "$msg"
   # #err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
fi

echo $msg
echo




# ---------------------------------------> create sflux/GFS forcing
# ---------------------------------------> create sflux/GFS forcing
file_log=log_create_surface_forcing_gfs.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_atl_create_surface_forcing_gfs.sh"
${USHstofs3d}/stofs_3d_atl_create_surface_forcing_gfs.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg "$jlogfile" "$msg"
   # #err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
fi

echo $msg
echo


# ---------------------------------------> create sflux/HRRR forcing
# ---------------------------------------> create sflux/HRRR forcing
file_log=log_create_surface_forcing_hrrr.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_atl_create_surface_forcing_hrrr.sh"  
${USHstofs3d}/stofs_3d_atl_create_surface_forcing_hrrr.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg "$jlogfile" "$msg"
   # #err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
fi

echo $msg
echo


# ---------------------------------------> create rtofs/obc_3dth_nudge forcing
# ---------------------------------------> create rtofs/obc_3dth_nudge forcing
file_log=log_create_obc_3dth_nudge.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_atl_create_obc_3dth_nudge.sh"
${USHstofs3d}/stofs_3d_atl_create_obc_3dth_nudge.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg "$jlogfile" "$msg"
   # #err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
fi

echo $msg
echo


# ---------------------------------------> create restart file 
# FLAG_RESTART_RTOFS=1: only use RTOFS 
# FLAG_RESTART_RTOFS=2: use combined RTOFS restart & STOFS3D hotstart

file_log=log_create_restart.${cycle}.log

fn_restart_coldstart_fix=${FIXstofs3d}/stofs_3d_atl_restart_coldstart.nc
#fn_hotstart_oper_prev=${COMOUT_PREV}/${RUN}.${cycle}.hotstart.stofs3d.nc
#z fn_restart_oper=${DATA_prep_restart}/${RUN}.${cycle}.restart.stofs3d.nc
fn_restart_rerun=${COMOUTrerun}/${RUN}.${cycle}.restart.nc

mkdir -p ${COMOUTrerun} 
mkdir -p ${DATA_prep_restart}


if [[ $COLDSTART = YES ]]; then
    msg="${msg}\n restart.nc: COLDSTART=${COLDSTART}, restart file from fix/"
    echo -e ${msg}; echo "${msg}" >> ${file_log}

    if [[ $(find ${fn_restart_coldstart_fix} -type f -size  +20G 2>/dev/null) ]]; then
       cpreq -fp ${fn_restart_coldstart_fix} ${fn_restart_rerun}
       msg="${msg}\n done: copy ${fn_restart_coldstart_fix} \n  ${fn_restart_rerun}"
       echo -e "${msg}"; echo "${msg}" >> ${file_log} 

    else
       msg="WARNING: not found - ${{fn_restart_coldstart_fix}";
       echo "${msg}"; echo "${msg}" >> ${file_log}
    fi	    


else   # COLDSTART=NO
   msg="COLDSTART=${COLDSTART}"


# ------------------------
  LIST_fn_fnl_hotstart=''
  days=(0 1 2 3 4)

  cnt_files=0
  for k in ${days[@]}; do
      date_k=`date -d "${PDYHH_NCAST_BEGIN:0:8} ${k} days ago" +%Y%m%d`

      fn_hotstart_oper=${COMROOT}/${RUN}.${date_k}/${RUN}.${cycle}.hotstart.stofs3d.nc

      if [ -s $fn_hotstart_oper ]; then
        if [[ $(find ${fn_hotstart_oper} -type f -size  +20G 2>/dev/null) ]];
        then
           LIST_fn_fnl_hotstart+="${fn_hotstart_oper} "
           echo "OK: $fn_hotstart_oper : filesize $filesize (GT 22GB)"
           cnt_files=$((cnt_files+1))
        else
           echo "WARNING: " $fn_hotstart_oper ": filesize less than 22GB"
        fi
      else
        echo "WARNING: "  $fn_hotstart_oper " does not exist"
      fi
  done
  echo "cnt_files = " ${cnt_files}

  if [[ $cnt_files -ge 1 ]]; then
     LIST_fn_fnl_hotstart=(${LIST_fn_fnl_hotstart[@]})

     fn_hotstart_oper_prev=${LIST_fn_fnl_hotstart[0]};
     echo "found: fn_hotstart_oper_prev = ${fn_hotstart_oper_prev}"
   
     msg="FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}"
     if [[ ${FLAG_RESTART_RTOFS} -ne 1 ]]; then
      cpreq -pf ${fn_hotstart_oper_prev} ${fn_restart_rerun}

      msg="${msg}\n restart.nc: without using RTOFS"
      echo -e ${msg}; echo "${msg}" >> ${file_log}
     fi	   
  else
     msg="WARNING: not found - ${fn_hotstart_oper_prev}"; 
     echo "${msg}"; echo "${msg}" >> ${file_log}
  fi	


msg="FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}"
if [ ${FLAG_RESTART_RTOFS} -eq 1 ]; then
   
   pgm="${USHstofs3d}/stofs_3d_atl_create_restart_combine_rtofs_stofs.sh"
   ${USHstofs3d}/stofs_3d_atl_create_restart_combine_rtofs_stofs.sh >> ${file_log} 2>&1

   msg="${msg}\n restart.nc: used RTOFS"
fi
   echo -e "${msg}"; echo "${msg}" >> ${file_log} 2>&1  


export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg "$jlogfile" "$msg"
   # #err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg "$jlogfile" "$msg"
fi

echo $msg
echo

fi  # COLDSTART


# ---------------------------------------> Completed preparing param.nml, bctides, forcing files

msg=" Finished creating  param.nml, bctides, river/gfs/hrrr/rtofs forcing files SUCCESSFULLY "
postmsg "$jlogfile" "$msg"

# cp -p $jlogfile $COMOUT


echo 
echo " Finished running - exstofs_3d_atl_prep_processing.sh at " `date`
echo
 


