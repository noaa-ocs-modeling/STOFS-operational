import os
from datetime import datetime, timedelta
import subprocess
import pathlib

import numpy as np

if __name__ == '__main__':

    #date = datetime.now() - timedelta(days=1)
    date = datetime.now()
    print(date.strftime("%Y%m%d")) 
    cache = pathlib.Path(f'./{date.strftime("%Y%m%d")}')
    cache.mkdir(exist_ok=True, parents=True)

    products = {'conus': 'medium_range', 'hawaii': 'short_range', 'alaska': 'medium_range'}

    for layer, prod in products.items():
        if layer == 'conus':
            d1 = f'{prod}_mem1'
            channel = 'channel_rt_1'

        if layer == 'alaska':
            d1 = f'{prod}_{layer}_mem1'
            channel = 'channel_rt_1'
        elif layer == 'hawaii':
            d1 = f'{prod}_{layer}'
            channel = 'channel_rt'

        for i in np.arange(48):  

            if 'medium_range' in prod:
                tid = f'{i+1:02d}'
            else:
                tid = f'{i+1:02d}00'

            #url = f"https://para.nomads.ncep.noaa.gov/pub/data/nccf/com/nwm/v3.0/nwm.{date.strftime('%Y%m%d')}/{d1}/nwm.t00z.{prod}.{channel}.f0{tid}.{layer}.nc"
            #url = f"/lfs/h1/ops/para/com/nwm/v3.0/nwm.{date.strftime('%Y%m%d')}/{d1}/nwm.t00z.{prod}.{channel}.f0{tid}.{layer}.nc"
            #cmd = f'wget --no-check-certificate {url} -P {cache}' 
            #sts = subprocess.Popen(cmd, shell=True).wait()
            src = f'/lfs/h1/ops/prod/com/nwm/v3.0/nwm.{date.strftime("%Y%m%d")}/{d1}/nwm.t00z.{prod}.{channel}.f0{tid}.{layer}.nc'
            dst = f'./{date.strftime('%Y%m%d')}/nwm.t00z.{prod}.{channel}.f0{tid}.{layer}.nc'
            os.symlink(src, dst)

