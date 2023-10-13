#!/bin/bash 


################################################################################
#  Name: stofs_3d_atl_create_river_forcing_nwm.sh                              #
#  This script reads the NWM river forecast data to create the STOFS_3D_ATL    #
#  river forcing files, stofs_3d_atl.t12z.{msource, vsink,vsource}.th, that    #
#  are needed for the nowcast and forecast simulations.                        #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2022   #
################################################################################

# ---------------------------> Begin ...
# set -x

echo 'The script stofs_3d_atl_create_river_forcing_nwm.sh started ' 


# ---------------------------> directory/file names
  dir_wk=${DATA_prep_nwm}


  echo dir_wk = ${DATA_prep_nwm}
  sleep 2


  mkdir -p $dir_wk
  cd $dir_wk
  rm -rf ${dir_wk}/*

  mkdir -p ${COMOUTrerun}

  pgmout=pgmout_nwm.$$
  rm -f $pgmout


# ---------------------------> Global Variables

  # fn_py_create_river_th=${PYstofs3d}/river_th_extract2asci.py
  
  # v6.1 Linlin
  fn_py_create_river_th=${PYstofs3d}/gen_sourcesink.py


  # 96hr:: attn!
  N_list_target=121   # 121*3600/86400=1+4.0417
  N_list_min=97       # 97=121-24 (excluded lines 1-4 if *.th from yesterday'c cycle is used)  


# cp files to work dir
 fn_src_sink_before_reloc=stofs_3d_atl_river_source_sink.in.before_relocate
 fn_src_conus_json=stofs_3d_atl_river_sources_conus.json
 fn_src_scale=stofs_3d_atl_river_source_scale.txt
 fn_sink_conus_json=stofs_3d_atl_river_sinks_conus.json
 fn_reloc_map=stofs_3d_atl_river_relocate_map.txt
 fn_src_sink_in=stofs_3d_atl_river_source_sink.in
 
 #fn_msource_th=${FIXstofs3d}/stofs_3d_atl_river_msource.th
 #fn_vsink_th=${FIXstofs3d}/stofs_3d_atl_river_vsink.th 

 cp -f  ${PYstofs3d}/relocate_source_feeder_lean.py  relocate_source_feeder_lean.py
 cp -f  ${FIXstofs3d}/${fn_src_sink_before_reloc} source_sink.in.before_relocate
 cp -f  ${FIXstofs3d}/${fn_src_conus_json} sources_conus.json
 cp -f  ${FIXstofs3d}/${fn_src_scale} source_scale.txt
 cp -f  ${FIXstofs3d}/${fn_sink_conus_json} sinks_conus.json
 cp -f  ${FIXstofs3d}/${fn_reloc_map} relocate_map.txt
 cp -f  ${FIXstofs3d}/${fn_src_sink_in} source_sink.in
 # cp -f  ${FIXstofs3d}/${fn_msource_th} msource.th
 # cp -f  ${FIXstofs3d}/${fn_vsink_th} vsink.th


# ---------------------------> Dates
   yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
   yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}


# ------> nowcast/forecast cycle(s) & hr
#   current_CC=$CC_CURRENT


# ---------------------------> default: create list of nwm files
 list_fn_yest_t06z=`ls ${COMINnwm}/nwm.${yyyymmdd_prev}/medium_range_mem1/nwm.t06z.medium_range.channel_rt_1.f006.conus.nc`
 list_fn_yest_t12z=`ls ${COMINnwm}/nwm.${yyyymmdd_prev}/medium_range_mem1/nwm.t12z.medium_range.channel_rt_1.f00{1,2,3,4,5,6}.conus.nc`
 list_fn_yest_t18z=`ls ${COMINnwm}/nwm.${yyyymmdd_prev}/medium_range_mem1/nwm.t18z.medium_range.channel_rt_1.f00{1,2,3,4,5,6}.conus.nc`
 list_fn_today_t00z=`ls ${COMINnwm}/nwm.${yyyymmdd_today}/medium_range_mem1/nwm.t00z.medium_range.channel_rt_1.f00{1,2,3,4,5,6}.conus.nc`
 
 # 96hr:: list_fn_today_t06z=`ls ${COMINnwm}/nwm.${yyyymmdd_today}/medium_range_mem1/nwm.t06z.medium_range.channel_rt_1.f0{0,1,2,3,4,5}?.conus.nc`
 list_fn_today_t06z=`ls ${COMINnwm}/nwm.${yyyymmdd_today}/medium_range_mem1/nwm.t06z.medium_range.channel_rt_1.f0{0,1,2,3,4,5,6,7,8,9}?.conus.nc`
 list_fn_today_t06z_2=`ls ${COMINnwm}/nwm.${yyyymmdd_today}/medium_range_mem1/nwm.t06z.medium_range.channel_rt_1.f1{0,1}?.conus.nc` 

# LIST_fn_all=($list_fn_yest_t06z $list_fn_yest_t12z $list_fn_yest_t18z $list_fn_today_t00z $list_fn_today_t06z)  
 
 LIST_fn_all_1="${list_fn_yest_t06z} "
 LIST_fn_all_1+="${list_fn_yest_t12z[@]} "
 LIST_fn_all_1+="${list_fn_yest_t18z[@]} "
 LIST_fn_all_1+="${list_fn_today_t00z[@]} "
 LIST_fn_all_1+="${list_fn_today_t06z[@]} "
 LIST_fn_all_1+="${list_fn_today_t06z_2[@]}"

 #LIST_fn_all_1=(${LIST_fn_all_1[@]})

  #echo ${#LIST_fn_all_1[@]}

  #A=${LIST_fn_all_1[@]}; for a in ${A[@]}; do echo $a; done
  
  #echo "Raw list: LIST_fn_all_1"
  #for a in ${LIST_fn_all_1[@]}; then echo $a; done


# ---------------------------> backup: create list of nwm files
 list_fn_yest_t06z=`ls ${COMINnwm}/nwm.${yyyymmdd_prev}/medium_range_mem1/nwm.t06z.medium_range.channel_rt_1.f006.conus.nc`

 # 96hr:: list_fn_yest_t12z=`ls ${COMINnwm}/nwm.${yyyymmdd_prev}/medium_range_mem1/nwm.t12z.medium_range.channel_rt_1.f0{0,1,2,3,4,5,6,7}?.conus.nc`
 list_fn_yest_t12z=`ls ${COMINnwm}/nwm.${yyyymmdd_prev}/medium_range_mem1/nwm.t12z.medium_range.channel_rt_1.f0{0,1,2,3,4,5,6,7,8,9}?.conus.nc`
 #list_fn_yest_t12z_2=`ls ${COMINnwm}/nwm.${yyyymmdd_prev}/medium_range_mem1/nwm.t12z.medium_range.channel_rt_1.f1{0,1}?.conus.nc`
 list_fn_yest_t12z_2=`ls ${COMINnwm}/nwm.${yyyymmdd_prev}/medium_range_mem1/nwm.t12z.medium_range.channel_rt_1.f1{0,1,2}?.conus.nc`

 LIST_fn_all_2="${list_fn_yest_t06z} "
 LIST_fn_all_2+="${list_fn_yest_t12z[@]} "
 # 96 hr
 LIST_fn_all_2+="${list_fn_yest_t12z_2[@]}"

  echo; echo "LIST_fn_all_1:"
  A=$LIST_fn_all_1; for a in ${A[@]}; do echo $a; done
  echo; echo "LIST_fn_all_2:"
  A=$LIST_fn_all_2; for a in ${A[@]}; do echo $a; done
  echo; echo;

# check file sizes (e.g., nwm_1.nc: 14368257)
 FILESIZE=10000000

list_route_no=(1 2) 
for flag_route_no in ${list_route_no[@]}; do

 echo $flag_route_no
 if [[ $flag_route_no == 1 ]]; then
    LIST_fn_all=$LIST_fn_all_1
 else
    LIST_fn_all=$LIST_fn_all_2 
 fi	 

 echo "flag_route_no = $flag_route_no"; #sleep 1

 LIST_fn_final=''
 for fn_nwm_k_sz in $LIST_fn_all
  do
   echo "Processing:: " $fn_nwm_k_sz

   if [ -s $fn_nwm_k_sz ]; then
      filesize=`wc -c $fn_nwm_k_sz | awk '{print $1}' `

      if [ $filesize -ge $FILESIZE ];
      then
         LIST_fn_final+="${fn_nwm_k_sz} "
      else
         echo "WARNING: " $fn_nwm_k_sz ": filesize $filesize less than $FILESIZE"
         echo "WARNING: " $fn_nwm_k_sz ": filesize $filesize less than $FILESIZE"  >> $jlogfile
      fi

   else
      echo "WARNING: "  $fn_nwm_k_sz " does not exist"
      echo "WARNING: "  $fn_nwm_k_sz " does not exist"  >> $jlogfile
   fi
 done

 if [[ $flag_route_no == 1 ]]; then
    LIST_fn_final_1=$LIST_fn_final
 else
    LIST_fn_final_2=$LIST_fn_final
 fi
done # for flag_route_no in 

 #A=$LIST_fn_final_1; for a in ${A[@]}; do echo $a; done
 # A=$LIST_fn_final_2; for a in ${A[@]}; do echo $a; done

 
 N_list_1=${#LIST_fn_final_1[@]}
 N_list_2=${#LIST_fn_final_2[@]}

 echo; echo N_list_1=$N_list_1; echo
       echo N_list_2=$N_list_2; echo

 A1=($LIST_fn_final_1)
 B2=($LIST_fn_final_2)

  N_list_1=${#A1[@]}; echo; echo "N_list_1 = $N_list_1"; echo
  N_list_2=${#B2[@]}; echo; echo "N_list_2 = $N_list_2"; echo;

  #N_list_target=73

# if [[ ${N_list_1} > 0 ]] && [[ ${N_list_1} < ${N_list_target} ]] && [[ ${N_list_2} > ${N_list_1} ]]; then 
# if [[ ${N_list_1} -gt 0 ]] && [[ ${N_list_1} -lt ${N_list_target} ]] && [[ ${N_list_2} -gt ${N_list_1} ]]; then
if [[ ${N_list_1} -gt 1 ]]; then

  LIST_fn_final=${A1[@]}
	
  if [[ ${N_list_1} -lt ${N_list_target} ]] && [[ ${N_list_2} -gt ${N_list_1} ]]; then	
    echo "N_list_1 = $N_list_1"; echo "N_list_2 = $N_list_2"
    
    n_diff_1_2=$((${N_list_2}-${N_list_1}))
    
    # error   LIST_fn_final=${A1[@]} ${B2[@]:$N_list_1:$n_diff_1_2}
    LIST_fn_final=(${A1[@]} ${B2[@]:$N_list_1:$n_diff_1_2}) 

    echo "combined: LIST_fn_1 & 2: "
    for a in ${LIST_fn_final[@]}; do echo $a; done  
 
  else  
    LIST_fn_final=${A1[@]}
    echo "LIST_fn_final_1 is used"
  fi

elif [[ ${N_list_2} -gt 1 ]]; then
  LIST_fn_final=${B2[@]}
  echo "LIST_fn_final_2 is used"

else
  LIST_fn_final=()
  echo "Neither of LIST_fn_final_{1,2} is used"  

fi	

 # ---------------------> ln, process data
 rm -f nwm_???.nc

 i_cnt_nwm=0
 i_cnt_list_fn=0
  for fn_link_curr_f001_end in ${LIST_fn_final[@]};
  do

   let i_cnt_nwm=i_cnt_nwm+1
   i_cnt_nwm_3digits=`printf "%03d" $i_cnt_nwm`

   let i_cnt_list_fn=i_cnt_list_fn+1 
 
   echo "ln -sf " $fn_link_curr_f001_end nwm_${i_cnt_nwm_3digits}.conus.nc 

   ln -sf $fn_link_curr_f001_end nwm_${i_cnt_nwm_3digits}.conus.nc

  done


# ------------------> create river vsource.th 
# vsink.th & msource.th are static files for v.6.1 grid

  #str_yyyy_mm_dd_hr=`date -d ${PDYHH_NCAST_BEGIN:0:8}  +%Y-%m-%d`-${cyc}
   str_yyyy_mm_dd_hr=${PDYHH_NCAST_BEGIN:0:4}-${PDYHH_NCAST_BEGIN:4:2}-${PDYHH_NCAST_BEGIN:6:2}-${cyc}

  echo 'Beginning date of river data (th) (yyyy_mm_dd_hr) = '  $str_yyyy_mm_dd_hr


  list_nwm_files=`ls nwm_???.*.nc`
  if [ ! -z "${list_nwm_files}" ]; then
     python $fn_py_create_river_th  $str_yyyy_mm_dd_hr   >> $pgmout 2> errfile

     export err=$?; #err_chk
     pgm=$fn_py_create_river
     if [ $err -eq 0 ]; then
        msg=`echo python  completed normally`
        echo $msg
        echo $msg >> $pgmout
     else
        msg=`echo python did not complete normally`
        echo $msg
        echo $msg >> $pgmout
     fi
  else
    msg="Attention: nwm_xxx.nc not existed;"'\n'"$pgm did not complete normally"
    echo -e $msg
    echo -e $msg >> $pgmout
  fi
  

# begin QC .th ---
if [ 1 -eq 1 ]; then

# ------------------> QC & archive/rename files
 # cp -f  ${FIXstofs3d}/${fn_msource_th} msource.th
 # cp -f  ${FIXstofs3d}/${fn_vsink_th} vsink.th


# (1) msource.th
  fn_msource_th_std=${RUN}.${cycle}.msource.th 
  fn_msource_th=${FIXstofs3d}/stofs_3d_atl_river_msource.th

  FILESIZE_msource_th=1000
  if [ -f $fn_msource_th ]; then
     sz_test=`wc -c $fn_msource_th | awk '{print $1}'`
     if [ $sz_test -ge $FILESIZE_msource_th ]; then
        cpreq  -pf ${fn_msource_th}           ${COMOUTrerun}/${fn_msource_th_std}
     fi
  else
    echo " river forcing  file not created or file size is too small: " $fn_msource_th
    echo " river forcing  file not created or file size is too small: " $fn_msource_th  >> $jlogfile
  fi
  export err=$?; #err_chk


# (2) vsink.th
  fn_vsink_th_std=${RUN}.${cycle}.vsink.th
  fn_vsink_th=${FIXstofs3d}/stofs_3d_atl_river_vsink.th

  FILESIZE_vsink_th=1000
  if [ -f $fn_vsink_th ]; then
     sz_test=`wc -c $fn_vsink_th | awk '{print $1}'`
     if [ $sz_test -ge $FILESIZE_vsink_th ]; then
        cpreq  -pf ${fn_vsink_th}           ${COMOUTrerun}/${fn_vsink_th_std}
     fi
  else
    echo " river forcing  file not created or file size is too small: " $fn_vsink_th
    echo " river forcing  file not created or file size is too small: " $fn_vsink_th  >> $jlogfile
  fi
  export err=$?; #err_chk


# (3) vsource.th
# list_riv_src_sink=(vsource vsink)
  list_riv_src_sink=(vsource)

for str_fn_river_th in ${list_riv_src_sink[@]}; do

   fn_river_th_std=${RUN}.${cycle}.${str_fn_river_th}.th

   fn_river_th=${str_fn_river_th}.th
   fn_riv_wk=${fn_river_th}.th_tmp
   fn_river_th_ori=${fn_river_th}.th_ori

   echo " QA/QC: fn_river_th = ${fn_river_th}"

 #N_rows_riv_th_ori=`cat ${fn_river_th} | wc -l`  
 #if [[ -f ${fn_river_th} ]] && [[ `cat ${fn_river_th} | wc -l` -ge 2 ]]; then
 #if [[ -f ${fn_river_th} ]] && [[ ${N_rows_riv_th_ori} -ge 2 ]]; then
 
 if [[ -f ${fn_river_th} ]]; then
   N_rows_riv_th_ori=`cat ${fn_river_th} | wc -l`	 
 else
   N_rows_riv_th_ori=$((0))
 fi 	 

 echo
 echo N_rows_riv_th_ori=${N_rows_riv_th_ori}
 echo N_list_min=${N_list_min}
 echo 

 if [[ ${N_rows_riv_th_ori} -ge ${N_list_min} ]]; then

   #cp -f ${fn_river_th} ${fn_river_th_ori}
   #cp -f ${fn_river_th} ${fn_riv_wk}

   #N_rows_riv_th_ori=`cat ${fn_river_th} | wc -l`

   if [[ ${N_rows_riv_th_ori} -lt ${N_list_target} ]]; then

      cp -f ${fn_river_th} ${fn_river_th_ori}
      cp -f ${fn_river_th} ${fn_riv_wk}

      line_end_ori=`tail -n 1  ${fn_river_th}`; #echo ${line_end_ori}

      for ((k=1; k<=$((N_list_target-N_rows_riv_th_ori+1)); k++))
      do
             echo ${line_end_ori} >> ${fn_riv_wk}
      done
        msg_tmp=" Attention: ${fn_river_th}, N_rows_ori=${N_rows_riv_th_ori}, appended ${k} lines"
        echo ${msg_tmp};

        mv ${fn_riv_wk} ${fn_river_th}
        # (2023/3/31) cpreq -pf ${fn_river_th} ${COMOUTrerun}/${fn_river_th_std}

    else
        # (2023/3/31) cpreq -pf ${fn_river_th} ${COMOUTrerun}/${fn_river_th_std}
    	msg_tmp="python output - OK: ${fn_river_th}, N_rows_ori=${N_rows_riv_th_ori}"
	#msg_tmp="${msg_tmp}\n File archived: cpreq -pf ${fn_river_th} ${COMOUTrerun}/${fn_river_th_std}"
        #echo -e ${msg_tmp};
    fi


    # (2023/3/31) cpreq -pf ${fn_river_th} ${COMOUTrerun}/${fn_river_th_std}
      fn_tmp1=${fn_river_th}_tmp_1
      fn_tmp2=${fn_river_th}_tmp_2    
      fn_tmp3=${fn_river_th}_tmp_3

      rm -f $fn_tmp1; rm -f $fn_tmp2; rm -f $fn_tmp3
    
      cp -f ${fn_river_th}  ${fn_tmp1}
      echo; echo fn_tmp1=`ls -l  ${fn_tmp1}`
      echo; echo  fn_river_th=`ls -l ${fn_river_th}`

      mv ${fn_river_th}  ${fn_tmp2}
 
      line_1_ori_2_end=`head -n 1 ${fn_tmp2} | cut -d' ' -f 2-`
      line_2_ori_2_end=`head -n 2 ${fn_tmp2} | tail -n 1 | cut -d' ' -f 2-`

      line_1_new="0 ${line_1_ori_2_end}"
      line_2_new="3600 ${line_2_ori_2_end}"

      tail -n +3 ${fn_tmp2} > ${fn_tmp3}

      rm -f ${fn_river_th_std}
      { echo  ${line_1_new}; echo  ${line_2_new}; cat ${fn_tmp3}; } > ${fn_river_th_std}

      cpreq -pf ${fn_river_th_std} ${COMOUTrerun}/${fn_river_th_std}
 
    msg_tmp="${msg_tmp}\n File archived: cpreq -pf ${fn_river_th} ${COMOUTrerun}/${fn_river_th_std}"
    echo -e ${msg_tmp};


 else # backup2; if [[ ${N_rows_riv_th_ori} -ge ${N_list_min} ]]
    msg="Backup2 river data were used: fn_river_th=${fn_river_th}"
    echo -e ${msg}

    fn_tmp1=${fn_river_th_std}_tmp_1
    fn_tmp2=${fn_river_th_std}_tmp_2
    fn_tmp3=${fn_river_th_std}_tmp_3
    rm -f $fn_tmp1; rm -f $fn_tmp2; rm -f $fn_tmp3 

    # head -n 75 stofs3d.t12z.vsource.th | awk '{print $1,$2,$3,$4,$5}' > tmp_6col; fn_river_th_std=tmp_6col; cp $fn_river_th_std $fn_tmp1
    cpreq -pf ${COMOUT_PREV}/rerun/${fn_river_th_std} ${fn_tmp1}
    tail -n +25 ${fn_tmp1}  > ${fn_tmp2}
    # tail -n +27 ${fn_tmp1}  > ${fn_tmp2}

    line_end_ori=`tail -n 1 ${fn_tmp2}`
    N_row_tmp=`cat ${fn_tmp2} | wc -l`

      for ((k=1; k<=$((N_list_target-N_row_tmp)); k++))
      do
             echo ${line_end_ori} >> ${fn_tmp2}
      done

      line_1_ori_2_end=`head -n 1 ${fn_tmp2} | cut -d' ' -f 2-`
      line_2_ori_2_end=`head -n 2 ${fn_tmp2} | tail -n 1 | cut -d' ' -f 2-` 
 
      line_1_new="0 ${line_1_ori_2_end}"
      line_2_new="3600 ${line_2_ori_2_end}" 
      
      #cp -pf ${fn_tmp2} ${fn_tmp2}_sav
      #sed -i "1s/.*/${line_1_new}/" ${fn_tmp2}
      #sed -i "2s/.*/${line_2_new}/" ${fn_tmp2}
      
      #tail -n +27 ${fn_tmp1} > ${fn_tmp3}
      tail -n +3 ${fn_tmp2} > ${fn_tmp3}

      rm -f ${fn_river_th_std}
      { echo  ${line_1_new}; echo  ${line_2_new}; cat ${fn_tmp3}; } > ${fn_river_th_std} 
      #{ echo  ${line_1_new}; echo  ${line_2_new}; cat ${fn_tmp2}; } > ${fn_river_th_std}

      cpreq -pf ${fn_river_th_std}  ${COMOUTrerun}/${fn_river_th_std}


 fi  # if [[ -f ${fn_river_th} ]]

done  # for str_fn_river_th

 
 fi # begin QC .th



ls -l ${COMOUTrerun}/*.th

echo
echo "The script stofs_3d_atl_create_river_forcing_nwm.sh completed " 
echo 






