#!/bin/bash


###########################################################################
#  Name: stofs_3d_atl_create_awips_shef.sh                                # 
#  This is a post-processing script that reads station time series data,  #   
#  outputs/staout_1 to create the AWIPS/shef-type station time series     #
#  date, stofs_3d_atl.t12z.points.cwl.shef.                               #
#                                                                         #
#  Remarks:                                                               #
#                                                       September, 2022   #
###########################################################################


# ---------------------------> Begin ...
 set -x

  fn_this_sh="stofs_3d_atl_create_awips_shef.sh"

  echo "${fn_this_sh} began at UTC: " `date -u`

  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  cd ${DATA}

# ---------------------------> Global Variables
  fin_staout_nc_json=${FIXstofs3d}/stofs_3d_atl_staout_nc.json
  
  fin_staout_nc_csv=${FIXstofs3d}/stofs_3d_atl_staout_nc.csv

  fin_shef_navd88_mllw=${FIXstofs3d}/stofs_3d_atl_sta_awips_shef_navd88_mllw.txt

  cp -fp ${fin_staout_nc_json}   ${DATA}
  cp -fp ${fin_staout_nc_csv}    ${DATA}
  cp -fp ${fin_shef_navd88_mllw} ${DATA}


  fn_py_gen_nc=${PYstofs3d}/generate_station_timeseries.py
  fn_exe_gen_nc2shef=${EXECstofs3d}/stofs_3d_atl_netcdf2shef

  #type=cwl; YMDH=2022053012; fin_nc=schout_timeseries_at_obs_locations_${YMDH:0:8}.nc; fin_shef_navd88_mllw=stations_navd88_mllw.txt
  #./estofs_netcdf2shef con $type $YMDH ${fin_nc} ${fin_shef_navd88_mllw}


# ------------------> check file existence
# staout_x: listed in *_staout.json

  list_staout_no=(1 2 5 6 7 8)

  list_fn_base=(staout_)

  echo "In : checking file existence: "
 

  dir_input=outputs/
  num_missing_files=0
  for k_no in ${list_staout_no[@]};  
  do
   
    for k_fn in ${list_fn_base[@]}; 
    do

       fn_k=outputs/${k_fn}${k_no}
       if [ -s ${fn_k} ]; then
          echo "checked: ${fn_k} exists"
       
       else
          num_missing_files=`expr ${num_missing_files} + 1`
          echo "checked: ${fn_k} does NOT exist" 
       fi
    done

  done


# ------------------> create 6-min station time series file (.nc)
     yyyymmdd_hh_ref=`date -d ${PDYHH_NCAST_BEGIN:0:8}  +%Y-%m-%d`-${cyc}
  
     dir_input=./outputs/
     dir_output=./

     python ${fn_py_gen_nc}  --date ${yyyymmdd_hh_ref}  --input_dir ${dir_input}  --output_dir ${dir_output}  >> $pgmout 2> errfile

     fn_py_out_nc_6min=staout_timeseries_${yyyymmdd_hh_ref}.nc
     echo fn_py_out_nc_6min = ${fn_py_out_nc_6min}    

 
     fn_sta_cwl_t_s_vel_nfcast_std=${RUN}.${cycle}.points.cwl.temp.salt.vel.nc
     
     cpreq -pf ${dir_output}/${fn_py_out_nc_6min} ${dir_output}/${fn_sta_cwl_t_s_vel_nfcast_std}

     # archive & prep shef input
     # fn_py_out_nc_30min_fcast0_48hr=staout_zeta_30min_fcast0_48_for_shefFTN.nc

     export err=$?

        if [ $err -eq 0 ]; then

           cpreq -pf ${dir_output}/${fn_py_out_nc_6min} ${COMOUT}/${fn_sta_cwl_t_s_vel_nfcast_std}

	   if [ $SENDDBN = YES ]; then
             $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job ${COMOUT}/${fn_sta_cwl_t_s_vel_nfcast_std}
	   fi

           msg="Creation/Archiving of ${dir_output}/${fn_sta_cwl_t_s_vel_nfcast_std} was successfully created"
           echo $msg; echo $msg >> $pgmout

        else
           mstofs="Creation/Archiving of ${dir_output}/${fn_sta_cwl_t_s_vel_nfcast_std} failed"
           echo $msg; echo $msg >> $pgmout
        fi
          
export err=$?; #err_chk  


# ------------------> create 30-min AWIPS SHEF files (.nc)

  # (1)  extract SHEF stations from the above 6-min satout_xxx.nc
    fn_py_out_nc_6min_shef_only=${fn_py_out_nc_6min}_shef_only
    ncks -O -C -d station,0,146,1  ${fn_py_out_nc_6min}  ${fn_py_out_nc_6min_shef_only}  


    # extract 30-min data for shef ftn
     fn_py_out_nc_30min_fcast0_48hr=staout_zeta_30min_fcast0_48_for_shefFTN.nc
     rm -f ${fn_py_out_nc_30min_fcast0_48hr}
     
     # ncks -v zeta -v station_name -d time,239,,5 ${fn_py_out_nc_6min_shef_only}  -O ${fn_py_out_nc_30min_fcast0_48hr}
     ncks -d time,239,,5 ${fn_py_out_nc_6min_shef_only}  -O ${fn_py_out_nc_30min_fcast0_48hr}     

  
  # (2) call fortran exe; outputs: fort.5xxx, then merge into stofs3d.t12z.points.cwl.shef
  fin_shef_ftn=${fn_py_out_nc_30min_fcast0_48hr}

  type=cwl; 
  YMDH=${PDYHH_FCAST_BEGIN}
  
  #mkdir -p DIR_SHEF_fort_files
  #cd ${DIR_SHEF_fort_files}
  
  rm -f fort.5???

  echo 1-fin_shef_ftn=${fin_shef_ftn}
  ls -l ${fin_shef_ftn}
  ls -l ${fin_shef_navd88_mllw}


  echo 2-fn_exe_gen_nc2shef= ${fn_exe_gen_nc2shef}
  echo 3-type=$type
  echo 4-YMDH=$YMDH
  echo 5-fin_shef_ftn=${fin_shef_ftn}
  echo 6-fin_shef_navd88_mllw=${fin_shef_navd88_mllw}
  echo

  ${fn_exe_gen_nc2shef} con $type $YMDH ${fin_shef_ftn} ${fin_shef_navd88_mllw}

  fn_shef_merged=${RUN}.${cycle}.points.cwl.shef
  rm -f ${fn_shef_merged}

  cat fort.5??? >> ${fn_shef_merged} 
    

  # archive
    export err=$?

    if [ $err -eq 0 ]; then
      cp -pf ${fn_shef_merged} ${COMOUT}

      msg="Creation/Archiving of ${fn_shef_merged} was successfully created"
      echo $msg; echo $msg >> $pgmout


      if [ $SENDDBN = YES ]; then
        $DBNROOT/bin/dbn_alert MODEL STOFS_SHEF  $job ${COMOUT}/${fn_shef_merged} 
        export err=$?; err_chk
      fi
    


      else
        mstofs="Creation/Archiving of ${dir_output}/${fn_shef_merged} failed"
        echo $msg; echo $msg >> $pgmout
    fi


export err=$?; #err_chk

echo 
echo "${fn_this_sh} completed at UTC: `date`"
echo 


