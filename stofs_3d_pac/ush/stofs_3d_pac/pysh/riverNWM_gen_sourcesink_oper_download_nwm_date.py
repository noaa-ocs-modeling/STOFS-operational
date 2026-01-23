import os
from datetime import datetime, timedelta
import glob
import argparse
import json

import numpy as np
import pandas as pd
from netCDF4 import Dataset

if __name__ == '__main__':
    '''
    Usage: python extract2asci.py "yyyy-mm-dd" or "yyyy-mm-dd hh:mm:ss"
    Run this script in oper_3D/NWM/Combined/ directory. Inputs are in the same directory:
        1. sources_{conus, alaska, hawaii}_global.json
           sinks_{conus, alaska, hawaii}_global.json
        2. climatology file "Dai_Trenberth_climatology_1990-2018_hourly.csv"
        3. work direcotry "basepath"
        4. cached/

    '''

    #input paramters 
    argparser = argparse.ArgumentParser()
    argparser.add_argument('date', type=datetime.fromisoformat, help='input file date')
    args=argparser.parse_args()
    date=args.date - timedelta(days=1)
    #startdate = datetime.now().date() - timedelta(days=1)
    ###date = datetime.now() - timedelta(days=1)
    startdate = datetime(date.year, date.month, date.day)
    print(f'startdate is {startdate}')

    #1. region name
    layers = ['conus', 'alaska', 'hawaii']

    #2.
    clima_filename = 'Dai_Trenberth_climatology_1990-2018_hourly.csv'

    #3. base path
    srcpath = '/lfs/h1/ops/prod/com/nwm/v3.0/'
    #basepath = '/home1/06923/hyu05/work/oper_3D_Pac/river/NWM'
    basepath = '.'

    #generate timevector
    rnday = timedelta(days=4)
    timevector1 = np.arange(startdate, rnday-timedelta(days=1), timedelta(days=1)).astype(datetime)
    timevector2 = np.arange(startdate, rnday+timedelta(hours=1), timedelta(hours=1)).astype(datetime)
    print(timevector1)
    print(enumerate(timevector1))
    print(timevector2)
    print(enumerate(timevector2))

    sources_all = {}
    ###sinks_all = {}
    eid_sources = []
    ###eid_sinks = []
    times = []
    dates = []

    for layer in layers:
        print(f'layer is {layer}')
        fname_source = f'./sources_{layer}_global.json'
        ###fname_sink = f'./sinks_{layer}_global.json'
        sources_fid = json.load(open(fname_source))
        ###sinks_fid = json.load(open(fname_sink))

        #add to the final list
        eid_sources.extend(list(sources_fid.keys()))
        ###eid_sinks.extend(list(sinks_fid.keys()))


        #link data
        files = glob.glob(f'./cached/nwm*.{layer}.nc')
        #remove old files 
        if files is not None:
           print('Remove old files')
           for f in files:
               try: 
                   os.remove(f)
               except OSError as e:
                   print("Error: %s : %s" % (f, e.strerror))

        #link new data
        for i, date in enumerate(timevector2):
            if i == 0:
                date2 = timevector1[0] - timedelta(days=1)
                if layer == 'conus':
                    src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/medium_range_mem1/nwm.t00z.medium_range.channel_rt_1.f024.{layer}.nc'
                elif layer == 'alaska':
                    src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/medium_range_alaska_mem1/nwm.t00z.medium_range.channel_rt_1.f024.{layer}.nc'
                elif layer == 'hawaii':
                    src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/short_range_hawaii/nwm.t00z.short_range.channel_rt.f02400.{layer}.nc'
            elif i >= 1 and i <= 24:
                date2 = timevector1[0]
                if i == 24:
                    it = f'{int(date.hour)+24:03d}'
                else:
                    it = f'{int(date.hour):03d}'
                if layer == 'conus':
                    src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/medium_range_mem1/nwm.t00z.medium_range.channel_rt_1.f{it}.{layer}.nc'
                elif layer == 'alaska':
                    src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/medium_range_alaska_mem1/nwm.t00z.medium_range.channel_rt_1.f{it}.{layer}.nc'
                elif layer == 'hawaii':
                    src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/short_range_hawaii/nwm.t00z.short_range.channel_rt.f{it}00.{layer}.nc'
            elif i >= 25 and i <=72 and layer == 'hawaii':
                date2 = timevector1[1]
                if i >= 25 and i <= 47:
                    it = f'{int(date.hour):03d}'
                elif i >= 48 and i <= 71:
                    it = f'{int(date.hour)+24:03d}'
                else:
                    it = f'{int(date.hour)+48:03d}'
                src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/short_range_hawaii/nwm.t00z.short_range.channel_rt.f{it}00.{layer}.nc'
            elif i >= 73 and i <=96 and layer == 'hawaii':
                date2 = timevector1[1]
                it = f'{48:03d}'
                src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/short_range_hawaii/nwm.t00z.short_range.channel_rt.f{it}00.{layer}.nc'
            else:
                date2 = timevector1[1]
                if i >= 25 and i <= 47:
                    it = f'{int(date.hour):03d}'
                elif i >= 48 and i <= 71:
                    it = f'{int(date.hour)+24:03d}'
                elif i >= 72 and i <= 95:
                    it = f'{int(date.hour)+48:03d}'
                else:
                    it = f'{int(date.hour)+72:03d}'
                if layer == 'conus':
                    src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/medium_range_mem1/nwm.t00z.medium_range.channel_rt_1.f{it}.{layer}.nc'
                elif layer == 'alaska':
                    src = f'{srcpath}/nwm.{date2.strftime("%Y%m%d")}/medium_range_alaska_mem1/nwm.t00z.medium_range.channel_rt_1.f{it}.{layer}.nc'
            dst = f'{basepath}/cached/nwm.t00z.{date.strftime("%Y%m%d%H")}.{layer}.nc'
            ###dst = f'{basepath}/cached/nwm_{i+1:03d}.{layer}.nc'
            os.symlink(src, dst)

