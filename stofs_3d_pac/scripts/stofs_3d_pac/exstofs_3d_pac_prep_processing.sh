#!/bin/bash 

##############################################################################
#  Name: exstofs_3d_pac_prep_processing.sh                                      #
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
  #set $setoff
  set $seton

  fn_this_script="exstofs_3d_pac_prep_processing.sh"

  msg="Starting script: STOFS3D prepare model control & forcing files"
  echo "$msg"
  postmsg  "$msg"


  echo "module list in ${fn_this_script}"
  module list
  echo; echo

 
  # flag to control the type of restart file
  # FLAG_RESTART_RTOFS= 0: use stofs3D hotstart.nc; 1: only use RTOFS; 2: combined RTOFS restart & STOFS3D hotstart

  
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
#ln -sf $FIXstofs3d/${RUN}_river_source_sink.in  source.in
ln -sf $FIXstofs3d/${RUN}_shapiro.gr3  shapiro.gr3
ln -sf $FIXstofs3d/${RUN}_sal_nudge.gr3  SAL_nudge.gr3
ln -sf $FIXstofs3d/${RUN}_param.nml_6globaloutput param.nml_template 
ln -sf $FIXstofs3d/${RUN}_river_msource.th  msource.th
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

export pgm="${USHstofs3d}/stofs_3d_pac_create_param_nml.sh"
${USHstofs3d}/stofs_3d_pac_create_param_nml.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg  "$msg"
   cat ${file_log}
   # #err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg  "$msg"
   cat ${file_log}
fi

echo $msg
echo 



# ---------------------------------------> create mpi script
##  rm -f $DATA/mpmdscript


# ---------------------------------------> create bctides.in
file_log=log_create_bctides.${cycle}.log
export pgm="${USHstofs3d}/stofs_3d_pac_create_bctides_in.sh"
${USHstofs3d}/stofs_3d_pac_create_bctides_in.sh >> ${file_log} 2>&1  


export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg  "$msg"
   # #err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg  "$msg"
fi

echo $msg
echo


##echo "${USHstofs3d}/stofs_3d_pac_create_bctides_in.sh >> ${file_log} 2>&1 " >> $DATA/mpmdscript


if [[ 1 -eq 1 ]]; then

# ---------------------------------------> create nwm/river forcing (nwm+GloFAS)

file_log=log_create_river_forcing_nwm.${cycle}.log
export pgm="${USHstofs3d}/stofs_3d_pac_create_river_forcing_nwm.sh"
${USHstofs3d}/stofs_3d_pac_create_river_forcing_nwm.sh  >> ${file_log} 2>&1


export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg  "$msg"
   cat ${file_log}
   err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg  "$msg"
   cat ${file_log}
fi

echo $msg
echo


##echo "${USHstofs3d}/stofs_3d_pac_create_river_forcing_nwm.sh  >> ${file_log} 2>&1  " >> $DATA/mpmdscript

fi
if [[ 1 -eq 1 ]]; then

# ---------------------------------------> create sflux/GFS forcing
file_log=log_create_surface_forcing_gfs.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_pac_create_surface_forcing_gfs.sh"
${USHstofs3d}/stofs_3d_pac_create_surface_forcing_gfs.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg  "$msg"
   cat ${file_log}
   err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg  "$msg"
   cat ${file_log}
fi

echo $msg
echo


##echo "${USHstofs3d}/stofs_3d_pac_create_surface_forcing_gfs.sh  >> ${file_log} 2>&1 " >> $DATA/mpmdscript

fi
if [[ 1 -eq 1 ]]; then

# ---------------------------------------> create sflux/HRRR forcing
file_log=log_create_surface_forcing_hrrr.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_pac_create_surface_forcing_hrrr.sh"  
${USHstofs3d}/stofs_3d_pac_create_surface_forcing_hrrr.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg  "$msg"
   cat ${file_log}
   err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg  "$msg"
   cat ${file_log}
fi

echo $msg
echo


##echo "${USHstofs3d}/stofs_3d_pac_create_surface_forcing_hrrr.sh  >> ${file_log} 2>&1 " >> $DATA/mpmdscript

fi
if [[ 1 -eq 1 ]]; then

# ---------------------------------------> create rtofs/obc_3dth_nudge_restore forcing
file_log=log_create_obc_3dth_nudge_restore.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_pac_create_obc_3dth_nudge_restore.sh"
${USHstofs3d}/stofs_3d_pac_create_obc_3dth_nudge_restore.sh  >> ${file_log} 2>&1

export err=$?
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg  "$msg"
   cat ${file_log}
   err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg  "$msg"
   cat ${file_log}
fi

echo $msg
echo


##echo "${USHstofs3d}/stofs_3d_pac_create_obc_3dth_nudge_restore.sh  >> ${file_log} 2>&1 " >> $DATA/mpmdscript

fi
if [[ 1 -eq 0 ]]; then

# ---------------------------------------> finalize mpmdscript

     chmod 775 $DATA/mpmdscript
    export MP_PGMMODEL=mpmd

    #N_cpu=6
    mpiexec -l -np 6 --cpu-bind verbose,core cfp $DATA/mpmdscript

    export err=$?
    if [ $err -ne 0 ];
    then
       msg=" Execution of mpmdscript did not complete normally - WARNING"
       postmsg "$jlogfile" "$msg"
       #cat $DATA/${file_log}*
       err_chk
    else
       msg=" Execution of $pgm completed normally"
       postmsg "$jlogfile" "$msg"
       #cat $DATA/${file_log}*
    fi

    echo $msg
    echo

fi
if [[ 1 -eq 1 ]]; then

# ---------------------------------------> create OB/river forcing
# ---------------------------------------> create OB/river forcing

file_log=log_create_river_forcing_ob.${cycle}.log

export pgm="${USHstofs3d}/stofs_3d_pac_create_river_forcing_ob.sh"
${USHstofs3d}/stofs_3d_pac_create_river_forcing_ob.sh  >> ${file_log} 2>&1

export err=$? 
if [ $err -ne 0 ]
then
   msg=" Execution of $pgm did not complete normally - WARNING"
   postmsg  "$msg"
   cat ${file_log}
   err_chk
else
   msg=" Execution of $pgm completed normally"
   postmsg  "$msg"
   cat ${file_log}
fi

echo $msg
echo
 

fi
if [[ 1 -eq 1 ]]; then

# ---------------------------------------> create restart file 

file_log=log_create_restart.${cycle}.log

fn_restart_coldstart_fix=${FIXstofs3d}/stofs_3d_pac_restart_coldstart.nc
fn_restart_rerun=${COMOUTrerun}/${RUN}.${cycle}.restart.nc

mkdir -p ${COMOUTrerun} 
mkdir -p ${DATA_prep_restart}


if [[ $COLDSTART = YES ]]; then

  # stofs v3.1
  # As the baroclinic 3-D system, stofs-3d-pac forbides using any climatological T/S data which is usually stored 
  # in a fix/: static cold start file. Using any clim. T/S to initialize the model T/S field would great-ly deteriorate 
  # the stofs-3d-pac performance skill. 


  # Bugzilla updated (Bug 1569 - Lack of coldstart capability, replied 2025/01/29)
    msg=''
    msg="${msg}\n Attention: COLDSTART is currently being defined as COLDSTART=YES. This is forbidden for stofs-3d-pac. The reason is as follows: "
    msg="${msg}\n stofs-3d-pac is a baroclinic 3-D system. To ensure its performance skill, the initial condition of temperature/salinity fields "
    msg="${msg}\n must be initialized with those close to the current days conditions. Hence, the COLDSTART approach (that uses fix: climatological T/S) "
    msg="${msg}\n should NOT be used. That is, the COLDSTART approach is NOT allowed."
    msg="${msg}\n Please update the COLDSTART definition to be: COLDSTART=NO"
    msg="${msg}\n"

#    msg=''
#    msg="${msg}\n Attention: COLDSTART is currently being defined as COLDSTART=YES. This is forbiden for stofs-3d-pac. Reason is as following: "
#    msg="${msg}\n stofs-3d-pac is a baroclinic 3-D system. To ensure its performance skill, the initial condition of temperature/salinity fields "
#    msg="${msg}\n must be initialized with those close to the current dates. Hence, the COLDSTART approach (that uses fix: climatological T/S) "
#    msg="${msg}\n should NOT be used. That is, the COLDSTART approach is UN-allowed." 
#    msg="${msg}\n Please update the COLDSTART definition to be: COLDSTART=NO"
#    msg="${msg}\n"

    postmsg  ' '
    echo -e "${msg}" >> ${file_log}
    echo -e "${msg}"

    #export err=1
    #err_chk
    
    err_exit "COLDSTART=YES is forbiden for stofs-3d-pac."


 # To obsolete the following of v2.1
 if [[ 0 -eq 1 ]]; then
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
 fi # obsoleted the above (which is v2.1)



else   # COLDSTART=NO
   msg="COLDSTART=${COLDSTART}"


# ------------------------
  LIST_fn_fnl_hotstart=''
  LIST_fn_fnl_hotstart_all_to_be_searched=''
  days=(0 1 2 3 4)

  cnt_files=0
  for k in ${days[@]}; do
      date_k=`date -d "${PDYHH_NCAST_BEGIN:0:8} ${k} days ago" +%Y%m%d`

      fn_hotstart_oper=$COMINstofs/${RUN}.${date_k}/${RUN}.${cycle}.hotstart.stofs3d.nc

      LIST_fn_fnl_hotstart_all_to_be_searched+="${fn_hotstart_oper} \n "

      if [ -s $fn_hotstart_oper ]; then
        if [[ $(find ${fn_hotstart_oper} -type f -size  +20G 2>/dev/null) ]];
        then
           LIST_fn_fnl_hotstart+="${fn_hotstart_oper} "
           echo "OK: $fn_hotstart_oper : filesize $filesize (GT 22GB)"
           cnt_files=$((cnt_files+1))
	   break
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
   
     cpreq -pf ${fn_hotstart_oper_prev} ${fn_restart_rerun}

  else

     # stofs-3d-pac: v3.1
     msg=" WARNING: The RESTART file is NOT found:   " 
     msg="${msg}\n FYI, this script has checked for the existence of following files and NONE was found. \n"
     msg="${msg}\n ${LIST_fn_fnl_hotstart_all_to_be_searched} "

     msg="${msg}\n Normally, the COMOUT directories store above RESTART files. The current case of failure usually occurs when "
     msg="${msg}\n the WCOSSII switches between production and development machines, which might cause a delay of mirroring "
     msg="${msg}\n the COMOUT data from the original to the new production machine. Hence, the solution is: "
     msg="${msg}\n Please make sure to complete the data mirroring first and then, to make the script run. \n"   
     
     echo -e "${msg}"; echo -e "${msg}" >> ${file_log}

     err_exit "RESTART FILE NOT FOUND. Please reference the above message to resolve the issue.";      
     
     #export err=1
     #err_chk

  fi	
fi  # COLDSTART == YES


fi  # bypass [[ 1 -eq 0]]
# ---------------------------------------> Completed preparing param.nml, bctides, forcing files

msg=" Finished creating  param.nml, bctides, river/gfs/hrrr/rtofs forcing files SUCCESSFULLY "
postmsg  "$msg"



echo 
echo " Finished running - exstofs_3d_pac_prep_processing.sh at " `date`
echo
 


