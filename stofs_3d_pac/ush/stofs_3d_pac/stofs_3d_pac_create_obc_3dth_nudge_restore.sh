#!/bin/bash

##################################################################################
#  Name: stofs_3d_pac_create_obc_3dth_nudge.sh                                   #
#  This script reads the NCEP/G-RTOFS data to create the STOFS_3D_PAC open       #
#  bouary forcing files, stofs_3d_pac.t12z.{elev2dth,uv3dth,tem3dth,sal3dth}.nc  #
#  and the bundary nudging files, stofs_3d_pac.t12z.{temnu,salnu}.nc.            #
#                                                                                #
#  Remarks:                                                                      #
#                                                              September, 2022   #
##################################################################################

# ---------------------------> Begin ...
# set -x

  fn_this_script="stofs_3d_pac_create_obc_3dth_nudge.sh"

  echo "${fn_this_script} started at UTC `date -u +%Y%m%d%H`"

  echo "module list in ${fn_this_script}"
  module list
  echo; echo

# ---------------------------> directory/file names
  dir_wk=${DATA_prep_rtofs}

  mkdir -p $dir_wk
  cd $dir_wk
  rm -rf ${dir_wk}/*

  mkdir -p ${dir_wk}/3dth
  mkdir -p ${dir_wk}/nudge
  mkdir -p ${dir_wk}/restore
  mkdir -p ${dir_wk}/outputs
  mkdir -p ${dir_wk}/link
  mkdir -p ${dir_wk}/tmp_sav
  mkdir -p ${dir_wk}/cnv_itp_nc
### gen_weight has to be copied or regenerated beforehand !!!
###  mkdir -p ${dir_wk}/cnv_itp_nc/gen_weight
  mkdir -p ${dir_wk}/aviso
  mkdir -p ${dir_wk}/aviso/outputs_src
  mkdir -p ${dir_wk}/aviso/link
  mkdir -p ${dir_wk}/aviso/3dth
  mkdir -p ${dir_wk}/aviso/psuado_nc

  mkdir -p ${COMOUTrerun}

  pgmout=pgmout_rtofs_obc_3dth_nudge.$$
  rm -f $pgmout

# ---------------------------> Global Variables
  fn_exe_gen_3Dth=${EXECstofs3d}/stofs_3d_pac_gen_3Dth_from_hycom
  fn_exe_gen_3Dth_new=${EXECstofs3d}/stofs_3d_pac_gen_3Dth_from_hycom_new
  fn_exe_gen_nudge=${EXECstofs3d}/stofs_3d_pac_gen_nudge_from_hycom

ln -sf ${FIXstofs3d}/rtofs_cvtST.nco ${dir_wk}/cvtST.nco
ln -sf ${FIXstofs3d}/rtofs_cvtUV.nco ${dir_wk}/cvtUV.nco
ln -sf ${FIXstofs3d}/rtofs_cvtZ.nco ${dir_wk}/cvtZ.nco

ln -sf ${FIXstofs3d}/rtofs_cvtST_cnv_itp_nc.nco ${dir_wk}/cnv_itp_nc/cvtST.nco
cp -rp ${FIXstofs3d}/rtofs_cnv_itp_nc_gen_weight ${dir_wk}/cnv_itp_nc/gen_weight
cp -rp ${FIXstofs3d}/rtofs_weight_rtofs_neareststod.nc ${dir_wk}/cnv_itp_nc/weight_rtofs_neareststod.nc

cp -rp ${EXECstofs3d}/stofs_3d_pac_gen_3Dth_from_hycom ${dir_wk}/3dth/gen_3Dth_from_hycom
cp -rp ${EXECstofs3d}/stofs_3d_pac_gen_3Dth_from_hycom ${dir_wk}/3dth/gen_3Dth_from_hycom.exe
ln -sf ${FIXstofs3d}/rtofs_gen_3Dth_from_nc.in ${dir_wk}/3dth/gen_3Dth_from_nc.in
ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.gr3 ${dir_wk}/3dth/hgrid.gr3
ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.ll ${dir_wk}/3dth/hgrid.ll
ln -sf ${FIXstofs3d}/stofs_3d_pac_vgrid.in ${dir_wk}/3dth/vgrid.in

cp -rp ${EXECstofs3d}/stofs_3d_pac_gen_nudge_from_hycom ${dir_wk}/nudge/gen_nudge_from_hycom
ln -sf ${FIXstofs3d}/rtofs_gen_nudge_from_nc.in ${dir_wk}/nudge/gen_nudge_from_nc.in
ln -sf ${FIXstofs3d}/stofs_3d_pac_tem_nudge.gr3 ${dir_wk}/nudge/TEM_nudge.gr3
ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.gr3 ${dir_wk}/nudge/hgrid.gr3
ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.ll ${dir_wk}/nudge/hgrid.ll
ln -sf ${FIXstofs3d}/stofs_3d_pac_vgrid.in ${dir_wk}/nudge/vgrid.in

cp -rp ${EXECstofs3d}/stofs_3d_pac_gen_nudge_from_hycom ${dir_wk}/restore/gen_nudge_from_hycom
ln -sf ${FIXstofs3d}/rtofs_gen_restore_from_nc.in ${dir_wk}/restore/gen_nudge_from_nc.in
ln -sf ${FIXstofs3d}/stofs_3d_pac_tem_nudge.gr3 ${dir_wk}/restore/TEM_nudge.gr3
ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.gr3 ${dir_wk}/restore/hgrid.gr3
ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.ll ${dir_wk}/restore/hgrid.ll
ln -sf ${FIXstofs3d}/stofs_3d_pac_vgrid.in ${dir_wk}/restore/vgrid.in

# ---------------------------> file names

# ---------------------------> roi: for nudging nc & 3Dth.nc

###idx_x1_3dz=221
###idx_x2_3dz=2588
###idx_y1_3dz=675
###idx_y2_3dz=1875

# --------------------------> dates
  yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
  yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}
# --------------------------> copy .sh, noc, lon, lat to $dir_wk/src/oper_script

# --------------------------> do all necessary preparation
###idate0=${yyyymmdd_today}
###idate=$(date -d"$idate0 - 1 day" +"%Y%m%d")

# --------------------------> processing getRTOFS_now.sh 
if [[ 1 -eq 1 ]]; then

#getRTOFS
### ./getRTOFS_now.sh #6mins
cd ${dir_wk}
rm -rf ${dir_wk}/tmp_sav/*

ofn=("t" "s" "u" "v")

idate0=${yyyymmdd_today}

idate=$(date -d"$idate0 - 1 day" +"%Y%m%d")
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_2ds_n012_diag.nc ./tmp_sav/ssh_${idate}12.nc
      ls -rtl ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_2ds_n012_diag.nc
      pwd
      echo ./tmp_sav/ssh_${idate}12.nc
for str in ${ofn[@]};
    do
      ln -sf ${COMINrtofs}/rtofs.${idate}/rtofs_glo_3dz_n024_daily_3z${str}io.nc ./tmp_sav/${str}3z_${idate}00.nc
done

idate=$(date -d"$idate0 - 0 day" +"%Y%m%d")
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_2ds_f012_diag.nc ./tmp_sav/ssh_${idate}12.nc
for str in ${ofn[@]};
    do
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_3dz_n024_daily_3z${str}io.nc ./tmp_sav/${str}3z_${idate}00.nc
done

idate=$(date -d"$idate0 + 1 day" +"%Y%m%d")
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_2ds_f036_diag.nc ./tmp_sav/ssh_${idate}12.nc
for str in ${ofn[@]};
    do
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_3dz_f024_daily_3z${str}io.nc ./tmp_sav/${str}3z_${idate}00.nc
done

idate=$(date -d"$idate0 + 2 day" +"%Y%m%d")
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_2ds_f060_diag.nc ./tmp_sav/ssh_${idate}12.nc
for str in ${ofn[@]};
    do
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_3dz_f048_daily_3z${str}io.nc ./tmp_sav/${str}3z_${idate}00.nc
done

idate=$(date -d"$idate0 + 3 day" +"%Y%m%d")
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_2ds_f084_diag.nc ./tmp_sav/ssh_${idate}12.nc
for str in ${ofn[@]};
    do
      ln -sf ${COMINrtofs}/rtofs.${idate0}/rtofs_glo_3dz_f072_daily_3z${str}io.nc ./tmp_sav/${str}3z_${idate}00.nc
done

###start0=$(date -d"$idate0 + 1 day" +"%Y%m%d")
###start=$(date -d"$idate0 + 0 day" +"%Y%m%d")
###end=$(date -d"$idate0 - 3 day" +"%Y%m%d")
###start0=$(/bin/date --date='1 days ago' +%Y%m%d) #1
###start=$(/bin/date --date='0 days ago' +%Y%m%d) #0
###end=$(/bin/date --date='-3 days ago' +%Y%m%d) #-2

fi
# --------------------------> processing convert_rtofs  
if [[ 1 -eq 1 ]]; then

###./convert_rtofs.sh #12mins
# example: convert_rtofs.sh 20110101 20110201
#
# This tool requires nco

  cd $dir_wk
idate0=${yyyymmdd_today}
idate=$(date -d"$idate0 - 1 day" +"%Y%m%d")

start0=$(date -d"$idate0 - 1 day" +"%Y%m%d")
#start=$(date -d"$idate0 + 0 day" +"%Y%m%d")
start=${start0}
end=$(date -d"$idate0 + 3 day" +"%Y%m%d")

#Subset region, original is 2D domain
#corresponding index in global data are
#i=223:2704/j=1052:2642
id_gx1=222
id_gx2=2703
isk_x=2
id_gy1=1051
id_gy2=2641
isk_y=2

echo start$start
echo end$end

while [[ $start -le $end ]]
do

     echo "SSH",$start
    #SSH file
     ncks -d X,$id_gx1,$id_gx2,$isk_x -d Y,$id_gy1,$id_gy2,$isk_y ./tmp_sav/ssh_${start}12.nc ./test0.nc
     ncatted -O -a _FillValue,ssh,d,, test0.nc
     ncap2 -O -s 'where(ssh>10000) ssh=-30000' test0.nc test1.nc
     ncatted -O -a _FillValue,ssh,a,f,-30000 test1.nc
     ncap2 -O -S cvtZ.nco test1.nc test2.nc
     ncrename -v lon,xlon -v lat,ylat  test2.nc
     ncatted -a valid_range,surf_el,d,, test2.nc
     ncks -O --mk_rec_dmn MT test2.nc -o test3.nc
     mv test3.nc outputs/SSH_${start}.nc
     rm -f ./test?.nc

     #read -n 1 -s

     echo "ST",$start
    #ST file 
     ncks -d X,$id_gx1,$id_gx2,$isk_x -d Y,$id_gy1,$id_gy2,$isk_y ./tmp_sav/t3z_${start}00.nc ./test0.nc
     ncks -d X,$id_gx1,$id_gx2,$isk_x -d Y,$id_gy1,$id_gy2,$isk_y ./tmp_sav/s3z_${start}00.nc ./test0_s.nc
     ncks -A -v salinity test0_s.nc test0.nc
     ncatted -O -a _FillValue,temperature,d,, test0.nc
     ncatted -O -a _FillValue,salinity,d,, test0.nc
     ncap2 -O -s 'where(temperature>10000) temperature=-30000' test0.nc test1.nc
     ncap2 -O -s 'where(salinity>10000) salinity=-30000' test1.nc test2.nc
     ncatted -O -a _FillValue,temperature,a,f,-30000 test2.nc
     ncatted -O -a _FillValue,salinity,a,f,-30000 test2.nc
     ncks -v temperature,salinity test2.nc test3.nc
     ncap2 -O -S cvtST.nco test3.nc test4.nc
     ncrename -v lon,xlon -v lat,ylat  test4.nc
     ncks -O --mk_rec_dmn MT test4.nc -o test5.nc
     mv test5.nc outputs/ST_${start}.nc
     rm -f ./test*.nc 

     echo "UV",$start
    #UV file
     #test0.nc from previous one to save time 
     ncks -d X,$id_gx1,$id_gx2,$isk_x -d Y,$id_gy1,$id_gy2,$isk_y ./tmp_sav/u3z_${start}00.nc ./test0.nc
     ncks -d X,$id_gx1,$id_gx2,$isk_x -d Y,$id_gy1,$id_gy2,$isk_y ./tmp_sav/v3z_${start}00.nc ./test0_v.nc
     ncks -A -v v test0_v.nc test0.nc
     ncatted -O -a _FillValue,u,d,, test0.nc
     ncatted -O -a _FillValue,v,d,, test0.nc
     ncap2 -O -s 'where(u>10000) u=-30000' test0.nc test1.nc
     ncap2 -O -s 'where(v>10000) v=-30000' test1.nc test2.nc
     ncatted -O -a _FillValue,u,a,f,-30000 test2.nc
     ncatted -O -a _FillValue,v,a,f,-30000 test2.nc
     ncks -v u,v test2.nc test3.nc
     ncap2 -O -S cvtUV.nco test3.nc test4.nc
     ncrename -v lon,xlon -v lat,ylat  test4.nc
     ncks -O --mk_rec_dmn MT test4.nc -o test5.nc
     mv test5.nc outputs/UV_${start}.nc
     rm -f ./test*.nc 

#  fi
#   forward date
     start=$(date -d"$start + 1 day" +"%Y%m%d")
done

fi
# --------------------------> processing link.sh  
if [[ 1 -eq 1 ]]; then

#Link files
###./link.sh  #4mins

cd ${dir_wk}/link
#rm old link
rm -f ./*.nc

idate0=${yyyymmdd_today}
idate=$(date -d"$idate0 - 1 day" +"%Y%m%d")

# Time range: -2~0 days to avoid vacancy
ict1=0
for ((iday=0;iday<=4; iday=iday+1))
   do
     echo $iday
     fday=$(date -d"$idate + $iday day" +"%Y%m%d")
     echo $fday

   #Link SSH
   if [ -f ../outputs/SSH_${fday}.nc ]
      then
        ict1=$(($ict1+1))
        ln -s ../outputs/SSH_${fday}.nc .
        final_day1=${fday}
        echo final${final_day1}
   else
        #Pretend data
        ln -s ../outputs/SSH_${final_day1}.nc ./SSH_${fday}.nc
        echo ../outputs/SSH_${final_day1}.nc
        echo ./SSH_${fday}.nc
   fi
   #Link ST 
   if [ -f ../outputs/ST_${fday}.nc ]
      then
        ict1=$(($ict1+1))
        ln -s ../outputs/ST_${fday}.nc .
        final_day2=${fday}
        echo final${final_day2}
   else
        #Pretend data
        ln -s ../outputs/ST_${final_day2}.nc ./ST_${fday}.nc
   fi
   #Link UV 
   if [ -f ../outputs/UV_${fday}.nc ]
      then
        ict1=$(($ict1+1))
        ln -s ../outputs/UV_${fday}.nc .
        final_day3=${fday}
        echo final${final_day1}
   else
        #Pretend data
        ln -s ../outputs/UV_${final_day3}.nc ./UV_${fday}.nc
   fi
done

#Check link
if [ $ict1 -eq 0 ]  ;
   then
     echo "No files to link!"  > ../nofile_in_rtofs
   else
     ncrcat -O SSH*nc ../SSH_1.nc.0
     ncrcat -O ST*nc ../TS_1.nc.0
     ncrcat -O UV*nc ../UV_1.nc.0
fi

#Change permission
pwd
cd ${dir_wk}
pwd
chmod 644 outputs/*.nc

fi
# --------------------------> processing cnv_itp_run.sh  
if [[ 1 -eq 1 ]]; then

#Gen itp-nc, about 3mins
cd ${dir_wk}/cnv_itp_nc
ln -sf ../UV_1.nc.0 UV_1.nc.0 
ln -sf ../TS_1.nc.0 TS_1.nc.0 
ln -sf ../SSH_1.nc.0 SSH_1.nc.0 

###./cnv_itp_run.sh
#cd /home1/06923/hyu05/work/oper_3D_Pac_stamp3/rtofs/cnv_itp_nc
#This took 3 mins
#date
#SSH
ncrename -d X,lon -d Y,lat SSH_1.nc.0 SSH_1.nc.rd
ncks -v surf_el,Longitude,Latitude SSH_1.nc.rd SSH_1.nc.rd.sink
ncremap -i SSH_1.nc.rd.sink -m weight_rtofs_neareststod.nc -o SSH_1.nc.rd.sink.itp
ncap2 -O -s "xlon=float(lon);ylat=float(lat)" SSH_1.nc.rd.sink.itp SSH_1.nc.rd.sink.itp.final
rm -f SSH_1.nc.rd SSH_1.nc.rd.sink SSH_1.nc.rd.sink.itp
#TS
ncrename -d X,lon -d Y,lat TS_1.nc.0 TS_1.nc.rd
ncks -v temperature,salinity,Longitude,Latitude TS_1.nc.rd TS_1.nc.rd.sink
ncpdq -U TS_1.nc.rd.sink TS_1.nc.rd.sink.unpack
ncremap -i TS_1.nc.rd.sink.unpack -m weight_rtofs_neareststod.nc -o TS_1.nc.rd.sink.itp
#ncap2 -O -s "xlon=float(lon);ylat=float(lat);depth=Depth" TS_1.nc.rd.sink.itp TS_1.nc.rd.sink.itp.final
ncap2 -O -S cvtST.nco TS_1.nc.rd.sink.itp TS_1.nc.rd.sink.itp.final
rm -f TS_1.nc.rd TS_1.nc.rd.sink TS_1.nc.rd.sink.itp TS_1.nc.rd.sink.unpack
#UV
ncrename -d X,lon -d Y,lat UV_1.nc.0 UV_1.nc.rd
ncks -v water_u,water_v,Longitude,Latitude UV_1.nc.rd UV_1.nc.rd.sink
ncremap -i UV_1.nc.rd.sink -m weight_rtofs_neareststod.nc -o UV_1.nc.rd.sink.itp
ncap2 -O -s "xlon=float(lon);ylat=float(lat);depth=Depth" UV_1.nc.rd.sink.itp UV_1.nc.rd.sink.itp.final
rm -f UV_1.nc.rd UV_1.nc.rd.sink UV_1.nc.rd.sink.itp
#date
cd ${dir_wk}
ln -sf cnv_itp_nc/UV_1.nc.rd.sink.itp.final UV_1.nc 
ln -sf cnv_itp_nc/TS_1.nc.rd.sink.itp.final TS_1.nc
ln -sf cnv_itp_nc/SSH_1.nc.rd.sink.itp.final SSH_1.nc 

fi

# --------------------------> processing adt 
if [[ 1 -eq 1 ]]; then
# prepare all ncessary inptu files in the directory
cd ${dir_wk}/aviso

ln -sf ${FIXstofs3d}/adt_cvtZ_src.nco ${dir_wk}/aviso/cvtZ_src.nco
cd ${dir_wk}/aviso/psuado_nc
ln -sf ${FIXstofs3d}/adt_TS_1.nc ${dir_wk}/aviso/psuado_nc/TS_1.nc
ln -sf TS_1.nc UV_1.nc

cd ${dir_wk}/aviso/3dth
ln -sf ${EXECstofs3d}/stofs_3d_pac_gen_3Dth_from_hycom ${dir_wk}/aviso/3dth/gen_3Dth_from_hycom.exe
cp -rp ${FIXstofs3d}/adt_gen_3Dth_from_nc.in ${dir_wk}/aviso/3dth/gen_3Dth_from_nc.in
ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.gr3 ${dir_wk}/aviso/3dth/hgrid.gr3
ln -sf ${FIXstofs3d}/stofs_3d_pac_hgrid.ll ${dir_wk}/aviso/3dth/hgrid.ll
ln -sf ${FIXstofs3d}/stofs_3d_pac_vgrid.in ${dir_wk}/aviso/3dth/vgrid.in
ln -sf ../psuado_nc/TS_1.nc TS_1.nc
ln -sf ../psuado_nc/UV_1.nc UV_1.nc
ln -sf ../SSH_1.nc SSH_1.nc


cd ${dir_wk}/aviso

###export PDYHH_FCAST_BEGIN=20250708
###export PDYHH_NCAST_BEGIN=20250707
  yyyymmdd_today=${PDYHH_FCAST_BEGIN:0:8}
  yyyymmdd_prev=${PDYHH_NCAST_BEGIN:0:8}
idate0=${yyyymmdd_today}
start=$(date -d"$idate0 -5 days" +"%Y%m%d")
end=$(date -d"$idate0 0 days" +"%Y%m%d")
start=$(date -d $start +%Y%m%d)
end=$(date -d $end +%Y%m%d)

while [[ $start -le $end ]]
do
     fday=$(date -d"$start" +"%Y-%m-%d")
     echo $fday
     echo $start

     if [ ! -f ./outputs_src/adt_${start}.nc ]
     then

ncks -O -v adt /lfs/h1/ops/prod/dcom/${start}/validation_data/marine/cmems/ssh/nrt_global_allsat_phy_l4_${start}_${start}.nc foo01_adt_only.nc
ncks -O -d latitude,-33.5,67.0 -d longitude,92.5,180.0 foo01_adt_only.nc foo02_west.nc
ncks -O -d latitude,-33.5,67.0 -d longitude,-180.0,-70.0 foo01_adt_only.nc foo02_east.nc
ncap2 -O -s 'where (longitude < 0.0) longitude=longitude+360' foo02_east.nc foo02_east.nc
ncks -O --mk_rec_dmn time foo02_west.nc foo02_west_time.nc
ncks -O --mk_rec_dmn time foo02_east.nc foo02_east_time.nc
ncpdq -O -a longitude,time  foo02_west_time.nc  foo02_west_time.nc
ncpdq -O -a longitude,time  foo02_east_time.nc  foo02_east_time.nc
ncrcat -O foo02_west_time.nc foo02_east_time.nc foo04_whole.nc
ncpdq -O -a time,longitude foo04_whole.nc foo04_whole.nc
ncks -O --fix_rec_dmn time foo04_whole.nc adt_test.nc

       ncks -O --mk_rec_dmn time adt_test.nc -o test1.nc
       ncrename -d longitude,xlon -d latitude,ylat test1.nc
       ncap2 -O -S cvtZ_src.nco test1.nc test1_out2.nc
       ncks -O -v xlon -v ylat -v surf_el test1_out2.nc -o final_adt.nc
       mv final_adt.nc ./outputs_src/adt_${start}.nc
       rm -f ./test1*.nc ./adt_test.nc
     else
       echo "adt_${start}.nc exist!"
     fi

     #Forward date
     start=$(date -d"$start + 1 day" +"%Y%m%d")

done

chmod 644 ./outputs_src/adt*nc
#./link.sh

###cd /home1/06923/hyu05/work/oper_3D_Pac_stamp3/aviso/link
cd ${dir_wk}/aviso/link
#rm old link
rm -f ./*.nc

# Time range: -2~0 days to avoid vacancy
ict1=0
for ((iday=1;iday>=-3; iday=iday-1))
###for ((iday=1;iday>=-2; iday=iday-1))
   do
     echo $iday
     fday=$(/bin/date --date="$iday days ago" +%Y%m%d)
     echo $fday
     niday=$((-$iday))
     echo $niday
     fday=$(date -d "$idate0 $niday days" +"%Y%m%d")
     echo $fday

   #Link ADT-original as SSH
   if [ -f ../outputs_src/adt_${fday}.nc ]
      then
        ict1=$(($ict1+1))
        ln -s ../outputs_src/adt_${fday}.nc ./SSH_${fday}.nc
        final_day=${fday}
   else
        #Pretend data
        ln -s ../outputs_src/adt_${final_day}.nc ./SSH_${fday}.nc
   fi
done

#Check link
if [ $ict1 -eq 0 ]  ;
   then
     echo "No files to link!"  > ../nofile_in_aviso
   else
     ncrcat -O SSH*nc ../SSH_1.nc
fi

### cd /home1/06923/hyu05/work/oper_3D_Pac_stamp3/aviso/3dth
#cd ${dir_wk}/aviso/3dt
#rm -f ./Pac.e*
#rm -f ./Pac.o*
#ln -sf ../SSH_1.nc .
###sbatch run_stamp3_skx #runtime is about 27 mins, set crontab earlier (before rtofs)

#./gen_3Dth_from_hycom.exe
#date
fi

# --------------------------> processing adt
if [[ 1 -eq 1 ]]; then

cd ${dir_wk}/aviso/3dth
rm -f ./Pac.e*
rm -f ./Pac.o*
ln -sf ../SSH_1.nc .
#sbatch run_stamp3_skx #runtime is about 27 mins, set crontab earlier (before rtofs)

./gen_3Dth_from_hycom.exe &
date

fi
# --------------------------> processing 3dth  
if [[ 1 -eq 1 ]]; then

#  Here took about 25 mins to dl & process nc, the following 3 can do concurrently
#Gen th.nc, ~ 40mins with origin-nc, 11mins with itp-nc
cd ${dir_wk}/3dth
pwd
ln -sf ../UV_1.nc UV_1.nc 
ln -sf ../TS_1.nc TS_1.nc 
ln -sf ../SSH_1.nc SSH_1.nc 
./gen_3Dth_from_hycom.exe &

fi

# --------------------------> processing nudge  
if [[ 1 -eq 1 ]]; then

#Gen nu.nc, ~ 20mins with origin-nc, 3mins with itp-nc
cd ${dir_wk}/nudge 
pwd
ln -sf ../TS_1.nc TS_1.nc 
./gen_nudge_from_hycom &

fi
# --------------------------> processing  restore
if [[ 1 -eq 1 ]]; then

#Gen restore.nc , > 2 hours with origin-nc, 5 mins with itp-nc
cd ${dir_wk}/restore 
pwd
ln -sf ../TS_1.nc TS_1.nc 
./gen_nudge_from_hycom &
pwd
wait
#Total time is 25 mins + 11mins= 36 mins

fi
# --------------------------> processing  make a copy of elev2D.th.nc
if [[ 1 -eq 1 ]]; then
### below will be tested but without replace thertofs reaults for now
### cp -rp ${dir_wk}/aviso/3dth/elev2D.th.nc ${dir_wk}/3dth/elev2D.th.nc 
#what to do with elev2D.th.nc. Find the size, if large than certain number, make a copy
adt_elev2d_size=50000
adt_elev2d_real_size=$((`wc -c ${dir_wk}/aviso/3dth/elev2D.th.nc | awk '{print $1}'`)) 
rtofs_elev2d_real_size=$((`wc -c ${dir_wk}/3dth/elev2D.th.nc | awk '{print $1}'`)) 
       if [[ ${adt_elev2d_real_size} -gt ${adt_elev2d_size} ]] && [[ ${rtofs_elev2d_real_size} -gt ${adt_elev2d_size} ]]; then 

basef01=${dir_wk}/aviso/3dth/elev2D.th
basef02=${dir_wk}/3dth/elev2D.th
ncap2 -O -s "time_series=time_series - time_series(0,:,:,:); time_step=time_step - time_step" ${basef02}.nc goo02.nc
ncks -O -d time,0,0 ${basef01}.nc goo06.nc
ncrcat -O goo06.nc goo06.nc goo06.nc goo06.nc goo06.nc goo07.nc
ncbo -O --op_typ=add goo02.nc goo07.nc goo04.nc
mv goo04.nc ${dir_wk}/aviso/3dth/elev2D.th.nc
rm goo*.nc

            cp -rp ${dir_wk}/aviso/3dth/elev2D.th.nc ${dir_wk}/3dth/elev2D.th.nc  
            echo ${adt_elev2d_size}
            echo ${adt_elev2d_real_size}
       elif [[ ${adt_elev2d_real_size} -gt ${adt_elev2d_size} ]]; then
            cp -rp ${dir_wk}/aviso/3dth/elev2D.th.nc ${dir_wk}/3dth/elev2D.th.nc  
            echo ${adt_elev2d_size}
            echo ${adt_elev2d_real_size}
       fi
fi

# --------------------------> processing  
if [[ 1 -eq 1 ]]; then

#rm old files
###rmfn=$(/bin/date --date="90 days ago" +%Y%m%d)
rmfn=$(date -d"$idate 90 days ago" +"%Y%m%d")
cd ${dir_wk}/outputs
pwd
rm -f ./*_${rmfn}.nc

fi 

if [[ 1 -eq 1 ]]; then
cd ${dir_wk}/restore
basef=surface_restore
startfile=${basef}.nc
ncks -O -d time,0,3 ${startfile} goo01.nc
ncks -O -d time,1,4 ${startfile} goo02.nc
ncap2 -O -s 'defdim("ensemble",1);' goo01.nc goo01_ens.nc
ncap2 -O -s 'defdim("ensemble",1);' goo02.nc goo02_ens.nc
ncecat -O -u ensemble goo01_ens.nc goo02_ens.nc goo0102_combined_ens.nc
ncwa -O -a ensemble goo0102_combined_ens.nc goo0102_averaged.nc
ncks -O --mk_rec_dmn time goo0102_averaged.nc goo0102_averaged_unlimited.nc
cp -rp  goo0102_averaged_unlimited.nc ${basef}.nc
rm goo*.nc
fn_std=${RUN}.${cycle}.surface_restore.nc
cp -pf surface_restore.nc ${COMOUTrerun}/${fn_std}

cd ${dir_wk}/nudge
baseflist=("TEM_nu" "SAL_nu")
for basef in "${baseflist[@]}"; do
startfile=${basef}.nc
ncks -O -d time,0,3 ${startfile} goo01.nc
ncks -O -d time,1,4 ${startfile} goo02.nc
ncap2 -O -s 'defdim("ensemble",1);' goo01.nc goo01_ens.nc
ncap2 -O -s 'defdim("ensemble",1);' goo02.nc goo02_ens.nc
ncecat -O -u ensemble goo01_ens.nc goo02_ens.nc goo0102_combined_ens.nc
ncwa -O -a ensemble goo0102_combined_ens.nc goo0102_averaged.nc
ncks -O --mk_rec_dmn time goo0102_averaged.nc goo0102_averaged_unlimited.nc
cp -rp  goo0102_averaged_unlimited.nc ${basef}.nc
rm goo*.nc
done
fn_std=${RUN}.${cycle}.temnu.nc
cp -pf TEM_nu.nc ${COMOUTrerun}/${fn_std}
fn_std=${RUN}.${cycle}.salnu.nc
cp -pf SAL_nu.nc ${COMOUTrerun}/${fn_std}

cd ${dir_wk}/3dth
baseflist=("elev2D.th" "TEM_3D.th" "SAL_3D.th" "uv3D.th")
for basef in "${baseflist[@]}"; do
startfile=${basef}.nc
ncks -O -d time,0,3 ${startfile} goo01.nc
ncks -O -d time,1,4 ${startfile} goo02.nc
ncap2 -O -s 'defdim("ensemble",1);' goo01.nc goo01_ens.nc
ncap2 -O -s 'defdim("ensemble",1);' goo02.nc goo02_ens.nc
ncecat -O -u ensemble goo01_ens.nc goo02_ens.nc goo0102_combined_ens.nc
ncwa -O -a ensemble goo0102_combined_ens.nc goo0102_averaged.nc
ncks -O --mk_rec_dmn time goo0102_averaged.nc goo0102_averaged_unlimited.nc
cp -rp  goo0102_averaged_unlimited.nc ${basef}.nc
rm goo*.nc
done
fn_std=${RUN}.${cycle}.uv3dth.nc
cp -pf uv3D.th.nc ${COMOUTrerun}/${fn_std}
fn_std=${RUN}.${cycle}.tem3dth.nc
cp -pf TEM_3D.th.nc ${COMOUTrerun}/${fn_std}
fn_std=${RUN}.${cycle}.sal3dth.nc
cp -pf SAL_3D.th.nc ${COMOUTrerun}/${fn_std}
fn_std=${RUN}.${cycle}.elev2dth.nc
cp -pf elev2D.th.nc ${COMOUTrerun}/${fn_std}
fi

### to be removed, useless script below
if [[ 1 -eq 0 ]]; then

#  cd ${dir_wk}/src/oper_script
  cd ${dir_wk}/final/outputs

# --------------------------> create {elev2D.th.nc, SAL_3D.th.nc, TEM_3D.th.nc, uv3D.th.nc}

# -------------------------------> create {TEM_nu.nc, SAL_nu.nc} 

# -------------------------------> create {surface_restore.nc} 

# ---------------------------------> QC & archive
list_var_ori=(elev2D.th TEM_3D.th SAL_3D.th uv3D.th TEM_nu SAL_nu)
list_var_std=(elev2dth tem3dth sal3dth uv3dth temnu salnu) 
list_end_time_step=(259200.0 259200.0 259200.0 259200.0 3.25 3.25) 
list_offset_time=(86400.0 86400.0 86400.0 86400.0 1.0 1.0)

# ${RUN}.${cycle}.temnu.nc

list_loop=(0 1 2 3 4 5)
N_dim_cr_min=4
N_dim_cr_max=4
list_fn_sz_cr=(46000 1200000 1200000 2400000 18000000 18000000)

for k in ${list_loop[@]}; do

fn_ori=${list_var_ori[k]}.nc
fn_std=${RUN}.${cycle}.${list_var_std[k]}.nc

echo $k, $fn_ori, $fn_std

   if [[ -s ${fn_ori} ]]; then 
       sz_k=$((`wc -c ${fn_ori} | awk '{print $1}'`)) 
       
       if [[ ${sz_k} -gt ${list_fn_sz_cr[$k]} ]]; then 
            dim_k=`ncdump -h  ${fn_ori}  | grep "time = UNLIMITED" | awk -F'(' '{print $2}' | awk -F' ' '{print $1}'`; 
 
            # apply wl offset
#            if [[ ${fn_ori} == "elev2D.th.nc" ]]; then
#               fn_non_offset=${fn_ori}_non_offset
#               mv ${fn_ori} ${fn_non_offset} 
#               ncap2 -O -S ${fn_nco_offset_wl_3dth}  ${fn_non_offset}  ${fn_ori}
#            fi

       else
            sz_k=$((0))
            dim_k=$((0))
       fi
   fi
   echo "dim=${dim_k}, sz_k-bytes=${sz_k}, sz_cr=${list_fn_sz_cr[$k]}"  

 
   flag_success=0
   time_end_step=${list_end_time_step[$k]}
   time_offset=${list_offset_time[$k]}

   if [[ ${dim_k} -ge ${N_dim_cr_max} ]]; then
      cpreq -pf ${fn_ori} ${COMOUTrerun}/${fn_std}
      echo "done: method - non-backup"
      flag_success=1  

   elif [[ ${dim_k} -ge ${N_dim_cr_min} ]]; then
      ncap2 -s "time(-1)=${time_end_step}" ${fn_ori} -O ${fn_std}
      cpreq -pf ${fn_std} ${COMOUTrerun}/${fn_std}
      echo "done: method - backup 1"    
      flag_success=1

   else 
      if [[ -f  ${COMOUT_PREV}/rerun/${fn_std} ]]; then 
         rm -f tmp*.nc

         fn_prev=prev_${fn_std}
         cpreq -pf ${COMOUT_PREV}/rerun/${fn_std} ${fn_prev}
         #fn_tmp1=tmp1_${fn_std}
         N_fn_prev=`ncdump -h ${fn_prev} | grep "time = UNLIMITED" | awk -F'(' '{print $2}' | awk -F' ' '{print $1}'`;

       if [[ ${N_fn_prev} -ge ${N_dim_cr_max} ]]; then                    
         fn_tmp1=tmp1_${fn_std}
         ncks -d time,4,,1 ${fn_prev} ${fn_tmp1}  
         #cpreq -pf ${COMOUT_PREV}/rerun/${fn_std} ${fn_tmp1}
         # time_offset=${list_offset_time[$k]}
         ncap2 -s "time=time-${time_offset}"  ${fn_tmp1} -O tmp2_${fn_std}
         ncap2 -s "time(-1)=${time_end_step}" tmp2_${fn_std}  -O ${fn_std}

         echo "time_offset= ${time_offset}, time_end_step= ${time_end_step}"
        
       fi        

         cpreq -pf ${fn_std} ${COMOUTrerun}/${fn_std}
         echo "done: method - backup 2"   
         flag_success=1 
      
      else
         msg="Warning: failed of (non-backup, backup1, backup 2) \n ${fn_std} Not created"
         echo -e ${msg}
      fi

   fi # if [[ ${dim_k} -ge ${N_dim_cr_max} ]]

done # for files

fi

  echo 
  echo "stofs_3d_pac_create_obc_forcing_rtofs.sh completed at date/time: " `date` 
  echo 

