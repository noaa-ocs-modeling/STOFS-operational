#!/bin/bash

#################################################################################################################
#  Name: exstofs_3d_pac_create_hot_restart.sh                                                                   #
#  This script is to create the global domain hotstart nc, and to archive it in com/rerun as follows:           #
#    (1) rename the original stofs_3d_pac.t12z.hotstart.stofs3d.nc to stofs_3d_pac.t12z.hotstart.stofs3d.v0.nc  #
#    (2) save the newly created file as stofs_3d_pac.t12z.hotstart.stofs3d.nc                                   # 
#                                                                                                               #
#  Remarks:                                                                                                     #
#                                                                                                 May 2023      #
#################################################################################################################

  seton='-xa'
#  setoff='+xa'

## set $seton

# ----------------------->
  fn_this_script=exstofs_3d_pac_create_hot_restart.sh

  msg="${fn_this_script}.sh  started"
  echo "$msg"
  postmsg  "$msg"

  pgmout=${fn_this_script}.$$


# -----------------------> check for available hotstart_x.nc

  mkdir -p ${DATA}/outputs
  cd ${DATA}; 

  echo "Current dir=`pwd`"; echo


  # NCPU_PBS==4320; minus N_scribe=6, hence, 4316; 
  # note: count (0, ..., 4316-1)
  #NCPU_PBS_hot_restart=4314

  let n_scribes=8
  let NCPU_PBS_hot_restart=${NCPU_PBS}-${n_scribes}
  echo "NCPU_PBS_hot_restart=${NCPU_PBS_hot_restart}"

  sz_cr_ht_subdmn_MB=100000    # bytes

  # list_steps_OI=(288 576 864 1152 1440 1728 2016 2304 2592 2880)
  # list_steps_OI=(2880 2592 2304 2016 1728 1440 1152 864 576 288) 
  ### list_steps_OI=(2592 2304 2016 1728 1440 1152 864 576 288)
  ### list_steps_OI=(2880 2400 1920 1440 960 480) this is pacific with 90s dt_timestep
  list_steps_OI=(2400 1920 1440 960 480)

  ### dt_timestep=150
  dt_timestep=90

  # str_ht_fn_prefix=
  flag_hotstart_found=0
  time_sec_merge_hotstart=0
  idx_time_step_merge_hotstart=0

  rm -f  tmp_chk_hotstart_file


  # (2025/01/30)
    dir_nco_tmp_archive=${COMOUT}/outputs_watchdog
  
#    fn_dir_NF_run_outputs_full_path=${COMOUT}/rerun/file_one_line_dir_NF_run_outputs
#    pid_jobs_NowForeCast=`head -n 1  ${fn_dir_NF_run_outputs_full_path} | awk -F' ' '{print $1}'`
#    dir_nco_tmp_archive=${TMPPATH}_$pid_jobs_NowForeCast


     echo
     echo "In exstofs_3d_pac_hot_restart_prep.sh: `pwd`: dir_nco_tmp_archive=${dir_nco_tmp_archive}"
     echo  
  

#   mkdir -p ${dir_nco_tmp_archive}


    # (2024/4)
    #dir_COM_hotstart=${COMOUT}/outputs_hotstart
    #dir_COM_2d3d_sta=${COMOUT}/outputs_2d3d_sta

    #  mkdir -p ${dir_COM_hotstart}
    #  mkdir -p ${dir_COM_2d3d_sta}
    #  ln -sf ${dir_COM_hotstart} .
    #  ln -sf ${dir_COM_2d3d_sta} .

 
# 2025/1/30 
if [ 0 -eq 1 ]; then
   echo; echo "Before cp dir_nco_tmp_archive: `date`"   
   if [ -d ${dir_nco_tmp_archive} ]; then
       echo; echo dir_nco_tmp_archive=${dir_nco_tmp_archive} exists; echo
      cp -f ${dir_nco_tmp_archive}/*  ${DATA}/outputs
   fi
 
   echo; echo "Done cp dir_nco_tmp_archive: `date`"; echo

fi

#    if [ -d ${dir_COM_hotstart} ]; then
#       echo; echo dir_COM_hotstart=${dir_COM_hotstart} exists; echo
#       cp -f ${dir_COM_hotstart}/*  ${DATA}/outputs	    
#    fi

#    if [ -d ${dir_COM_2d3d_sta} ]; then
#       echo; echo dir_COM_2d3d_sta=${dir_COM_2d3d_sta} exists; echo
#       cp -f ${dir_COM_2d3d_sta}/*  ${DATA}/outputs	    
#    fi


  cd ${dir_nco_tmp_archive}

  for k_OI in ${list_steps_OI[@]}
  do


     # list_fn_ht_OI=`ls ${DATA}/outputs/hotstart_0?????_${k_OI}.nc` 
     #list_fn_ht_OI=`ls ./outputs/hotstart_0?????_${k_OI}.nc 2> tmp_chk_hotstart_file`
      list_fn_ht_OI=`ls hotstart_0?????_${k_OI}.nc 2> tmp_chk_hotstart_file`

     echo "checking hotstart file of step=${k_OI}"

     # N_file_hotstart_default=`ls -lr  ./outputs/hotstart_0?????_*${k_OI}.nc 2>> tmp_chk_hotstart_file | wc -l`   
     N_file_hotstart_default=`ls -lr  ./hotstart_0?????_*${k_OI}.nc 2>> tmp_chk_hotstart_file | wc -l`    
 
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

  fn_src_nml_rerun_ihot1=${COMOUTrerun}/${RUN}.${cycle}.param.nml
  mv  ${fn_src_nml_rerun_ihot1}  ${fn_src_nml_rerun_ihot1}_backup_ihot1

  cpreq  -f  ${fn_src_nml_rerun_ihot1}_backup_ihot1   param.nml_ihot1_tmp  
    rm -f param.nml
    cat param.nml_ihot1_tmp | sed "s/ihot = 1/ihot = 2/" > param.nml

  fn_param_modelRun_std=${RUN}.${cycle}.param.nml
    cpreq -f param.nml ${COMOUT}/rerun/${fn_param_modelRun_std}
    cpreq -f param.nml ${COMOUT}/rerun/${fn_param_modelRun_std}_backup_ihot2

  # files for ihot=2:
  # post-crash run started 'new' dir: mv outputs/mirror.out outputs/mirror.out_cold_restart
    touch outputs/mirror.out
    touch outputs/flux.out

  if [[ ! -f "outputs/staout_1" ]]; then
     for i in {1,2,3,4,5,6,7,8,9}; do
        touch outputs/staout_${i}
     done
  fi
 
fi


# post-crash run started 'new' dir: mv outputs/mirror.out outputs/mirror.out_cold_restart
if [ 0 -eq 1 ]; then
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
   # use rerun/_restart.nc (at beginning time of nowcast)
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
  
   msg="\n To use the rerun/_restart.nc at beginning time of nowcast"   
   echo -e  $msg; echo $msg >> $pgmout


else	

    # Generate new global domain _restart.nc: to continue the unfinished run of the current cycle
    mkdir -p ${DATA}/outputs/
    cd ${DATA}/outputs/

    # cp local_global & hotstart nc to $DATA/outputs/
    touch ../log_cp_watchdog_hot_local2glb_timing.txt
    echo; echo "Before cp dir_nco_tmp_archive: `date`" > ../log_cp_watchdog_hot_local2glb_timing.txt

    
    # Find pid of the crashed run and get its archival location:
    # nco TMPPATH archive of the previous crashed run; the rerun/
    #dir_nco_tmp_archive=${COMOUT}/outputs_watchdog
    ##########     dir_nco_tmp_archive_prev_NF_run=
    



    if [ -d ${dir_nco_tmp_archive} ]; then
         echo; echo dir_nco_tmp_archive=${dir_nco_tmp_archive} exists; echo
         cp -fp  ${dir_nco_tmp_archive}/local_to_global_*  ${DATA}/outputs
         cp -fp  ${dir_nco_tmp_archive}/hotstart_*_${idx_time_step_merge_hotstart}.nc  ${DATA}/outputs
         cp -fp  ${dir_nco_tmp_archive}/staout* ${DATA}/outputs

    fi

    echo; echo "Done cp dir_nco_tmp_archive: `date`"; echo
    echo "Done cp dir_nco_tmp_archive: `date`" >> ../log_cp_watchdog_hot_local2glb_timing.txt


    #idx_time_step_merge_hotstart=576
    fn_merged_hotstart_ftn=hotstart_it\=${idx_time_step_merge_hotstart}.nc
    fn_hotstart_stofs3d_merged_std=${RUN}.${cycle}.restart.nc

    msg=`echo Begin to run ${EXECstofs3d}/stofs_3d_pac_combine_hotstart -i  ${idx_time_step_merge_hotstart}`
    echo $msg; echo $msg >> $pgmout

    ${EXECstofs3d}/stofs_3d_pac_combine_hotstart  -i  ${idx_time_step_merge_hotstart}

    export err=$?
    pgm=${EXECstofs3d}/stofs_3d_pac_combine_hotstart

    if [ $err -eq 0 ]; then
       msg=`echo $pgm  completed normally`
       echo $msg; echo $msg >> $pgmout

       # fn_merged_hotstart_ftn=hotstart_it\=${idx_time_step_merge_hotstart}
       if [ -s ${fn_merged_hotstart_ftn} ]; then
          msg="echo ${fn_merged_hotstart_ftn} has been created";
          echo $msg; echo $msg >> $pgmout


          mv ${COMOUT}/rerun/${fn_hotstart_stofs3d_merged_std} ${COMOUT}/rerun/${fn_hotstart_stofs3d_merged_std}_ihot1
          cpreq -pf ${fn_merged_hotstart_ftn}  ${COMOUT}/rerun/${fn_hotstart_stofs3d_merged_std}
          ln -sf  ${COMOUT}/rerun/${fn_hotstart_stofs3d_merged_std}  ${COMOUT}/rerun/${fn_hotstart_stofs3d_merged_std}_back_ihot2

	  cd ${DATA}; 
          rm -f mv hotstart.nc 
          ln -sf ${COMOUT}/rerun/${fn_hotstart_stofs3d_merged_std} hotstart.nc

       else
         msg=`echo ${fn_merged_hotstart_ftn}} was not created`
         echo $msg; echo $msg >> $pgmout
       fi

    else
       msg=`echo $pgm did not complete normally`
       echo $msg; echo $msg >> $pgmout
    fi

fi





