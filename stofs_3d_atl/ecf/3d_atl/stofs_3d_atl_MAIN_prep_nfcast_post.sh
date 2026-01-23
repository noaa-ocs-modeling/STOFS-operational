#!/bin/bash -l


# This is the top level, main program to performance the full cycle OFS runs
# for a specified date. 
# It calls:
#    jstofs_3d_atl_prep_t12z.ecf: prepare model forcing data
#    jstofs_3d_atl_now_forecast_t12z.ecf: nowcast & forecast model simulations
#    jstofs_3d_atl_watchdog.ecf: dynamically arhive model outputs 
#    jstofs_3d_atl_post1_t12z.ecf/jstofs_3d_atl_post2_t12z.ecf: post model data processing
#    jstofs_3d_atl_temp_salt_restart.ecf: annually re-initialize model T/S 
# Call sequence xample:
#    ./jstofs_3d_atl_MAIN_prep_nfcast_post.sh 
#    


echo
echo ' Begin: jstofs_3d_atl_reRUN_qsub_prep_and_now_forecast_post.sh ' 
echo 

. /lfs/h1/nos/estofs/noscrub/IT-stofs.v3.1.0/stofs_3d_atl/versions/run.ver


export model=stofs
HOMEstofs=
export HOMEstofs=${HOMEstofs:-/lfs/h1/nos/estofs/noscrub/IT-stofs.v3.1.0/stofs_3d_atl

export DIR_ECF=${HOMEstofs}/ecf/3d_atl
export DIR_JOBS=${HOMEstofs}/jobs



# -------------------> Update Date information for rerun

export YMD_CURRENT_DATE_RERUN=`date +%Y%m%d`



# -------------------< Begin RERUN

# -----> Preppare stofs3d inputs/forcing
  PREP=$(qsub  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN} ${DIR_ECF}/jstofs_3d_atl_prep_t12z.ecf) 


# -----> Model run: stofs3d model run
  NFCAST=$(qsub -W depend=afterok:$PREP -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_now_forecast_t12z.ecf)
  #  NFCAST=$(qsub -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_now_forecast_t12z.ecf)


# WATCH-DOG
  WATCHDOG=$(qsub -W depend=afterok:$PREP -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_watchdog.ecf)
  # WATCHDOG=$(qsub -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_watchdog.ecf)


# POST-I: processing - add attr; staout 6-min nc & SHEF file; AWS/EC2 auto nc files;
#                   profile netcdf files; adcirc fmt file; grib2
  POST_I=$(qsub -W depend=afterok:$NFCAST  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_post1_t12z.ecf)


# POST-II: processing, to generate 2d-field data
  POST_II=$(qsub -W depend=afterok:$NFCAST  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_post2_t12z.ecf)


# POST-III: processing: annual update of T/S: G-RTOFS
  TEMP_SALT_RESTART=$(qsub -W depend=afterok:$POST_II  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_temp_salt_restart.ecf)



echo
echo ' End of jstofs_3d_atl_qsub_prep_and_now_forecast_post.sh '
echo


