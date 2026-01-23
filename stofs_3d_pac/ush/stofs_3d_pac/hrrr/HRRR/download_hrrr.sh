#!/bin/sh
set -x
#
DTOOL=${DTOOL:-curl}     ## DTOOL can be curl or wget
if [ $DTOOL = wget ] ; then OPN=O ; else OPN=o ; fi
mkdir -p $DATADIR
cd $DATADIR
FH=00
FH2=00
fh=00
FEND=`expr $FH + $ENDHOUR`
#
while [ $FH -le $FEND ]; do
   FH2=$FH
#   if [ $FH -lt 100 ]; then FH2=${FH:1:2}; fi
   if [ ! -f pgbf$FH2 ]
   then
      $DTOOL "https://nomads.ncep.noaa.gov/cgi-bin/filter_hrrr_2d.pl?file=hrrr.t${CYC}z.wrfsfcf${FH}.grib2&lev_10_m_above_ground=on&lev_2_m_above_ground=on&lev_mean_sea_level=on&lev_surface=on&var_DLWRF=on&var_DSWRF=on&var_MSLMA=on&var_PRATE=on&var_SPFH=on&var_TMP=on&var_UGRD=on&var_VGRD=on&subregion=&leftlon=${LONMIN}&rightlon=${LONMAX}&toplat=${LATMAX}&bottomlat=${LATMIN}&dir=%2Fhrrr.$iyr$imon$iday%2Fconus" -${OPN} pgbf$FH2

   fi
#  if [ $FH -ge 120 ]; then INCBASE=3 ; fi # 3 hour output after 120
   FH=`expr $FH + $INCBASE`
#   if [ $FH -lt 100 ]; then FH=0$FH; fi
   if [ $FH -lt 10  ]; then FH=0$FH; fi
   fh=`expr $FH `
   if [ $fh -lt 10  ]; then fh=0$fh; fi
done
cd -
