#!/bin/bash

#################################################################################################################
#  Name: exstofs_3d_atl_watchdog.sh                                                                             #
#  This script is to archive history nc files & to create global domain hotrestart 12-hrly files (to place in   #
#      dir_COM_hotstart=${COMOUT}/outputs_hotstart                                                              #
#      dir_COM_2d3d_sta=${COMOUT}/outputs_2d3d_sta                                                              #
#                                                                                                               #
#      place the _288 in COMOUT/rerun                                                                           #
#         - to do: rm merge to form hotstart from (1) post_proc_2.sh & (2) prep-hot start.sh                    #
#                                                                                                               #
#                                                                                                               #
#  create the global domain hotstart nc, and to archive it in com/rerun as follows:                             #
#    (1) rename the original stofs_3d_atl.t12z.hotstart.stofs3d.nc to stofs_3d_atl.t12z.hotstart.stofs3d.v0.nc  #
#    (2) save the newly created file as stofs_3d_atl.t12z.hotstart.stofs3d.nc                                   #
#                                                                                                               #
#  Remarks:                                                                                                     #
#                                                                                           September 2025      #
#################################################################################################################

   seton='-xa'
   # setoff='+xa'
   set $seton

# ----------------------->
  fn_this_script=exstofs_3d_atl_watchdog.sh

  msg="${fn_this_script}.sh  started"
  echo "$msg"
  postmsg  "$msg"

  pgmout=${fn_this_script}.$$


# -----------------------> check for available hotstart_x.nc
  # NCPU_PBS==4320; minus N_scribe=6, hence, 4316;
  # note: count (0, ..., 4316-1)
  # CPU_PBS_hot_restart=5994

  sz_cr_ht_subdmn_MB=100000    # bytes

  # list_steps_OI=(288 576 864 1152 1440 1728 2016 2304 2592 2880)
  # list_steps_OI=(2880 2592 2304 2016 1728 1440 1152 864 576 288)
  # dt_timestep=150


# -----------------------> COMOUT dir  
    dir_watchdog_COMOUT=${COMOUT}/outputs_watchdog
    echo "exstofs_3d_atl_watchdog.sh: dir_watchdog_COMOUT=${dir_watchdog_COMOUT}"
    mkdir -p ${dir_watchdog_COMOUT}
  
   
# -----------------------> Working dir
   mkdir -p ${DATA}/outputs
   cd ${DATA};

   echo "Current dir=`pwd`"; echo

     
# -----------------------> check upper level ln -s dir
   fn_dir_NF_run_outputs=${COMOUT}/rerun/file_one_line_dir_NF_run_outputs


if [ 1 -eq 1 ]; then

   time_idle_sec=180 	

   let diff_cr_sec=${time_idle_sec}+60

   let diff_cr_min=${diff_cr_sec}/60

   flag_status_fn_dir_NF_run_outputs=0

    while [[ ${flag_status_fn_dir_NF_run_outputs} -eq 0 ]]; do

      if [ -f  ${fn_dir_NF_run_outputs} ]; then

         time_fn_dir_NF_run_outputs=$(stat -c %Y ${fn_dir_NF_run_outputs})
         echo $time_fn_dir_NF_run_outputs

         time_now_sec=$( printf "%(%s)T\n" -1)
         diff_time_now_fn_dirName=$(( time_now_sec - time_fn_dir_NF_run_outputs ))
	 
	 let diff_time_now_fn_dirName_min=$diff_time_now_fn_dirName/60
	 echo "diff_time_now_fn_dirName (min)=$diff_time_now_fn_dirName_min (vs. diff_cr_min=${diff_cr_min})"

         #diff_cr_sec=600  # 5 min
         if [ ${diff_time_now_fn_dirName} -le  $diff_cr_sec ]; then
            flag_status_fn_dir_NF_run_outputs=1
         else
            flag_status_fn_dir_NF_run_outputs=0  
         fi

	 echo flag_status_fn_dir_NF_run_outputs=${flag_status_fn_dir_NF_run_outputs}

      else
         msg=" ../${fn_dir_NF_run_outputs} of this time NF submission has not been created yet";
         msg+="\n Wait another ${time_idle_sec}"
         echo -e ${msg}
      fi  # [ -f  ${fn_dir_NF_run_outputs} ];
      
      sleep ${time_idle_sec}

   done

   msg="\n  ${fn_dir_NF_run_outputs} has been created"
   #msg+="\n " ` echo ${fn_dir_NF_run_outputs}`
   postmsg "$msg"
fi

   sleep 10


   pid_jobs_NowForeCast=`head -n 1  ${fn_dir_NF_run_outputs} | awk -F' ' '{print $1}'`

   echo pid_jobs_NowForeCast=$pid_jobs_NowForeCast

   dir_nco_tmp_archive=${TMPPATH}_$pid_jobs_NowForeCast
       echo "exstofs_3d_atl_watchdog.sh: dir_nco_tmp_archive=${dir_nco_tmp_archive}"    
       mkdir -p ${dir_nco_tmp_archive}


   dir_NF_run_outputs=`head -n 1  ${fn_dir_NF_run_outputs} | awk -F' ' '{print $2}'`
      echo dir_NF_run_outputs=${dir_NF_run_outputs}
         

   cp -fp  ${fn_dir_NF_run_outputs}   ${dir_watchdog_COMOUT}/file_one_line_dir_NF_run_outputs_from_rerun
   cp -fp  ${fn_dir_NF_run_outputs}   ${dir_nco_tmp_archive}/file_one_line_dir_NF_run_outputs_from_rerun


  # ----------> Purpose: watchdog skip doing cp'ing the results of TIME_STEP_end_of_FCAST 
    TIME_STEP_end_of_FCAST=2880
    echo
    echo TIME_STEP_end_of_FCAST=$TIME_STEP_end_of_FCAST


  # ----------> check now/forecast progress; merge global hotstart; archive global history NC
   list_time_step=(288 576 864 1152 1440 1728 2016 2304 2592 2880)
   list_str_rnday=(05 10 15 20 25 30 35 40 45 50)
   list_cnt_no=($(seq 0 1 9))        
   
   TIME_STEP_nextDay_nowcast=576

   fn_mirror=${dir_NF_run_outputs}/mirror.out

   
     # -----> identify the FIRST TIME STEP of list_time_step in mirror.out of "this" run
     # check NFcast progress; hotrestart case: mirror.out TIME STEP does not begin from ==1


     str_egrep_TIME_STEP='(\s288;|\s576;|\s864;|\s1152;|\s1440;|\s1728;|\s2016;|\s2304;|\s2592;|\s2880;)'

     time_step_first_OI_mirror=${list_time_step[0]};
     while [[ 1 ]]; do
        
        if [ -f ${fn_mirror} ]; then 
           rtn_egrep_TIME_STEP=`egrep  ${str_egrep_TIME_STEP}  ${fn_mirror}`

	   if ! [ x"${rtn_egrep_TIME_STEP}"y = xy ]; then
              # time_step_first_OI_mirror=`echo $rtn_egrep_TIME_STEP | awk -F' TIME STEP= ' '{print $NF}' | awk -F';' '{print $1}'`;  # e.g. 288
              time_step_first_OI_mirror=`echo $rtn_egrep_TIME_STEP | awk -F'TIME STEP= ' '{print $2}' | awk -F';' '{print $1}'`;
              echo ${time_step_first_OI_mirror} 
   
              i_seq_cnt_base0=$(( $(printf "%s\n" "${list_time_step[@]}" | grep -m1 -Fxn "$time_step_first_OI_mirror" | cut -d: -f1) - 1 ));            
              
              echo time_step_first_OI_mirror=$time_step_first_OI_mirror
              echo i_seq_cnt_base0=$i_seq_cnt_base0
              echo list_time_step[${i_seq_cnt_base0}] = ${list_time_step[${i_seq_cnt_base0}]}
              echo   

       
              i_time_step=$time_step_first_OI_mirror;   
              flag_run_status=`egrep " ${i_time_step};"  ${fn_mirror} >/dev/null; echo $?`       
     
              echo "flag_run_status=${flag_run_status} (0:suceecess)"; echo

              if [[ ${flag_run_status} == 0 ]]; then
                 msg="Model run completed. Proceed to archive nc files ..."

                 sleep 60s

                 echo -e ${msg};  
                 echo -e  ${msg} >> $pgmout
                 break
        
              else
                 echo "Wait for TIME STEP in mirror: ${time_idle_sec} more seconds"; echo
                 sleep ${time_idle_sec}    # 1min=60s
                 # cnt=$(( ${cnt} + 1 ))

              fi

           else 
		echo "\n ${rtn_egrep_TIME_STEP}y=xy; rtn_egrep_TIME_STEP is empty string"   
 
           fi   # if [ -n "${rtn_egrep_TIME_STEP}}" ]; then           


        else    # if [ -f ${fn_mirror} ];
           echo "${fn_mirror} has not been generated: wait ${time_idle_sec} more seconds"
           sleep ${time_idle_sec}

        fi      # if [ -f ${fn_mirror} ];


     done # while [[ 1 ]]; do


   # 
   let n_rem_in_list=${#list_time_step[@]}-$i_seq_cnt_base0 
   rem_list_cnt_no=(${list_cnt_no[@]:i_seq_cnt_base0:n_rem_in_list}); # 0-based idx
     echo "rem_list_cnt_no= ${rem_list_cnt_no[@]}" 


   FLAG_status_merge_ftn=0  # =0: failed
   cnt=0
   for i_no in ${rem_list_cnt_no[@]}; do
     idx_arr=${i_no}
     i_time_step=${list_time_step[$idx_arr]}
 
     
     echo "for i_no=: ino= ${i_no}"
     echo "i_time_step=${list_time_step[$idx_arr]}" 

     # grep 'TIME STEP=' mirror.out | grep '2304;'
 
     # check NFcast progress
     while [[ 1 ]]; do
        #flag_run_status=`egrep '"TIME STEP=".*" ${i_time_step};"' ${fn_mirror} >/dev/null; echo $?`
        flag_run_status=`egrep " ${i_time_step};"  ${fn_mirror} >/dev/null; echo $?`       
     
        echo "flag_run_status=${flag_run_status} (0:suceecess)"; echo

        if [[ ${flag_run_status} == 0 ]]; then
          msg="Model run: TIME STEP=${i_time_step} has completed"
          echo -e ${msg};  
          echo -e  ${msg} >> $pgmout
          break

        else
          echo "Model run: TIME STEP=${i_time_step} yet finished: Wait for ${time_idle_sec} more seconds"; echo

          sleep ${time_idle_sec}    # 10min=600s

          cnt=$(( ${cnt} + 1 ))

	  echo "For TIME STEP=${i_time_step}: waiting time count=${cnt} (min)"; echo

        fi
    
     done # while [[ 1 ]]; do
     
      
      # archive local_to_global: Only need to do this for "Once"   
     

      postmsg "Begin watchdog copy: i_time_step=${i_time_step}"

  
      if [[ ${i_time_step} == ${list_time_step[${rem_list_cnt_no[0]}]} ]]; then
          echo i_time_step=${i_time_step}
	  echo "list_time_step[{rem_list_cnt_no[0]}]=${list_time_step[${rem_list_cnt_no[0]}]}"
          postmsg "cp local_to_global files"

          # rpreq -f ../${dir_upperLevel_outputs}/local_to_global_0*  ${dir_watchdog_COMOUT} 
          cpreq  -fp  ${dir_NF_run_outputs}/local_to_global_0*  ${dir_watchdog_COMOUT}
	  cpreq  -fp  ${dir_NF_run_outputs}/local_to_global_0*  ${dir_nco_tmp_archive}

      fi


         export err=$?
         pgm=${SCRstofs3d}/exstofs_3d_atl_watchdog.sh

         if [ $err -eq 0 ]; then

            echo; echo "Before comparing  ${i_time_step} -eq ${TIME_STEP_end_of_FCAST}"; echo;
            echo i_time_step=${i_time_step}
	    echo TIME_STEP_end_of_FCAST=${TIME_STEP_end_of_FCAST}
	    echo

            if [[ ${i_time_step} -eq ${TIME_STEP_end_of_FCAST} ]]; then
                 # Not to cpreq files if it is the final TIME STEP==2880
                 # This is handled in exstofs_3d_atl_now_forecast.sh
               
		 msg=" Model is running for the ${TIME_STEP_end_of_FCAST}; its reults are to be copied to COMOUT by now/forecast script after model run" 
                 msg="${msg}\n In exstofs_3d_atl_watchdog.sh: exstofs_3d_atl_now_forecast.sh completed. Now to quit watchdog job.\n"
		 echo -e ${msg}
                 postmsg "$jlogfile" "$msg"        


            else  

                # archive files
                 cd ${DATA}

                 sleep 10s

                 postmsg "cp /mirror.out"
		 cpreq -fp  ${dir_NF_run_outputs}/mirror.out   ${dir_watchdog_COMOUT}
                 cpreq -fp  ${dir_NF_run_outputs}/mirror.out   ${dir_nco_tmp_archive}


                 
		 postmsg "cp hotstart_xxx.nc"
		 cpreq -fp ${dir_NF_run_outputs}/hotstart_0*_${i_time_step}.nc  ${dir_watchdog_COMOUT}
		 cpreq -fp ${dir_NF_run_outputs}/hotstart_0*_${i_time_step}.nc  ${dir_nco_tmp_archive}


		 let i_no_history_nc=${i_no}+1

                 postmsg "cp global history nc: No. (${i_no_history_nc})"
		 
		 cpreq -fp  ${dir_NF_run_outputs}/{horizontalVelX,horizontalVelY,out2d,salinity,temperature,zCoordinates,verticalVelocity,diffusivity}_${i_no_history_nc}.nc ${dir_watchdog_COMOUT} 
                 cpreq -fp  ${dir_NF_run_outputs}/{horizontalVelX,horizontalVelY,out2d,salinity,temperature,zCoordinates,verticalVelocity,diffusivity}_${i_no_history_nc}.nc ${dir_nco_tmp_archive}


                 postmsg " cp staout_x"
		 
		 cpreq  -fp  ${dir_NF_run_outputs}/staout_*  ${dir_watchdog_COMOUT}
                 cpreq  -fp  ${dir_NF_run_outputs}/staout_*  ${dir_nco_tmp_archive}

     
                 msg="Done archiving files for TIME STEP=${i_time_step}"
		 echo $msg; echo $msg >> $pgmout

            fi  # if [[ ${i_time_step} -eq ${TIME_STEP_end_of_FCAST}; then


            FLAG_status_merge_ftn=1
            

	 else   # if [ $err -eq 0 ]
             msg=`echo $pgm did not complete normally`
             echo $msg; echo $msg >> $pgmout

	     # fatal error exit
	     err_chk

         fi

   
         postmsg "Done watchdog copy: i_time_step=${i_time_step}"

                                                                         
   done     # for i_time_step in ${ist_time_step[@]}; do 


   
   msg="$pgm completed normally"
   echo $msg; echo $msg >> $pgmout

   echo 
   echo



