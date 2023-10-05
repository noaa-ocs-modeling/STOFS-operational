#!/bin/bash

#################################################################################
#  Name: stofs_3d_atl_create_geopackage.sh                                      #
#  This is a post-processing script that reads the water level field            #
#  time series data, out2d_{1,2,3}.nc (which are the outputs of the schisms     #
#  model run) to generate the GoePackage (.gpkg) files to support the NOAA/NOS  #
#  nowCOAST project.                                                            #
#                                                                               #
#  Remarks:                                                                     #
#                                                October 2022; May 2023         #
# 
##################################################################################

# ---------------------------> Begin ...
# set -x

# (Following is to be updated upon installation of python 3.10.4: new packages
# load ve/stofs/2.0.1, 2023/9/25)
#module unload python
#source /apps/prod/ve/intel/stofs/1.1/bin/activate


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
  echo "In: checking out2d_{1,2,...,10} files existence: "


  #cd ${DATA}/outputs

  mkdir -p ${DATA}/dir_geopkg
  cp -pa ${DATA}/Dir_backup_2d3d/out2d_*.nc ${DATA}/dir_geopkg

  cd ${DATA}/dir_geopkg

  list_adc_files=(out2d_1.nc out2d_2.nc out2d_3.nc out2d_4.nc out2d_5.nc out2d_6.nc out2d_7.nc out2d_8.nc out2d_9.nc out2d_10.nc)
  
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
     echo "out2d_{1,2,...,10}.nc: all exist"

     rm -f tmp_elev_out2d_?.nc; rm -f tmp_elev_out2d_??.nc 

     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_1.nc -C tmp_elev_out2d_1.nc 
     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_2.nc -C tmp_elev_out2d_2.nc
     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_3.nc -C tmp_elev_out2d_3.nc
     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_4.nc -C tmp_elev_out2d_4.nc
     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_5.nc -C tmp_elev_out2d_5.nc

     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_6.nc -C tmp_elev_out2d_6.nc
     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_7.nc -C tmp_elev_out2d_7.nc
     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_8.nc -C tmp_elev_out2d_8.nc
     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_9.nc -C tmp_elev_out2d_9.nc
     ncks -x -v dryFlagNode,windSpeedX,windSpeedY,depthAverageVelX,depthAverageVelY,dryFlagElement,dryFlagSide out2d_10.nc -C tmp_elev_out2d_10.nc


     rm -f tmp_elev_out2d_merged.nc
     ncrcat -C tmp_elev_out2d_1.nc tmp_elev_out2d_2.nc tmp_elev_out2d_3.nc tmp_elev_out2d_4.nc tmp_elev_out2d_5.nc  \
               tmp_elev_out2d_6.nc tmp_elev_out2d_7.nc tmp_elev_out2d_8.nc tmp_elev_out2d_9.nc tmp_elev_out2d_10.nc tmp_elev_out2d_merged.nc
     
   
     ncatted  -a units,time,o,c,"seconds since ${myr}-${mmon}-${mday} ${mhr}:00:00 +${utchr}" -a base_date,time,o,c,"${myr} ${mmon} ${mday} ${mhr} ${utchr}" tmp_elev_out2d_merged.nc

     #fn_py_gen_goejson=${PYstofs3d}/gen_geojson.py     
     python ${fn_py_gen_goejson} --input_filename tmp_elev_out2d_merged.nc

     #deactivate

  
  else
     echo "WARNING: out2d_{1,2,...,10}.nc were not all created"
     err_exit  

  fi

  
# -------------------> archive
     export err=$?

        if [ $err -eq 0 ]; then
           cp -pf ${RUN}.${cycle}.*.gpkg  ${COMOUT}

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



