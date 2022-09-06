#!/bin/bash


#####################################################################################
#  Name: stofs_3d_atl_create_restart_combine_rtofs_stofs.sh                         #
#  This script is being called on January 5 annually. It is to create the combined  #
#  model run restart file by combining the outputs of the G-RTOFS and the           #
#  STOFS_3D_ALT hotstart files. The purpose is to reinitialize the 3-D              #
#  temperature (T)/salinity (S) fields in offshore/deep ocean waters with the       #
#  G-RTOFS T/S fields.                                                              #
#                                                                                   #
#  Remarks:                                                                         #
#                                                            September, 2022        #
#####################################################################################


# ---------------------------> Begin ...
# set -x
# set +H

 fn_this_script=stofs_3d_atl_create_restart_from_rtofs.sh
 echo "${fn_this_script} started at UTC `date -u ` "


# ---------------------------> directory/file names
  dir_wk=${DATA_prep_restart}

  echo "dir_wk = ${dir_wk}"
  echo "dir_wk = $DATA_prep_restart}"


  mkdir -p $dir_wk
  cd $dir_wk
  rm -f ${dir_wk}/*

  pgmout=pgmout_restart_from_rtofs.$$
  rm -f $pgmout

  flag_rst_rtofs_success=0
  flag_rst_cbn_success=0


# --------------------------> dates
  if [ $# -ne 0 ] && [ -n "$1" ];
    then
      yyyymmddhr_rerun=$1
    else
      yyyymmddhr_rerun=${PDYHH_FCAST_BEGIN}
    fi   

  yyyymmddhr_rst=${yyyymmddhr_rerun}
  #yyyymmddhr_rst=$($NDATE -24 $yyyymmddhr_rerun)
  #yyyymmdd_rerun=${yyyymmddhr_rerun:0:8}
  yyyymmdd_rst=${yyyymmddhr_rst:0:8}

  echo "Date to rerun the model: yyyymmddhr_rerun = " $yyyymmddhr_rerun
  echo "Date of restart file (nowcast:24 hr before): yyyymmddhr_rst= $yyyymmddhr_rst"

# --------------------------> filenames/COMOUT dirfile (to save restart.nc) 
  #fn_restart_rtofs_ftn=hotstart.nc
  #fn_restart_rtofs_std=${RUN}.${cycle}.restart.rtofs.nc
  #fn_src_hotstart_from_oper_fullPath=${COMOUT_PREV}/${RUN}.${cycle}.hotstart.stofs3d.nc  
  

# ---------------------------> Global Variables
  fn_nco_ssh=${FIXstofs3d}/stofs_3d_atl_obc_3dth_cvt_ssh.nco
  fn_nco_tsuv=${FIXstofs3d}/stofs_3d_atl_obc_3dth_cvt_tsuv.nco  

  fn_exe_gen_hotstart=${EXECstofs3d}/stofs_3d_atl_gen_hot_from_hycom
  fn_input_gen_hotstart=${FIXstofs3d}/stofs_3d_atl_hotstart_nc.in

  cpreq -pf ${fn_input_gen_hotstart} ${dir_wk}/gen_hot_from_nc.in


# ---------------------------> roi: for nudging nc & 3Dth.nc
#idx_x1_2ds=2787
idx_x1_2ds=2337
idx_x2_2ds=2841
idx_y1_2ds=1598
idx_y2_2ds=2177

idx_x1_3dz=14
idx_x2_3dz=518
idx_y1_3dz=94
idx_y2_3dz=673


# --------------------------> create list of RTOFS files
    hr_rst=0${yyyymmddhr_rst:8:2}
    fn_rtofs_2d=rtofs_glo_2ds_n${hr_rst}_diag.nc
    fn_rtofs_3d=rtofs_glo_3dz_n${hr_rst}_6hrly_hvr_US_east.nc

    FILESIZE=150000000
    days=(0 1 2 3 4)
    list_dates=(${yyyymmdd_rst})
    LIST_fn_final_2d=''
    LIST_fn_final_3d=''

   cnt_2d=0;
   cnt_3d=0; 
   for k in ${days[@]}; do

      #list_dates="$list_dates,`date -d "${yyyymmdd_rst} ${k} days ago" +%Y%m%d`"
      date_k=`date -d "${yyyymmdd_rst} ${k} days ago" +%Y%m%d`

      # 2D 
      FILESIZE=150000000
      fn_2d_k_sz=${COMINrtofs}/rtofs.${date_k}/${fn_rtofs_2d}
      echo "Checking file size:: " $fn_2d_k_sz

      if [ -s $fn_2d_k_sz ]; then
        filesize=`wc -c $fn_2d_k_sz | awk '{print $1}' `

        if [ $filesize -ge $FILESIZE ];
        then
           LIST_fn_final_2d+="${fn_2d_k_sz} "
           echo "OK: $fn_2d_k_sz : filesize $filesize (GT ${FILESIZE})"
           cnt_2d=$((cnt_2d+1))   
        
        else
           echo "WARNING: " $fn_2d_k_sz ": filesize $filesize less than $FILESIZE"
        fi
      else
        echo "WARNING: "  $fn_2d_k_sz " does not exist"
      fi

    # 3D: files: check file sizes
      FILESIZE=200000000
      fn_3d_k_sz=${COMINrtofs}/rtofs.${date_k}/${fn_rtofs_3d}    

      echo "Checking file size:: " $fn_3d_k_sz

      if [ -s $fn_3d_k_sz ]; then
        filesize=`wc -c $fn_3d_k_sz | awk '{print $1}' `

        if [ $filesize -ge $FILESIZE ];
        then
           LIST_fn_final_3d+="${fn_3d_k_sz} "
            echo "OK: ${fn_3d_k_sz}: filesize $filesize (GT ${FILESIZE})"
            cnt_3d=$((cnt_3d+1))

        else
           echo "WARNING: " $fn_3d_k_sz ": filesize $filesize less than $FILESIZE"
        fi

      else
        echo "WARNING: "  $fn_3d_k_sz " does not exist"
      fi
      
   done	    


echo "cnt_2d = $cnt_2d, cnt_3d = $cnt_3d"

if [[ $cnt_2d -gt 1 ]] && [[ $cnt_3d -gt 1 ]]; then
   LIST_fn_final_2d_qc=`echo ${LIST_fn_final_2d}  | awk -F' ' '{print $1}'`
   LIST_fn_final_3d_qc=`echo ${LIST_fn_final_3d}  | awk -F' ' '{print $1}'`

   echo "RTOFS files being used: "
   echo "LIST_fn_final_2d_qc = ${LIST_fn_final_2d_qc}"
   echo "LIST_fn_final_3d_qc = ${LIST_fn_final_3d_qc}"
   echo 

fi

if [[ $cnt_2d -gt 1 ]] && [[ $cnt_3d -gt 1 ]]; then
  # ----------> Process 
    rm -f rtofs_glo_*nc
    rm -f RTOFS_2D_*nc

    # 2D: ln -s files
    rm -f RTOFS_2D_???.nc
 
    let cnt=-1
    for fn_2D_k in $LIST_fn_final_2d_qc
    do
      echo "processing  $fn_2D_k"

      let cnt=$cnt+1
      fn_2D_link=RTOFS_2D_`seq -f "%03g" $cnt 1 $cnt`.nc
      ln -sf $fn_2D_k $fn_2D_link

    done

    # 3D: ln -s files
    rm -f RTOFS_3D_???.nc 

    let cnt=-1
    for fn_3D_k in $LIST_fn_final_3d_qc
    do
      echo "processing $fn_3D_k"

      let cnt=$cnt+1
      fn_3D_link=RTOFS_3D_`seq -f "%03g" $cnt 1 $cnt`.nc
      ln -sf $fn_3D_k $fn_3D_link

    done


# --------------------------> Process rotfs data
  list_fn_2ds=`ls RTOFS_2D_*nc`
  list_var_oi='MT,Date,Longitude,Latitude,ssh'
  for fn_2ds in $list_fn_2ds
  do
    fn_in=$fn_2ds
    fn_out=rio_ssh_$fn_in
    ncks -O -d X,$idx_x1_2ds,$idx_x2_2ds -d Y,$idx_y1_2ds,$idx_y2_2ds -v $list_var_oi  $fn_in  $fn_out   

  done

  list_fn_3dz=`ls RTOFS_3D_*nc | sort` 
  list_var_oi='MT,Date,Longitude,Latitude,temperature,salinity,u,v'
  for fn_3dz  in $list_fn_3dz
  do
    fn_in=$fn_3dz
    fn_out=rio_tsuv_$fn_in
    ncks -O -d X,$idx_x1_3dz,$idx_x2_3dz -d Y,$idx_y1_3dz,$idx_y2_3dz -v $list_var_oi  $fn_in  $fn_out    

  done

  # merge into correct sequence
  rm -f merged_RTOFS_*${cycle}*.nc

  fn_merged_2ds=merged_RTOFS_2D_${cycle}.nc
  list_fn_2D_n_f_rio=`ls rio_ssh_RTOFS_2D_???.nc | sort`
  ncrcat -C $list_fn_2D_n_f_rio  $fn_merged_2ds
 

  fn_merged_3dz=merged_RTOFS_3D_${cycle}.nc
  list_fn_3D_n_f_rio=`ls rio_tsuv_RTOFS_3D_???.nc | sort`
  ncrcat -C $list_fn_3D_n_f_rio  $fn_merged_3dz
  
 
  fn_SSH_1_nc=SSH_1_${yyyymmdd_rst}_${cycle}.nc
  fn_TSUV_1_nc=TSUV_1_${yyyymmdd_rst}_${cycle}.nc

 
  # create schsim SSH_1.nc & TSUV_1.nc
  rm -f test0?_3Dth_nu.nc
  rm -f $fn_SSH_1_nc 
  ncatted -O -a _FillValue,ssh,d,, -a missing_value,ssh,d,, $fn_merged_2ds  test01_3Dth_nu.nc
  ncap2 -O -s 'where(ssh>10000) ssh=-30000' test01_3Dth_nu.nc test02_3Dth_nu.nc
  ncatted -O -a _FillValue,ssh,a,f,-30000 -a missing_value,ssh,a,f,-30000 test02_3Dth_nu.nc test03_3Dth_nu.nc
  ncrename -d MT,time -d X,xlon -d Y,ylat  test03_3Dth_nu.nc
  ncap2 -O -S $fn_nco_ssh test03_3Dth_nu.nc test04_3Dth_nu.nc
  ncks -CO -x -v Date,MT,X,Y  test04_3Dth_nu.nc  $fn_SSH_1_nc 
  # cp -f  SSH_${yyyymmdd}_${cycle}_3Dth_nu.nc SSH_3Dth_nu.nc


  rm -f tmp0?_3Dth_nu.nc
  rm -f $fn_TSUV_1_nc 
  ncrename -d MT,time -d Depth,lev -d X,xlon -d Y,ylat  -v u,water_u -v v,water_v  $fn_merged_3dz  tmp01_3Dth_nu.nc
  ncap2 -O -S $fn_nco_tsuv  tmp01_3Dth_nu.nc tmp02_3Dth_nu.nc
  ncks -O -x -v Depth,Date,MT,X,Y tmp02_3Dth_nu.nc  $fn_TSUV_1_nc
  # cp -f TSUV_${yyyymmdd}_${cycle}_3Dth_nu.nc TSUV_3Dth_nu.nc
  

# --------------------------> create {elev2D.th.nc, SAL_3D.th.nc, TEM_3D.th.nc, uv3D.th.nc}
 rm -f {SSH,TS,UV}_1.nc

 ln -sf ${fn_SSH_1_nc}  SSH_1.nc
 ln -sf ${fn_TSUV_1_nc} TS_1.nc
 ln -sf ${fn_TSUV_1_nc} UV_1.nc

 ln -sf ${FIXstofs3d}/stofs_3d_atl_vgrid.in       vgrid.in
 ln -sf ${FIXstofs3d}/stofs_3d_atl_hgrid.ll       hgrid.ll
 ln -sf ${FIXstofs3d}/stofs_3d_atl_hgrid.gr3      hgrid.gr3
 ln -sf ${FIXstofs3d}/stofs_3d_atl_estuary.gr3    estuary.gr3

 ln -sf ${FIXstofs3d}/stofs_3d_atl_ocean.dbf      ocean.dbf
 ln -sf ${FIXstofs3d}/stofs_3d_atl_ocean.prj      ocean.prj
 ln -sf ${FIXstofs3d}/stofs_3d_atl_ocean.shp      ocean.shp 
 ln -sf ${FIXstofs3d}/stofs_3d_atl_ocean.shx      ocean.shx 

 #ln -sf ${PYstofs3d}/pylib.py                pylib.py
 #ln -sf ${fn_input_gen_hotstart}             gen_hot_from_nc.in                

  
# -------------------------> restart_from_rtofs.nc
  $fn_exe_gen_hotstart    >> $pgmout 2> errfile

  export err=$?; #err_chk
  pgm=$fn_exe_gen_hotstart


  if [ $err -eq 0 ]; then
    msg=`echo $pgm  completed normally`
    echo $msg
    echo $msg >> $pgmout

  else
    msg=`echo $pgm did not complete normally`
    echo $msg
    echo $msg >> $pgmout
  fi

  # ----------> rename/archive hotstart.nc
  fn_restart_rtofs_ftn=hotstart.nc
  #fn_rst_rtofs=${fn_restart_rtofs_ftn}
  fn_restart_rtofs_std=${RUN}.${cycle}.restart.rtofs.nc

  if [[ $(find ${fn_restart_rtofs_ftn} -type f -size  +20G 2>/dev/null) ]]; then
    flag_rst_rtofs_success=1
   
    ln -sf ${fn_restart_rtofs_ftn}  ${fn_restart_rtofs_std}

    msg="Created: rtofs restart file - ${fn_restart_rtofs_ftn}/${fn_restart_rtofs_std}"
    echo $msg; echo $msg >> $pgmout 
  else
    flag_rst_rtofs_success=0	  
    echo "Failed to create: rtofs restart file - ${fn_restart_rtofs_ftn}/${fn_restart_rtofs_std}" 
  fi

else  # if [[ $cnt_2d -gt 1 ]] && [[ $cnt_3d -gt 1 ]] 
    flag_rst_rtofs_success=0
    msg="Failed to create: rtofs restart file - No input RTOFS files"
    echo -e ${msg}
fi


# -------------------------> blend/combine  restart_from_rtofs & hotstart_from_stofs3d

  LIST_fn_fnl_hotstart=''
  days=(0 1 2 3 4)

  cnt_files=0
  for k in ${days[@]}; do

      date_k=`date -d "${PDYHH_NCAST_BEGIN:0:8} ${k} days ago" +%Y%m%d`

      fn_hotstart_oper_chk=${COMROOT}/${RUN}.${date_k}/${RUN}.${cycle}.hotstart.stofs3d.nc

      if [ -s $fn_hotstart_oper_chk ]; then
        if [[ $(find ${fn_hotstart_oper_chk} -type f -size  +20G 2>/dev/null) ]];
        then
           LIST_fn_fnl_hotstart+="${fn_hotstart_oper_chk} "
           echo "OK: $fn_hotstart_oper_chk : filesize $filesize (GT 22GB)"
           cnt_files=$((cnt_files+1))

        else
           echo "WARNING: " $fn_hotstart_oper_chk ": filesize less than 22GB"
        fi
      else
        echo "WARNING: "  $fn_hotstart_oper_chk " does not exist"
      fi

  done
  echo "cnt_files = " ${cnt_files}
 
  flag_exist_rst_oper=0
  if [[ $cnt_files -ge 1 ]]; then
     LIST_fn_fnl_hotstart=(${LIST_fn_fnl_hotstart[@]})

     fn_src_hotstart_from_oper_fullPath=${LIST_fn_fnl_hotstart[0]};
     echo -e "found: fn_src_hotstart_from_oper_fullPath = \n  ${fn_src_hotstart_from_oper_fullPath}"

       flag_exist_rst_oper=1

       msg="Found:  ${fn_src_hotstart_from_oper_fullPath}"
       echo "${msg}"; echo "${msg}"  >> $jlogfile

    else
       msg="Not found: ${fn_src_hotstart_from_oper_fullPath}"
       echo "${msg}"; echo "${msg}"  >> $jlogfile
    fi


  # combine oper & rtofs
  # fn_out_restart_cbn=${RUN}.${cycle}.restart.combine.nc

  fn_py_input_hotstart_from_oper=hotstart_from_oper.nc
  fn_py_input_hotstart_from_rtofs=hotstart_from_hycom.nc

  if [ $flag_rst_rtofs_success -eq 1 ] && [ $flag_exist_rst_oper -eq 1 ]; then
      rm -f $fn_py_input_hotstart_from_oper
      rm -f $fn_py_input_hotstart_from_rtofs
      ln -sf ${fn_src_hotstart_from_oper_fullPath}   $fn_py_input_hotstart_from_oper
      ln -sf ${fn_restart_rtofs_std} $fn_py_input_hotstart_from_rtofs

      python ${PYstofs3d}/hotstart_proc.py >> $pgmout 2> errfile
  fi

  fn_hotstart_cbn=new_hotstart.nc
  fn_out_restart_cbn=${RUN}.${cycle}.restart.combine.nc

  flag_rst_cbn_success=0
  if [[ $(find $fn_hotstart_cbn -type f -size  +20G 2>/dev/null) ]]; then
    flag_rst_cbn_success=1
    ln -sf ${fn_hotstart_cbn} ${fn_out_restart_cbn}

    msg="Combined rtofs and stofs3d hotstart: ${COMOUT}/${fn_restart_rtofs_stofs3d_std}  was successfully created"
    echo $msg; echo $msg >> $pgmout
  fi
  
  
  fn_restart_rerun=${COMOUTrerun}/${RUN}.${cycle}.restart.nc 
  if [[ $flag_rst_cbn_success -eq 1 ]]; then
     cpreq -pfL ${fn_hotstart_cbn} ${fn_restart_rerun} 
  
     msg="fn_restart_rerun (combined rtofs & oper) = ${fn_hotstart_cbn} \n"
     msg=(${msg} "archived at :  ${fn_restart_rerun}")
  
 
  elif [[ ${flag_exist_rst_oper} -eq 1 ]]; then
     cpreq -pfL ${fn_src_hotstart_from_oper_fullPath} ${fn_restart_rerun}

     msg="fn_restart_rerun (source: rtofs) = ${fn_src_hotstart_from_oper_fullPath}\n" 
     msg+="archived at :  ${fn_restart_rerun}"

  else
    cpreq -pfL ${fn_src_hotstart_from_oper_fullPath} ${fn_restart_rerun}	  
    msg="WARNING: Not created - ${fn_restart_rerunn}"
    msg+="Not created:  (cbn rtofs & oper; rtofs; oper) \n"
    msg+="Restart file: ${fn_src_hotstart_from_oper_fullPath}"

  fi

  echo -e ${msg}; echo;
  echo -e ${msg} >> $pgmout


echo 
echo "${fn_this_script} completed at UTC `date -u ` "

echo 





