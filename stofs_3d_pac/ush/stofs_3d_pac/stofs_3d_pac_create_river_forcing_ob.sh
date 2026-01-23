#!/bin/bash 


################################################################################
#  Name: stofs_3d_pac_create_river_forcing_ob.sh                               #
#  This script reads the reiver discharge and temperature data from  USGS and  #
#  other sources (possibly usace, canada agency, etc) to create the            #
#  STOFS_3D_PAC open boundary input file (defined by bctides.in) flux.th,      #
#  TEM_1.th and (if necessary) other input files (require scripts modification)#
#  that are needed for the nowcast and forecast simulations.                   #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2022   #
################################################################################

# ---------------------------> Begin ...
# set -x

echo 'The script stofs_3d_pac_create_river_forcing_ob.sh started at UTC' `date -u +%Y%m%d%H`


# ---------------------------> directory/file names
  dir_wk=${DATA_prep_ob}

  echo dir_wk = ${DATA_prep_ob}
  sleep 2


  mkdir -p $dir_wk
  cd $dir_wk
  rm -rf ${dir_wk}/*
  mkdir -p ${dir_wk}/sflux

  mkdir -p ${COMOUTrerun}

  pgmout=pgmout_ob.$$
  rm -f $pgmout


# ---------------------------> Global Variables
###  fn_py_create_river_th=${PYstofs3d}/river_th_extract2asci.py
  fn_py_riverOB_extract_stations_pacific=${PYstofs3d}/riverOB_extract_stations_pacific.py
  ###fn_py_riverOB_gen_fluxth=${PYstofs3d}/riverOB_gen_fluxth.py
  ###fn_py_riverOB_gen_temp_1=${PYstofs3d}/riverOB_gen_temp_1.py
  fn_py_riverOB_gen_fluxth=${PYstofs3d}/riverOB_gen_fluxth_new.py
  fn_py_riverOB_gen_temp_1=${PYstofs3d}/riverOB_gen_temp_1_new.py

  #fn_source_sink_in=${FIXstofs3d}/stofs_3d_pac_river_source_sink.in
###  fn_source_scale=${FIXstofs3d}/stofs_3d_pac_source_scale.txt
###  fn_pump_sinks=${FIXstofs3d}/stofs_3d_pac_river_pump_sinks.txt
###  fn_featureID_source_idx=${FIXstofs3d}/stofs_3d_pac_river_featureid_source.idx
###  fn_featureID_sink_idx=${FIXstofs3d}/stofs_3d_pac_river_featureid_sink.idx

###  fn_flux_th=${FIXstofs3d}/stofs_3d_pac_river_flux.th

  N_list_target=74
  N_list_min=49

# -------------------------> cp files to work dir

  cd ${dir_wk}/sflux
  ln -sf ${DATA_prep_gfs}/sflux_air_1.0001.nc .
  cd ${dir_wk}

# ---------------------------> Dates
   yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
   yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}
###   myr=${yyyymmdd_today:0:4}
###   mmon=${yyyymmdd_today:4:2}
###   mday=${yyyymmdd_today:6:2}
   myr=${yyyymmdd_prev:0:4}
   mmon=${yyyymmdd_prev:4:2}
   mday=${yyyymmdd_prev:6:2}


# ------> nowcast/forecast cycle(s) & hr
#   current_CC=$CC_CURRENT


# ---------------------------> default: create list of ob files
# ---------------------------> link the data tank data directly to working directory
#  ln -sf /lfs/h1/ops/prod/dcom/${yyyymmdd_prev}/wtxtbul/usgs_river.0510 .
#  ln -sf /lfs/h1/ops/prod/dcom/${yyyymmdd_prev}/wtxtbul/usgs_river.2010 usgs_river.txt
  ln -sf /lfs/h1/ops/prod/dcom/${yyyymmdd_prev}/wtxtbul/usgs_river.2310 usgs_river.txt
###  ln -sf /lfs/h1/ops/dev/dcom/${yyyymmdd_today}/canadian_water/BC_08MF005_hourly_hydrometric.csv .
###  ln -sf /lfs/h1/ops/dev/dcom/${yyyymmdd_today}/can_streamgauge/08MF005_hydrometric.csv .
  PATH_A_FILE01="/lfs/h1/ops/dev/dcom/${yyyymmdd_today}/can_streamgauge/08MF005_hydrometric.csv"
  PATH_B_FILE01="/lfs/h1/ops/prod/dcom/${yyyymmdd_today}/can_streamgauge/08MF005_hydrometric.csv"
  if [ -f "$PATH_A_FILE01" ]; then
      ln -sf "$PATH_A_FILE01" .
      echo "$PATH_A_FILE01 successfully."
  elif [ -f "$PATH_B_FILE01" ]; then
      ln -sf "$PATH_B_FILE01" .
      echo "altrenatively $PATH_B_FILE01 successfully."
  else
      echo "Error: Neither $PATH_A_FILE01 nor $PATH_B_FILE01 was found."
  fi
  ln -sf /lfs/h1/ops/prod/dcom/usace_streamflow/OR00001.json .

# ---------------------------> backup: create list of ob files


# check file sizes (e.g., nwm_1.nc: 14368257)


# ---------------------> ln, process data


# ------------------> create river flux.th & TEM_1.th
  str_yyyy_mm_dd_hr=`date -d ${PDYHH_NCAST_BEGIN:0:8}  +%Y-%m-%d`-${cyc}

###  echo 'Beginning date of river data (th) (yyyy_mm_dd_hr) = '  $str_yyyy_mm_dd_hr
  echo 'Beginning date of river data (th) (yyyy_mm_dd_hr) = '  $str_yyyy_mm_dd_hr


###     python $fn_py_create_river_th  $str_yyyy_mm_dd_hr   >> $pgmout 2> errfile
     python $fn_py_riverOB_extract_stations_pacific    >> $pgmout 2> errfile
     export err01=$?; #err_chk
###     python $fn_py_riverOB_gen_fluxth    >> $pgmout 2> errfile
     python $fn_py_riverOB_gen_fluxth $str_yyyy_mm_dd_hr   >> $pgmout 2> errfile
     export err02=$?; #err_chk
###     python $fn_py_riverOB_gen_temp_1     >> $pgmout 2> errfile
###     python $fn_py_riverOB_gen_temp_1 "${myr}-${mmon}-${mday} ${cyc}:00:00"    >> $pgmout 2> errfile
     python $fn_py_riverOB_gen_temp_1 ${myr}-${mmon}-${mday}-${cyc}    >> $pgmout 2> errfile
     export err03=$?; #err_chk

     pgm=$fn_py_create_river

  echo "--- Final Check ---"
     if [ $err01 -eq 0 ] && [ $err02 -eq 0 ] && [ $err03 -eq 0 ]; then
        msg=`echo python  all 3 scripts completed normally (err01=$err01, err02=$err02, err03=$err03)`
        echo $msg
        echo $msg >> $pgmout
     else
        msg=`echo python  at least one script did not complete normally (err01=$err01, err02=$err02, err03=$err03)`
        echo $msg
        echo $msg >> $pgmout
     fi
###  else
###    msg="Attention: nwm_xxx.nc not existed;"'\n'"$pgm did not complete normally"
###    echo -e $msg
###    echo -e $msg >> $pgmout
###  fi

#backup
     ###backfn=$(/bin/date --date="5 days ago" +%Y%m%d)
     backfn=$(date -d"$yyyymmdd_today -5 days" +"%Y%m%d")
     mv $backfn ./backup/
  

# ------------------> QC & archive/rename files
# flux.th
  fn_flux_th_std=${RUN}.${cycle}.flux.th 
  fn_flux_th=flux.th 

  FILESIZE_flux_th=200
  if [ -f $fn_flux_th ] && [ $(stat -c %s "$fn_flux_th") -gt $FILESIZE_flux_th ]; then
     cpreq  -pf ${fn_flux_th}           ${COMOUTrerun}/${fn_flux_th_std}
  elif [ -f ${COMOUTrerun_PREV}/$fn_flux_th ] && [ $(stat -c %s ${COMOUTrerun_PREV}/$fn_flux_th) -gt $FILESIZE_flux_th ]; then
     cpreq  -pf ${COMOUTrerun_PREV}/${fn_flux_th}           ${COMOUTrerun}/${fn_flux_th_std}
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_flux_th
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_flux_th  >> $jlogfile
  else
     echo "Warning: failed to supply the necessary input file: " $fn_flux_th
     echo "Warning: failed to supply the necessary input file: " $fn_flux_th  >> $jlogfile
  fi

#  if [ -f $fn_flux_th ]; then
#     sz_test=`wc -c $fn_flux_th | awk '{print $1}'`
#     if [ $sz_test -ge $FILESIZE_flux_th ]; then
#        cpreq  -pf ${fn_flux_th}           ${COMOUTrerun}/${fn_flux_th_std}
#     fi
#  else
#    echo " river forcing  file not created or file size is too small: " $fn_flux_th
#    echo " river forcing  file not created or file size is too small: " $fn_flux_th  >> $jlogfile
#  fi
  export err=$?; #err_chk

# TEM_1.th
  fn_TEM_1_th_std=${RUN}.${cycle}.TEM_1.th 
  fn_TEM_1_th=TEM_1.th 

  FILESIZE_TEM_1_th=200
  if [ -f $fn_TEM_1_th ] && [ $(stat -c %s "$fn_TEM_1_th") -gt $FILESIZE_TEM_1_th ]; then
     cpreq  -pf ${fn_TEM_1_th}           ${COMOUTrerun}/${fn_TEM_1_th_std}
  elif [ -f ${COMOUTrerun_PREV}/$fn_TEM_1_th ] && [ $(stat -c %s ${COMOUTrerun_PREV}/$fn_TEM_1_th) -gt $FILESIZE_TEM_1_th ]; then
     cpreq  -pf ${COMOUTrerun_PREV}/${fn_TEM_1_th}           ${COMOUTrerun}/${fn_TEM_1_th_std}
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_TEM_1_th
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_TEM_1_th  >> $jlogfile
  else
     echo "Warning: failed to supply the necessary input file: " $fn_TEM_1_th
     echo "Warning: failed to supply the necessary input file: " $fn_TEM_1_th  >> $jlogfile
  fi

#  if [ -f $fn_TEM_1_th ]; then
#     sz_test=`wc -c $fn_TEM_1_th | awk '{print $1}'`
#     if [ $sz_test -ge $FILESIZE_TEM_1_th ]; then
#        cpreq  -pf ${fn_TEM_1_th}           ${COMOUTrerun}/${fn_TEM_1_th_std}
#     fi
#  else
#    echo " river forcing  file not created or file size is too small: " $fn_TEM_1_th
#    echo " river forcing  file not created or file size is too small: " $fn_TEM_1_th  >> $jlogfile
#  fi
  export err=$?; #err_chk

ls -l ${COMOUTrerun}/*.th

echo
echo "The script stofs_3d_pac_create_river_forcing_ob.sh completed at date/time: " `date`
echo 

