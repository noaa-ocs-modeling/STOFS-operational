#!/bin/bash

################################################################################
#  Name: stofs_3d_pac_create_AWS_autoval_nc.sh                                 #
#  This is a post-processing script that reads the nowcast and forecast        #
#  outputs, out2d_{1,2,3}.nc to create station time series data,               #
#  stofs_3d_pac.t12z.points.cwl.nc and the maximum water level data,           #
#  stofs_3d_pac.t12z.fields.cwl.maxele.nc. Both files are used by the auto-    #
#  val to conduct automatically model skill assessment (operated on the AWS S3 #
#  platform.                                                                   #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2022   #
################################################################################


# ---------------------------> Begin ...
set -x

  fn_this_sh="stofs_3d_pac_create_AWS_autoval_nc.sh"

  echo " ${fn_this_sh} began "  
 
  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  msg="In ${fn_this_sh}:: begins ... " 
  echo $msg >> $pgmout
  
  cd ${DATA}/outputs
  
  msg="Found nc files: `ls out2d_{?,??}.nc`"
  echo ${msg}; echo $msg >> $pgmout   
  echo 

# ---------------------------> Global Variables

fn_fnl_zeta_geoid_lmsl=${FIXstofs3d}/stofs_3d_pac_field_geoid_lmsl.nc

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


list_file_cnt=(3 4 5 6)
for k in ${list_file_cnt[@]};
do
 
  fin_out2d_fcast_k=out2d_${k}.nc
  echo "processing (k={3,...,10}): $fin_out2d_fcast_k"

  ncks -O -d time,0,,1 -v $var_OI ${fin_out2d_fcast_k} tmp_out2d_oi_fcast_${k}.nc
  ncra -O -F -d time,1,12 -y max tmp_out2d_oi_fcast_${k}.nc  tmp_max_elev_${k}.nc

done


 fn_merge_2time_max=tmp_max_elev_merged.nc
 ncrcat -O tmp_max_elev_3.nc tmp_max_elev_4.nc tmp_max_elev_5.nc tmp_max_elev_6.nc  ${fn_merge_2time_max}


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

ncbo -O --op_typ=add -v zeta_max tmp_attr.nc $fn_fnl_zeta_geoid_lmsl foo05.nc
ncks -C -O -x -v zeta_max tmp_attr.nc foo06.nc
ncks -A foo05.nc foo06.nc

fn_fnl_zeta_max=${RUN}.${cycle}.fields.cwl.maxele.nc
fn_fnl_zeta_max_lmsl=${RUN}.t12z.fields.cwl.maxele.lmsl.nc
cp -pf tmp_attr.nc ${fn_fnl_zeta_max}
cp -pf foo06.nc ${fn_fnl_zeta_max_lmsl}


 # archive max zeta nc
 export err=$?
        if [ $err -eq 0 ]; then
           cp -pf ${DATA}/outputs/${fn_fnl_zeta_max}  ${COMOUT}/${fn_fnl_zeta_max}
           cp -pf ${DATA}/outputs/${fn_fnl_zeta_max_lmsl}  ${COMOUT}/${fn_fnl_zeta_max_lmsl}

           if [ $SENDDBN = YES ]; then
            $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job ${COMOUT}/${fn_fnl_zeta_max}
            export err=$?; err_chk
           fi

        else
           mstofs="Creation/Archiving of ${DATA}/outputs/${fn_fnl_zeta_max} failed"
           echo $msg; echo $msg >> $pgmout

        fi

# ==============================> point nc

cd ${DATA}; pwd


  f_in_point=${RUN}.t12z.points.cwl.temp.salt.vel.nc 
  f_out_point_autoval=${RUN}.t12z.points.cwl.nc

      
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

#cp stofs3d.t12z.points.cwl.temp.salt.vel.nc p1.nc

#ncatted -O -h -a units,time,o,c,"seconds since 2021-06-20 12:00:00        ! NCDASE - BASE_DAT"  p1.nc
#ncatted -O -h -a base_date,time,o,c,"seconds since 2021-06-20 12:00:00        ! NCDASE - BASE_DAT" p1.nc

#cp p1.nc ../stofs3d.t12z.points.cwl.nc

echo 
echo "${fn_this_sh} completed"
echo 








