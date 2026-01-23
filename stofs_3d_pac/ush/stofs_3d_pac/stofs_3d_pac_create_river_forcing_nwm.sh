#!/bin/bash 

################################################################################
#  Name: stofs_3d_pac_create_river_forcing_nwm.sh                              #
#  This script reads the NWM river forecast data to create the STOFS_3D_PAC    #
#  river forcing files, stofs_3d_pac.t12z.{msource, vsink,vsource}.th, that    #
#  are needed for the nowcast and forecast simulations.                        #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2022   #
################################################################################

# ---------------------------> Begin ...
# set -x

echo 'The script stofs_3d_pac_create_river_forcing_nwm.sh started at UTC' `date -u +%Y%m%d%H`

# ---------------------------> directory/file names
###  module load awscli

  dir_wk=${DATA_prep_nwm}

  echo dir_wk = ${DATA_prep_nwm}
  sleep 2

  mkdir -p $dir_wk
  cd $dir_wk
  rm -rf ${dir_wk}/*

  mkdir -p ${dir_wk}/cached
  mkdir -p ${dir_wk}/GloFAS_clim
  mkdir -p ${dir_wk}/GloFAS_prep
  mkdir -p ${dir_wk}/NWM_json
  mkdir -p ${dir_wk}/redis_static
  mkdir -p ${dir_wk}/cached
  mkdir -p ${COMOUTrerun}

  pgmout=pgmout_nwm.$$
  rm -f $pgmout

# ---------------------------> Global Variables
  fn_py_create_download=${PYstofs3d}/riverNWM_gen_sourcesink_oper_download_nwm_date.py
  fn_py_create_river_th=${PYstofs3d}/riverNWM_gen_sourcesink_GLOFAS.py

  fn_source_sink_in=${FIXstofs3d}/stofs_3d_pac_river_source_sink.in
  fn_vsource_th=${FIXstofs3d}/stofs_3d_pac_river_vsource.th
  fn_msource_th=${FIXstofs3d}/stofs_3d_pac_river_msource.th

# cp files to work dir
  cpreq -f ${fn_source_sink_in}         ${dir_wk}/source_sink.in
  cpreq -f $fn_vsource_th            ${dir_wk}/vsource.th   
  cpreq -f $fn_msource_th            ${dir_wk}/msource.th   
  cpreq -f ${EXECstofs3d}/stofs_3d_pac_redistribute_source_static ${dir_wk}/redis_static/redistribute_source_static

  cpreq -f ${FIXstofs3d}/redistribute_source.in ${dir_wk}/redis_static/redistribute_source.in
  cpreq -f ${FIXstofs3d}/vsource.th.12z.oper ${dir_wk}/redis_static/vsource.th.12z.oper
  cpreq -f ${FIXstofs3d}/vsource.th.p90 ${dir_wk}/redis_static/vsource.th.p90
###  cpreq -f $fn_featureID_sink_idx    ${dir_wk}/featureID_sink.idx
###  cpreq -f ${FIXstofs3d}/source_sink.in    ${dir_wk}/source_sink.in
  cpreq -f ${FIXstofs3d}/sources_alaska_global.json    ${dir_wk}/NWM_json/sources_alaska_global.json
  cpreq -f ${FIXstofs3d}/sources_hawaii_global.json    ${dir_wk}/NWM_json/sources_hawaii_global.json
  cpreq -f ${FIXstofs3d}/sources_conus_global.json    ${dir_wk}/NWM_json/sources_conus_global.json
  cpreq -f ${FIXstofs3d}/vsource.th.clim.redis.noNWM    ${dir_wk}/GloFAS_clim/vsource.th.clim.redis.noNWM
  cpreq -f ${FIXstofs3d}/source_sink.in.clim.redis.noNWM    ${dir_wk}/GloFAS_clim/source_sink.in.clim.redis.noNWM
  cpreq -f ${FIXstofs3d}/glofas_prepRUN31l_NWM500km.npz    ${dir_wk}/GloFAS_prep/glofas_prepRUN31l_NWM500km.npz
  cd ${dir_wk}/GloFAS_prep  
  ln -sf ../GloFAS_clim/vsource.th.clim.redis.noNWM . 
  ln -sf ../GloFAS_clim/source_sink.in.clim.redis.noNWM .
  ln -sf glofas_prepRUN31l_NWM500km.npz glofas_prep.npz
  cd ${dir_wk}
  ln -sf NWM_json/sources_hawaii_global.json . 
  ln -sf NWM_json/sources_alaska_global.json . 
  ln -sf NWM_json/sources_conus_global.json . 
  ###cpreq -f ${fn_source_sink_in}         ${dir_wk}/redis/source_sink.in.0
  ###cpreq -f $fn_vsource_th            ${dir_wk}/redis/vsource.th.0 
  ###cpreq -f $fn_msource_th            ${dir_wk}/redis/msource.th.0   
  cd ${dir_wk}/redis_static
  ln -sf ../source_sink.in source_sink.in.0
  ln -sf ../vsource.th vsource.th.0
  ln -sf ../msource.th msource.th.0
ln -sf vsource.th.p90 vsource.th.control

  ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.gr3 ${dir_wk}/redis_static/hgrid.gr3
  cpreq -f ${FIXstofs3d}/redistribute_source.in ${dir_wk}/redis_static/redistribute_source.in
  cd ${dir_wk}

# ---------------------------> Dates
   yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
   yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}

idate0=${yyyymmdd_today}
idate0iso=$(date -d"$idate0" +"%Y-%m-%d")

echo $idate0
echo $idate0iso

idate=$(date -d"$idate0 - 1 day" +"%Y%m%d")
idateiso=$(date -d"$idate0 - 1 day" +"%Y-%m-%d")
export idatestart=${idateiso} #Always -1 day
###idateiso=$(/bin/date --date="1 days ago" +%Y-%m-%d) #Always -1 day

if [[ 1 -eq 1 ]]; then        
###python riverNWM_gen_sourcesink_oper_download_nwm_date.py ${idate0iso}    >> $pgmout 2> errfile
python ${fn_py_create_download} ${idate0iso}    >> $pgmout 2> errfile
     export err=$?; #err_chk
     pgm=$fn_py_create_river
     if [ $err -eq 0 ]; then
        msg=`echo python download nwm completed normally`
        echo $msg
        echo $msg >> $pgmout
     else
        msg=`echo python download nwm did not complete normally`
        echo $msg
        echo $msg >> $pgmout
     fi

cd ${dir_wk}
fi

# download glofas from aws s3: this will never happen!

ln -sf /lfs/h1/ops/prod/dcom/${idate}/validation_data/marine/cmems/glofas/GLOFAS-global-30day_${idate}.nc GLOFAS-global-dl.nc


if [[ 1 -eq 1 ]]; then

#Gen vsource
cd ${dir_wk}
#-N has to be absolute path
######python ${fn_py_create_river_th} $idatestart -d 4 -G ./GloFAS_prep -j ./NWM_json -C -N $wrk_path/NWM    >> $pgmout 2> errfile
###python gen_sourcesink_GLOFAS.py $idatestart -d 3 -G ./GloFAS_prep -j ./NWM_json -C -N $wrk_path/NWM
###python gen_sourcesink_GLOFAS.py $idatestart -d 3 -G ./GloFAS_prep -j ./NWM_json -N $wrk_path/cached
######python gen_sourcesink_GLOFAS.py $idatestart -d 4 -G ./GloFAS_prep -j ./NWM_json -g GLOFAS-global-dl.nc -N $wrk_path/NWM    >> $pgmout 2> errfile
python ${fn_py_create_river_th} $idatestart -d 4 -G ./GloFAS_prep -j ./NWM_json -g GLOFAS-global-dl.nc   >> $pgmout 2> errfile
     export err=$?; #err_chk
     pgm=$fn_py_create_river
     if [ $err -eq 0 ]; then
        msg=`echo python nwm/GloFAS blending completed normally`
        echo $msg
        echo $msg >> $pgmout
     else
        msg=`echo python nwm/GloFAS blending did not complete normally`
        echo $msg
        echo $msg >> $pgmout
     fi

fi

if [[ 1 -eq 1 ]]; then

#Gen 12z vsource
###./gen_12z_vsourth.sh

sed -n "13,97 p" vsource.th > vsource.th.12z.oper0
awk '{print (NR-1)*3600., substr($0, index($0,$2)) }' vsource.th.12z.oper0 > vsource.th.12z.oper
rm -f ./vsource.th.12z.oper0
mv vsource.th vsource.th_full_length
mv vsource.th.12z.oper vsource.th

fi

if [[ 1 -eq 0 ]]; then

cd ${dir_wk}

else

cd ${dir_wk}/redis_static
./redistribute_source_static

fi

# msource.th
  fn_msource_th_std=${RUN}.${cycle}.msource.th 
  fn_msource_th=msource.th 

  FILESIZE_msource_th=3043000
  if [ -f $fn_msource_th ] && [ $(stat -c %s "$fn_msource_th") -gt $FILESIZE_msource_th ]; then
     cpreq  -pf ${fn_msource_th}           ${COMOUTrerun}/${fn_msource_th_std}
  elif [ -f ${COMOUTrerun_PREV}/$fn_msource_th ] && [ $(stat -c %s ${COMOUTrerun_PREV}/$fn_msource_th) -gt $FILESIZE_msource_th ]; then
     cpreq  -pf ${COMOUTrerun_PREV}/${fn_msource_th}           ${COMOUTrerun}/${fn_msource_th_std}
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_msource_th
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_msource_th  >> $jlogfile
  else
     echo "Warning: failed to supply the necessary input file: " $fn_msource_th
     echo "Warning: failed to supply the necessary input file: " $fn_msource_th  >> $jlogfile
  fi
# cp -pf msource.th ${COMOUTrerun}/${fn_msource_th_std}

# vsource.th
  fn_vsource_th_std=${RUN}.${cycle}.vsource.th 
  fn_vsource_th=vsource.th 

  FILESIZE_vsource_th=2536000
  if [ -f $fn_vsource_th ] && [ $(stat -c %s "$fn_vsource_th") -gt $FILESIZE_vsource_th ]; then
     cpreq  -pf ${fn_vsource_th}           ${COMOUTrerun}/${fn_vsource_th_std}
  elif [ -f ${COMOUTrerun_PREV}/$fn_vsource_th ] && [ $(stat -c %s ${COMOUTrerun_PREV}/$fn_vsource_th) -gt $FILESIZE_vsource_th ]; then
     cpreq  -pf ${COMOUTrerun_PREV}/${fn_vsource_th}           ${COMOUTrerun}/${fn_vsource_th_std}
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_vsource_th
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_vsource_th  >> $jlogfile
  else
     echo "Warning: failed to supply the necessary input file: " $fn_vsource_th
     echo "Warning: failed to supply the necessary input file: " $fn_vsource_th  >> $jlogfile
  fi
# cp -pf vsource.th ${COMOUTrerun}/${fn_vsource_th_std}

# source_sink.in
  fn_source_sink_in_std=${RUN}.${cycle}.source_sink.in 
  fn_source_sink_in=source_sink.in 

  FILESIZE_source_sink_in=25800
  if [ -f $fn_source_sink_in ] && [ $(stat -c %s "$fn_source_sink_in") -gt $FILESIZE_source_sink_in ]; then
     cpreq  -pf ${fn_source_sink_in}           ${COMOUTrerun}/${fn_source_sink_in_std}
  elif [ -f ${COMOUTrerun_PREV}/$fn_source_sink_in ] && [ $(stat -c %s ${COMOUTrerun_PREV}/$fn_source_sink_in) -gt $FILESIZE_source_sink_in ]; then
     cpreq  -pf ${COMOUTrerun_PREV}/${fn_source_sink_in}           ${COMOUTrerun}/${fn_source_sink_in_std}
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_source_sink_in
     echo "warning: copy from PREV, river forcing  file not created or file size is too small: " $fn_source_sink_in  >> $jlogfile
  else
     echo "Warning: failed to supply the necessary input file: " $fn_source_sink_in
     echo "Warning: failed to supply the necessary input file: " $fn_source_sink_in  >> $jlogfile
  fi
# cp -pf source_sink.in ${COMOUTrerun}/${fn_source_sink_in_std}


# ------> nowcast/forecast cycle(s) & hr
#   current_CC=$CC_CURRENT
# ---------------------------> default: create list of nwm files
# ---------------------> ln, process data
# ------------------> create river vsource.th & vsink.th
# ------------------> QC & archive/rename files
# msource.th
# vsource.th & vsink.th

echo
echo "The script stofs_3d_pac_create_river_forcing_nwm.sh completed at date/time: " `date`
echo 

