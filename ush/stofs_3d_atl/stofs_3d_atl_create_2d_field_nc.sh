#!/bin/bash


#############################################################################
#  Name: stofs_3d_atl_create_2d_field_nc.sh                                 #
#  This script reads the SCHISM output files with the names containing any  #
#  strings in {out2d,temperature,salinity,horizontalVelX,horizontalVelY,    #
#  zCoordinates} and creates the 2-D field data,                            #
#  stofs_3d_atl.t12z.{n001_024,f001_024,025_048}.field2d.nc                 #
#                                                                           #
#  Remarks:                                                                 #
#############################################################################


# ---------------------------> Begin ...
# set -x
#  set +H

  echo " stofs_3d_atl_create_2d_field_nc.sh began" 

  pgmout=pgmout_stofs3d_create_2d_field_nc.$$
  rm -f $pgmout

  # idx_day_no: SINGLE element number, NOT an array!
  idx_day_no=$1
  echo "idx_day_no=${idx_day_no}"

  ##list_day_no=(${idx_day_no})

  cd ${DATA}

# ------------------> check file existence
  #list_day_no=(1 2 3)

  list_fn_base=(horizontalVelX  horizontalVelY  out2d  salinity  temperature  zCoordinates)

  echo "In stofs_3d_atl_create_2d_field_nc.sh: checking file existence: "
 
  num_missing_files=0
  ## for k_no in ${list_day_no[@]};  
  k_no=${idx_day_no}
   
    for k_fn in ${list_fn_base[@]}; 
    do

       fn_k=outputs/${k_fn}_${k_no}.nc
       if [ -s ${fn_k} ]; then
          echo "checked: ${fn_k} exists"
       else
          num_missing_files=`expr ${num_missing_files} + 1`
          echo "checked: ${fn_k} does NOT exist; number of missing files=${num_missing_files}" 
       fi
    done



# ------------------> create 2D nc: intpl
  yyyymmdd_hh_ref=${PDYHH_NCAST_BEGIN:0:4}-${PDYHH_NCAST_BEGIN:4:2}-${PDYHH_NCAST_BEGIN:6:2}-${cyc}

  #for k_no in ${list_day_no[@]};



  list_hr_range=(n001_012 n013_024 f001_012 f013_024 f025_036 f037_048  \
	                           f049_060 f061_072 f073_084 f085_096)  

     stack_no=${k_no}
   
     let i_hr_range=$((stack_no-1))
     str_hr_range=${list_hr_range[${i_hr_range}]}

      #fn_2d_field_std=${RUN}.${cycle}.${str_hr_range}.field2d.nc
      #fn_2d_field_date_tag=${RUN}.field2d.${str_hr_range}.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc


      echo "Processing: results/stack_no = ${stack_no}" 

      mkdir -p results
      python ${PYstofs3d}/extract_slab_fcst_netcdf4.py  --date ${yyyymmdd_hh_ref}  --stack ${stack_no}  >> $pgmout 2> errfile
      #python ${PYstofs3d}/extract_slab_fcst_netcdf4.py  --date ${yyyymmdd_hh_ref}  --stack ${stack_no}


   msg="Completed: extract_slab_fcst_netcdf4.py, stack_no: ${idx_day_no} "
   echo $msg; echo
   echo $msg > $pgmout

  # cp files
      fn_out_py=results/schout_2d_${stack_no}.nc
      #fn_2d_field_std=${RUN}.${cycle}.${str_hr_range}.field2d.nc
      fn_2d_field_std=${RUN}.${cycle}.field2d_${str_hr_range}.nc

      echo pwd = `pwd`
      echo fn_out_py=${fn_out_py}
      echo fn_2d_field_std=${fn_2d_field_std}

      if [[ -f ${fn_out_py}  ]]; then
           # 2023/8/16
           ncatted -a long_name,elev,o,c,"water surface elevation above xgeoid20b"  ${fn_out_py}

           cpreq -pf ${fn_out_py}  ${COMOUT}/${fn_2d_field_std}
           #cpreq -pf ${fn_out_py}  ${COMOUT}/${fn_2d_field_date_tag}

           msg="Done cp: fn_out_py = ${fn_out_py}"$'\n'; 
	   echo -e $msg; echo;
           echo -e $msg >> $pgmout

         if [ $SENDDBN = YES ]; then
            $DBNROOT/bin/dbn_alert MODEL STOFS_NETCDF $job ${COMOUT}/${fn_2d_field_std}
            export err=$?; err_chk
          fi

      else
	   msg="Not existed: ${fn_out_py}"$'\n'   
           msg=${msg}"Creation/Archiving of results/${fn_2d_field_std} failed"
           echo -e $msg; echo;
	   echo -e $msg >> $pgmout
      fi



export err=$?; #err_chk  

echo 
echo "stofs_3d_atl_create_2d_field_nc.sh  completed "
echo 


