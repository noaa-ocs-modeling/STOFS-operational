#!/bin/bash -l


# This is the top level, main program to performance the full cycle OFS runs
# for a specified date. 
# It calls:
#    jstofs_3d_atl_prep_t12z.ecf: prepare model forcing data
#    jstofs_3d_atl_now_forecast_t12z.ecf: nowcast & forecast model simulations
#    jstofs_3d_atl_post1_t12z.ecf/jstofs_3d_atl_post2_t12z.ecf: post model data processing
# Call sequence xample:
#    yyyymmdd_of_interest=20220901
#    ./jstofs_3d_atl_MAIN_prep_nfcast_post.sh yyyymmdd_of_interest
#    


echo
echo ' Begin: jstofs_3d_atl_reRUN_qsub_prep_and_now_forecast_post.sh ' 
echo 

. /lfs/h1/nos/estofs/noscrub/IT-stofs.v2.1.0/versions/stofs_3d_atl/run.ver

export model=stofs
HOMEstofs=
#export HOMEstofs=${HOMEstofs:-/lfs/h1/nos/estofs/noscrub/IT-stofs.v2.1.0/${model}.${stofs_ver}}
export HOMEstofs=${HOMEstofs:-/lfs/h1/nos/estofs/noscrub/IT-stofs.v2.1.0}

export DIR_ECF=${HOMEstofs}/ecf/stofs_3d_atl
export DIR_JOBS=${HOMEstofs}/jobs/stofs_3d_atl


# -------------------> Update Date information for rerun

#unset YMD_CURRENT_DATE_RERUN

if [ $# -ne 0 ] && [ -n "$1" ]; then

  export YMD_CURRENT_DATE_RERUN=$1
  echo; echo "Your input, argu[0]: YMD_CURRENT_DATE_RERUN = ${YMD_CURRENT_DATE_RERUN}"; echo

else

  echo; echo "Attention - you need to input, argu[0] for YMD_CURRENT_DATE_RERUN"; echo "Script run: exist now"; echo
  exit 1

fi	


echo ; echo "In stofs_3d_atl_MAIN_reRUN_prep_nfcast_post.sh:  YMD_CURRENT_DATE_RERUN = ${YMD_CURRENT_DATE_RERUN}"; echo 
sleep 2s



# -------------------< Begin RERUN

# Preppare stofs3d inputs/forcing
echo ${YMD_CURRENT_DATE_RERUN}
echo  ${DIR_ECF}/jstofs_3d_atl_prep_t12z.ecf
ls -l  ${DIR_ECF}/jstofs_3d_atl_prep_t12z.ecf


PREP=$(qsub  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN} ${DIR_ECF}/jstofs_3d_atl_prep_t12z.ecf) 


# Model run: stofs3d model run
NFCAST=$(qsub -W depend=afterok:$PREP -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_now_forecast_t12z.ecf)


# POST-I: processing - add attr; staout 6-min nc & SHEF file; AWS/EC2 auto nc files;
#                   profile netcdf files; adcirc fmt file; grib2
  POST_I=$(qsub -W depend=afterok:$NFCAST  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_post1_t12z.ecf)


# POST-II: processing: merge sub-domain hotstart files; generate 2d-field data
  POST_II=$(qsub -W depend=afterok:$NFCAST  -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_post2_t12z.ecf)


# POST-III: processing: annual update of T/S: G-RTOFS
  POST_III=$(qsub -W depend=afterok:$POST_II -v YMD_CURRENT_DATE_RERUN=${YMD_CURRENT_DATE_RERUN}  ${DIR_ECF}/jstofs_3d_atl_post3_t12z.ecf)



echo
echo ' End of jstofs_3d_atl_qsub_prep_and_now_forecast_post.sh '
echo


