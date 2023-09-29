#!/bin/sh
###############################################################################
#                                                                             #
# Compiles all codes, moves executables to exec and cleans up                 #
#                                                                             #
#                                                                 Feb, 2016   #
#                                                                 Jun, 2020   #
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

  source ../../versions/stofs_2d_glo/build.ver
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
                echo " Copy $exename to stofs_2d_glo_${exename} at exec " >> $outfile
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
          echo " Moving $code to exec " >> $outfile
          make clean
          echo ' ' >> $outfile
          cd ..
       fi
     done
  fi

# 3. Create all execution with debug
  if [ $1 -eq "debug" ]; then
     for code in $fcodes; do 
       if [ ${code} == "stofs_2d_glo_padcirc" ]; then
          echo " Making $code " >> $outfile
          cd ${code}.?d/work
          make all DEBUG=full >> $outfile
          if [ -s padcirc ]; then
             for exename in adcprep padcirc; do
                echo " Copy $exename to stofs_2d_glo_${exename} at exec " >> $outfile
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
          echo " Moving $code to exec " >> $outfile
          make clean
          echo ' ' >> $outfile
          cd ..
       fi
     done
  fi 

# 4. Create all execution with debug
  if [ $1 -eq "stofs_2d_glo_padcirc" ]; then
          echo " Making $1 " >> $outfile
          cd $1.?d/work
          if [ $2 == "debug" ]; then
             make all DEBUG=full >> $outfile
          else
             make all >> $outfile
          fi
          if [ -s padcirc ]; then
             for exename in adcprep padcirc; do
                echo " Copy $exename to stofs_2d_glo_${exename} at exec " >> $outfile
                cp -f $exename ../../../../exec/stofs_2d_glo/stofs_2d_glo_${exename}
             done
          fi
          make clean
          echo ' ' >> $outfile
          cd ../..
  fi

# 5. Clean all execution
  if [ $1 -eq "clean" ]; then
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
  fi
