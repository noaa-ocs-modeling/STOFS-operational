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

  echo "${fn_this_sh} began at UTC: " `date -u`

  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  cd ${DATA}

# ---------------------------> Global Variables
  fn_node_id_cityPoly_adc=${FIXstofs3d}/stofs_3d_atl_node_id_city_poly_adcirc.txt

  fn_py_gen_nc=${PYstofs3d}/generate_adcirc.py
  # python generate_adcirc.py --input_filename ./outputs/out2d_1.nc --output_dir ./extract/


# ------------------> check file existence
# staout_x: listed in *_staout.json

  list_num=(1 2 3)

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


   list_YMD=(${PDYHH_NCAST_BEGIN:0:8} ${PDYHH_FCAST_BEGIN:0:8} ${PDYHH_FCAST_END:0:8})

   cnt=-1
   for k_no in ${list_num[@]};
   do

     let cnt=cnt+1
     YMD_k_no=${list_YMD[${cnt}]}

     echo "processing: ${dir_input}/out2d_${k_no}.nc for ${YMD_k_no}: "
     # python ${fn_py_gen_nc}  --input_filename ${dir_input}/out2d_${k_no}.nc  --output_dir ${dir_output}  >> $pgmout 2> errfile
     python ${fn_py_gen_nc}  --input_filename ${dir_input}/out2d_${k_no}.nc  --input_city_identifier_file  ${fn_node_id_cityPoly_adc}  --output_dir ${dir_output}  >> $pgmout 2> errfile 



     fn_py_out_nc=schout_adcirc_${k_no}.nc
     fn_adc_nfcast_std=schout_adcirc_${YMD_k_no}.nc     

     export err=$?
        if [ $err -eq 0 ]; then
           cp -pf ${dir_output}/${fn_py_out_nc} ${COMOUT}/${fn_adc_nfcast_std}
        
        else
           mstofs="Creation/Archiving of ${dir_output}/${fn_adc_nfcast_std} failed"
           echo $msg; echo $msg >> $pgmout
       
        fi

    done



echo 
echo "${fn_this_sh} completed at UTC: `date`"
echo 


