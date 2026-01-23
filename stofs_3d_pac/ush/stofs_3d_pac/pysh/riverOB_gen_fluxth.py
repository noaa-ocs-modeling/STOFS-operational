from datetime import datetime, timedelta
import pytz

import numpy as np
import pandas as pd

unit_conv = 0.028316846

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
    df.rename(columns={df.columns[0]: 'flow'}, inplace=True)

    data = []
    for dt in datevectors:
        data.append(round(float(df.loc[dt]['flow'])*unit_conv, 3))
    #dt = datevectors[0]
    #data.append(round(float(df.loc[dt]['flow'])*unit_conv, 3))
    #data.append(data[-1])
    data.append(data[-1])
    data.append(data[-1])
    return data

def get_fraser_river_obs(fname, datevectors):
    df = pd.read_csv(fname, sep=',', na_values='')
    df.drop(df.columns[[0, 2, 3, 4, 5, 7, 8, 9]],axis=1, inplace=True)
    df.rename(columns={df.columns[0]: 'date_local', df.columns[1]: 'flow'}, inplace=True)
    ts = pd.to_datetime(pd.Series(df['date_local'].values))
    #ts2 = ts.dt.tz_localize('US/Pacific', ambiguous='infer', nonexistent='shift_forward')
    ts3 = ts.dt.tz_convert('UTC')
    df.insert(1, 'date_utc', ts3)
    #df.drop('date_local', inplace=True)
    df.set_index('date_utc', inplace=True)
    data = []
    for dt in datevectors:
        data.append(round(float(df.loc[dt]['flow']), 3))
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

    flow = {}
    #Willamette
    df1 = pd.read_csv('usgs_station_14211720.txt', skiprows=25, sep='\t', na_values=' ')
    df1.drop(df1.iloc[:,5:], axis=1, inplace=True)
    flow['Willamette'] = get_usgs_obs(df1, datevectors)

    #Dalles - replace USACE station for columbia river
    df2 = pd.read_csv('usgs_station_14105700.txt', skiprows=16, sep='\t', na_values=' ')
    df2.drop(df2.iloc[:,4:16], axis=1, inplace=True)
    df2.drop(df2.iloc[:,5:], axis=1, inplace=True)
    #tmp = get_usgs_obs(df2, datevectors)
    flow['Columbia'] = np.array(get_usgs_obs(df2, datevectors))*1.2

    #Lewis
    df3 = pd.read_csv('usgs_station_14220500.txt', skiprows=8, sep='\t', na_values=' ')
    df3.drop(df3.iloc[:,5:], axis=1, inplace=True)
    flow['Lewis'] = get_usgs_obs(df3, datevectors)

    #Cowlitz
    df4 = pd.read_csv('usgs_station_14243000.txt', skiprows=12, sep='\t', na_values=' ')
    df4.drop(df4.columns[[4, 5, 7, 8, 9, 10, 11, 12, 13]], axis=1, inplace=True)
    flow['Cowlitz'] = get_usgs_obs(df4, datevectors)

    #Fraser river
    fname_fraser = 'BC_08MF005_hourly_hydrometric.csv'
    #get fraser river
    flow['Fraser'] = get_fraser_river_obs(fname_fraser, datevectors)

    #write file
    data = []
    for i, date in enumerate(datevectors2):
        line = []
        dt = (date - datevectors[0]).total_seconds()
        print(f'time = {dt}')
        line.append(dt)
        for riv in rivers:
            if riv == 'Columbia':
                line.append(-round(flow[riv][i]/3, 3))
            else:
                line.append(-flow[riv][i])

        data.append(line)

    newset = np.array(data)
    np.savetxt('flux.th', newset, fmt='%.3f')
