#!/bin/bash

################################################################################
#  Name: stofs_3d_atl_create_AWS_autoval_nc.sh                                 #
#  This is a post-processing script that reads the nowcast and forecast        #
#  outputs, out2d_{1,2,3}.nc to create station time series data,               #
#  stofs_3d_atl.t12z.points.cwl.nc and the maximum water level data,           #
#  stofs_3d_atl.t12z.fields.cwl.maxele.nc. Both files are used by the auto-    #
#  val to conduct automatically model skill assessment (operated on the AWS S3 #
#  platform.                                                                   #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2022   #
################################################################################


# ---------------------------> Begin ...
set -x

  fn_this_sh="stofs_3d_atl_create_AWS_autoval_nc.sh"

  echo " ${fn_this_sh} began "  
 
  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  msg="In ${fn_this_sh}:: begins ... " 
  echo $msg >> $pgmout
  
  cd ${DATA}/outputs
  
  msg="Found nc files: `ls out2d_{?,??}.nc`"
  echo ${msg}; echo $msg >> $pgmout   
  echo 


# ---------------------------> max zeta field

cd ${DATA}; pwd


myr=`cat param.nml | grep start_year | cut -d'=' -f2 | awk '{print $1}'`
mmon=`cat param.nml | grep start_month | cut -d'=' -f2 | awk '{print $1}'`
mday=`cat param.nml | grep start_day | cut -d'=' -f2 | awk '{print $1}'`
mhr=`cat param.nml | grep start_hour | cut -d'=' -f2 | cut -d'!' -f1 | awk '{print $1}'`
utchr=`cat param.nml | grep utc_start | cut -d'=' -f2 | cut -d'!' -f1 | awk '{print $1}'`
echo "Adding time attribute:" $myr $mmon $mday $mhr $utchr


cd ${DATA}/outputs

var_OI='time,SCHISM_hgrid_node_x,SCHISM_hgrid_node_y,depth,elevation'


list_file_cnt=(3 4 5 6 7 8 9 10)
for k in ${list_file_cnt[@]};
do
 
  fin_out2d_fcast_k=out2d_${k}.nc
  echo "processing (k={3,...,10}): $fin_out2d_fcast_k"

  ncks -O -d time,0,,1 -v $var_OI ${fin_out2d_fcast_k} tmp_out2d_oi_fcast_${k}.nc
  ncra -O -F -d time,1,12 -y max tmp_out2d_oi_fcast_${k}.nc  tmp_max_elev_${k}.nc

done


 fn_merge_2time_max=tmp_max_elev_merged.nc
 ncrcat -O tmp_max_elev_3.nc tmp_max_elev_4.nc tmp_max_elev_5.nc tmp_max_elev_6.nc  \
           tmp_max_elev_7.nc tmp_max_elev_8.nc tmp_max_elev_9.nc tmp_max_elev_10.nc ${fn_merge_2time_max}


fn_max_all=tmp_imax_elev_all.nc
ncra -O -F -d time,1,,1 -y max ${fn_merge_2time_max} ${fn_max_all}


fn_in_max_0time=tmp_max_elev_0time.nc
ncwa -O -F -a time,1 ${fn_max_all}  ${fn_in_max_0time}


ncrename -O -v elevation,zeta_max -d nSCHISM_hgrid_node,node -v SCHISM_hgrid_node_x,x -v SCHISM_hgrid_node_y,y ${fn_in_max_0time}


 ncap2 -s 'defdim("time",2);time($time)={90000,432000};' -O  ${fn_in_max_0time}   tmp_attr.nc

ncap2 -O -s 'time=double(time)' tmp_attr.nc tmp_attr.nc

ncatted -O -h -a _FillValue,zeta_max,a,f,-99999. tmp_attr.nc
ncatted -O -h -a _FillValue,global,o,c,-99999. tmp_attr.nc


ncatted -O -h -a units,time,a,c,"seconds since ${myr}-${mmon}-${mday} ${mhr}:00" tmp_attr.nc
ncatted -O -h -a base_date,time,a,c,"${myr}-${mmon}-${mday} ${mhr}:00" tmp_attr.nc

ncatted -O -h -a units,depth,a,c,"m" tmp_attr.nc
ncatted -O -h -a coordinates,depth,a,c,"time y x" tmp_attr.nc
ncatted -O -h -a long_name,depth,a,c,"distance  below geoid" tmp_attr.nc
ncatted -O -h -a standard_name,depth,a,c,"depth below geoid" tmp_attr.nc
ncatted -O -h -a mesh,depth,a,c,"adcirc_mesh" tmp_attr.nc
ncatted -O -h -a long_name,depth,a,c,"distance  below geoid" tmp_attr.nc


fn_fnl_zeta_max=${RUN}.${cycle}.fields.cwl.maxele.nc
cp -pf tmp_attr.nc ${fn_fnl_zeta_max}


 # archive max zeta nc
 export err=$?
        if [ $err -eq 0 ]; then
           cp -pf ${DATA}/outputs/${fn_fnl_zeta_max}  ${COMOUT}/${fn_fnl_zeta_max}

           if [ $SENDDBN = YES ]; then
            $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job ${COMOUT}/${fn_fnl_zeta_max}
            export err=$?; err_chk
           fi

        else
           mstofs="Creation/Archiving of ${DATA}/outputs/${fn_fnl_zeta_max} failed"
           echo $msg; echo $msg >> $pgmout

        fi


echo 
echo "${fn_this_sh} completed"
echo 








