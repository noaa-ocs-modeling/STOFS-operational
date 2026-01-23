#!/bin/bash

#################################################################################
#  Name: stofs_3d_atl_create_merged_hotstart_nc.sh                              #
#                                                                               #
#  Remarks: this script creates the global domain hotstart.nc through merging   #
#           the sub-domain hotstart nc                                          #
#                                                                               #
#                                                    December 2023; Aug. 2025   #
#################################################################################


# ---------------------------> Begin ...
 set -x

  fn_this_sh="stofs_3d_atl_create_merged_hotstart_nc.sh"

  echo " ${fn_this_sh} began"  
 
  pgmout=`pwd`/pgmout_stofs3d_create_merged_hotstart_nc.$$
  rm -f $pgmout

  msg="In ${fn_this_sh}:: begins ... " 
  echo $msg >> $pgmout
  

# ---------------------------> Global Variables


# -------------------------->
  cd ${DATA}/outputs; pwd
  

    idx_time_step_merge_hotstart=576
    fn_merged_hotstart_ftn=hotstart_it\=${idx_time_step_merge_hotstart}.nc
    fn_hotstart_stofs3d_merged_std=${RUN}.${cycle}.hotstart.stofs3d.nc

    ${EXECstofs3d}/stofs_3d_atl_combine_hotstart  -i  ${idx_time_step_merge_hotstart}


    export err=$?
    if [ $err -eq 0 ]; then
       msg=`echo $fn_this_sh completed normally`
       echo $msg; echo $msg >> $pgmout

       if [ -s ${fn_merged_hotstart_ftn} ]; then
          msg=`echo ${fn_merged_hotstart_ftn}} has been created`;
          echo $msg; echo $msg >> $pgmout

          fn_merged_hotstart_ftn_time_00=${fn_merged_hotstart_ftn}_time_00
          ncap2 -O -s 'time=0.0' ${fn_merged_hotstart_ftn}  ${fn_merged_hotstart_ftn_time_00}

          echo 'cp: ${fn_merged_hotstart_ftn_time_00} ${COMOUT}/${fn_hotstart_stofs3d_merged_std}'
          echo 
          cpreq -pf ${fn_merged_hotstart_ftn_time_00} ${COMOUT}/${fn_hotstart_stofs3d_merged_std}

       else
         msg=`echo ${fn_merged_hotstart_ftn}} was not created`
         echo $msg; echo $msg >> $pgmout
       fi

    else
       msg=`echo $fn_this_sh did not complete normally`
       echo $msg; echo $msg >> $pgmout

    fi


echo 
echo "${fn_this_sh} completed "
echo 








