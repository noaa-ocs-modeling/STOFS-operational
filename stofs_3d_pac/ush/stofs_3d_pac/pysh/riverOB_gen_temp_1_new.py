import argparse
from datetime import datetime, timedelta
import pytz

import numpy as np
import pandas as pd
from pandas.tseries.offsets import Second
import netCDF4 as nc
from netCDF4 import Dataset

def get_usgs_obs(df=None, datevectors=None, datevectors2=None):
    #df = pd.read_csv(fname, skiprows=26,sep='\t', na_values=' ')
    df.drop([0], inplace=True)
    tz = df['tz_cd'].iloc[1]
    #df.drop(columns=['agency_cd', 'site_no', 'tz_cd', '117345_00060_cd'], inplace=True)
    df.drop(df.columns[[0, 1, 3]], axis=1, inplace=True)
    ts = pd.to_datetime(pd.Series(df['datetime'].values))
    ts2 = ts.dt.tz_localize('US/Pacific', ambiguous='infer', nonexistent='shift_forward')
    ts3 = ts2.dt.tz_convert('UTC')
    df.drop(columns=['datetime'], inplace=True)
    df.reset_index(drop=True, inplace=True)
    df.insert(1, 'date_utc', ts3)
    df.set_index('date_utc', inplace=True)
    df.rename(columns={df.columns[0]: 'temp'}, inplace=True)
    df.dropna(axis=0, inplace=True)


    data = []
    for i, dt in enumerate(datevectors):
        print(f'Getting data for day {i+1}:')
        try:
            data.append(float(df.loc[dt]['temp']))
        except:
            if i == 0:
                raise KeyError(f'No water temperature data for hindcast {dt}, use old TEM_1.th!')
            else:
                print (f"No water temperature data for {dt}, use the previous day's data!")

    for dt in datevectors2[i+1:]:
        data.append(data[-1])
    return data

def get_river_hydrometric(fname, datevectors, datevectors2):

    df = pd.read_csv(fname, sep=',', na_values='')
    df.drop(df.columns[[0, 4, 5, 6, 7, 8]],axis=1, inplace=True)
    df.rename(columns={df.columns[0]: 'date_local', df.columns[1]: 'parameter', df.columns[2]: 'value'}, inplace=True)

    # Convert date_local to datetime (already in UTC)
    df['date_utc'] = pd.to_datetime(df['date_local'])

    df_temp = df[df['parameter'] == 5].copy()

    df_temp.set_index('date_utc', inplace=True)

    # extract Temperature
    data_temp = []
    for i, dt in enumerate(datevectors):
        print(f'[Temp] Getting data for day {i+1}:')
        try:
            data_temp.append(round(float(df_temp.loc[dt]['value']), 3))
        except:
            if i == 0:
                raise KeyError(f'No Temperature data for {dt}, check input file!')
            else:
                print(f"No Temperature data for {dt}, use previous day's data.")
                data_temp.append(data_temp[-1])

    for dt in datevectors2[i+1:]:
        data_temp.append(data_temp[-1])

    return data_temp

if __name__ == '__main__':

    #date = datetime.now() - timedelta(days=1)
    #date = datetime(2023, 7, 15)
    #input paramters 
    argparser = argparse.ArgumentParser()
    argparser.add_argument('date',
        type=datetime.fromisoformat,
        help="The date format 'YYYY-MM-DD HH:MM:SS'",
    )

    args=argparser.parse_args()
    startDT=args.date
    print(f'startdate is {startDT}')

    #startDT = datetime(date.year, date.month, date.day, 12)
    endDT = startDT + timedelta(days=1)
    datevectors = pd.date_range(start=startDT.strftime('%Y-%m-%d %H:00:00'), end=endDT.strftime('%Y-%m-%d %H:00:00'), tz=pytz.UTC)
    endDT2 = startDT + timedelta(days=4)
    datevectors2 = pd.date_range(start=startDT.strftime('%Y-%m-%d %H:00:00'), end=endDT2.strftime('%Y-%m-%d %H:00:00'), tz=pytz.UTC)

    #station_ids = {'Willamette': '14211720', 'Lewis': '14220500', 'Cowlitz': '14243000', 'Dalles': '14105700'}

    #orders[Willamette, columbia/3, columbia/3, columbia/3, lewis, Cowlitz, fraser]
    rivers = ['Willamette', 'Columbia', 'Columbia', 'Columbia', 'Lewis', 'Cowlitz', 'Fraser']

    temp = {}
###    #Willamette
###    print(f'Getting temperature data for Wilamette river...')
###    df1 = pd.read_csv('usgs_station_14211720.txt', skiprows=25, sep='\t', na_values=' ')
###    #agency_cd       site_no datetime        tz_cd 172755_00010    172755_00010_cd
###    df1 = df1[['agency_cd', 'site_no', 'datetime', 'tz_cd', '172755_00010']]
###    #df1.drop(df1.iloc[:,5:], axis=1, inplace=True)
###    temp['Willamette'] = get_usgs_obs(df1, datevectors, datevectors2)

###    #Willamette
###    print(f'Getting temperature data for Wilamette river...')
###    df1 = pd.read_csv('usgs_station_14207770.txt', skiprows=16, sep='\t', na_values=' ')
###    #agency_cd       site_no datetime        tz_cd 333295_00010    333295_00010_cd
###    df1 = df1[['agency_cd', 'site_no', 'datetime', 'tz_cd', '333295_00010']]
###    #df1.drop(df1.iloc[:,5:], axis=1, inplace=True)
###    temp['Willamette'] = get_usgs_obs(df1, datevectors, datevectors2)

    #Willamette
    print(f'Getting temperature data for Wilamette river...')
    lookup = 'agency_cd'
    with open('usgs_station_14207770.txt','r') as f:
        for num, line in enumerate(f, 1):
            if lookup in line:             
                row_num = num     
                print(lookup, ': found at line: ', row_num, ' up level: ', row_num-1)
    print('last ', lookup, ': found at line: ', row_num, ' up level: ', row_num-1)
    ###df1 = pd.read_csv('usgs_station_14207770.txt', skiprows=row_num-1, sep='\t', na_values=' ')
    df1 = pd.read_csv('usgs_station_14207770.txt', skiprows=row_num-1, sep='\t', na_values=' ')
    #agency_cd       site_no datetime        tz_cd 333295_00010    333295_00010_cd
    df1 = df1[['agency_cd', 'site_no', 'datetime', 'tz_cd', '333295_00010']]
    #df1.drop(df1.iloc[:,5:], axis=1, inplace=True)
    temp['Willamette'] = get_usgs_obs(df1, datevectors, datevectors2)

    #Dalles - replace USACE station for columbia river
    print(f'Getting temperature data for Columbia river...')
    lookup = 'agency_cd'
    with open('usgs_station_14105700.txt','r') as f:
        for num, line in enumerate(f, 1):
            if lookup in line:             
                row_num = num     
                print(lookup, ': found at line: ', row_num, ' up level: ', row_num-1)
    print('last ', lookup, ': found at line: ', row_num, ' up level: ', row_num-1)
    df2 = pd.read_csv('usgs_station_14105700.txt', skiprows=row_num-1, sep='\t', na_values=' ')
    df2 = df2[['agency_cd', 'site_no', 'datetime', 'tz_cd', '116759_00010']]
    temp['Columbia'] = get_usgs_obs(df2, datevectors, datevectors2)

    #Lewis - use Columbia river's temperature
    temp['Lewis'] = temp['Columbia']

    #Cowlitz - use Columbia river's temperature
    temp['Cowlitz'] = temp['Columbia']

    #Fraser river - linear regression with airT (y=0.83x+2.817)
    ###print(f'Getting temperature data for Fraser river using air temperature regression...')
    ###point = (49.38, 238.55)
    ###ds = Dataset('sflux/sflux_air_1.0001.nc')
    ###lon = ds['lon'][0, :]
    ###lat = ds['lat'][:, 0]
    ###idxs = ((lat - point[0]) > 0) & ((lat - point[0]) < 0.2)
    ###lat_idx = np.where(idxs)[0]
    ###idxs = ((lon - point[1]) > 0) & ((lon - point[1]) < 0.2)
    ###lon_idx = np.where(idxs)[0]
    ###
    ###times = ds['time'][:]
    ###sflux_startdate = pd.Timestamp(ds['time'].units.split('since ')[-1], tz='UTC')
    ###timestamps = [sflux_startdate + round(dt*86400)*Second() for dt in times]
    ###airT = np.squeeze(ds['stmp'][:, lat_idx, lon_idx] - 273.15)
    ###waterT = 0.83 * airT + 2.817
    #set waterT below zero to zero
    ###idxs = waterT < 0
    ###waterT[idxs] = 0
    ###df = pd.DataFrame(waterT, index=timestamps)

    ###indices = np.where(np.isin(timestamps, datevectors2))[0]
    ###temp['Fraser'] = df.iloc[np.array(indices)][0].values

    #Fraser river - linear regression with airT (y=0.83x+2.817)
    print(f'Getting temperature data for Fraser river...')
    fname_fraser = '08MF005_hydrometric.csv'
    #get fraser river
    temp['Fraser'] = get_river_hydrometric(fname_fraser, datevectors, datevectors2)

    #write file
    data = []
    for i, date in enumerate(datevectors2[:-1]):
        line = []
        dt = (date - datevectors[0]).total_seconds()
        print(f'time = {dt}')
        line.append(dt)
        for riv in rivers:
            print(f'river:  {riv}')
            line.append(temp[riv][i])

        data.append(line)

    newset = np.array(data)
    np.savetxt('TEM_1.th', newset, fmt='%.3f')
