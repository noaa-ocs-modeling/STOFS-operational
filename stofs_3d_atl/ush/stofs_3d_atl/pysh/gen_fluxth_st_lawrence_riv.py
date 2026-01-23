#!/usr/bin/env python3

'''
Version : 1.0
Purpose : Generate the flux.th & TEM_1.th file using WCOSS2 data tank for Canadian River data

Description:
    1. Usage : python gen_st_lawrence_riv_v1.py '<start_date>'
     - <start_date> : The start time of run in the format 'YYYY-MM-DD HH:00:00'
     - for example : '2025-06-14 09:00:00'; '2025-06-14 23:00:00'

    2. Parameters : (Manually set by the user)
     - fname : file name from WCOSS2 (e.g. 02OA016_hydrometric.csv)

       Note: the file should be in the same directory of script.

     - save_dir : Save directory where the flux.th output files are saved

    3. Outputs
     - flux.th : flux data (time interval : 1 day=86400 seconds)
     - TEM_1.th : temperature data (time interval : 1 day=86400 seconds)

'''

from datetime import datetime, timedelta
import argparse

import numpy as np
import pandas as pd

def get_river_hydrometric(fname, datevectors, datevectors2):

    df = pd.read_csv(fname, sep=',', na_values='')
    df.drop(df.columns[[0, 4, 5, 6, 7, 8]],axis=1, inplace=True)
    df.rename(columns={df.columns[0]: 'date_local', df.columns[1]: 'parameter', df.columns[2]: 'value'}, inplace=True)

    # Convert date_local to datetime (already in UTC)
    df['date_utc'] = pd.to_datetime(df['date_local'])

    df_temp = df[df['parameter'] == 5].copy()
    df_flow = df[df['parameter'] == 47].copy()

    df_temp.set_index('date_utc', inplace=True)
    df_flow.set_index('date_utc', inplace=True)

    # extract Flow
    data_flow = []
    for i, dt in enumerate(datevectors):
        print(f'[Flow] Getting data for day {i+1}:')
        try:
            data_flow.append(round(float(df_flow.loc[dt]['value']), 3))
        except:
            if i == 0:
                raise KeyError(f'No Flow data for {dt}, use old flux.th!')
            else:
                print(f"No Flow data for {dt}, use previous day's data.")
                data_flow.append(data_flow[-1])

    for dt in datevectors2[i+1:]:
        data_flow.append(data_flow[-1])

    # extract Temperature
    data_temp = []
    for i, dt in enumerate(datevectors):
        print(f'[Temp] Getting data for day {i+1}:')
        try:
            data_temp.append(round(float(df_temp.loc[dt]['value']), 3))
        except:
            if i == 0:
                print(f'No Temperature data for {dt}, check input file!, use default -9999.')
                #raise KeyError(f'No Temperature data for {dt}, check input file!')
                data_temp.append(-9999)
            else:
                print(f"No Temperature data for {dt}, use previous day's data.")
                data_temp.append(data_temp[-1])

    for dt in datevectors2[i+1:]:
        data_temp.append(data_temp[-1])

    return data_flow, data_temp

if __name__ == '__main__':

    #input paramters
    fname = '02OA016_hydrometric.csv'
    save_dir = './'

    # Parse command line arguments
    argparser = argparse.ArgumentParser()
    argparser.add_argument('date',
    type=datetime.fromisoformat,
    help="The date format 'YYYY-MM-DD HH:00:00'",
    )
    args = argparser.parse_args()


    #enddate = args.date
    startdate = args.date
    print(f"startdate is {startdate}")

    start_date_str = startdate.strftime('%Y-%m-%d %H:00:00')
    end_date_str = (startdate + timedelta(days=1)).strftime('%Y-%m-%d %H:00:00') # hindcast

    enddate = startdate + timedelta(days=1) # hindcast
    datevectors = pd.date_range(start=startdate.strftime('%Y-%m-%d %H:00:00'), end=enddate.strftime('%Y-%m-%d %H:00:00'), tz='UTC')
    enddate2 = startdate + timedelta(days=6) # hindcast + forecast
    datevectors2 = pd.date_range(start=startdate.strftime('%Y-%m-%d %H:00:00'), end=enddate2.strftime('%Y-%m-%d %H:00:00'), tz='UTC')

    rivers = ['St_lawrence']

    flow = {}
    temp = {}
    flow['St_lawrence'], temp['St_lawrence']  = get_river_hydrometric(fname, datevectors, datevectors2)

    # write file
    data_flux = []
    data_temp = []

    for i, date in enumerate(datevectors2):
        dt = int((date - datevectors[0]).total_seconds())
        print(f'time = {dt}')

        line_flux = [dt]
        line_temp = [dt]

        for riv in rivers:
            line_flux.append(-flow[riv][i])   # flow
            line_temp.append(temp[riv][i])    # temp

        data_flux.append(line_flux)
        data_temp.append(line_temp)

    np.savetxt('flux.th', np.array(data_flux), fmt=['%d','%.3f'])
    np.savetxt('TEM_1.th', np.array(data_temp), fmt=['%d','%.3f'])



