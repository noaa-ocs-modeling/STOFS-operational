#!/bin/bash
###################################################################
echo "----------------------------------------------------"
echo "exnawips - convert NCEP GRIB files into GEMPAK Grids"
echo "----------------------------------------------------"
echo "History: Mar 2000 - First implementation of this new script."
echo "S Lilly: May 2008 - add logic to make sure that all of the "
echo "                    data produced from the restricted ECMWF"
echo "                    data on the CCS is properly protected."
echo "         Apr 2012 - Modified version for stofs grids only"
#####################################################################

set -xa
msg="Starting stofs_2d_glo_gempak script"
echo "$msg"
postmsg "$jlogfile" "$msg"

export 'PS4=gempak_${domain}:$SECONDS + '

export domain=$1
export region=$2

if [ $# = 1 ]; then
  mkdir -m 775 $DATA/$domain
  cd $DATA/$domain
elif [ $# = 2 ]; then
  mkdir -m 775 $DATA/${domain}_${region}
  cd $DATA/${domain}_${region}
fi

# copy model specific tables
cpreq ${GEMfix}/${RUN}_g2varsncep1.tbl g2varsncep1.tbl
cpreq ${GEMfix}/${RUN}_g2vcrdwmo3.tbl g2vcrdwmo3.tbl

msg="Begin job for $jobid"
postmsg "$jlogfile" "$msg"

yymmdd=`echo $PDY | cut -c 3-8`
#
NAGRIB=nagrib2
GDDIAG=gddiag
#
#set default gempak variables
cpyfil=gds
garea=dset
gbtbls=
maxgrd=4999
kxky=
grdarea=
proj=
output=T
pdsext=no
gpack=none
glevel=0
gvcord=none
grdtyp=s
cpyfil=gds
anlyss="4/2;2;2;2"
proj_region="lcc/25.0;-95.0;25.0"

for fhr in `seq -w 0 180`; do
    fhr=f${fhr}
    if [ $# = 1 ]; then
       cpreq ${COMIN}/${RUN}.${cycle}.${domain}.${fhr}.grib2 ${RUN}.${cycle}.${domain}.${fhr}.grib2
       GRIBIN=${RUN}.${cycle}.${domain}.${fhr}.grib2
       GEMGRD=${RUN}_${domain}_${PDY}${cyc}${fhr}
       cpreq $GRIBIN grib${domain}.${fhr}

$NAGRIB << EOF
       GBFILE   = grib${domain}.${fhr}
       INDXFL   = 
       GDOUTF   = $GEMGRD
       PROJ     = $proj
       GRDAREA  = $grdarea
       KXKY     = $kxky
       MAXGRD   = $maxgrd
       CPYFIL   = $cpyfil
       GAREA    = $garea
       OUTPUT   = $output
       G2TBLS   = $gbtbls
       G2DIAG   = 
       PDSEXT   = $pdsext
       l
       r
EOF
       export err=$?;err_chk

       if [ $SENDCOM = "YES" ] ; then
          cpfs $GEMGRD $COMOUTgempak/$GEMGRD
       fi
       echo done > ${GEMGRD}.done

       if [ $SENDDBN = "YES" ] ; then
          $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job \
          $COMOUTgempak/$GEMGRD
       else
          echo "##### DBN_ALERT_TYPE is: ${DBN_ALERT_TYPE} - $COMOUTgempak/$GEMGRD #####"
       fi
    elif [ $# = 2 ];then
       if [ $domain = conus.east ]; then
          case $region in
               se ) grdarea_region="21;-85;35;-73"
                    kxky_region="462;538" ;;
               ne ) grdarea_region="33;-80;54;-60"
                    kxky_region="769;730" ;;
               gom) grdarea_region="19;-131;32;-80"
                    kxky_region="1960;500" ;;
          esac

       for elem in cwl swl htp; do
           if [ $elem == "cwl" ]; then
              gfunc=etcwl
              parm=
           elif [ $elem == "swl" ]; then
              gfunc=etsrg
              parm=surge_
           elif [ $elem == "htp" ]; then
              gfunc=elev
              parm=tides_
           fi

           GEMGRD=${RUN}_${domain}_${PDY}${cyc}${fhr}
           while [ ! -r $DATA/${domain}/${GEMGRD}.done ]; do
                 let ic=ic+1
                 if [ $ic -gt 600 ]; then
                    err_exit "$DATA/${domain}/${GEMGRD} is not available after waiting 10 minutes!"
                 fi
                 sleep 10
           done

           cpreq ${DATA}/${domain}/${GEMGRD} .
           GRIBIN_region=${GEMGRD}
           GEMGRD_region=${RUN}_${domain}_${region}_${PDY}${cyc}${fhr}

$GDDIAG << EOFGDDIAG
       GDFILE   = ${GRIBIN_region}
       GDOUTF   = ${GEMGRD_region}
       GFUNC    = $gfunc
       GDATTIM  = ${yymmdd}/${cyc}00${fhr}
       GLEVEL   = $glevel
       GVCORD   = $gvcord
       GRDNAM   = $gfunc^${yymmdd}/${cyc}00${fhr}
       GRDTYP   = $grdtyp
       GPACK    = $gpack
       GRDHDR   =
       PROJ     = $proj_region
       GRDAREA  = $grdarea_region
       KXKY     = $kxky_region
       MAXGRD   = $maxgrd
       CPYFIL   =
       ANLYSS   = $anlyss
       l
       r

EOFGDDIAG
       export err=$?;err_chk
       done

       if [ $SENDCOM = "YES" ] ; then
          cpfs $GEMGRD_region $COMOUTgempak/$GEMGRD_region
       fi

       if [ $SENDDBN = "YES" ] ; then
          $DBNROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job \
          $COMOUTgempak/$GEMGRD_region
       else
          echo "##### DBN_ALERT_TYPE is: ${DBN_ALERT_TYPE} - $COMOUTgempak/$GEMGRD_region #####"
       fi
       fi
    fi
done
gpend
#####################################################################
# GOOD RUN
set +x
echo "**************JOB $NET NAWIPS COMPLETED NORMALLY ON THE IBM"
echo "**************JOB $NET NAWIPS COMPLETED NORMALLY ON THE IBM"
echo "**************JOB $NET NAWIPS COMPLETED NORMALLY ON THE IBM"
set -x
#####################################################################

msg="Completing STOFS gempak script"
echo "$msg"
postmsg "$jlogfile" "$msg"

############################### END OF SCRIPT #######################
