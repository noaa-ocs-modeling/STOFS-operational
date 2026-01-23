#!/bin/bash


################################################################################
#  Name: stofs_3d_atl_create_adcirc_nc.sh                                      #
#  This is a post-processing script that reads the water level field           #
#  time series data, outputs/out2d_{1,2,3}.nc to create the field water level  #
#  time series data, schout_adcirc_{1,2,3}.nc (that are used to support the    #
#  Coastal Emergency Risks Assessment (CERA) Project.                          #
#                                                                              #
#  Remarks:                                                                    #
#                                                    Sep. 2022; Aug. 2025      #
################################################################################


# ---------------------------> Begin ...
set -x

  fn_this_sh="stofs_3d_atl_create_adcirc_nc.sh"

  echo "${fn_this_sh} began"

  pgmout=${fn_this_sh}.$$
  rm -f $pgmout

  cd ${DATA}

# ---------------------------> Global Variables
  fn_node_id_cityPoly_adc=${FIXstofs3d}/stofs_3d_atl_node_id_city_poly_adcirc.txt

  fn_py_gen_nc=${PYstofs3d}/generate_adcirc.py


# ------------------> check file existence
# staout_x: listed in *_staout.json

##    list_num=(1 2 3 4 5 6 7 8 9 10)


      idx_1_adc=$1
      idx_2_adc=$2
      idx_day_adc=$3

      # e.g., idx_1_adc=1; idx_2_adc=2; idx_day_adc=1


      list_num=($idx_1_adc $idx_2_adc)

  list_fn_base=(out2d_)

  echo "In : checking file existence: "
 

  #dir_input=outputs/
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
  
  #   dir_input=./outputs
  #   dir_output=./dir_adcirc_nc
  dir_input=outputs

  mkdir -p dir_adcirc_nc

# ------------------> merge out2d_x 12hr to 24hr
  # ncrcat ${dir_output}/schout_adcirc_${idx_1_adc}.nc   ${dir_output}/schout_adcirc_${idx_2_adc}.nc   -O ${dir_output}/schout_adcirc_merged_${idx_day_adc}.nc
    
  # in generate_adcirc.py: input_fileindex=os.path.basename(input_filename).replace("_", ".").split(".")[1]  # get the file index only  
  
  fn_out2d_ncrcat=out2dMerged${idx_1_adc}and${idx_2_adc}_${idx_day_adc}.nc
  ncrcat ${dir_input}/out2d_${idx_1_adc}.nc ${dir_input}/out2d_${idx_2_adc}.nc -O dir_adcirc_nc/${fn_out2d_ncrcat}
  

# ------------------> date variables 
   echo {PDYHH_NCAST_BEGIN:0:8}, {PDYHH_FCAST_BEGIN:0:8}, {PDYHH_FCAST_END:0:8}
   echo ${PDYHH_NCAST_BEGIN:0:8}, ${PDYHH_FCAST_BEGIN:0:8}, ${PDYHH_FCAST_END:0:8}

   
   PDY_FCAST_DAY2=${PDYp1}
   PDY_FCAST_DAY3=${PDYp2}

   list_YMD=(${PDYHH_NCAST_BEGIN:0:8} ${PDYHH_FCAST_BEGIN:0:8} ${PDY_FCAST_DAY2} ${PDY_FCAST_DAY3} ${PDYHH_FCAST_END:0:8})
   echo "list_YMD= ${list_YMD[@]}"


   
   python ${fn_py_gen_nc}  --input_filename dir_adcirc_nc/${fn_out2d_ncrcat}  --input_city_identifier_file  ${fn_node_id_cityPoly_adc}  --output_dir dir_adcirc_nc  >> $pgmout 2> errfile 
   
   echo "Done - `pwd`/dir_adcirc_nc/out2d_merged_day_${idx_day_adc}.nc"


   
   list_k_no=(${idx_day_adc})  
   #for k_no in {1,2,3,4,5}
   for k_no in ${list_k_no[@]} 
   do	   
     
     let k_merged=$k_no

     #fn_py_out_nc=schout_adcirc_merged_${k_no}.nc
     fn_py_out_nc=schout_adcirc_${k_no}.nc  

     let k_list_YMD=$((k_no-1))
     YMD_k_no=${list_YMD[$k_list_YMD]}
     fn_adc_nfcast_std=schout_adcirc_${YMD_k_no}.nc     
 
     echo $fn_adc_nfcast_std 

     export err=$?
        if [ $err -eq 0 ]; then
           cp -pf dir_adcirc_nc/${fn_py_out_nc} ${COMOUT}/${fn_adc_nfcast_std}
        else
           msg="Creation/Archiving of dir_adcirc_nc/${fn_adc_nfcast_std} failed"
           echo $msg; echo $msg >> $pgmout
        fi

   done


echo 
echo "${fn_this_sh} completed "
echo 


