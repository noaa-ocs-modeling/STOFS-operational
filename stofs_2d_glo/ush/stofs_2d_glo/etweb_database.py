#!python3

#-----------------------------------------------------------------------------
# cron.tcl --
#     This program generates a graph which combines the extra-tropical storm
#   surge with a computed tide, and observations (where available) to create
#   an estimate of the combined water level.
#     It then attempts to ftp the resulting graph, associated text file,
#   and color coded map to www.nws.noaa.gov/mdl/etsurge.
#
# 10/2000 Arthur Taylor (RSIS/MDL) Created
#  5/2002 Arthur Taylor (RSIS/MDL) Updated
# 10/2023 Soroosh Mani (NOS/OCS/CSDL/CMMB) To Python
#
# Notes:
#-----------------------------------------------------------------------------
# Global variables:
#   RAY1(...)
#     tl          : Toplevel to use when using cronshow.tcl
#     statusList  : The stations for which I have calculated the status.
#                   Usually all stations...
#     Backup_list : The files for which we updated the Waterlevel...
#                   hence we need to "backup" these files on the web server.
#     got_surge   : Flag to say if we downloaded the surge files from the IBM
#
#     Wid         : The Width of the main gd image
#     Hei         : The Height of the main gd image
#     Beg_Time    : Start time of data
#     End_Time    : Stop time of data
#     Num_Hours   : Total hours of data ((end+beg)*24 +1)
#     <hr>        : is hours after Beg_Time.
#     (<hr>,cwl): 99.9 or cwl
#     (<hr>,obs): observation
#     (<hr>,anom): anom (obs-(cwl))
#     (<hr>,pred): cwl+anom
#
#     cwl         : List of (time cwl) pairs
#     obs         : List of (time obs) pairs
#     anom        : List of (time (obs-(cwl)) pairs
#     pred        : List of (time (cwl+anom))
#     now         : Time the program was sourced.
#     min_time    : Minimum Time to plot
#     max_time    : Maximum Time to plot
#   src_dir     : Path of the source directory.
#   CronShow    : 0 if no cronshow.tcl, 1 if cronshow.tcl
#-----------------------------------------------------------------------------

import argparse
import logging
import os
import sys
import shutil
import time
import urllib.request
from urllib.error import HTTPError
from datetime import datetime, timedelta
from pathlib import Path

import pytz
import numpy as np
import pandas as pd
import xarray as xr

sys.path.append(os.environ.get('LIBstofs'))  # OR set PYTHONPATH
import archive  # replace 'archive.tcl'


INTERNET = bool(int(os.environ.get('INTERNET', 0)))
DATA = Path(os.environ.get('DATA'))


# NOTE: Assuming UTC = GMT, although they are not technically the same
DT64REF = np.datetime64('1970-01-01T00:00:00')
GMT = pytz.timezone('gmt')
ZONES = {
    'CST': pytz.timezone('US/Central'),
    'EST': pytz.timezone('US/Eastern'),
    'HST': pytz.timezone('US/Hawaii'),
    'PST': pytz.timezone('US/Pacific'),
    'YST': pytz.timezone('US/Alaska'),
}


logging.basicConfig(filename=f'{DATA}/log/database.log', filemode='a')
_logger = logging.getLogger(__name__)


# NOTE: Numpy datetime is always meant to be utc time, a tz-aware 
# datetime set to xarray becomes a UTC tz-naive datetime in numpy!
# Sometimes xarray converts tz-aware datetime to pandas Timestamp object
# array which is still tz-aware, but strangely a tz-aware Timestamp
# that is set to xarray is stored as numpy utc tz-naive type!!
# ds = xr.Dataset()
# ds['time1'] = datetime.now()  # as numpy
# ds['time2'] = datetime.now(pytz.timezone('est'))  # as Timestamp
# ds['time3'] = ds.time2.item()  # converted to UTC and stored as numpy!!
#
# Let's go with storing datetim64 on xarray and assuming xarray datetimes
# are always stored in UTC



def _to_datetime(xr_dt64):
    ts = (np.datetime64(xr_dt64, 'ns') - DT64REF) / np.timedelta64(1, 's')
    return datetime.utcfromtimestamp(ts)


def parse_cli():

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--date', '-d',
        type=pd.to_datetime,
        help=(
            'Choice for date in ISO 8601-like format.'
            + 'If offset is not provided it\'s assumed to be UTC'
        )
    )

    args = parser.parse_args()


    return args


def process_cli(args):
    user = {}

    user['date'] = datetime.now(GMT)
    if args.date is not None:
        user['date'] = args.date

    print(f"Date chosen as {user['date'].strftime('%D %T')}")

    # Use tz-naive datetimes in GMT time
    for nm in ['date']:
        if user[nm].tzinfo is None:
            # If it's tz-naive assume it's in GMT
            continue

        # Else convert to GMT and make it naive
        user[nm] = user[nm].astimezone(GMT).replace(tzinfo=None)


    return user



#########################################################################
def Init_Time(ds, days_before, days_after):

    # All times are tz-naive and assumed to be in GMT
    nHrs = (days_after + days_before) * 24 + 1
    hrs = np.arange(nHrs)
    ret_ds = xr.Dataset(
        data_vars=dict(
            **ds.data_vars.variables,
            begTime=ds['cur'] - np.timedelta64(days_before, 'D'),
            endTime=ds['cur'] + np.timedelta64(days_after, 'D'),
            numHours=nHrs,
            # +1 to account for daylight saving adjustment cases
            cwl=('hr', np.ones(hrs.shape) * 99.9),
            obs=('hr', np.ones(hrs.shape) * 99.9),
        ),
        coords={
            **ds.coords.variables,
            'hr': hrs,
        },
        attrs=ds.attrs,
    )

    return ret_ds


#*******************************************************************************
# Procedure Read_WaterLevel
#
# Purpose:
#     Read a combined water level file looking for a particular station.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   file       (I) The combined waterlevel file in question.
#   name       (I) Name of the station.
#   month      (I) The month the combined water level file is valid for
#   year       (I) The year the combined water level file is valid for
#
# Returns: -1 if it didn't find the station.
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Adjusts ray(cwl)
#*******************************************************************************
def Read_WaterLevel(mut_ds, arch_file, file, month, year, name, temp_file):

    last_time = archive.Read_ArchCWL(mut_ds, arch_file)
    with open(file, 'r') as fp:
        line = fp.readline().split()
        day = int(line[2][0:2])
        hour = int(line[2][2:4])
        # tz-naive time created from file datetimes, assumed to be GMT
        time = datetime(year, month, day, hour, 0, 0)
        begTime = _to_datetime(mut_ds['begTime'].item())


        # If the following is NOT true, then we need to Update the
        # Archive file. else we are done.
        if not (time > last_time or pd.isna(last_time)):
            return 0

        backupList = mut_ds.attrs.setdefault('Backup_list', [])
        backupList.append(Path(arch_file).stem)

        # Remove ',' before the state code in crontab file
        name = name.lower()
        name2 = name.strip()
        nm_len = len(name2)
        name2 = f"{name[:nm_len - 4]}{name[nm_len - 3:]}"

        # Read the rest
        # cwl is a ref in xarray dataset's underlying array
        cwl = mut_ds.cwl.values
        hrs = mut_ds.hr
        for line in fp:
            # Name from the model file
            lower = line.lower()

            if name2 not in lower:
                continue

            wl = line[92:96]
            if wl == "****":
                wl = 99.9
            else:
                wl = float(wl) / 10

            # TODO: Check issue with ceil/floor
            tm_hr = int(
                (time - begTime).total_seconds() / 3600
            )
            if tm_hr not in hrs:
                continue
            # Assumption: tm_hr is the same as positional index
            cwl[tm_hr] = wl

            # For storage in New ArchCWL
            # tz-naive time assumed to be in GMT
            date = time.strftime('%m/%d/%Y %H')  # 13 char
            nm_tag = f'{name.upper():<75}'
            if len(name) > 74:
                nm_parts = name.upper().split(',')
                nm_stn = ''.join(nm_parts[:-1]).strip()
                nm_state = nm_parts[-1].strip()
                nm_tag = f'{nm_stn[:67]}...,{nm_state:>3} '  # 75 char

            line1 = (nm_tag + f'{date}{line[88:]}').strip('\n')


            line = fp.readline()
            # For storage in New ArchCWL
            line2 = line.strip('\n')
            for i in range(1, 25):
                wl = line[-4 + 4 * i:4 * i]
                if wl == "****":
                    wl = 99.9
                else:
                    wl = float(wl) / 10
                tm = time + timedelta(hours=i)
                # TODO: Check issue with ceil/floor
                tm_hr = int(
                    (tm - begTime).total_seconds() / 3600
                )
                if tm_hr not in hrs:
                    continue
                # Assumption: tm_hr is the same as positional index
                cwl[tm_hr] = wl


            line = fp.readline()
            # For storage in New ArchCWL
            line3 = line.strip('\n')
            for i in range(1, 25):
                wl = line[-4 + 4 * i:4 * i]
                if wl == "****":
                    wl = 99.9
                else:
                    wl = float(wl) / 10
                tm = time + timedelta(days=1, hours=i)
                # TODO: Check issue with ceil/floor
                tm_hr = int(
                    (tm - begTime).total_seconds() / 3600
                )
                if tm_hr not in hrs:
                    continue
                # Assumption: tm_hr is the same as positional index
                cwl[tm_hr] = wl


            line = fp.readline()
            # For storage in New ArchCWL
            line4 = line.strip('\n')
            for i in range(1, 25):
                wl = line[-4 + 4 * i:4 * i]
                if wl == "****":
                    wl = 99.9
                else:
                    wl = float(wl) / 10
                tm = time + timedelta(days=2, hours=i)
                # TODO: Check issue with ceil/floor
                tm_hr = int(
                    (tm - begTime).total_seconds() / 3600
                )
                if tm_hr not in hrs:
                    continue
                # Assumption: tm_hr is the same as positional index
                cwl[tm_hr] = wl


            line = fp.readline()
            # For storage in New ArchCWL
            line5 = line.strip('\n')
            for i in range(1, 25):
                wl = line[-4 + 4 * i:4 * i]
                if wl == "****":
                    wl = 99.9
                else:
                    wl = float(wl) / 10
                tm = time + timedelta(days=3, hours=i)
                # TODO: Check issue with ceil/floor
                tm_hr = int(
                    (tm - begTime).total_seconds() / 3600
                )
                if tm_hr not in hrs:
                    continue
                # Assumption: tm_hr is the same as positional index
                cwl[tm_hr] = wl

            Path(arch_file).parent.mkdir(exist_ok=True, parents=True)
            archive.Write_ArchCWL(
                mut_ds, arch_file, 
                line1, line2, line3, line4, line5,
                temp_file
            )

            return 0

        print(f"Didn't find {name}")
        return -1


#*******************************************************************************
# Procedure Read_ObsFile
#
# Purpose:
#     Read a file that contains a stations observations, for tide values,
#   and observation values.  (File was obtained by downloading it as a html
#   document, and stripping out stuff outside of <pre></pre> blocks.
#
# Variables:(I=input)(O=output)
#   ray_name   (I) Global array to store the data in.
#   obsFile    (I) The file to read the observations from.
#
# Returns: NULL
#
# History:
#    10/2000 Arthur Taylor created
#
# Notes:
#   Adjusts ray(obs)
#*******************************************************************************
def Read_ObsFile(mut_ds, obsFile, archFile, temp_file, days_before, mllw, msl):

    with open(temp_file, 'w') as ap:
        ap.write("Header line must be in .obs file\n")

        # The False is so we leave the observations in MLLW.
        last_time = archive.Read_ArchObs(mut_ds, archFile, ap, False)
        first_time = pd.NaT

        # Read in the observations.
        if obsFile is None:
            return

        unknown_hours = []
        unknown_replacement = {}
        with open(obsFile, 'r') as fp:
            line = fp.readline()
            begTime = _to_datetime(mut_ds['begTime'].item())
            hrs = mut_ds.hr
            # obs_ary is a ref into xarray dataset's underlying array
            obs_ary = mut_ds.obs.values
            for line in fp:
                dateTime = line.split(',')[0]
                date = dateTime.split()[0].split('-')
#                date = '/'.join([date[1], date[2], date[0]])
                try:
                    # Datetimes from the obs file is assumed to be in GMT
#                    time = pd.to_datetime(f'{date} {dateTime.split()[1]}:00')
                    time = datetime(
						year=int(date[0]),
						month=int(date[1]),
						day=int(date[2]),
						hour=int(dateTime.split()[1].split(':')[0]),
						minute=int(dateTime.split()[1].split(':')[1]),
                    )
                except:
                    continue

                cur_MinSec = time.strftime("%M%S")
                # tz-naive, assumed to be in GMT
                if cur_MinSec == "0000":
                    try:
                        obs = float(line.split(',')[1])
                    except ValueError:
                        obs = 99.9

                    # TODO: Check issue with ceil/floor
                    tm_hr = int(
                        (time - begTime).total_seconds() / 3600.
                    )
                    if tm_hr not in hrs:
                        continue

                    if pd.isna(first_time):
                        first_time = time   

                    if (obs < 99) and (obs > -99):
                        # Assumption: tm_hr is the same as positional index
                        obs_ary[tm_hr] = obs
                    else:
                        # Assumption: tm_hr is the same as positional index
                        obs_ary[tm_hr] = 99.9
                        unknown_hours.append(tm_hr)
                    
                elif cur_MinSec == "0600":
                    time = time - timedelta(minutes=6)
                    # TODO: Check issue with ceil/floor
                    tm_hr = int(
                        (time - begTime).total_seconds() / 3600.
                    )
                    if tm_hr not in hrs:
                        continue
                    try:
                        obs = float(line.split(',')[1])
                    except ValueError:
                        obs = 99.9
                    if (obs < 99) and (obs > -99):
                        unknown_replacement[(tm_hr, 2)] = obs
                    else:
                        unknown_replacement[(tm_hr, 2)] = 99.9

                elif cur_MinSec == "5400":
                    time = time + timedelta(minutes=6)
                    # TODO: Check issue with ceil/floor
                    tm_hr = int(
                        (time - begTime).total_seconds() / 3600.
                    )
                    if tm_hr not in hrs:
                        continue
                    try:
                        obs = float(line.split(',')[1])
                    except ValueError:
                        obs = 99.9
                    if (obs < 99) and (obs > -99):
                        unknown_replacement[(tm_hr, 3)] = obs
                    else:
                        unknown_replacement[(tm_hr, 3)] = 99.9


            for tm_hr in unknown_hours:
                left_value = unknown_replacement.get((tm_hr, 2), 99.9)
                right_value = unknown_replacement.get((tm_hr, 3), 99.9)
                has_replacement = (
                    left_value != 99.9 and right_value != 99.9
                )
                if not has_replacement:
                    continue


                # Assumption: tm_hr is the same as positional index
                obs_ary[tm_hr] = (left_value + right_value) / 2.0

            # TODO: No need to clear?
#            unknown_replacement.clear()

        #Store the new observations.
        if pd.isna(last_time) and not pd.isna(first_time):
            # First time might not be on the 00 hour
            first_time = first_time.replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            last_time = first_time - timedelta(hours=1)

        if not pd.isna(last_time):
            archive.Write_ArchObs(mut_ds, ap, last_time)

    Path(archFile).parent.mkdir(exist_ok=True, parents=True)
    shutil.copy(temp_file, archFile)
    Path(temp_file).unlink()



def Refresh(
    mut_ds,
    surge_stn,
    obs_stn,
    tide_stn,  # unused
    cwl_file,
    surge_flag,
    title,  # unused
    arch_cwl,
    temp_file,
    temp2_file,
    days_before,
    arch_obs,
    display_days,  # unused
    mllw,  # unused
    msl,  # unused
    mhhw,  # unused
    zone,  # unused
    mat,  # unused
    filt_anom,  # unused
):

    if surge_flag:
        if not mut_ds['got_surge']:
            print("Getting Anonymous Surge2")
            # NOTE: We don't need getdata in STOFS
            print(
                "This is already done by the code that massaged the"
                + " ESTOFS data into ETSS format."
                + "\nDon't grab more data into the /model folder."
            )
#            if not getdata.Get_Anonymous_Surge2(mut_ds):
#                _logger.error("had problems getting EtSurge data")
#                print("had problems getting EtSurge data")
#
#                mut_ds['got_surge'] = True:
#                _logger.info("Got data EtSurge")

        if 'cur' not in mut_ds:
            print("reading waterlevel file")
            with open(f'{DATA}/model/{cwl_file}', 'r') as fp:
                line = fp.readline()

            # NOTE: File times are assumed to be in GMT
            day = int(line.split()[2][:2])
            hour = int(line.split()[2][2:4])
            print(f"Hour: {hour} :Day :{day}")

            # Start at current time, and go backward in 24 hour steps
            # until day/hour match day/hour from water level file.
            # 
            # xarray stores in tz-naive datetime64 array
            # so `cur` is tz-naive and assumed to be in GMT
            cur = _to_datetime(mut_ds['now'].item())
            cur_day = cur.day
            while cur_day != day:
                cur -= timedelta(days=1)
                cur_day = cur.day

            # xarray stores in tz-naive datetime64 array
            mut_ds['cur'] = cur.replace(
                hour=hour, minute=0, second=0, microsecond=0
            )

    # Init Beg_time/End_time, and init ray elements to 99.9
    mut_ds = Init_Time(mut_ds, days_before, 4)

    mut_ds['min_time'] = pd.NaT
    mut_ds['max_time'] = pd.NaT

    # Need month year; note `mut_ds['cur']` is tz-naive assumed GMT
    month = _to_datetime(mut_ds['cur'].item()).month
    year = _to_datetime(mut_ds['cur'].item()).year

    Read_WaterLevel(
        mut_ds,
        arch_cwl,
        DATA / 'model' / cwl_file,
        month,
        year,
        surge_stn,
        temp_file
    )

    _logger.info("Have Read water levels.. Get obs?")

    if (obs_stn != "") and (obs_stn[0] != "?"):
        obs_stn = ""
    if obs_stn != "":
        stn = obs_stn.split('=')[1].split('+')[0]
        if INTERNET:
            beg = _to_datetime(mut_ds['begTime'].item())
            end = _to_datetime(mut_ds['endTime'].item())
            url = ('https://tidesandcurrents.noaa.gov/api/datagetter?'
                + 'product=water_level&application=NOS.COOPS.TAC.WL'
                + f'&begin_date={beg.strftime("%Y%m%d %H:%M")}'
                + f'&end_date={end.strftime("%Y%m%d %H:%M")}&time_zone=gmt'
                + f'&station={stn}&datum=MLLW&units=english&interval='
                + '&format=csv'
            ).replace(' ', '%20')
            try:
                fn, hdr = urllib.request.urlretrieve(url, temp_file)
            except HTTPError:
                print(f'Error retrieving station {stn}')
                obs_stn = ""

        else:
            # Copy obs from dcom
            shutil.copy(f'{DATA}/database/{stn}.csv', temp_file)

    _logger.info("Got obs")
    if (obs_stn != "") and (Path(temp_file).stat().st_size > 10000):
        #
        # Problem1: HTML code has 2 pre only one /pre
        # Problem2: The number of char on a line can increase without warning.
        #
        Read_ObsFile(
            mut_ds, temp_file, arch_obs, temp2_file, days_before, mllw, msl
        )
    else:
        Read_ObsFile(
            mut_ds, None, arch_obs, temp_file, days_before, mllw, msl
        )


def Main_Init(mut_ds):
    mut_ds['txt_file'] = DATA / 'default.txt'
    mut_ds.attrs['Backup_list'] = []
    mut_ds['got_surge'] = False


def Main(mut_ds, user):
    # NOTE: In xarray tz-aware datetime is stored as pandas object array,
    # but we want to store as tz-naive numpy.datetime64 (at GMT/UTC value)
    mut_ds['now'] = user['date']
    mut_ds.attrs['timezone'] = GMT

    _logger.info(f"Starting {time.time_ns()}")
    Main_Init(mut_ds)

    with open(DATA / 'data' / 'cron.bnt', 'r') as fp:
        line = fp.readline()
        txtlist = []
        for line in fp:
            print(f"Starting line {line}")
            line = line.split(':')
            if line[0].strip() and line[0].strip()[0] == '#':
                continue

            _logger.info(f"Working with {line}")
            mut_ds['txt_file'] = DATA / 'model' / f'{line[1]}.txt'
            mut_ds['cur_abrev'] = line[1]

            zone = line[16]
            # NOTE: e.g. EST is static timezone, while US/Eastern can
            # be daylight saving depending on date
            #
            # mut_ds['now'] is in tz-naive, the value is in GMT, first
            # we `localize` it and then get the value in the specified
            # timezone to check if the value in the specified timezone
            # has daylight saving offset
            tzinfo = ZONES[zone]
#            is_dst = bool(
#                GMT.localize(
#                    _to_datetime(mut_ds['now'].item())
#                ).astimezone(tzinfo).dst()
#            )
#            if zone != 'HST' and is_dst:
#                zone = f"{zone[0]}DT"
            mllw = float(line[12])
            msl = float(line[14])
            mhhw = float(line[14])
            mat = line[17].split('#')[0]
            filt_anom = line[18]
            Refresh(
                mut_ds=mut_ds,
                surge_stn=line[2],
                obs_stn=line[3],
                tide_stn=line[4],
                cwl_file=Path(line[5]),
                surge_flag=bool(int(line[6])),
                title=line[7],
                arch_cwl=DATA / 'database' / f'{line[1]}.cwl',
                temp_file=DATA / 'temp.txt',
                temp2_file=DATA / 'temp2.txt',
                days_before=5,
                arch_obs=DATA / 'database' / f'{line[1]}.obs',
                display_days=1.5,
                mllw=mllw,
                msl=msl,
                mhhw=mhhw,
                zone=tzinfo,
                mat=mat,
                filt_anom=filt_anom,
            )

            txtlist.append(f'{line[1]}.txt')

    print("")


#-----------------------------------------------------------------------------
# Done with Procs, start program.
#-----------------------------------------------------------------------------


if __name__ == '__main__':
    os.chdir(DATA)

    args = parse_cli()
    user = process_cli(args)
    dataset = xr.Dataset()
    Main(dataset, user)
