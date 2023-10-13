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
# set -x
#  set +H

  fn_this_sh="stofs_3d_atl_create_AWS_autoval_nc.sh"

  echo " ${fn_this_sh} began "  
 
  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  msg="In ${fn_this_sh}:: begins ... " 
  echo $msg >> $pgmout
  
  cd ${DATA}/outputs
  
  msg="Found nc files: `ls out2d_?.nc`"
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


if [ 1 -eq 0 ]; then
 fin_out2d_fcast1=out2d_2.nc
 fin_out2d_fcast2=out2d_3.nc
 fin_out2d_fcast3=out2d_4.nc
 fin_out2d_fcast4=out2d_5.nc

 ncks -O -d time,0,,1 -v $var_OI ${fin_out2d_fcast1}  tmp_out2d_oi_fcast1.nc
 ncks -O -d time,0,,1 -v $var_OI ${fin_out2d_fcast2}  tmp_out2d_oi_fcast2.nc
 ncks -O -d time,0,,1 -v $var_OI ${fin_out2d_fcast3}  tmp_out2d_oi_fcast3.nc
 ncks -O -d time,0,,1 -v $var_OI ${fin_out2d_fcast4}  tmp_out2d_oi_fcast4.nc

 ncra -O -F -d time,1,24 -y max tmp_out2d_oi_fcast1.nc  tmp_max_elev_day1.nc
 ncra -O -F -d time,1,24 -y max tmp_out2d_oi_fcast2.nc  tmp_max_elev_day2.nc
 ncra -O -F -d time,1,24 -y max tmp_out2d_oi_fcast3.nc  tmp_max_elev_day3.nc
 ncra -O -F -d time,1,24 -y max tmp_out2d_oi_fcast4.nc  tmp_max_elev_day4.nc
fi


list_file_cnt=(3 4 5 6 7 8 9 10)
# list_file_nf_hr=(n001_012 n013_024 f001_012 f013_024 f025_036 f037_048 f049_060 f061_072 f073_084 f085_096)
#for k in ${list_file_cnt}
for k in ${list_file_cnt[@]};
do
 
  fin_out2d_fcast_k=out2d_${k}.nc
  echo "processing (k={3,...,10}): $fin_out2d_fcast_k"

  ncks -O -d time,0,,1 -v $var_OI ${fin_out2d_fcast_k} tmp_out2d_oi_fcast_${k}.nc
  ncra -O -F -d time,1,12 -y max tmp_out2d_oi_fcast_${k}.nc  tmp_max_elev_${k}.nc

done


#fn_merge_2time_max=tmp_max_elev_day1234.nc
#ncrcat -O tmp_max_elev_day1.nc tmp_max_elev_day2.nc tmp_max_elev_day3.nc tmp_max_elev_day4.nc  ${fn_merge_2time_max}
 fn_merge_2time_max=tmp_max_elev_merged.nc
 ncrcat -O tmp_max_elev_3.nc tmp_max_elev_4.nc tmp_max_elev_5.nc tmp_max_elev_6.nc  \
           tmp_max_elev_7.nc tmp_max_elev_8.nc tmp_max_elev_9.nc tmp_max_elev_10.nc ${fn_merge_2time_max}


fn_max_all=tmp_imax_elev_all.nc
ncra -O -F -d time,1,,1 -y max ${fn_merge_2time_max} ${fn_max_all}


fn_in_max_0time=tmp_max_elev_0time.nc
ncwa -O -F -a time,1 ${fn_max_all}  ${fn_in_max_0time}


ncrename -O -v elevation,zeta_max -d nSCHISM_hgrid_node,node -v SCHISM_hgrid_node_x,x -v SCHISM_hgrid_node_y,y ${fn_in_max_0time}


#ncap2 -s 'defdim("time",2);time($time)={90000,259200};' -O  ${fn_in_max_0time}   tmp_attr.nc
 ncap2 -s 'defdim("time",2);time($time)={90000,432000};' -O  ${fn_in_max_0time}   tmp_attr.nc

ncap2 -O -s 'time=double(time)' tmp_attr.nc tmp_attr.nc

ncatted -O -h -a _FillValue,zeta_max,a,f,-99999. tmp_attr.nc
ncatted -O -h -a _FillValue,global,o,c,-99999. tmp_attr.nc

#ncatted -O -h -a units,time,a,c,"seconds since 2021-06-09 12:00:00        ! NCDASE - BASE_DAT" tmp_attr.nc
#ncatted -O -h -a base_date,time,a,c,"2021-06-09 12:00:00        ! NCDASE - BASE_DATE" tmp_attr.nc

##ncatted -O -h -a units,time,a,c,"seconds since 2021-06-09 12:00" tmp_attr.nc
##ncatted -O -h -a base_date,time,a,c,"2021-06-09 12:00" tmp_attr.nc
# ncatted  -a units,elevation,o,c,"m" -a data_horizontal_center,elevation,o,c,"node" -a data_vertical_center,elevation,o,c,"full" -a mesh,elevation,o,c,"SCHISM_hgrid" ./outputs/${str}_${ict}.nc
#  ncatted  -a units,time,o,c,"seconds since ${myr}-${mmon}-${mday} ${mhr}:00:00 +${utchr}" -a base_date,time,o,c,"${myr} ${mmon} ${mday} ${mhr} ${utchr}" ./outputs/${str}_${ict}.nc


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

        else
           mstofs="Creation/Archiving of ${DATA}/outputs/${fn_fnl_zeta_max} failed"
           echo $msg; echo $msg >> $pgmout

        fi


# ==============================> point nc
# The following is scrited in stofs_3d_atl_create_awips_shef.sh,
#    in which f_in_point is created.
#
  #f_in_point=${RUN}.${cycle}.points.cwl.temp.salt.vel.nc 
  #f_out_point_autoval=${RUN}.${cycle}.points.cwl.nc
  #cp -f ${DATA}/dir_shef/${f_in_point} ${COMOUT}/${f_out_point_autoval}

if [ 0 -eq 1 ]; then      
       if [ -s ${f_in_point} ]; then
          echo "checked: ${f_in_point} exists"

          cp -f ${DATA}/${f_in_point} ${COMOUT}/${f_out_point_autoval}
      

          export err=$?
          if [ $err -eq 0 ]; then
             mstofs="Creation/Archiving of ${f_in_point} was successful"
          else
             mstofs="Creation/Archiving of ${f_in_point} failed"
          fi    

          echo $msg; echo $msg >> $pgmout

       else
          num_missing_files=`expr ${num_missing_files} + 1`
          echo "checked: ${f_in_point} does NOT exist"

       fi

fi

echo 
echo "${fn_this_sh} completed"
echo 








