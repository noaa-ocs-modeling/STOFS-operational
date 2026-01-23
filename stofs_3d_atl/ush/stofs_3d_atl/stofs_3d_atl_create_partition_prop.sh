#!/bin/bash

#################################################################################################################
#  Name: stofs_3d_atl_create_partition_prop.sh                                                                #
#                                                                                                               #
#  Remarks:                                                                                                     #
#                                                                                                 2024          #
#################################################################################################################

  seton='-xa'
#  setoff='+xa'
  set $seton

# ----------------------->
  fn_this_script=stofs_3d_atl_create_partition_prop.sh

  msg="${fn_this_script}.sh  started"
  echo "$msg"
  postmsg  "$msg"

  pgmout=${fn_this_script}.$$

# -----------------------> check for for avaiablability of partition_prop.nc

  mkdir -p ${DATA}/outputs
  cd ${DATA}; 

  echo "Current dir=`pwd`"; echo

  # NCPU_PBS==4320; minus N_scribe=6, hence, 4316; 
  # note: count (0, ..., 4316-1)
  #NCPU_PBS_hot_restart=4314

  
# ----------> check N_partition of the existing partition.prop
# fn_par_prop_rerun=

  fn_par_prop_default_fix=partition.prop
  
  #awk '{if(max<$1){max=$1;line=$2}}END{print line}' file   
  nproc_default_fix=$(awk -F' ' "{print \$2 }" partition.prop  | awk 'BEGIN{a=1}{if ($1>0+a) a=$1} END{print a}')

  echo
  echo "nproc_default_fix= ${nproc_default_fix} + 1"
  echo

 
  #let n_scribes=6
  let n_scribes=8
  let nproc_tgt=${NCPU_PBS}-${n_scribes}
     echo "nproc_tgt=${nproc_tgt}"
     echo
 

let nproc_default_fix_plus_1=${nproc_default_fix}+1     
if [[ ${nproc_default_fix_plus_1} -eq ${nproc_tgt} ]]; then 

  echo " In stofs_3d_atl_create_partition_prop.sh: "
   
  echo "No new partition.prop needs to be generated; continue to use the default in fix"
  echo 


else

  echo " In stofs_3d_atl_create_partition_prop.sh: "	
  echo "Default partition.prop does not match the need: nproc_default_fix_plus_1=${nproc_default_fix_plus_1}; nproc_tgt=${nproc_tgt}" 
  echo 
   
  mv partition.prop partition_prop_nproc_default_fix_${nproc_default_fix};

  # ----------> 
  # fn_exe_gen_partition=${EXECstofs3d}/stofs_3d_atl_gpmetis
    fn_exe_gen_partition=gpmetis      # WCOSS2 system app

    cd ${DATA}


    # ---------> Create new partition.prop
     rm -f graphinfo
     rm -f graphinfo.part.${nproc_tgt}
     cp -fp ${FIXstofs3d}/stofs_3d_atl_graphinfo.txt ./ 
      
     ${fn_exe_gen_partition}  stofs_3d_atl_graphinfo.txt  ${nproc_tgt}  -ufactor=1.01  -seed=15


     fn_partition_new=partition.prop_NCPU_PBS_${NCPU_PBS}_nproc_${nproc_tgt}
       rm -f ${fn_partition_new}
       awk '{print NR,$0}' stofs_3d_atl_graphinfo.txt.part.${nproc_tgt} > ${fn_partition_new}

     ln -sf ${fn_partition_new} partition.prop 

     
   # ---------->
    export err=$?

    if [ $err -eq 0 ]; then

      fn_partition_std_name=stofs_3d_atl_partition.prop	    
      cp -pf ${fn_partition_new}  ${COMOUT}/rerun/${fn_partition_std_name}

      msg="Creation/Archiving of ${fn_partitioni_new} was successfully created"
      echo $msg; echo $msg >> $pgmout

    else
      msg="Creation/Archiving of ${dir_output}/${fn_sta_profile} failed"
      echo $msg; echo $msg >> $pgmout

    fi 

fi  # if [[ ${nproc_default_fix} -eq ${nproc_tgt} ]]; then 


echo 
echo "${fn_this_sh} completed "
       







  
