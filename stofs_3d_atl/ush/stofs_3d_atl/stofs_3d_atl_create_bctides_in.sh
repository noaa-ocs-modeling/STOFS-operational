#!/bin/bash

################################################################################
#  Name: stofs_3d_atl_create_bctides_in.sh                                     # 
#  This script creates the tidal forcing file, stofs_3d_atl.t12z.bctides.in,   #
#  for the nowcast and forecast simulations.                                   #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2022   #
################################################################################

# ---------------------------> Begin ...
set -x

  echo 'stofs_3d_atl_create_bctides_in.sh started'


# ---------------------------> directory/file names
  dir_wk=${DATA}

  echo dir_wk = ${DATA}
  sleep 2

  mkdir -p $dir_wk
  cd $dir_wk

  pgmout=pgmout_nwm.$$
  rm -f $pgmout


# --------------------------->
 rm -f bctides.in*

  fn_generate_bctides_in=${EXECstofs3d}/stofs_3d_atl_tide_fac
  fn_bctides_in_template=${FIXstofs3d}/stofs_3d_atl_bctides.in_template
 
  fn_bctides_in_datetime_tag=${RUN}.bctides.nfcast.${PDYHH:0:8}.${cycle}.in
  fn_bctides_in_std=${RUN}.${cycle}.bctides.in

  cpreq -f $fn_bctides_in_template bctides.in_template
  rm -f fn_bctides_in_std
  

# --------------------> Today's date
  N_days_run=$N_DAYS_MODEL_RUN_PERIOD
  yyyy=${PDYHH_NCAST_BEGIN:0:4}
  mm=${PDYHH_NCAST_BEGIN:4:2}
  dd=${PDYHH_NCAST_BEGIN:6:2}
  hr=${PDYHH_NCAST_BEGIN:8:2}

  str_hh_dd_mm_yr_begin="$hr,$dd,$mm,$yyyy"


# create input file:
rm -f input_generate_bctides.in
echo $N_days_run > input_generate_bctides.in
echo $str_hh_dd_mm_yr_begin >> input_generate_bctides.in
echo "y" >> input_generate_bctides.in

# create bctides.in
$fn_generate_bctides_in < input_generate_bctides.in


fn_bctides_in=bctides.in
  FILESIZE_min=1000
  if [ -f $fn_bctides_in ]; then
     sz_test=`wc -c $fn_bctides_in  | awk '{print $1}'`

     if [ $sz_test -ge $FILESIZE_min ]; then
        cpreq -f  bctides.in  $fn_bctides_in_datetime_tag
        cp  -pf ${fn_bctides_in_datetime_tag}  ${COMOUTrerun}/${fn_bctides_in_std}
     fi

  else
    echo " ${fn_bctides_in} not created or file size is too small: " $fn_bctides_in
  fi
  export err=$?;


echo 
echo 'stofs_3d_atl_create_bctides_in.sh completed ' 
echo ' '







