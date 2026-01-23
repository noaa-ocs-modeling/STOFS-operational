from datetime import datetime, timedelta
import pytz

import numpy as np
import pandas as pd
from netCDF4 import Dataset
#import xarray as xr

def get_usgs_obs(df=None, datevectors=None):
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
    for dt in datevectors:
        data.append(float(df.loc[dt]['temp']))
    #dt = datevectors[0]
    #data.append(float(df.loc[dt]['temp']))
    #data.append(data[-1])
    data.append(data[-1])
    data.append(data[-1])
    return data

if __name__ == '__main__':

    date = datetime.now() - timedelta(days=1)
    #date = datetime(2023, 6, 15)
    startDT = datetime(date.year, date.month, date.day, 12)
    endDT = startDT + timedelta(days=1)
    datevectors = pd.date_range(start=startDT.strftime('%Y-%m-%d %H:00:00'), end=endDT.strftime('%Y-%m-%d %H:00:00'), tz=pytz.UTC)
    endDT2 = startDT + timedelta(days=3)
    datevectors2 = pd.date_range(start=startDT.strftime('%Y-%m-%d %H:00:00'), end=endDT2.strftime('%Y-%m-%d %H:00:00'), tz=pytz.UTC)

    #station_ids = {'Willamette': '14211720', 'Lewis': '14220500', 'Cowlitz': '14243000', 'Dalles': '14105700'}

    #orders[Willamette, columbia/3, columbia/3, columbia/3, lewis, Cowlitz, fraser]
    rivers = ['Willamette', 'Columbia', 'Columbia', 'Columbia', 'Lewis', 'Cowlitz', 'Fraser']

    temp = {}
    #Willamette
    df1 = pd.read_csv('usgs_station_14211720.txt', skiprows=25, sep='\t', na_values=' ')
    #agency_cd       site_no datetime        tz_cd 172755_00010    172755_00010_cd
    df1 = df1[['agency_cd', 'site_no', 'datetime', 'tz_cd', '172755_00010']]
    #df1.drop(df1.iloc[:,5:], axis=1, inplace=True)
    temp['Willamette'] = get_usgs_obs(df1, datevectors)

    #Dalles - replace USACE station for columbia river
    df2 = pd.read_csv('usgs_station_14105700.txt', skiprows=16, sep='\t', na_values=' ')
    df2 = df2[['agency_cd', 'site_no', 'datetime', 'tz_cd', '116759_00010']]
    temp['Columbia'] = get_usgs_obs(df2, datevectors)

    #Lewis - use Columbia river's temperature
    temp['Lewis'] = temp['Columbia']

    #Cowlitz - use Columbia river's temperature
    temp['Cowlitz'] = temp['Columbia']

    #Fraser river - linear regression with airT (y=0.83x+2.817)
    point = (49.38, 238.55)
    ds = Dataset('sflux/sflux_air_1.0001.nc')
    lon = ds['lon'][0, :]
    lat = ds['lat'][:, 0]
    idxs = ((lat - point[0]) > 0) & ((lat - point[0]) < 0.2)
    lat_idx = np.where(idxs)[0]
    idxs = ((lon - point[1]) > 0) & ((lon - point[1]) < 0.2)
    lon_idx = np.where(idxs)[0]
    airT = np.squeeze(ds['stmp'][11:24*4:24, lat_idx, lon_idx] - 273.15)
    waterT = 0.83 * airT + 2.817
    
    #set waterT below zero to zero
    idxs = waterT < 0
    waterT[idxs] = 0
    temp['Fraser'] = waterT

    #write file
    data = []
    for i, date in enumerate(datevectors2):
        line = []
        dt = (date - datevectors[0]).total_seconds()
        print(f'time = {dt}')
        line.append(dt)
        for riv in rivers:
            line.append(temp[riv][i])

        data.append(line)

    newset = np.array(data)
    np.savetxt('TEM_1.th', newset, fmt='%.3f')
