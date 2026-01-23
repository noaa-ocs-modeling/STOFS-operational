#!/bin/bash

##################################################################################
#  Name: stofs_3d_atl_create_obc_nudge.sh                                   #
#  This script reads the NCEP/G-RTOFS data to create the STOFS_3D_ATL open       #
#  bouary forcing files, stofs_3d_atl.t12z.{elev2dth,uv3dth,tem3dth,sal3dth}.nc  #
#  and the bundary nudging files, stofs_3d_atl.t12z.{temnu,salnu}.nc.            #
#                                                                                #
#  Remarks:                                                                      #
#                                                              September, 2022   #
##################################################################################


# ---------------------------> Begin ...
set -x

  fn_this_script="stofs_3d_atl_create_obc_nudge.sh"

  echo "${fn_this_script} started "

  echo "module list in ${fn_this_script}"
  module list
  echo; echo


# ---------------------------> directory/file names
  dir_wk=${DATA_prep_rtofs}/dir_nudge

  mkdir -p $dir_wk
  cd $dir_wk
  rm -rf ${dir_wk}/*

  mkdir -p ${COMOUTrerun}

  pgmout=pgmout_rtofs_obc_nudge.$$
  rm -f $pgmout


# ---------------------------> Global Variables
  fn_exe_gen_3Dth=${EXECstofs3d}/stofs_3d_atl_gen_3Dth_from_hycom
  fn_exe_gen_nudge=${EXECstofs3d}/stofs_3d_atl_gen_nudge_from_hycom

  fn_input_gen_3Dth=${FIXstofs3d}/stofs_3d_atl_obc_3dth_nc.in
  fn_input_gen_nudge=${FIXstofs3d}/stofs_3d_atl_obc_nudge_nc.in

  fn_nco_ssh=${FIXstofs3d}/stofs_3d_atl_obc_3dth_cvt_ssh.nco
  fn_adt_weight=${FIXstofs3d}/stofs_3d_atl_adt_weight.nc
  fn_adt_cvtz_nco=${FIXstofs3d}/stofs_3d_atl_adt_cvtz.nco


  fn_nco_tsuv=${FIXstofs3d}/stofs_3d_atl_obc_3dth_cvt_tsuv.nco 

  # 96 hr:: N_list_target_2D=14
  # 96 hr:: N_list_target_3D=14
  # 96 hr:: FYI: [12:6:+12+24*5] == {12    18    24    30    36    42    48    54    60    66    72    78    84    90    96   102   108   114   120   126   132}, N=21 pnts
  N_list_target_2D=21
  N_list_target_3D=21


# ---------------------------> file names
  fn_rtofs_obc_elev2d_th_ori=elev2D.th.nc
  fn_rtofs_obc_elev2d_th_std=${RUN}.${cycle}.elev2dth.nc

  fn_rtofs_obc_TEM_3Dth_ori=TEM_3D.th.nc
  fn_rtofs_obc_TEM_3Dth_std=${RUN}.${cycle}.tem3dth.nc
  
  fn_rtofs_obc_SAL_3Dth_ori=SAL_3D.th.nc
  fn_rtofs_obc_SAL_3Dth_std=${RUN}.${cycle}.sal3dth.nc

  fn_rtofs_obc_UV_3Dth_ori=uv3D.th.nc
  fn_rtofs_obc_UV_3Dth_std=${RUN}.${cycle}.uv3dth.nc

  fn_rtofs_nu_TEM_ori=TEM_nu.nc
  fn_rtofs_nu_TEM_std=${RUN}.${cycle}.temnu.nc

  fn_rtofs_nu_SAL_ori=SAL_nu.nc
  fn_rtofs_nu_SAL_std=${RUN}.${cycle}.salnu.nc


# ---------------------------> roi: for nudging nc & 3Dth.nc

idx_x1_2ds=2805
idx_x2_2ds=2923
idx_y1_2ds=1598
idx_y2_2ds=2325

idx_x1_3dz=422
idx_x2_3dz=600
idx_y1_3dz=94
idx_y2_3dz=835


# v6 RTOFS-2D, nudge dmn: 2805  2923  1598  2325
# v6 RTOFS-3D, nudge dmn: [482  600   94  821]


# --------------------------> dates
  yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
  yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}

# --------------------------> default: create list of RTOFS files
    list_fn_2D_n=`ls ${COMINrtofs}/rtofs.${yyyymmdd_today}/rtofs_glo_2ds_{n012,n018}_diag.nc | sort`
    
    # 96 hr:: list_fn_2D_f=`ls ${COMINrtofs}/rtofs.${yyyymmdd_today}/rtofs_glo_2ds_{f000,f006,f012,f018,f024,f030,f036,f042,f048,f054,f060,f066}_diag.nc`
    list_fn_2D_f=`ls ${COMINrtofs}/rtofs.${yyyymmdd_today}/rtofs_glo_2ds_{f000,f006,f012,f018,f024,f030,f036,f042,f048,f054,f060,f066,f072,f078,f084,f090,f096,f102,f108,f114,f120}_diag.nc`


    list_fn_2D_n_f_1="${list_fn_2D_n[@]} "
    list_fn_2D_n_f_1+="${list_fn_2D_f[@]}"

    list_fn_3D_n=`ls ${COMINrtofs}/rtofs.${yyyymmdd_today}/rtofs_glo_3dz_{n012,n018,n024}_6hrly_hvr_US_east.nc | sort`
    # 96 hr:: list_fn_3D_f=`ls ${COMINrtofs}/rtofs.${yyyymmdd_today}/rtofs_glo_3dz_{f006,f012,f018,f024,f030,f036,f042,f048,f054,f060,f066,f072,f078}_6hrly_hvr_US_east.nc`
    list_fn_3D_f=`ls ${COMINrtofs}/rtofs.${yyyymmdd_today}/rtofs_glo_3dz_{f006,f012,f018,f024,f030,f036,f042,f048,f054,f060,f066,f072,f078,f084,f090,f096,f102,f108,f114,f120}_6hrly_hvr_US_east.nc`

    list_fn_3D_n_f_1="${list_fn_3D_n[@]} "
    list_fn_3D_n_f_1+="${list_fn_3D_f[@]}"

#  --------------------------> backup
 
    # 96 hr: list_fn_2D_n_f_2=`ls ${COMINrtofs}/rtofs.${yyyymmdd_prev}/rtofs_glo_2ds_{f012,f018,f024,f030,f036,f042,f048,f054,f060,f066,f072,f078,f084,f090}_diag.nc`
    # FYI: [12:6:+12+24*5] == {12    18    24    30    36    42    48    54    60    66    72    78    84    90    96   102   108   114   120   126   132}, N=21 pnts
    list_fn_2D_n_f_2=`ls ${COMINrtofs}/rtofs.${yyyymmdd_prev}/rtofs_glo_2ds_{f012,f018,f024,f030,f036,f042,f048,f054,f060,f066,f072,f078,f084,f090,f096,f102,f108,f114,f120,f126,f132,f144}_diag.nc`
    
    # 96 hrlist_fn_3D_n_f_2=`ls ${COMINrtofs}/rtofs.${yyyymmdd_prev}/rtofs_glo_3dz_{f012,f018,f024,f030,f036,f042,f048,f054,f060,f066,f072,f078,f084,f090}_6hrly_hvr_US_east.nc`
    list_fn_3D_n_f_2=`ls ${COMINrtofs}/rtofs.${yyyymmdd_prev}/rtofs_glo_3dz_{f012,f018,f024,f030,f036,f042,f048,f054,f060,f066,f072,f078,f084,f090,f096,f102,f108,f114,f120,f126,f132,f144}_6hrly_hvr_US_east.nc`    



    echo; echo "list_fn_2D_n_f_1"
    A=$list_fn_2D_n_f_1;  for a in ${A[@]}; do echo $a; done

    echo; echo "list_fn_2D_n_f_2"
    A=$list_fn_2D_n_f_2;  for a in ${A[@]}; do echo $a; done


# ------------------------> check file sizes
    rm -f rtofs_glo_*nc
    rm -f RTOFS_2D_*nc

# 2D files: check file sizes
FILESIZE=150000000

list_route_no=(1 2)
for flag_route_no in ${list_route_no[@]}; do

 echo $flag_route_no
 if [[ $flag_route_no == 1 ]]; then
    list_fn_2D_n_f=$list_fn_2D_n_f_1
 else
    list_fn_2D_n_f=$list_fn_2D_n_f_2
 fi
 echo "flag_route_no = $flag_route_no";
   
    LIST_fn_final_2d=''
    for fn_2d_k_sz in $list_fn_2D_n_f
    do
      echo "Checking file size:: " $fn_2d_k_sz

      if [ -s $fn_2d_k_sz ]; then
        filesize=`wc -c $fn_2d_k_sz | awk '{print $1}' `

        if [ $filesize -ge $FILESIZE ];
        then
           LIST_fn_final_2d+="${fn_2d_k_sz} "
        else
           echo "WARNING: " $fn_2d_k_sz ": filesize $filesize less than $FILESIZE"
           echo "WARNING: " $fn_2d_k_sz ": filesize $filesize less than $FILESIZE"  
        fi

      else
        echo "WARNING: "  $fn_2d_k_sz " does not exist"
        echo "WARNING: "  $fn_2d_k_sz " does not exist"  
      fi
    done

 if [[ $flag_route_no == 1 ]]; then
    LIST_fn_final_2d_1=$LIST_fn_final_2d
 else
    LIST_fn_final_2d_2=$LIST_fn_final_2d
 fi

done # for flag_route_no i


# merge if missing

 A1=($LIST_fn_final_2d_1)
 B2=($LIST_fn_final_2d_2)

  N_list_1=${#A1[@]}; echo $N_list_1
  N_list_2=${#B2[@]}; echo $N_list_2;

  N_list_target=N_list_target_2D

if [[ ${N_list_1} -gt 2 ]]; then

  LIST_fn_final_2d=${A1[@]}

  if [[ ${N_list_1} -lt ${N_list_target} ]] && [[ ${N_list_2} -gt ${N_list_1} ]]; then
    echo "N_list_1 = $N_list_1"; echo "N_list_2 = $N_list_2"

    n_diff_1_2=$((${N_list_2}-${N_list_1}))

    # error   LIST_fn_final_2d=${A1[@]} ${B2[@]:$N_list_1:$n_diff_1_2}
    LIST_fn_final_2d=(${A1[@]} ${B2[@]:$N_list_1:$n_diff_1_2})

    echo "combined: LIST_fn_1 & 2: "
    for a in ${LIST_fn_final_2d[@]}; do echo $a; done
  
  else
    LIST_fn_final_2d=${A1[@]}  
  fi

elif [[ ${N_list_2} -gt 2 ]]; then
  LIST_fn_final_2d=${B2[@]}

else
  LIST_fn_final_2d=()

fi

    # 2D: ln -s files
    rm -f RTOFS_2D_???.nc
 
    LIST_fn_final_2d=(${LIST_fn_final_2d[@]});

  echo ${LIST_fn_final_2d[@]}; echo  
  echo N_LIST_fn_final_2d = ${#LIST_fn_final_2d[@]} 
  for a in ${LIST_fn_final_2d[@]}; do echo $a; done; echo;


  N_min_rtofs_cr=10  
  if [[ ${#LIST_fn_final_2d[@]} -ge ${N_min_rtofs_cr} ]]; then
    let cnt=-1
    for fn_2D_k in ${LIST_fn_final_2d[@]}
    do
      echo "checking file size:: " $fn_2D_k

      let cnt=$cnt+1
      fn_2D_link=RTOFS_2D_`seq -f "%03g" $cnt 1 $cnt`.nc
      ln -sf $fn_2D_k $fn_2D_link

    done

  else
	  echo "N_LIST_fn_final_2d(${N_LIST_fn_final_2d}) < ${N_min_rtofs_cr}"

  fi	  


# ---------> 3D: files: check file sizes
    FILESIZE=200000000

list_route_no=(1 2)
for flag_route_no in ${list_route_no[@]}; do

  echo $flag_route_no
  if [[ $flag_route_no == 1 ]]; then
    list_fn_3D_n_f=$list_fn_3D_n_f_1
  else
    list_fn_3D_n_f=$list_fn_3D_n_f_2
  fi
  echo "flag_route_no = $flag_route_no";


    LIST_fn_final_3d=''
    for fn_3d_k_sz in $list_fn_3D_n_f
    do
      echo "Checking file size:: " $fn_3d_k_sz

      if [ -s $fn_3d_k_sz ]; then
        filesize=`wc -c $fn_3d_k_sz | awk '{print $1}' `

        if [ $filesize -ge $FILESIZE ];
        then
           LIST_fn_final_3d+="${fn_3d_k_sz} "
        else
           echo "WARNING: " $fn_3d_k_sz ": filesize $filesize less than $FILESIZE"
           echo "WARNING: " $fn_3d_k_sz ": filesize $filesize less than $FILESIZE"  
        fi

      else
        echo "WARNING: "  $fn_3d_k_sz " does not exist"
        echo "WARNING: "  $fn_3d_k_sz " does not exist"  
      fi
    done

 if [[ $flag_route_no == 1 ]]; then
    LIST_fn_final_3d_1=$LIST_fn_final_3d
 else
    LIST_fn_final_3d_2=$LIST_fn_final_3d
 fi

done # for flag_route_no i


# merge if missing
 N_list_1=${#LIST_fn_final_3d_1[@]}
 N_list_2=${#LIST_fn_final_3d_2[@]}
 echo $N_list_1; echo $N_list_2

 A1=($LIST_fn_final_3d_1)
 B2=($LIST_fn_final_3d_2)

  N_list_1=${#A1[@]}; echo $N_list_1
  N_list_2=${#B2[@]}; echo $N_list_2;

  N_list_target=N_list_target_3D

if [[ ${N_list_1} -gt 2 ]]; then

  LIST_fn_final_3d=${A1[@]}

  if [[ ${N_list_1} -lt ${N_list_target} ]] && [[ ${N_list_2} -gt ${N_list_1} ]]; then
    echo "N_list_1 = $N_list_1"; echo "N_list_2 = $N_list_2"

    n_diff_1_2=$((${N_list_2}-${N_list_1}))

    # error   LIST_fn_final_3d=${A1[@]} ${B2[@]:$N_list_1:$n_diff_1_2}
    LIST_fn_final_3d=(${A1[@]} ${B2[@]:$N_list_1:$n_diff_1_2})

    echo "combined: LIST_fn_1 & 2: "
    for a in ${LIST_fn_final_3d[@]}; do echo $a; done

  else
    LIST_fn_final_3d=${A1[@]}	  

  fi

elif [[ ${N_list_2} -gt 2 ]]; then
  LIST_fn_final_3d=${B2[@]}

else
  LIST_fn_final_3d=()	

fi


LIST_fn_final_3d=(${LIST_fn_final_3d[@]})

    # 3D: ln -s files
    rm -f RTOFS_3D_???.nc

  N_min_rtofs_cr=10;  
  if [[ ${#LIST_fn_final_3d[@]} -ge ${N_min_rtofs_cr} ]]; then
    let cnt=-1
    for fn_3D_k in ${LIST_fn_final_3d[@]};
    do
      echo "checking file size:: " $fn_3D_k

      let cnt=$cnt+1
      fn_3D_link=RTOFS_3D_`seq -f "%03g" $cnt 1 $cnt`.nc
      ln -sf $fn_3D_k $fn_3D_link
    done
  else
     echo "N_LIST_fn_final_3d < ${N_min_rtofs_cr}"

  fi	  

    # 3dz_{non-n000, n006,n024,non-f000,f006,f192}, OK- w/o f000, use n024! w/o n000, use n024 of yesterday


# ============================================> Process rotfs data


if [[ ${#LIST_fn_final_3d[@]} -ge ${N_min_rtofs_cr} ]] && [[ ${#LIST_fn_final_2d[@]} -ge ${N_min_rtofs_cr} ]]; then
        
	list_fn_2ds=(); list_fn_2ds=`ls RTOFS_2D_*nc | sort`; list_fn_2ds=(${list_fn_2ds[@]});
	list_fn_3dz=(); list_fn_3dz=`ls RTOFS_3D_*nc | sort`; list_fn_3dz=(${list_fn_3dz[@]});

  N_list_fn_2ds=${#list_fn_2ds[@]}
  N_list_fn_3dz=${#list_fn_3dz[@]}

  N_min_list_2d_3d=${N_list_fn_2ds}
  if [[ ${N_list_fn_2ds} -gt ${N_list_fn_3dz} ]]; then N_min_list_2d_3d=${N_list_fn_3dz}; fi;
  echo N_list_fn_2ds_3d = ${N_min_list_2d_3d}

  llst_fn_2ds_new=();  list_fn_2ds_new=(${list_fn_2ds[@]:0:${N_min_list_2d_3d}})
  list_fn_3dz_new=(); list_fn_3dz_new=(${list_fn_3dz[@]:0:${N_min_list_2d_3d}})

  echo "N_list_fn_2ds_new= ${#list_fn_2ds_new[@]}"
  echo "N_list_fn_3dz_new= ${#list_fn_3dz_new[@]}"

  list_var_oi='MT,Date,Longitude,Latitude,ssh'
  for fn_2ds in ${list_fn_2ds_new[@]}
  do

    echo "begin: ${fn_2ds} ..."	  
    fn_in=$fn_2ds
    fn_out=rio_ssh_$fn_in
    ncks -O -d X,$idx_x1_2ds,$idx_x2_2ds -d Y,$idx_y1_2ds,$idx_y2_2ds -v $list_var_oi  $fn_in  $fn_out   

  done

  list_var_oi='MT,Date,Longitude,Latitude,temperature,salinity,u,v'
  for fn_3dz  in ${list_fn_3dz_new[@]}
  do
    echo "begin: ${fn_3dz} ..."	  
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


  fn_SSH_1_nc=SSH_1_${yyyymmdd_today}_${cycle}.nc
  fn_SSH_1_nc_rtofs_only=SSH_1_rtofs_only.nc

  fn_TSUV_1_nc=TSUV_1_${yyyymmdd_today}_${cycle}.nc


  # create schsim SSH_1.nc & TSUV_1.nc
  rm -f test0?_3Dth_nu.nc

  rm -f ${fn_SSH_1_nc_rtofs_only}

  ncatted -O -a _FillValue,ssh,d,, -a missing_value,ssh,d,, $fn_merged_2ds  test01_3Dth_nu.nc
  ncap2 -O -s 'where(ssh>10000) ssh=-30000' test01_3Dth_nu.nc test02_3Dth_nu.nc
  ncatted -O -a _FillValue,ssh,a,f,-30000 -a missing_value,ssh,a,f,-30000 test02_3Dth_nu.nc test03_3Dth_nu.nc
  ncrename -d MT,time -d X,xlon -d Y,ylat  test03_3Dth_nu.nc
  ncap2 -O -S $fn_nco_ssh test03_3Dth_nu.nc test04_3Dth_nu.nc
  
  ncks -CO -x -v Date,MT,X,Y  test04_3Dth_nu.nc  $fn_SSH_1_nc_rtofs_only  

  cp -pf $fn_SSH_1_nc_rtofs_only SSH_1_raw_RTOFS.nc

  rm -f tmp0?_3Dth_nu.nc
  rm -f $fn_TSUV_1_nc
  ncrename -d MT,time -d Depth,lev -d X,xlon -d Y,ylat  -v u,water_u -v v,water_v  $fn_merged_3dz  tmp01_3Dth_nu.nc
  ncap2 -O -S $fn_nco_tsuv  tmp01_3Dth_nu.nc tmp02_3Dth_nu.nc
  ncks -O -x -v Depth,Date,MT,X,Y tmp02_3Dth_nu.nc  $fn_TSUV_1_nc


# --------------------------> prepare input files

 rm -f {SSH,TS,UV}_1.nc

 ln -sf ${fn_SSH_1_nc}  SSH_1.nc

 
 ln -sf ${fn_TSUV_1_nc} TS_1.nc


 ln -sf ${fn_TSUV_1_nc} UV_1.nc

 ln -sf ${FIXstofs3d}/stofs_3d_atl_vgrid.in       vgrid.in
 ln -sf ${FIXstofs3d}/stofs_3d_atl_tem_nudge.gr3  TEM_nudge.gr3
 ln -sf ${FIXstofs3d}/stofs_3d_atl_hgrid.ll       hgrid.ll
 ln -sf ${FIXstofs3d}/stofs_3d_atl_hgrid.gr3      hgrid.gr3
 ln -sf ${FIXstofs3d}/stofs_3d_atl_estuary.gr3    estuary.gr3


# --------------------------> create {elev2D.th.nc, SAL_3D.th.nc, TEM_3D.th.nc, uv3D.th.nc}
# Not included


# -------------------------------> create {TEM_nu.nc, SAL_nu.nc} 
  rm -f gen_nudge_from_nc.in
  ln -sf ${fn_input_gen_nudge}  gen_nudge_from_nc.in

  rm -f {TEM_nu,SAL_nu}.nc

  $fn_exe_gen_nudge    >> $pgmout 2> errfile


  export err=$?;
  pgm=$fn_exe_gen_nudge

  if [ $err -eq 0 ]; then
    msg=`echo $pgm  completed normally`
    echo $msg
    echo $msg >> $pgmout

  else
    msg=`echo $pgm did not complete normally`
    echo $msg
    echo $msg >> $pgmout
  fi

else   # if [[ ${#LIST_fn_final_3[@]} -ge ${N_min_rtofs_cr} ]]
  msg="RTOFS: no files were processed:\n"
  msg="${msg}; N_min_rtofs_2d/3d LT ${N_min_rtofs_cr}"
  echo -e ${msg}

fi	


# ---------------------------------> QC & archive
list_var_ori=(elev2D.th TEM_3D.th SAL_3D.th uv3D.th TEM_nu SAL_nu)
list_var_std=(elev2dth tem3dth sal3dth uv3dth temnu salnu) 

# upgrade
  list_end_time_step=(475200.0 475200.0 475200.0 475200.0 5.5 5.5)

  list_offset_time=(86400.0 86400.0 86400.0 86400.0 1.0 1.0)


# Only nu.nc:
list_loop=(4 5)

# upgrade

# FYI: elev3dth.nc/temnu.nc: time={0,21600,...,475200}, 6-hrly, 23 points
  N_dim_cr_min=17
  N_dim_cr_max=21


list_fn_sz_cr=(21000 312000 312000 605000 10440000 10440000)


for k in ${list_loop[@]}; do

fn_ori=${list_var_ori[k]}.nc
fn_std=${RUN}.${cycle}.${list_var_std[k]}.nc

echo $k, $fn_ori, $fn_std


   if [[ -s ${fn_ori} ]]; then 
       sz_k=$((`wc -c ${fn_ori} | awk '{print $1}'`)) 
       
       if [[ ${sz_k} -gt ${list_fn_sz_cr[$k]} ]]; then 
            dim_k=`ncdump -h  ${fn_ori}  | grep "time = UNLIMITED" | awk -F'(' '{print $2}' | awk -F' ' '{print $1}'`; 

       else
            sz_k=$((0))
            dim_k=$((0))
       fi
   fi
   echo "dim=${dim_k}, sz_k-bytes=${sz_k}, sz_cr=${list_fn_sz_cr[$k]}"  

 
   flag_success=0
   time_end_step=${list_end_time_step[$k]}
   time_offset=${list_offset_time[$k]}

   if [[ ${dim_k} -ge ${N_dim_cr_max} ]]; then
      cpreq -pf ${fn_ori} ${COMOUTrerun}/${fn_std}
      echo "done: method - non-backup"
      flag_success=1  

   else 
      if [[ -f  ${COMOUT_PREV}/rerun/${fn_std} ]]; then 
         rm -f tmp*.nc

	 fn_prev=prev_${fn_std}
         cpreq -pf ${COMOUT_PREV}/rerun/${fn_std} ${fn_prev}
         
         cpreq -pf ${fn_std} ${COMOUTrerun}/${fn_std}
         echo "done: method - backup 2"   
         flag_success=1 
      
      else
         msg="Warning: failed of (non-backup, backup 2) \n ${fn_std} Not created"
         echo -e ${msg}
      fi

   fi # if [[ ${dim_k} -ge ${N_dim_cr_max} ]]

done # for files



  echo 
  echo "stofs_3d_atl_create_obc_nudge.sh completed "  
  echo 


