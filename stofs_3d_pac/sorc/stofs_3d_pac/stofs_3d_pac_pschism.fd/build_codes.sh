#!/bin/sh


### cd /apps/sw_review/nos/schism
cd /lfs/h1/nos/estofs/noscrub/L.Shi/schism_new_ver_fromDan_stampede3

source ./stofs_3d_atl.build_load_modules 
module list

export COMP_F=ftn
export COMP_F_MPI90=ftn
export COMP_F_MPI=ftn
export COMP_CC=cc

cd ./src

# clean
  make clean

# "make all" creates the pschism exe file,  ./src/pschism_WCOSS2_VL
   make all


