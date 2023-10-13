#!/bin/bash


################################################################################
#  Name: stofs_3d_atl_create_adcirc_nc.sh                                      #
#  This is a post-processing script that reads the water level field           #
#  time series data, outputs/out2d_{1,2,3}.nc to create the field water level  #
#  time series data, schout_adcirc_{1,2,3}.nc (that are used to support the    #
#  Coastal Emergency Risks Assessment (CERA) Project.                          #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2022   #
################################################################################


# ---------------------------> Begin ...
# set -x

  fn_this_sh="stofs_3d_atl_create_adcirc_nc.sh"

  echo "${fn_this_sh} began"

  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  cd ${DATA}

# ---------------------------> Global Variables
  fn_node_id_cityPoly_adc=${FIXstofs3d}/stofs_3d_atl_node_id_city_poly_adcirc.txt

  fn_py_gen_nc=${PYstofs3d}/generate_adcirc.py
  # python generate_adcirc.py --input_filename ./outputs/out2d_1.nc --output_dir ./extract/


# ------------------> check file existence
# staout_x: listed in *_staout.json

  # list_num=(1 2 3)
    list_num=(1 2 3 4 5 6 7 8 9 10)


  list_fn_base=(out2d_)

  echo "In : checking file existence: "
 

  dir_input=outputs/
  num_missing_files=0
  for k_no in ${list_num[@]};  
  do
   
    for k_fn in ${list_fn_base[@]}; 
    do

       fn_k=outputs/${k_fn}${k_no}.nc
       if [ -s ${fn_k} ]; then
          echo "checked: ${fn_k} exists"
       
       else
          num_missing_files=`expr ${num_missing_files} + 1`
          echo "checked: ${fn_k} does NOT exist" 
       fi
    done

  done


# ------------------> create nc files
  
     dir_input=./outputs
     dir_output=./dir_adcirc_nc
     mkdir -p ${dir_output}

   echo {PDYHH_NCAST_BEGIN:0:8}, {PDYHH_FCAST_BEGIN:0:8}, {PDYHH_FCAST_END:0:8}
   echo ${PDYHH_NCAST_BEGIN:0:8}, ${PDYHH_FCAST_BEGIN:0:8}, ${PDYHH_FCAST_END:0:8}


   # list_YMD=(${PDYHH_NCAST_BEGIN:0:8} ${PDYHH_FCAST_BEGIN:0:8} ${PDYHH_FCAST_END:0:8})
   
   PDY_FCAST_DAY2=${PDYp1}
   PDY_FCAST_DAY3=${PDYp2}

   list_YMD=(${PDYHH_NCAST_BEGIN:0:8} ${PDYHH_FCAST_BEGIN:0:8} ${PDY_FCAST_DAY2} ${PDY_FCAST_DAY3} ${PDYHH_FCAST_END:0:8})
   echo "list_YMD= ${list_YMD[@]}"

   #cnt=-1
   for k_no in ${list_num[@]};
   do

     #let cnt=cnt+1
     #YMD_k_no=${list_YMD[${cnt}]}

     echo "python - processing: ${dir_input}/out2d_${k_no}.nc: "   #  for ${YMD_k_no}: "
     # python ${fn_py_gen_nc}  --input_filename ${dir_input}/out2d_${k_no}.nc  --output_dir ${dir_output}  >> $pgmout 2> errfile
     python ${fn_py_gen_nc}  --input_filename ${dir_input}/out2d_${k_no}.nc  --input_city_identifier_file  ${fn_node_id_cityPoly_adc}  --output_dir ${dir_output}  >> $pgmout 2> errfile 
     echo "Done - ${dir_input}/out2d_${k_no}.nc"
   done

  
   # merge half day file into daily 
   ncrcat ${dir_output}/schout_adcirc_1.nc  ${dir_output}/schout_adcirc_2.nc  -O ${dir_output}/schout_adcirc_merged_1.nc
   ncrcat ${dir_output}/schout_adcirc_3.nc  ${dir_output}/schout_adcirc_4.nc  -O ${dir_output}/schout_adcirc_merged_2.nc
   ncrcat ${dir_output}/schout_adcirc_5.nc  ${dir_output}/schout_adcirc_6.nc  -O ${dir_output}/schout_adcirc_merged_3.nc
   ncrcat ${dir_output}/schout_adcirc_7.nc  ${dir_output}/schout_adcirc_8.nc  -O ${dir_output}/schout_adcirc_merged_4.nc
   ncrcat ${dir_output}/schout_adcirc_9.nc  ${dir_output}/schout_adcirc_10.nc -O ${dir_output}/schout_adcirc_merged_5.nc 


   for k_no in {1,2,3,4,5}
   do	   
     
     let k_merged=$k_no
     fn_py_out_nc=schout_adcirc_merged_${k_no}.nc

     let k_list_YMD=$((k_no-1))
     YMD_k_no=${list_YMD[$k_list_YMD]}
     fn_adc_nfcast_std=schout_adcirc_${YMD_k_no}.nc     
 
     echo $fn_adc_nfcast_std 

     export err=$?
        if [ $err -eq 0 ]; then
           cp -pf ${dir_output}/${fn_py_out_nc} ${COMOUT}/${fn_adc_nfcast_std}
        else
           mstofs="Creation/Archiving of ${dir_output}/${fn_adc_nfcast_std} failed"
           echo $msg; echo $msg >> $pgmout
        fi

   done


echo 
echo "${fn_this_sh} completed "
echo 


