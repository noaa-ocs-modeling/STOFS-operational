#!/bin/csh
cd /home1/06923/hyu05/work/oper_3D_Pac/sflux/HRRR_CB
rm -f ./HRRR_CB.e*
rm -f ./HRRR_CB.o*
sbatch run_serial_frontera 
