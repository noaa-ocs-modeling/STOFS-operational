#!/bin/ksh
################################################################################
#
# Name:  getges.sh            Author:  Mark Iredell
#
# Abstract:
# This script copies the valid global guess file to a given file.
# Alternatively, it writes the name of the guess file to standard output.
# Specify option "-n network" for the job network (default global).
# Other options are gdas, gfs, cdas, mrf, prx, etc.
# Specify option "-e environment" for the job environment (default prod).
# Another option is test.
# Specify option "-f fhour" for the specific forecast hour wanted (default any).
# Specify option "-q" for quiet mode to turn off script messages.
# Specify option "-r resolution" for the resolution wanted (default high).
# Other options are 25464 17042, 12628, low, 6228, namopl, any.
# Specify option "-t filetype" for the filetype wanted from among these choices:
# sigges (default), siggm3, siggm2, siggm1, siggp1, siggp2, siggp3,
# sfcges, sfcgm3, sfcgm2, sfcgm1, sfcgp1, sfcgp2, sfcgp3,
# biascr, satang, satcnt, gesfil
# pgbges, pgiges, pgbgm6, pgigm6, pgbgm3, pgigm3, pgbgp3, pgigp3,
# sigcur, sfccur, pgbcur, pgicur, prepqc, tcvg12, tcvges, tcvitl, 
# enggrb, enggri, icegrb, icegri, snogrb, snogrb_high, snogri, sstgrb, sstgri.
# Specify option "-v valid" for the valid date wanted (default $CDATE).
# Currently, the valid hours specified must be a multiple of 3.
# Either 2-digit or 4-digit years are currently allowed.
# Specify positional argument to be the file to which to copy the guess.
# If missing, the NAME of the guess file is written to standard output.
# A nonzero return code from this script means either the arguments are invalid
# or the guess could not be found; a message is written to standard error in
# this case, but neither a file copy nor a standard output write will be done.
# The file returned is guaranteed to exist and be readable.
# The script uses the utility commands ndate and nhour.
#
# Example 1. Copy the production sigma guess for 1998100100 to the file sges.
#  getges.sh -e prod -t sigges -v 1998100100 sges 
#
# Example 2. Assign the pressure grib guess for the date 1998100121.
#  export CDATE=1998100121
#  export XLFUNIT_12="$(getges.sh -qt pgbges||echo /dev/null)"
#
# Example 3. Get the PRX pgb analysis or the best valid guess at 1998100112.
#  getges -e prx -t pgbcur -v 1998100112 pgbfile
#
# Example 5. Get the 24-hour GFS forecast sigma file valid at 1998100112.
#  getges -t sigcur -v 1998100112 -f 24 -e gfs sigfile
#
# History: 1996 December    Iredell       Initial implementation
#          1997 March       Iredell       Nine new filetypes
#          1997 April       Iredell       Two new filetypes and -f option
#          1997 December    Iredell       Four new filetypes
#          1998 April       Iredell       4-digit year allowed;
#                                         sigges internal date no longer checked
#          1998 May         Iredell       T170L42 defaulted; four new filetypes
#                                         and two filetypes deleted
#          1998 June        Rogers        Nam types added
#          1998 September   Iredell       high is default resolution
#          2000 March       Iredell       Cdas and -n option
#          2000 June        Iredell       Eight new filetypes
#          2002 April       Treadon       T254L64 defaulted; add angle dependent
#                                         bias correction file
#          2003 March       Iredell       GFS network out to 384 hours
#          2003 August      Iredell       Hourly global guesses
#          2005 September   Treadon       Add satellite data count file (satcnt)
#          2006 September   Gayno         Add high-res snow analysis
#          2009 January     Rogers        Added sfluxgrb file
#          2011 April       Rogers        Added GFS pg2ges file
#          2016 April       Yuji          Added GFS sflux grib2 file
#
################################################################################
#-------------------------------------------------------------------------------
# Set some default parameters.
set -x

fhbeg=00                         # hour to begin searching backward for guess
fhinc=01                         # hour to increment backward in search
fhend=384                        # hour to end searching backward for guess
#ndate=/nwprod/util/exec/ndate
#ndate=/gpfs/hps/nco/ops/nwprod/prod_util.v1.0.5/exec/ndate
#nhour=/nwprod/util/exec/nhour
#nhour=/gpfs/hps/nco/ops/nwprod/prod_util.v1.0.5/exec/nhour

#-------------------------------------------------------------------------------
# Get options and arguments.
netwk=global                     # default network
envir=prod                       # default environment
fhour=any                        # default forecast hour
quiet=NO                         # default quiet mode
resol=high                       # default resolution
typef=sigges                     # default filetype
valid=${CDATE:-'?'}              # default valid date
valid=$CDATE                     # default valid date
err=0
while getopts n:e:f:qr:t:v: opt;do
 case $opt in
  n) netwk="$OPTARG";;
  e) envir="$OPTARG";;
  f) fhour="$OPTARG";;
  q) quiet=YES;;
  r) resol="$OPTARG";;
  t) typef="$OPTARG";;
  v) valid="$OPTARG";;
  \?) err=1;;
 esac
done
shift $(($OPTIND-1))
gfile=$1
if [[ -z $valid ]];then
 echo "$0: either -v option or environment variable CDATE must be set" >&2
elif [[ $# -gt 1 ]];then
 echo "$0: too many positional arguments" >&2
elif [[ $err -ne 0 ]];then
 echo "$0: invalid option" >&2
fi
if [[ $gfile = '?' || $# -gt 1 || $err -ne 0 || -z $valid ||\
      $netwk = '?' || $envir = '?' || $fhour = '?' || $resol = '?' ||\
      $typef = '?' || $valid = '?' ]];then
 echo "Usage: getges.sh [-n network] [-e environment] [-f fhour] [-q] [-r resolution]" >&2
 echo "                 [-t filetype] [-v valid] [gfile]" >&2
 if [[ $netwk = '?' ]];then
  echo "         network choices:" >&2
  echo "           global (default), namopl, gdas, gfs, cdas, etc." >&2
 elif [[ $envir = '?' ]];then
  echo "         environment choices:" >&2
  echo "           prod (default), test, para, dump, prx" >&2
  echo "           (some network values allowed for compatibility)" >&2
 elif [[ $fhour = '?' ]];then
  echo "         fhour is optional specific forecast hour" >&2
 elif [[ $resol = '?' ]];then
  echo "         resolution choices:" >&2
  echo "           high (default), 25464, 17042, 12628, low, 6228, namopl, any" >&2
 elif [[ $typef = '?' ]];then
  echo "         filetype choices:" >&2
  echo "           sigges (default), siggm3, siggm2, siggm1, siggp1, siggp2, siggp3," >&2
  echo "           sfcges, sfcgm3, sfcgm2, sfcgm1, sfcgp1, sfcgp2, sfcgp3," >&2
  echo "           sfgges, sfggp3, biascr, satang, satcnt, gesfil" >&2
  echo "           pgbges, pgiges, pgbgm6, pgigm6, pgbgm3, pgigm3, pgbgp3, pgigp3," >&2
  echo "           sigcur, sfccur, pgbcur, pgicur, prepqc, tcvg12, tcvges, tcvitl," >&2
  echo "           enggrb, enggri, icegrb, icegri, snogrb, snogri, sstgrb, sstgri," >&2
  echo "           pg2cur, pg2ges, restrt" >&2
 elif [[ $valid = '?' ]];then
  echo "         valid is the valid date in yyyymmddhh or yymmddhh form" >&2
  echo "         (default is environmental variable CDATE)" >&2
 elif [[ $gfile = '?' ]];then
  echo "         gfile is the guess file to write" >&2
  echo "         (default is to write the guess file name to stdout)" >&2
 else
  echo "         (Note: set a given option to '?' for more details)" >&2 
 fi
 exit 1
fi
if [[ $envir != prod && $envir != test && $envir != para && $envir != dump && $envir != pr? && $envir != dev ]];then
 netwk=$envir
 envir=prod
 echo '************************************************************' >&2
 echo '* CAUTION: Using "-e" is deprecated in this case.          *' >&2
 echo '*          Please use "-n" instead.                        *' >&2       
 echo '************************************************************' >&2
fi
fhbeg=$($NHOUR $valid)
[[ $fhbeg -le 0 ]]&&fhbeg=00
((fhbeg=(10#$fhbeg-1)+1))
[[ $fhbeg -lt 10 ]]&&fhbeg=0$fhbeg
if [[ $typef = enggrb ]];then
 typef=icegrb
 echo '************************************************************' >&2
 echo '* CAUTION: Using "-t enggrb" is now deprecated.            *' >&2
 echo '*          Please use "-t icegrb".                         *' >&2       
 echo '************************************************************' >&2
elif [[ $typef = enggri ]];then
 typef=icegri
 echo '************************************************************' >&2
 echo '* CAUTION: Using "-t enggri" is now deprecated.            *' >&2
 echo '*          Please use "-t icegri".                         *' >&2       
 echo '************************************************************' >&2
fi

#-------------------------------------------------------------------------------
# Assemble guess list in descending order from the best guess.
geslist=""
geslist00=""

# GFS
if [[ $netwk = gfs ]];then
 fhend=384
 case $typef in
  sfgges) geslist='
   $COMINges/gfs.$day/${cyc}/atmos/gfs.t${cyc}z.sfluxgrbf$fh3.grib2' 
   ;;
  rtofs_a) geslist='
   $COMINrtofs/rtofs.$day/rtofs_glo.t${cyc}z.f$fh.archv.a'
   ;;
  rtofs_b) geslist='
   $COMINrtofs/rtofs.$day/rtofs_glo.t${cyc}z.f$fh.archv.b'
   ;;
 esac
fi

#-------------------------------------------------------------------------------
# Loop until guess is found.
fh=$fhbeg
while [[ $fh -le $fhend ]];do
 ((fhm6=10#$fh-6))
 [[ $fhm6 -lt 10 && $fhm6 -ge 0 ]]&&fhm6=0$fhm6
 ((fhm3=10#$fh-3))
 [[ $fhm3 -lt 10 && $fhm3 -ge 0 ]]&&fhm3=0$fhm3
 ((fhm2=10#$fh-2))
 [[ $fhm2 -lt 10 && $fhm2 -ge 0 ]]&&fhm2=0$fhm2
 ((fhm1=10#$fh-1))
 [[ $fhm1 -lt 10 && $fhm1 -ge 0 ]]&&fhm1=0$fhm1
 ((fhp1=10#$fh+1))
 [[ $fhp1 -lt 10 ]]&&fhp1=0$fhp1
 ((fhp2=10#$fh+2))
 [[ $fhp2 -lt 10 ]]&&fhp2=0$fhp2
 ((fhp3=10#$fh+3))
 [[ $fhp3 -lt 10 ]]&&fhp3=0$fhp3
 id=$($NDATE -$fh $valid)
 typeset -L8 day=$id
 typeset -R2 cyc=$id
 fh3="$(printf "%03d" $(( 10#$fh )) )"
 eval list=\$getlist$fh
 [[ -z $list ]]&&list=${geslist}
 for gestest in $list;do
  eval ges=$gestest
  [[ $quiet = NO ]]&&echo Checking: $ges >&2
  [[ -r $ges ]]&&break 2
 done
 fh=$((10#$fh+10#$fhinc))
 [[ $fh -lt 10 ]]&&fh=0$fh
done
if [[ $fh -gt $fhend ]];then
   echo "FATAL ERROR: $ges file did not exist" >&2
# echo getges.sh: unable to find $netwk.$envir.$typef.$resol.$valid >&2
   exit 8
fi

#-------------------------------------------------------------------------------
# Either copy guess to a file or write guess name to standard output.
if [[ -z "$gfile" ]];then
 echo $ges
 exit $?
else
 cpreq $ges $gfile
 exit $?
fi
