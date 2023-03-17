#!/bin/bash
# --------------------------------------------------------------------------- #
# Script stofs_2d_glo_multistart.sh finds the latest hot start file for nowcast
# and forecast simulation
# --------------------------------------------------------------------------- #
# Start of stofs_2d_glo_multistart.sh script -------------------------------- #
# 1.  Set times
# 1.a Loop to find file

  set -x
  export date=$PDY
  export YMDH=${PDY}${cyc}

  wndh=3
  nowh=6

  ymdh=$YMDH
  iback=0

  while [ $iback -le $nback ]
  do
    ymdh=`$NDATE -$nowh $ymdh`
    pdate=`echo $ymdh | cut -c 1-8`
    pcyc=`echo $ymdh | cut -c 9-10`
    pdir=${COM}/${RUN}.${pdate}
    pfile=${RUN}.t${pcyc}z.$1

    if [ $COLDSTART = YES ]; then
       if [ -d $pdir ]; then
          set +e
          nr=`ls ${pdir}/$pfile 2> /dev/null | wc -l | awk '{print $1}'`
	  echo $nr
          set -e
          if [ $nr -gt 0 ]; then
             iback=$nback
          fi
       fi
       iback=`expr $iback + 1`
    else
       if [ -d $pdir ]; then
          set +e
          nr=`ls ${pdir}/$pfile 2> /dev/null | wc -l | awk '{print $1}'`
          set -e
          if [ $nr -gt 0 ]; then
             iback=$nback
          fi
       fi
       iback=`expr $iback + 1`
    fi
  done
  if [ $nr -eq 0 ]; then
     echo "FATAL ERROR: there are no $1 files, please restart with COLDSTART=YES"
     err_exit
  fi

# --------------------------------------------------------------------------- #
# 2.  Write time

  echo $ymdh > stofs_2d_glo_multistart.out

# End of stofs_2d_glo_multistart.sh script ---------------------------------- #
