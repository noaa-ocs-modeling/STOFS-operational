#!/bin/csh
cd /home1/06923/hyu05/work/oper_3D_Pac/sflux/HRRR
rm -f ./HRRR.e*
rm -f ./HRRR.o*
sbatch run_serial_frontera $1
