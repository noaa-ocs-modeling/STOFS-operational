#!/bin/bash

#Prepare files
#cd /home1/06923/hyu05/work/oper_3D_Pac/rtofs/final/nudge
###cd /sciclone/schism10/hyu05/NOAA_Pacific/rtofs_global_subset/frontera/rtofs/final/nudge
dir_wk=${DATA_prep_rtofs}
cd ${dir_wk}/final/nudge
rm -f ./$1_nu*.nc 
cp ../../indian_1/nudge/$1_nu.nc ./$1_nu_ind1.nc
cp ../../indian_2/nudge/$1_nu.nc ./$1_nu_ind2.nc
cp ../../pacific_1/nudge/$1_nu.nc ./$1_nu_pac1.nc
cp ../../pacific_2/nudge/$1_nu.nc ./$1_nu_pac2.nc
cp ../../pacific_3/nudge/$1_nu.nc ./$1_nu_pac3.nc
cp ../../arctic/nudge/$1_nu.nc ./$1_nu_arc.nc

#rename
ncrename -d node,node_ind1 -v map_to_global_node,map_to_global_node_ind1 -v tracer_concentration,tracer_concentration_ind1 $1_nu_ind1.nc
ncrename -d node,node_ind2 -v map_to_global_node,map_to_global_node_ind2 -v tracer_concentration,tracer_concentration_ind2 $1_nu_ind2.nc
ncrename -d node,node_pac1 -v map_to_global_node,map_to_global_node_pac1 -v tracer_concentration,tracer_concentration_pac1 $1_nu_pac1.nc
ncrename -d node,node_pac2 -v map_to_global_node,map_to_global_node_pac2 -v tracer_concentration,tracer_concentration_pac2 $1_nu_pac2.nc
ncrename -d node,node_pac3 -v map_to_global_node,map_to_global_node_pac3 -v tracer_concentration,tracer_concentration_pac3 $1_nu_pac3.nc
ncrename -d node,node_arc -v map_to_global_node,map_to_global_node_arc -v tracer_concentration,tracer_concentration_arc $1_nu_arc.nc

#sink to arc; arc is base
ncks -A -v map_to_global_node_ind1,tracer_concentration_ind1 $1_nu_ind1.nc $1_nu_arc.nc
ncks -A -v map_to_global_node_ind2,tracer_concentration_ind2 $1_nu_ind2.nc $1_nu_arc.nc
ncks -A -v map_to_global_node_pac1,tracer_concentration_pac1 $1_nu_pac1.nc $1_nu_arc.nc
ncks -A -v map_to_global_node_pac2,tracer_concentration_pac2 $1_nu_pac2.nc $1_nu_arc.nc
ncks -A -v map_to_global_node_pac3,tracer_concentration_pac3 $1_nu_pac3.nc $1_nu_arc.nc

#create new vars with new-dim
ncap2 -S ${dir_wk}/src/oper_script/add_dims.nco $1_nu_arc.nc $1_nu_final0.nc

#sink vars to new nc
ncks -v map_to_global_node_final,tracer_concentration_final $1_nu_final0.nc $1_nu_final.nc

#rename vars
ncrename -v map_to_global_node_final,map_to_global_node -v tracer_concentration_final,tracer_concentration -d node_final,node $1_nu_final.nc 

#cp files to outputs
cp $1_nu_final.nc ../outputs/$1_nu.nc

#subset final nc 
#./subset_nu.sh $1
