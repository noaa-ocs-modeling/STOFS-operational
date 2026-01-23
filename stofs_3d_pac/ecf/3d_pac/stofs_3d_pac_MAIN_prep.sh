#!/bin/bash -l


# This is the top level, main program to performance the full cycle OFS runs
# for a specified date. 
# It calls:
#    jstofs_3d_pac_prep_t12z.ecf: prepare model forcing data
#    jstofs_3d_pac_now_forecast_t12z.ecf: nowcast & forecast model simulations
#    jstofs_3d_pac_post1_t12z.ecf/jstofs_3d_pac_post2_t12z.ecf: post model data processing
# Call sequence xample:
#    yyyymmdd_of_interest=20220901
#    ./jstofs_3d_pac_MAIN_prep_nfcast_post.sh yyyymmdd_of_interest
#    


echo
echo ' Begin: jstofs_3d_pac_reRUN_qsub_prep_and_now_forecast_post.sh ' 
echo 

. /lfs/h1/nos/estofs/noscrub/IT-stofs.v3.1.0/stofs_3d_pac/versions/run.ver

export model=stofs
HOMEstofs=
export HOMEstofs=${HOMEstofs:-/lfs/h1/nos/estofs/noscrub/IT-${model}.${stofs_ver}/${model}_3d_pac}


export DIR_ECF=${HOMEstofs}/ecf/3d_pac
export DIR_JOBS=${HOMEstofs}/jobs


# -------------------> Update Date information for rerun

#unset YMD_CURRENT_DATE_RERUN

if [ $# -ne 0 ] && [ -n "$1" ]; then

  export YMD_CURRENT_DATE_RERUN=$1
  echo; echo "Your input, argu[0]: YMD_CURRENT_DATE_RERUN = ${YMD_CURRENT_DATE_RERUN}"; echo

else

  export YMD_CURRENT_DATE_RERUN=$(date +%Y%m%d)
  echo; echo "Attention - without input, it is assumed that the script run at current time ${YMD_CURRENT_DATE_RERUN}, at t12z. need modified if run at t00z";
###  echo; echo "Attention - you need to input, argu[0] for YMD_CURRENT_DATE_RERUN"; echo "Script run: exist now"; echo
###  exit 1

fi	


echo ; echo "In stofs_3d_pac_MAIN_reRUN_prep_nfcast_post.sh:  YMD_CURRENT_DATE_RERUN = ${YMD_CURRENT_DATE_RERUN}"; echo 
sleep 2s



# -------------------< Begin RERUN

# -----> Preppare stofs3d inputs/forcing
  PREP=$(qsub  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN} ${DIR_ECF}/jstofs_3d_pac_prep_t12z.ecf) 


# -----> Model run: stofs3d model run
###  NFCAST=$(qsub -W depend=afterok:$PREP -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_now_forecast_t12z.ecf)
###     NFCAST=$(qsub -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_now_forecast_t12z.ecf)


# WATCH-DOG
###  WATCHDOG=$(qsub -W depend=afterok:$PREP -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_watchdog.ecf)
###     WATCHDOG=$(qsub -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_watchdog.ecf)


# POST-I: processing - add attr; staout 6-min nc & SHEF file; AWS/EC2 auto nc files;
#                   profile netcdf files; adcirc fmt file; grib2
###  POST_I=$(qsub -W depend=afterok:$NFCAST  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_post1_t12z.ecf)
###  POST_I=$(qsub -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_post1_t12z.ecf)


# POST-II: processing, to generate 2d-field data
###  POST=$(qsub -W depend=afterok:$NFCAST  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_post2_t12z.ecf)
###     POST=$(qsub -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_post2_t12z.ecf)


# POST-III: processing: annual update of T/S: G-RTOFS
###  TEMP_SALT_RESTART=$(qsub -W depend=afterok:$NFCAST  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_temp_salt_restart.ecf)
###     TEMP_SALT_RESTART=$(qsub -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_pac_temp_salt_restart.ecf)


# (2023/4/26) Post processing: to generate geoPackage data
# (placed in POST_1: 1st to be executed:: POST_IV=$(qsub -W depend=afterok:$NFCAST  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}   ${DIR_ECF}/jstofs_3d_pac_post4_t12z.ecf)



echo
echo ' End of jstofs_3d_pac_qsub_prep_and_now_forecast_post.sh '
echo


