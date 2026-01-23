#!/bin/csh
cd /home1/06923/hyu05/work/oper_3D_Pac/sflux/HRRR_AK
rm -f ./HRRR_AK.e*
rm -f ./HRRR_AK.o*
sbatch run_serial_frontera $1
