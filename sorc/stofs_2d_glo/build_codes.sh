#!/bin/sh
###############################################################################
#                                                                             #
# Compiles all codes, moves executables to exec and cleans up                 #
#                                                                             #
#                                                                 Feb, 2016   #
#                                                                 Jun, 2020   #
#                                                                 Aug, 2022   #
#                                                                             #
###############################################################################
#
# --------------------------------------------------------------------------- #
# 1. Preparations: seek source codes to be compiled
export COMP=ftn
export COMP_MPI=ftn
export C_COMP=cc
export C_COMP_MP=cc

  fcodes=`ls -d *.fd | sed 's/\.fd//g'`
  echo " FORTRAN codes found: "$fcodes
  outfile=`pwd`/build_codes.out
  rm -f $outfile

  source ./stofs_2d_glo_build
  module list

# 2. Create all execution

  if [ $# -eq 0 ];then
     for code in $fcodes; do 
       if [ ${code} == "stofs_2d_glo_padcirc" ]; then
          echo " Making $code " >> $outfile
          cd ${code}.?d/work
          make all >> $outfile
          if [ -s padcirc ]; then
             for exename in adcprep padcirc; do
                echo " Copy $exename to stofs_2d_glo_${exename} at exec/stofs_2d_glo " >> $outfile
                cp -f $exename ../../../../exec/stofs_2d_glo/stofs_2d_glo_${exename}
             done
          fi
          make clean
          echo ' ' >> $outfile
          cd ../..
       else  
          echo " Making $code " >> $outfile
          cd ${code}.?d
          make >> $outfile
          echo " Moving $code to exec/stofs_2d_glo " >> $outfile
          make clean
          echo ' ' >> $outfile
          cd ..
       fi
     done
  elif [ $1 == "stofs_2d_glo_padcirc" ]; then
          echo " Making $1 " >> $outfile
          cd $1.?d/work
          if [ $2 == "debug" ]; then
             make all DEBUG=full >> $outfile
          else
             make all >> $outfile
          fi
          if [ -s padcirc ]; then
             for exename in adcprep padcirc; do
                echo " Copy $exename to stofs_2d_glo_${exename} at exec/stofs_2d_glo " >> $outfile
                cp -f $exename ../../../../exec/stofs_2d_glo/stofs_2d_glo_${exename}
             done
          fi
          make clean
          echo ' ' >> $outfile
          cd ../..
# 3. All execution with DEBUG=full
  elif [ $1 == "debug" ]; then
     for code in $fcodes; do 
       if [ ${code} == "stofs_2d_glo_padcirc" ]; then
          echo " Making $code " >> $outfile
          cd ${code}.?d/work
          make all DEBUG=full >> $outfile
          if [ -s padcirc ]; then
             for exename in adcprep padcirc; do
                echo " Copy $exename to stofs_2d_glo_${exename} at exec/stofs_2d_glo " >> $outfile
                cp -f $exename ../../../../exec/stofs_2d_glo/stofs_2d_glo_${exename}
             done
          fi
          make clean
          echo ' ' >> $outfile
          cd ../..
       else  
          echo " Making $code " >> $outfile
          cd ${code}.?d
          make DEBUG=full >> $outfile
          echo " Moving $code to exec/stofs_2d_glo " >> $outfile
          make clean
          echo ' ' >> $outfile
          cd ..
       fi
     done
# 4. Clean all execution
  elif [ $1 == "clean" ]; then
     for code in $fcodes; do
       if [ ${code} == "stofs_2d_glo_padcirc" ]; then
          echo " removing $code " >> $outfile
          cd ${code}.?d/work
          echo " clean $exename " >> $outfile
          make clean
          make clobber
          echo ' ' >> $outfile
          cd ../..
       else
          echo " removing $code " >> $outfile
          cd ${code}.?d
          make clean
          echo ' ' >> $outfile
          cd ..
       fi
     done
  else
          echo " Making $1 " >> $outfile
          cd $1.?d
          if [ $2 == "debug" ]; then
             make DEBUG=full >> $outfile
          else
             make >> $outfile
          fi
          echo " Moving $1 to exec/stofs_2d_glo " >> $outfile
          make clean
          echo ' ' >> $outfile
          cd ..
  fi
