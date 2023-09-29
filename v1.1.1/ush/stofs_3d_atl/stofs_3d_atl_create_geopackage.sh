#!/bin/bash

#################################################################################
#  Name: stofs_3d_atl_create_geopackage.sh                                      #
#  This is a post-processing script that reads the water level field            #
#  time series data, out2d_{1,2,3}.nc (which are the outputs of the schisms     #
#  model run) to generate the GoePackage (.gpkg) files to support the NOAA/NOS  #
#  nowCOAST project.                                                            #
#                                                                               #
#  Remarks:                                                                     #
#                                                             October, 2022     #
#################################################################################

# ---------------------------> Begin ...
 set -x

# Steven (NCO, 2022/10/6)
# FYI, this script needs to be executed 3 min earlier ahead of _post1.sh/_add_attr_sh

#module unload python
#ource /apps/prod/ve/intel/stofs/1.1/bin/activate


  fn_this_sh="stofs_3d_atl_create_geopackage.sh"

  echo "${fn_this_sh} began at UTC: " `date -u`
  echo; echo

  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  cd ${DATA}

  myr=`cat param.nml | grep start_year | cut -d'=' -f2 | awk '{print $1}'`
  mmon=`cat param.nml | grep start_month | cut -d'=' -f2 | awk '{print $1}'`
  mday=`cat param.nml | grep start_day | cut -d'=' -f2 | awk '{print $1}'`
  mhr=`cat param.nml | grep start_hour | cut -d'=' -f2 | cut -d'!' -f1 | awk '{print $1}'`
  utchr=`cat param.nml | grep utc_start | cut -d'=' -f2 | cut -d'!' -f1 | awk '{print $1}'`
  echo "Adding time attribute:" $myr $mmon $mday $mhr $utchr

# ---------------------------> Global Variables
  fn_py_gen_goejson=${PYstofs3d}/gen_geojson.py

# ------------------> check file existence
  echo "In: checking out2d_{1,2,3} files existence: "

  cd ${DATA}/outputs

  #list_adc_files=(geo_out2d_1.nc geo_out2d_2.nc geo_out2d_3.nc)
  list_adc_files=(geo_elev_out2d_1.nc geo_elev_out2d_2.nc geo_elev_out2d_3.nc)
  
  num_missing_files=0
  for fn_k  in ${list_adc_files[@]};  
  do
       if [ -s ${fn_k} ]; then
          echo "checked: ${fn_k} exists"
       
       else
          num_missing_files=`expr ${num_missing_files} + 1`
          echo "checked: ${fn_k} does NOT exist" 
       fi
  done

  if [[ ${num_missing_files} -eq 0 ]];  then
     echo "out2d_{1,2,3}.nc: all exist"

     rm -f tmp_elev_out2d_123.nc
     ncrcat -C geo_elev_out2d_1.nc geo_elev_out2d_2.nc geo_elev_out2d_3.nc tmp_elev_out2d_123.nc
     
   
     ncatted  -a units,time,o,c,"seconds since ${myr}-${mmon}-${mday} ${mhr}:00:00 +${utchr}" -a base_date,time,o,c,"${myr} ${mmon} ${mday} ${mhr} ${utchr}" tmp_elev_out2d_123.nc

     #fn_py_gen_goejson=${PYstofs3d}/gen_geojson.py     
     python ${fn_py_gen_goejson} --input_filename tmp_elev_out2d_123.nc

     # Steven (NCO, 2022/10/6)
#    deactivate

  
  else
     echo "WARNING: out2d_{1,2,3}.nc were not all created"
     err_exit  

  fi

  
# -------------------> archive
     export err=$?

        if [ $err -eq 0 ]; then
           cp -pf *.gpkg  ${COMOUT}

           msg="Creation/Archiving of json files was successfully created/archived"
           echo $msg; echo $msg >> $pgmout

        else
           mstofs="Creation/Archiving of json files  failed"
           echo $msg; echo $msg >> $pgmout
        fi
          
export err=$?; #err_chk  

echo 
echo "${fn_this_sh} completed at UTC: `date`"
echo 



