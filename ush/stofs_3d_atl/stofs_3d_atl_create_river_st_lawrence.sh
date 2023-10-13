#!/bin/bash


################################################################################
#  Name:  stofs_3d_atl_create_river_st_lawrence.sh                             #
#  This script reads the St Lawrence Riv observed data and sflux/*0001.nc      #
#  to create the STOFS_3D_ATL                                                  #
#  river forcing files, stofs_3d_atl.t12z.{msource, vsink,vsource}.th, that    #
#  are needed for the nowcast and forecast simulations.                        #
#                                                                              #
#  Remarks:                                                                    #
#                                                            September, 2023   #
################################################################################

# ---------------------------> Begin ...
# set -x

echo 'The script stofs_3d_atl_create_river_st_lawrence.sh  started at UTC'


# ---------------------------> directory/file names
  dir_wk=${DATA_prep_river_st_lawrence}

  echo dir_wk = ${dir_wk}


  mkdir -p $dir_wk
  cd $dir_wk
  rm -rf ${dir_wk}/*

  mkdir -p ${COMOUTrerun}

  pgmout=pgmout_nwm.$$
  rm -f $pgmout


# ---------------------------> Global Variables
  # fn_py_create_river_th=${PYstofs3d}/river_th_extract2asci.py

  # v6.1 Linlin
  fn_py_create_river_flux_stLaw=${PYstofs3d}/gen_fluxth_st_lawrence_riv.py
  fn_py_create_river_tem_stLaw=${PYstofs3d}/gen_temp_1_st_lawrence_riv.py


# ---------------------------> Dates
   yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
   yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}

   #str_yyyy_mm_dd_hr=`date -d "${PDYHH_NCAST_BEGIN:0:8}"  +%Y-%m-%d`-${cyc}
   str_yyyy_mm_dd_hr=${PDYHH_NCAST_BEGIN:0:4}-${PDYHH_NCAST_BEGIN:4:2}-${PDYHH_NCAST_BEGIN:6:2}-${cyc}
   
   #str_yyyy_mm_dd_hr_prev=`date -d "${PDYHH_NCAST_BEGIN:0:8} 1 days ago" +%Y-%m-%d`-${cyc} 
   PDYHH_NCAST_BEGIN_1day_ago=$(finddate.sh ${PDYHH_NCAST_BEGIN} d-1)
   str_yyyy_mm_dd_hr_prev=${PDYHH_NCAST_BEGIN_1day_ago:0:4}-${PDYHH_NCAST_BEGIN_1day_ago:4:2}-${PDYHH_NCAST_BEGIN_1day_ago:6:2}-${cyc}


# ------> nowcast/forecast cycle(s) & hr
# current_CC=$CC_CURRENT


# ---------------------------> to create flux.sh
# /lfs/h1/ops/dev/dcom/20230708/canadian_water/QC_02OA016_hourly_hydrometric.csv

  fn_in_st_law_riv=/lfs/h1/ops/prod/dcom/${yyyymmdd_today}/canadian_water/QC_02OA016_hourly_hydrometric.csv
  fn_in_st_law_riv_prev=/lfs/h1/ops/prod/dcom/${yyyymmdd_prev}/canadian_water/QC_02OA016_hourly_hydrometric.csv 

  fn_st_law_riv_flux_th_std=${RUN}.${cycle}.riv.obs.flux.th

  flag_flux_success=0

  for k in {1,2};
  do

    if [[ ${k} -eq 1 ]] && [[ -f "$fn_in_st_law_riv" ]];  then
      #fn_in=${fn_in_st_law_riv}       
      ln -sf ${fn_in_st_law_riv} river_st_law_obs.csv
      break

    elif [[ ${k} -eq 2 ]] && [[ -f "$fn_in_st_law_riv_prev" ]]; then
      ln -sf ${fn_in_st_law_riv_prev} river_st_law_obs.csv
      break
    
    fi 
 done



  rm -f flux.th
  if [ -f river_st_law_obs.csv ]; then

      # 20230716/canadian_water/QC_02OA016_hourly_hydrometric.csv
      # fn_py_create_river_flux_stLaw.py --> ok to run 2023-07-15-12, or 2023-07-14-12

      python  ${fn_py_create_river_flux_stLaw}  ${str_yyyy_mm_dd_hr}
  fi

  if [[ -s flux.th ]] && [[ `wc -l flux.th | awk '{print $1}'` -ge 6 ]]; then
         cp -f flux.th ${COMOUTrerun}/${fn_st_law_riv_flux_th_std}
         flag_flux_success=1

         msg="success: k=${k}: file=`ls -lrt river_st_law_obs.csv`"
         msg=" ${msg} \n output: `ls -lrt flux.th | awk '{print $9}'`"
         echo -e $msg
         echo -e ${msg} >> $pgmout
         echo 

  else  # from archived yesterday
  
      msg="Attn - either or both are unavailable/incomplete: St Lawrence Riv data"
      msg="$msg \n ${fn_in_st_law_riv} \n ${fn_in_st_law_riv_prev}"
      echo -e ${msg}
      echo -e ${msg} >> $pgmout


         #cp -p str_yyyy_mm_dd_hr_prev         
         cp -fp ${COMOUT_PREV}/rerun/${fn_st_law_riv_flux_th_std}  flux_prev.th              

         STR_time_flux_prev=( $( cat flux_prev.th ) )
         N_time_step=$(( ${#STR_time_flux_prev[@]} / 2 ))

         rm -f flux.th
         for k_line in $(seq 1 ${N_time_step}); do

            idx_1=$(( (${k_line}-1)*2 ))

            if [ ${k_line} -lt ${N_time_step} ]; then
               idx_2=$(( (${k_line}-1)*2+3 ))
            else
               idx_2=$(( (${k_line}-2)*2+3 ))
            fi

            echo "k_line=$k_line; idx_1=$idx_1; idx_2=$idx_2"
            echo "${STR_time_flux_prev[${idx_1}]} ${STR_time_flux_prev[${idx_2}]}" >> flux.th
            #echo "${STR_time_flux_prev[${idx_1}]} ${STR_time_flux_prev[${idx_2}]}"

         done

         if [[ -s flux.th ]] && [[ `wc -l flux.th | awk '{print $1}'` -ge 6 ]]; then
           cp -f flux.th ${COMOUTrerun}/${fn_st_law_riv_flux_th_std}
           flag_flux_success=1

           msg="Backup used (yesterday rerun): ${COMOUT_PREV}/rerun/${fn_st_law_riv_flux_th_std}"
           echo ${msg}
           echo ${msg} >> $pgmout
           echo  
         fi

  fi



# ---------------------------> to create TEM_1.th     
  fn_st_law_riv_tem_1_std=${RUN}.${cycle}.riv.obs.tem_1.th

  flag_tem_success=0

  fn_sflux_nc=${COMOUTrerun}/stofs_3d_atl.t12z.gfs.rad.nc

  if [ -f ${fn_sflux_nc} ]; then
    ln -sf ${fn_sflux_nc} . 
    python  ${fn_py_create_river_tem_stLaw}  ${str_yyyy_mm_dd_hr}   
  fi

  if [[ -s TEM_1.th ]] && [[ `wc -l TEM_1.th | awk '{print $1}'` -ge 6 ]]; then
         cp -f TEM_1.th  ${COMOUTrerun}/${fn_st_law_riv_tem_1_std}
         flag_tem_success=1

         msg="source file: ${fn_sflux_nc} \n Success: file=`ls -lr TEM_1.th | awk '{print $9}'`"
         echo -e ${msg}
         echo -e ${msg} >> $pgmout
        

  else  # from archived yesterday
         #cp -p str_yyyy_mm_dd_hr_prev         
         # cp -fp ${COMOUT_PREV}/rerun/${fn_st_law_riv_tem_1_std}  ${COMOUTrerun}/${fn_st_law_riv_flux_th_std}               

         cp -fp ${COMOUT_PREV}/rerun/${fn_st_law_riv_tem_1_std} TEM_1_prev.th
         STR_time_tem_prev=( $( cat TEM_1_prev.th ) )
         N_time_step=$(( ${#STR_time_tem_prev[@]} / 2 ))
         
         rm -f TEM_1.th
         for k_line in $(seq 1 ${N_time_step}); do

            idx_1=$(( (${k_line}-1)*2 ))

            if [ ${k_line} -lt ${N_time_step} ]; then
               idx_2=$(( (${k_line}-1)*2+3 ))
            else
               idx_2=$(( (${k_line}-2)*2+3 )) 
            fi

            #echo "k_line=$k_line; idx_1=$idx_1; idx_2=$idx_2"
            echo "${STR_time_tem_prev[${idx_1}]} ${STR_time_tem_prev[${idx_2}]}" >> TEM_1.th
            
         done 
        
         if [[ -s TEM_1.th ]] && [[ `wc -l TEM_1.th | awk '{print $1}'` -ge 6 ]]; then
           cp -f TEM_1.th  ${COMOUTrerun}/${fn_st_law_riv_tem_1_std}
           flag_tem_success=1

           msg="Backup used (yesterday rerun): ${COMOUT_PREV}/rerun/${fn_st_law_riv_tem_1_std}"
           echo ${msg} >> $pgmout
         
         fi

    fi    

# ---------------------------> Summary
  echo
  msg=" Work dir:" 
  msg="${msg}\n `ls -lrt flux.th`"
  msg="${msg}\n `ls -lrt TEM_1.th` \n"  
  echo -e $msg
  echo -e ${msg} >> $pgmout

  msg="${COMOUTrerun}:"
  msg="${msg}\n `ls -lrt ${COMOUTrerun}/${fn_st_law_riv_flux_th_std}`"
  msg="${msg}\n `ls -lrt ${COMOUTrerun}/${fn_st_law_riv_flux_th_std}` \n"
  echo -e ${msg}
  echo -e ${msg} >> $pgmout
  

echo
echo "The script stofs_3d_atl_create_river_st_lawrence completed " 
echo





