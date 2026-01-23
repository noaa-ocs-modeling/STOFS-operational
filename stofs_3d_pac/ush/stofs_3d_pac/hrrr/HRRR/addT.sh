#!/bin/bash
for ic in $(seq 1 6) 
do
ncap2 -Oh -s "tin=${ic}" -s "time@units=\"days since $iyr-$imon-$iday 00:00:00\"" -s "time@base_date ={ $iyr, $imon, $iday, 0}" -S addT.nco  -v pgbf0$ic.nc t00$ic.nc
done

for ic in $(seq 7 9) 
do
ncap2 -Oh -s "tin=${ic}" -s "time@units=\"days since $iyr-$imon-$iday 00:00:00\"" -s "time@base_date ={ $iyr, $imon, $iday, 0}" -S addT.nco  -v pgbf0$ic.nc t00$ic.nc
done

for ic in $(seq 10 48) 
do
ncap2 -Oh -s "tin=${ic}" -s "time@units=\"days since $iyr-$imon-$iday 00:00:00\"" -s "time@base_date ={ $iyr, $imon, $iday, 0}" -S addT.nco  -v pgbf$ic.nc t0$ic.nc
done

