#!/bin/bash

##############################################################################
#  Name: exstofs_3d_atl_post_3.sh                                            #
#  This script is a postprocessor to create the hotstart file, namely        #
#  stofs_3d_atl.t12z.hotstart.stofs3d.nc and copies the files to the com     #
#  directory. If the current model run date is Janunary 5, the T/S fields in #
#  hotstart file would be a combined STOFS-3D-atl outpus and G-RTOFS results.#
#                                                                            #
#  Remarks:                                                                  #
#                                                        September, 2022     #
##############################################################################

  seton='-xa'
#  setoff='+xa'
  set $seton


# ----------------------->

  file_log=log_create_restart.${cycle}.log

  fn_this_script=exstofs_3d_atl_post_3
  msg="${fn_this_script}.sh  started at UTC: `date -u `"
  echo "$msg"
  #postmsg "$jlogfile" "$msg"

  pgmout=${fn_this_script}.$$

  mkdir -p ${DATA}/restart
  cd ${DATA}/restart


  # ----------> define rtofs rst date
   MMDD_ANNUAL_UPDATE_RESTART_FILE=0105

   MMDD_FCAST_BEGIN=${PDYHH_FCAST_BEGIN:4:4} 
    


  FLAG_RESTART_RTOFS=0  
  if [[ ${MMDD_FCAST_BEGIN} == ${MMDD_ANNUAL_UPDATE_RESTART_FILE} ]]; then
    FLAG_RESTART_RTOFS=1

    msg="FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}; MMDD_ANNUAL_UPDATE_RESTART_FILE=${MMDD_ANNUAL_UPDATE_RESTART_FILE}; PDYHH_FCAST_BEGIN=${PDYHH_FCAST_BEGIN}"
    echo "$msg"; postmsg "$jlogfile" "$msg"      
    echo "FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}"; echo 

    echo "In ${fn_this_script}: FLAG_RESTART_RTOFS = " ${FLAG_RESTART_RTOFS}
    echo
  
      msg="FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}"
   
      export pgm="${USHstofs3d}/stofs_3d_atl_create_restart_combine_rtofs_stofs.sh"
      ${USHstofs3d}/stofs_3d_atl_create_restart_combine_rtofs_stofs.sh >> ${file_log} 2>&1

      msg="${msg}\n restart.nc: used RTOFS"
  
 
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


  else  #if [[ ${MMDD_FCAST_BEGIN} == ${MMDD_ANNUAL_UPDATE_RESTART_FILE} ]];
    
    msg="FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}; MMDD_ANNUAL_UPDATE_RESTART_FILE=${MMDD_ANNUAL_UPDATE_RESTART_FILE}; PDYHH_FCAST_BEGIN=${PDYHH_FCAST_BEGIN}"
    echo "$msg"; 
    
    #postmsg "$jlogfile" "$msg"
    
    echo "FLAG_RESTART_RTOFS=${FLAG_RESTART_RTOFS}"; echo
    echo "In ${fn_this_script}: FLAG_RESTART_RTOFS = " ${FLAG_RESTART_RTOFS}
    echo "No need to use G-RTOFS temperature & salinity data for creating restart file"
    echo

  fi    #if [[ ${MMDD_FCAST_BEGIN} == ${MMDD_ANNUAL_UPDATE_RESTART_FILE} ]];



  # ---------------------------------------> Completed post processing
  msg=" Finished ${fn_this_script}.sh  SUCCESSFULLY "
  #postmsg "$jlogfile" "$msg"

  chmod -Rf 755 $COMOUT


  echo
  echo $msg at `date`
  echo





