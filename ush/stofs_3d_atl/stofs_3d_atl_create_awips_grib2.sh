#!/bin/bash


#################################################################################
#  Name: stofs_3d_atl_create_awips_grib2.sh                                     #
#  This is a post-processing script that reads the water level field            #
#  time series data, schout_adcirc_{1,2,3,4,5}.nc (that are created by              #
#  another post-processing script, stofs_3d_atl_create_adcirc_nc.sh, in         #
#  the same directory as this script) to create the AWIPS WGRIB-format          #
#  time series files,                                                           #
#  (1) U.S. east conus are                                                      #
#   - separated hourly: stofs_3d_atl.t12z.conus.east.f{000,001,...,048}.grib2   #
#   - combined hourly:  stofs_3d_atl.t12z.conus.east.cwl.grib2                  #
#  (2) Puerto Rico area                                                         #
    - separated hourly: stofs_3d_atl.t12z.puertori.f{000,001,...,048}.grib2     #
    - combined hourly:  stofs_3d_atl.t12z.puertori.cwl.grib2                    #
#                                                                               #
#  Remarks:                                                                     #
#                                                             September, 2022   #
#################################################################################


# ---------------------------> Begin ...
# set -x

  fn_this_sh="stofs_3d_atl_netcdf2grib.sh"

  echo "${fn_this_sh} began at UTC: "

  echo "module list::"
  module list

  echo; echo

  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  cd ${DATA}

# ---------------------------> Global Variables
  fin_mask_conus_east_us=${FIXstofs3d}/stofs_3d_atl_awips_mask_conus_us_east.txt
  fin_mask_puertorico=${FIXstofs3d}/stofs_3d_atl_awips_mask_puerto_rico.txt

  # cp -fp ${fin_mask_conus_east_us}   ${DATA}
  # cp -fp ${fin_mask_puertorico}    ${DATA}

  fn_exe_gen_grib2=${EXECstofs3d}/stofs_3d_atl_netcdf2grib


# ------------------> check file existence
  echo "In: checking adcirc files existence: "

  cd ${DATA}/dir_adcirc_nc

  # exclude nowcast period  
  list_adc_files=(schout_adcirc_1.nc schout_adcirc_2.nc schout_adcirc_3.nc schout_adcirc_4.nc schout_adcirc_5.nc \ 
	          schout_adcirc_6.nc schout_adcirc_7.nc schout_adcirc_8.nc schout_adcirc_9.nc schout_adcirc_10.nc)
  
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
     echo "schout_adcirc_1,2,3,4,5 nc: all exist"

     fn_adc_merged=schout_adc_nfcast_days_1_2_3_4_5_merged.nc    
 
     rm -f ${fn_adc_merged}
     ncrcat -C -O schout_adcirc_1.nc schout_adcirc_2.nc schout_adcirc_3.nc schout_adcirc_4.nc schout_adcirc_5.nc \
	          schout_adcirc_6.nc schout_adcirc_7.nc schout_adcirc_8.nc schout_adcirc_9.nc schout_adcirc_10.nc ${fn_adc_merged}
  
  else
     echo "FATAL error: there are missing files: schout_adcirc_{1,...,10}.nc"
     err_exit  

  fi


# ------------------> create AWIPS grib2 files
     #yyyymmdd_hh_ref=$((${PDYHH_FCAST_BEGIN} + 1))
     yyyymmdd_hh_ref=${PDYHH_FCAST_BEGIN}

     ${fn_exe_gen_grib2} conus cwl  ${yyyymmdd_hh_ref} ${fin_mask_conus_east_us} ${fn_adc_merged} 3000
  
     ${fn_exe_gen_grib2} puertori cwl ${yyyymmdd_hh_ref} ${fin_mask_puertorico}  ${fn_adc_merged} 5000   


     # ./estofs_netcdf2grib conus cwl 2022050112 conus_mask.txt cwl.fort.63.nc 3000
     # ./estofs_netcdf2grib conus cwl  2022050112 puertorico_mask.txt cwl.fort.63.nc 5000


#     for fhr in $(seq -f "%03g" 0 48); do
     for fhr in $(seq -f "%03g" 0 96); do

      cp -f fort.3${fhr} ${RUN}.${cycle}.conus.east.f${fhr}.grib2
      cat fort.3${fhr} >> ${RUN}.${cycle}.conus.east.cwl.grib2

       cp -f fort.5${fhr} ${RUN}.${cycle}.puertori.f${fhr}.grib2
       cat fort.5${fhr} >> ${RUN}.${cycle}.puertori.cwl.grib2

     done

     msg=`ls -r *.grib2`; echo ${msg}; echo $msg >> $pgmout

     # AWIPS grib2 cwl
      type=cwl

      grid=puertori
       export FORT11=${RUN}.${cycle}.${grid}.${type}.grib2
       export FORT31=" "
       export FORT51=grib2_${RUN}.${cycle}.${grid}.${type}

       rm -f out_${grid}.txt; rm -f errfile_${grid}.txt

       fn_PARMstofs=${PARMstofs3d}/grib2_stofs_3d_atl_puertori_cwl
       tocgrib2 < $fn_PARMstofs > out_${grid}.txt 2> errfile_${grid}.txt

     grid=conus.east
       export FORT11=${RUN}.${cycle}.${grid}.${type}.grib2
       export FORT31=" "
       export FORT51=grib2_${RUN}.${cycle}.${grid}.${type}

       rm -f out_${grid}.txt; rm -f errfile_${grid}.txt

       fn_PARMstofs=${PARMstofs3d}/grib2_stofs_3d_atl_conus.east_cwl
       tocgrib2 < $fn_PARMstofs > out_${grid}.txt 2> errfile_${grid}.txt
 
       echo "right after tocgrib2: checking grib2_xxx.cwl"
       ls grib2_*.cwl



# -------------------> archive
     export err=$?

        if [ $err -eq 0 ]; then
           cp -pf *.grib2 ${COMOUT}

           mkdir -p ${COMOUT}/wmo	   
           cp -pf grib2_${RUN}.${cycle}.*.${type} ${COMOUT}/wmo

           echo "right after cp grib2_xxx.cwl to COM"
           ls grib2_${RUN}.${cycle}.*.${type}


           msg="Creation/Archiving of AWIPS grib2 files was successfully created/archived"
           echo $msg; echo $msg >> $pgmout

        else
           mstofs="Creation/Archiving of AWIPS grib2 files  failed"
           echo $msg; echo $msg >> $pgmout
        fi
          
export err=$?; #err_chk  


echo 
echo "${fn_this_sh} completed "
echo 


