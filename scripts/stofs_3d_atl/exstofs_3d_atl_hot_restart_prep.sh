#!/bin/bash

#################################################################################################################
#  Name: exstofs_3d_atl_create_hot_restart.sh                                                                   #
#  This script is to create the global domain hotstart nc, and to archive it in com/rerun as follows:           #
#    (1) rename the original stofs_3d_atl.t12z.hotstart.stofs3d.nc to stofs_3d_atl.t12z.hotstart.stofs3d.v0.nc  #
#    (2) save the newly created file as stofs_3d_atl.t12z.hotstart.stofs3d.nc                                   # 
#                                                                                                               #
#  Remarks:                                                                                                     #
#                                                                                                 May 2023      #
#################################################################################################################

#  seton='-xa'
#  setoff='+xa'
#  set $seton

# ----------------------->
  fn_this_script=exstofs_3d_atl_create_hot_restart.sh

  msg="${fn_this_script}.sh  started at UTC: `date  `"
  echo "$msg"
  postmsg "$jlogfile" "$msg"

  pgmout=${fn_this_script}.$$


# -----------------------> check for available hotstart_x.nc

  mkdir -p ${DATA}/outputs
  cd ${DATA}; 

  echo "Current dir=`pwd`"; echo


  # NCPU_PBS==4320; minus N_scribe=6, hence, 4316; 
  # note: count (0, ..., 4316-1)
  NCPU_PBS_hot_restart=4314

  sz_cr_ht_subdmn_MB=100000    # bytes

  # list_steps_OI=(288 576 864 1152 1440 1728 2016 2304 2592 2880)
  list_steps_OI=(2880 2592 2304 2016 1728 1440 1152 864 576 288) 
  dt_timestep=150

  # str_ht_fn_prefix=
  flag_hotstart_found=0
  time_sec_merge_hotstart=0
  idx_time_step_merge_hotstart=0

  rm -f  tmp_chk_hotstart_file

  for k_OI in ${list_steps_OI[@]}
  do


     # list_fn_ht_OI=`ls ${DATA}/outputs/hotstart_0?????_${k_OI}.nc` 
     list_fn_ht_OI=`ls ./outputs/hotstart_0?????_${k_OI}.nc 2> tmp_chk_hotstart_file`

     echo "checking hotstart file of step=${k_OI}"

     N_file_hotstart_default=`ls -lr  ./outputs/hotstart_0?????_*${k_OI}.nc 2>> tmp_chk_hotstart_file | wc -l`   
     
     echo
     echo checking hotstart file of step=${k_OI} 
     echo N_file_hotstart=${N_file_hotstart_default}
     echo
     
     flag_sz_cr=1
     
     if [[ ${N_file_hotstart_default} -eq ${NCPU_PBS_hot_restart} ]]; then
        echo N_file_hotstart_default=${N_file_hotstart_default}  
 
        for fn_ht_k in ${list_fn_ht_OI[@]}; 
        do
        
          sz_ht_k=`du -b ${fn_ht_k} | awk '{print $1}'`
          if [ $(( sz_ht_k )) -lt $sz_cr_ht_subdmn_MB ]; then 
             echo "Attn: size(${fn_ht_k})=${sz_ht_k} (bytes) LT ${sz_cr_ht_subdmn_MB}"               
             
             flag_sz_cr=0
             #break;
          fi  
        done

        if [[ ${flag_sz_cr} -eq 1 ]]; then
          flag_hotstart_found=1  
       
	  idx_time_step_merge_hotstart=${k_OI};
	  time_sec_merge_hotstart=$(( ${idx_time_step_merge_hotstart}*${dt_timestep} ))

	  break;
        fi


     else # case: LT; if [[ ${N_file_hotstart_default} -eq ${NCPU_PBS_hot_restart} ]] 
        echo "Attn: N_file_hotstart_default=${N_file_hotstart_default} LT ${NCPU_PBS_hot_restart} (target number)"

        #flag_hotstart_found=0
        	

     fi   # if [[ ${N_file_hotstart_default} -eq ${NCPU_PBS_hot_restart} ]]     

  done   # for k_OI in ${list_steps_OI[@]}	  

  echo 
  echo
  echo idx_time_step_merge_hotstart=${idx_time_step_merge_hotstart}
  echo time_sec_merge_hotstart=${time_sec_merge_hotstart} '(sec)'
  echo


# -----------------------> update nml  
if [[ ${time_sec_merge_hotstart}  -ne 0 ]]; then
 
  cd ${DATA}

  mv param.nml param.nml_cold_restart

  cat param.nml_cold_restart | sed "s/ihot = 1/ihot = 2/" > param.nml

  # backup param.nml of cold restart
  fn_param_modelRun_std=${RUN}.${cycle}.param.nml
  cpreq -f param.nml ${COMOUT}/rerun/${fn_param_modelRun_std}_hot_restart

  # files for ihot=2:
  mv outputs/mirror.out outputs/mirror.out_cold_restart
  touch outputs/mirror.out
  touch outputs/flux.out

  if [[ ! -f "outputs/staout_1" ]]; then
     for i in {1,2,3,4,5,6,7,8,9}; do
        touch outputs/staout_${i}
     done
  fi
 
fi


# -------------------------------------> merge hotstart files

if [[ ${time_sec_merge_hotstart} -eq 0 ]]; 
then	
   # cold restart file
   fn_restart_rerun=${COMOUTrerun}/${RUN}.${cycle}.restart.nc

   if [[ $(find ${fn_restart_rerun} -type f -size  +20G 2>/dev/null) ]]; then
     msg="restart.nc:  ${fn_restart_rerun}"
     ln -sf  ${fn_restart_rerun} ${DATA}/hotstart.nc
     # cpreq -pf ${fn_restart_rerun} ${DATA}/hotstart.nc
    
     list_fn_avail_input_forcing+=(" \n " $fn_restart_rerun)
     msg="restart.nc=${fn_restart_rerun}"

  else 
    fn_restart_hotstart="${fn_restart_rerun}"
    FLAG_all_exist_model_input_files=0
    list_fn_missed_input_forcing+=(" \n " ${fn_restart_rerun})

    echo -e "\n ${fn_restart_rerun}/hotstart file is not found in ${COMOUTrerun}"
    msg="\n WARNING: None existing: ${COMOUTrerun} - WARNING"
  fi
  
   msg="\n To use the cold restart nc"   
   echo -e  $msg; echo $msg >> $pgmout

else	
    # hot restart file
    cd ${DATA}/outputs/

    #idx_time_step_merge_hotstart=576
    fn_merged_hotstart_ftn=hotstart_it\=${idx_time_step_merge_hotstart}.nc
    fn_hotstart_stofs3d_merged_std=${RUN}.${cycle}.restart.nc

    msg=`echo Begin to run ${EXECstofs3d}/stofs_3d_atl_combine_hotstart -i  ${idx_time_step_merge_hotstart}`
    echo $msg; echo $msg >> $pgmout

    ${EXECstofs3d}/stofs_3d_atl_combine_hotstart  -i  ${idx_time_step_merge_hotstart}

    export err=$?
    pgm=${EXECstofs3d}/stofs_3d_atl_combine_hotstart

    if [ $err -eq 0 ]; then
       msg=`echo $pgm  completed normally`
       echo $msg; echo $msg >> $pgmout

       # fn_merged_hotstart_ftn=hotstart_it\=${idx_time_step_merge_hotstart}
       if [ -s ${fn_merged_hotstart_ftn} ]; then
          msg=`echo ${fn_merged_hotstart_ftn} has been created at; date`;
          echo $msg; echo $msg >> $pgmout

          cpreq -pf ${fn_merged_hotstart_ftn}  ${COMOUT}/rerun/${fn_hotstart_stofs3d_merged_std}_hot_restart

	  cd ${DATA}; 
          mv hotstart.nc hotstart.nc_cold_restart 2> tmp_rename_cold_restart_file
          ln -sf ${COMOUT}/rerun/${fn_hotstart_stofs3d_merged_std}_hot_restart hotstart.nc

       else
         msg=`echo ${fn_merged_hotstart_ftn}} was not created`
         echo $msg; echo $msg >> $pgmout
       fi

    else
       msg=`echo $pgm did not complete normally`
       echo $msg; echo $msg >> $pgmout
    fi

fi



