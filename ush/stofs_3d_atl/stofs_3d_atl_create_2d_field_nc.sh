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

  echo " stofs_3d_atl_create_2d_field_nc.sh began at UTC: " `date -u`

  pgmout=pgmout_stofs3d_create_2d_field_nc.$$
  rm -f $pgmout

  list_day_no=(1 2 3)

  cd ${DATA}


# ------------------> check file existence
  list_day_no=(1 2 3)

  list_fn_base=(horizontalVelX  horizontalVelY  out2d  salinity  temperature  zCoordinates)

  echo "In stofs_3d_atl_create_2d_field_nc.sh: checking file existence: "
 
  num_missing_files=0
  for k_no in ${list_day_no[@]};  
  do
   
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

  done


# ------------------> create 2D nc: intpl
  yyyymmdd_hh_ref=`date -d ${PDYHH_NCAST_BEGIN:0:8}  +%Y-%m-%d`-${cyc}

  for k_no in ${list_day_no[@]};
  do

     stack_no=${k_no}
     if [ ${stack_no} == 1 ]; then
        #yyyymmdd_hh_ref=`date -d ${PDYHH_NCAST_BEGIN:0:8}  +%Y-%m-%d`-${cyc}
        str_hr_range=n001_024
        #list_hr=`seq  -f n%03g 1 24`

      elif [ ${stack_no} == 2 ]; then
        #yyyymmdd_hh_ref=`date -d ${PDYHH_FCAST_BEGIN:0:8}  +%Y-%m-%d`-${cyc}
        str_hr_range=f001_024
        #list_hr=`seq  -f f%03g 1 24`

      else
        #yyyymmdd_hh_ref=`date -d ${PDYHH_FCAST_BEGIN:0:8}  +%Y-%m-%d`-${cyc}
	str_hr_range=f025_048
        #list_hr=`seq  -f f%03g 25 48`

      fi

      fn_2d_field_std=${RUN}.${cycle}.${str_hr_range}.field2d.nc
      #fn_2d_field_date_tag=${RUN}.field2d.${str_hr_range}.${PDYHH_FCAST_BEGIN:0:8}.${cycle}.nc


      echo "Processing: results/stack_no = ${stack_no}" 
      echo `date -u`

      #python ${PYstofs3d}/extract_slab_fcst_netcdf4.py  --date ${yyyymmdd_hh_ref}  --stack ${stack_no}  >> $pgmout 2> errfile
      # python ${PYstofs3d}/extract_slab_fcst_netcdf4.py  --date ${yyyymmdd_hh_ref}  --stack ${stack_no}  >> $pgmout 2> errfile  &

      #python ${PYstofs3d}/extract_slab_fcst_netcdf4.py  --date ${yyyymmdd_hh_ref}  --stack ${stack_no}  &
      python ${PYstofs3d}/extract_slab_fcst_netcdf4.py  --date ${yyyymmdd_hh_ref}  --stack ${stack_no}

   done

   msg="Completed: extract_slab_fcst_netcdf4.py, stack_no: 1,2,3 (all thress)"
   echo $msg; echo
   echo $msg > $pgmout

  # cp files
  for k_no in ${list_day_no[@]};
  do
     stack_no=${k_no}
     if [ ${stack_no} == 1 ]; then
        str_hr_range=n001_024
        #list_hr=`seq  -f n%03g 1 24`

      elif [ ${stack_no} == 2 ]; then
        str_hr_range=f001_024
        #list_hr=`seq  -f f%03g 1 24`

      else
        str_hr_range=f025_048
        #list_hr=`seq  -f f%03g 25 48`

      fi

      fn_out_py=results/schout_2d_${stack_no}.nc
      fn_2d_field_std=${RUN}.${cycle}.${str_hr_range}.field2d.nc

      echo pwd = `pwd`
      echo fn_out_py=${fn_out_py}
      echo fn_2d_field_std=${fn_2d_field_std}

      if [[ -f ${fn_out_py}  ]]; then

           cpreq -pf ${fn_out_py}  ${COMOUT}/${fn_2d_field_std}
           #cpreq -pf ${fn_out_py}  ${COMOUT}/${fn_2d_field_date_tag}

           msg="Done cp: fn_out_py = ${fn_out_py}"$'\n'; 
	   echo $msg; echo;
           echo $msg >> $pgmout

      else
	   msg="Not existed: ${fn_out_py}"$'\n'   
           msg=${msg}"Creation/Archiving of results/${fn_2d_field_std} failed"
           echo $msg; echo;
	   echo $msg >> $pgmout
      fi

  done


export err=$?; #err_chk  

echo 
echo "stofs_3d_atl_create_2d_field_nc.sh  completed at UTC: `date`"
echo 


