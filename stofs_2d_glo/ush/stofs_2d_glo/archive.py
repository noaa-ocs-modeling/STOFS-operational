from pathlib import Path
from datetime import datetime, timedelta

import numpy as np
import pandas as pd
import pytz


GMT = pytz.timezone('gmt')
DT64REF = np.datetime64('1970-01-01T00:00:00')


def _to_datetime(xr_dt64):
    ts = (np.datetime64(xr_dt64, 'ns') - DT64REF) / np.timedelta64(1, 's')
    return datetime.utcfromtimestamp(ts)


# file modified 03/2010 AWK to reflect removal of CRON in calling program
def Read_ArchCWL(mut_ds, archFile):
    last_time = pd.NaT
    if not Path(archFile).exists():
        return last_time.to_pydatetime()

    # tz-naive datetimes are assumed to be in GMT
    start = _to_datetime(mut_ds['begTime'].item())
    cur = mut_ds.cur
    # Reference
    cwl = mut_ds.cwl.values
    with open(archFile, 'r') as fp:
        for line in fp:
            # Timezone is assumed to be GMT for dates read from file
            try:
                time = pd.to_datetime(line[75:88], format='%m/%d/%Y %H')
            except Exception as e:
                if 'doesn\'t match format' in str(e):
                    # Ignore this entry
                    continue
                raise

            if time < start or time > cur:
                continue

            last_time = time
            # Total hours)
            tm_hr = int((time - start).total_seconds() // 3600)
            wl = line[92:96]
            if wl == "****":
                wl = 99.9
            else:
                wl = float(wl) / 10

            # Assumption: tm_hr is the same as positional index
            cwl[tm_hr] = wl


            line = line.strip('\n')
            if len(line) == 288:
                # It is a 48 hour forecast
                hrs_fcst = 48
            elif len(line) == 480:
                # It is a 96 hour forecast
                hrs_fcst = 96
            else:
                print("Unrecognized forecast length")
                continue

            for hr in range(1, hrs_fcst + 1):
                wl = line[92 + 4 * hr:96 + 4 * hr]
                if wl == "****":
                    wl = 99.9
                else:
                    wl = float(wl) / 10
                tm = time + timedelta(hours=hr)
                # Total hours
                tm_hr = int((tm - start).total_seconds() // 3600)
                # Assumption: tm_hr is the same as positional index
                cwl[tm_hr] =  wl

    return last_time.to_pydatetime()


def Write_ArchCWL(
    mut_ds, arch_file, line1, line2, line3, line4, line5, temp_file
):
    # Note: open with "a" starts after a norton-editor End-of-file
    #   use dos-edit to view what is actually going on.
    #   dos-edit allows one to get rid of End-of-file char.
    #
    with open(arch_file, 'a') as fp:
        fp.write(f"{line1}{line2}{line3}{line4}{line5}\n")



def Read_ArchObs(mut_ds, archFile, ap, adjust):
    # Read in old Archived Observations.
    # Store Observations that are earlier than the day of start in ap,
    # close archFile.

    # tz-naive data assumed to be in GMT
    start = _to_datetime(mut_ds['begTime'].item())
    last_time = pd.NaT
    hrs = mut_ds.hr.values
    # Reference
    obs = mut_ds.obs.values

    if not Path(archFile).exists():
        return last_time.to_pydatetime()

    with open(archFile, 'r') as fp:
        valid = False
        reRead = False

        # Skip header line.
        fp.readline()
        for line in fp:
            line = line.split()
            if len(line) != 25:
                continue

            # NOTE: File datetime are assumed to be in GMT
            time = pd.to_datetime(line[0], format='%m/%d/%Y')
            for col in range(1, 25):
                if line[col] == "":
                    continue

                tm = time + timedelta(hours=col -1)
                if tm < start:
                    continue

                # Total hours
                tm_hr = int((tm - start).total_seconds() // 3600)
                if tm_hr not in hrs:
                    continue

                # Assumption: tm_hr is the same as positional index
                obs[tm_hr] = float(line[col]) + adjust
                
                if not valid:
                    reRead = True
                    valid = True
                

            # TODO: Is is needed for Python?!
            # This is so that the first part of the line is stored in memory.
            if reRead:
                for col in range(1, 25):
                    if line[col] == "":
                        continue

                    tm = time + timedelta(hours=col -1)
                    # Total hours
                    tm_hr = int((tm - start).total_seconds() // 3600)
                    if tm_hr not in hrs:
                        continue

                    # Assumption: tm_hr is the same as positional index
                    obs[tm_hr] = float(line[col]) + adjust


            # Store it in the ap file.
            if not valid:
                # make sure line is long enough...
                while len(line) < 25:
                    line.append(f'{99.9:6.2f}')

                # Write line.
                ap.write(f'{line[0]} ')
                for col in range(1, 25):
                    ap.write(f'{float(line[col]):6.2f} ')
                ap.write('\n')

                # Done Write line.
                last_time = time + timedelta(hours=23)
            

    return last_time.to_pydatetime()


def Write_ArchObs(mut_ds, ap, last_time):

    time = last_time + timedelta(hours=1)
    # If last_time (and hence time) is tz-aware, change to GMT and
    # remove tzinfo, elseif it's tz-naive assume it's already in GMT
    if time.tzinfo is not None:
        time = time.astimezone(GMT).replace(tzinfo=None)

    # mut_ds times are all tz-naive and assumed to be in GMT
    now = _to_datetime(mut_ds['now'].item())
    begTime = _to_datetime(mut_ds['begTime'].item())
    obs = mut_ds.obs.values
    hrs = mut_ds.hr
    while time <= now:
        # Create line
        date = time.strftime('%m/%d/%Y')
        line = [date]
        for i in range(24):
            # NOTE: This total hours
            tm_hr = int((time - begTime).total_seconds() // 3600)
            if time <= now and tm_hr in hrs:
                # Assumption: tm_hr is the same as positional index
                line.append(f'{obs[tm_hr]:6.2f}')
            else:
                line.append(f'{99.9:6.2f}')
            
            time = time + timedelta(hours=1)

        # Write line.
        ap.write(f'{line[0]} ')
        for col in range(1, 25):
            ap.write(f'{float(line[col]):6.2f} ')
        ap.write('\n')

