#!/bin/bash

#########################################################################
#  Name: stofs_3d_atl_create_param_nml.sh                               #
#  This script created the model run control file, param.nml, for the   #
#  the nowcast and forecast simulations.                                #
#                                                                       #
#  Remarks:                                                             #
#                                                     September, 2022   #
#########################################################################




# ---------------------------> Begin ...
set -x

  fn_this_script="stofs_3d_atl_create_param_nml.sh"
  echo "${fn_this_script}  started "

  echo "module list in ${fn_this_script}"
  module list
  echo; echo


# ---------------------------> directory/file names
  dir_wk=${DATA}

  echo dir_wk = ${DATA}
  sleep 2

  mkdir -p $dir_wk
  cd $dir_wk

  pgmout=pgmout_nwm.$$
  rm -f $pgmout


  echo `pwd` '/stofs_3d_atl_create_param_nml.sh begin >>> '
  rm -f param.nml
  
  
# ---------------------------> date/time
  rnday=$N_DAYS_MODEL_RUN_PERIOD
  yyyy=${PDYHH_NCAST_BEGIN:0:4}
  mm=${PDYHH_NCAST_BEGIN:4:2}
  dd=${PDYHH_NCAST_BEGIN:6:2}
  start_hour=${PDYHH_NCAST_BEGIN:8:2}

  str_yyyymmdd_cycle=${PDYHH_FCAST_BEGIN:0:8}${cycle}
    
  fn_param_modelRun_date_tag=${RUN}.param.nfcast.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nml
  fn_param_modelRun_std=${RUN}.${cycle}.param.nml


  fn_param_template='param.nml_template'
  cat $fn_param_template | sed "s/rnday = .*/rnday = $rnday/" | sed "s/start_year = .*/start_year = $yyyy/" | sed "s/start_month = .*/start_month = $mm/" | sed "s/start_day = .*/start_day = $dd/" | sed "s/start_hour = .*/start_hour = $start_hour/" > $fn_param_modelRun_date_tag


  FILESIZE_min=1000
  if [ -f $fn_param_modelRun_date_tag ]; then
     sz_test=`wc -c $fn_param_modelRun_date_tag | awk '{print $1}'`

     if [ $sz_test -ge $FILESIZE_min ]; then
        cp  -pf ${fn_param_modelRun_date_tag}  ${COMOUTrerun}/${fn_param_modelRun_std}
     fi

  else
    echo " ${fn_param_modelRun_date_tag} not created or file size is too small: " $fn_param_modelRun_date_tag
  fi
  export err=$?;


echo 
echo 'param.nml created: ' $fn_param_modelRun_date_tag
echo 'stofs_3d_atl_create_param_nml.sh completed '  
echo

