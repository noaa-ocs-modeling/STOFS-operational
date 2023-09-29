#!/bin/sh
###############################################################################
#                                                                             #
# Compiles all codes, moves executables to exec and cleans up                 #
#                                                               August 2022   #
#                                                                             #
###############################################################################
#
# --------------------------------------------------------------------------- #
# 1. Preparations: seek source codes to be compiled

source ./stofs_3d_atl.build 
module list

export COMP_F=ftn
export COMP_F_MPI90=ftn
export COMP_F_MPI=ftn
export COMP_CC=cc

  run_name=stofs_3d_atl 
  exec=exec/${run_name}
  fn_prefix="stofs_3d_atl_"
  
  # example: dir_src=/lfs/h1/nos/estofs/noscrub/Zizang.Yang/dev.stofs.v1.1.0/sorc/stofs_3d_atl
  dir_src=`pwd`

  mkdir -p ${dir_src}/../../${exec}  


  fcodes=`ls -d ${fn_prefix}*.fd | sed 's/\.fd//g'`
  echo " FORTRAN codes found: "$fcodes

  outfile=`pwd`/build_codes.out
  rm -f $outfile

  echo `date; echo` > $outfile


# make - to compile all
if [ $# -eq 0 ];then
   for code in $fcodes; do

    if [[  ${code} == "stofs_3d_atl_pschism" ]]; then
        cd ${dir_src}/${code}.fd/src

	make clean   >> $outfile  2>&1
        # make pschism >> $outfile  2>&1
        make all >> $outfile  2>&1

         echo " Copying ${code} to ../../../../$exec "
         cp -f pschism_WCOSS2_VL  ${dir_src}/../../${exec}/${code}
         cd ${dir_src}

    else
     echo " Making $code " >> $outfile
          cd ${dir_src}/${code}.fd

          make >> $outfile
          echo " Copying ${code} to ../../../${exec} " >> $outfile
	  echo " Copying ${code} to ../../../${exec} "
          cp -pf ${code} ${dir_src}/../../${exec}		  
          cd ${dir_src} 
    fi
  
   done
 
elif [ $1 == "clean" ]; then  
    cd ${dir_src}   	
    echo " cleaning ... "
   
    code=$1
    for code in $fcodes; do
      if [[  ${code} == "stofs_3d_atl_pschism" ]]; then

        cd ${dir_src}/${code}.fd/src
        make clean

        echo " cleaning ${dir_src}/${code}.fd/src "  >> $outfile

        rm -rf ${code}.fd/build_exe

      else
       #echo " removing  $code " >> $outfile
       echo " removing  $code "
          cd ${dir_src}/${code}.fd
          make clean
      fi
      cd ${dir_src}
    done

else  	  
  # -----> make individual folder
  code="$1"
         
  echo " Making ${code} " >> $outfile
  echo " Making ${code} "
  
  cd ${dir_src}
 if [[  ${code} == "stofs_3d_atl_pschism" ]]; then
        cd ${dir_src}/${code}.fd/src

        make clean
        make pschism >> $outfile  2>&1

         echo " Copying ${code} to ../../../../$exec "
         cp -f pschism_WCOSS2_VL  ${dir_src}/../../${exec}/${code}
         cd ${dir_src}
     
 else
     cd ${dir_src}/${code}.fd
     make >> $outfile
     echo " Moving ${code} to ${exec} " >> $outfile

     mv ${code} ${dir_src}/../../${exec}
     make clean
     echo ' ' >> $outfile
     cd ${dir_src}
 fi

fi




