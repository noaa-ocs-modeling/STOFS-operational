#!/bin/bash

#
# this script executes the makefiles for the stofs_2d_glo_codes
#

export COMP=ftn
export COMP_MPI=ftn
export C_COMP=cc
export C_COMP_MP=cc

# can override makefile target (only debug is valid)
target=none
if [[ $# -eq 1 && $1 == debug ]]
then
  target=debug
fi

#mkdir -p /../../sorc/stofs_2d_glo/exec

BASE=`pwd`
dir_mods="$(dirname ${BASE})"
dir_mod0="$(dirname ${dir_mods})"
echo ${dir_mod0}

source ./stofs_2d_glo_build
module list

if [ $target == none ]; then make > stofs_2d_glo.compile.code.log 2>&1; fi
if [ $target == debug ]; then make debug > stofs_2d_glo.compile.code.debug.log 2>&1; fi

