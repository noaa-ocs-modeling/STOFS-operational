import json
from datetime import datetime, timezone
import pandas as pd

#USGS stations
stations = ['14211720', '14220500', '14243000', '14105700','14207770']
with open("usgs_river.txt",'r') as f:
    lines = f.read().splitlines()

start = []
sites = []
for i, line in enumerate(lines):
    if "Data provided" in line: 
        start.append(i)
        sites.append(line.split(' ')[-1])

for isite in range(len(sites)-1):
    if sites[isite] in stations:
        with open(f'usgs_station_{sites[isite]}.txt', 'w+') as f2:
            for i in range(start[isite], start[isite+1]-1):
                if "WARNING" in lines[i]: break
                f2.write(lines[i])
                f2.write('\n')

#USACE
filename = "BON.Flow-Out.Ave.1Hour.1Hour.txt"

with open("OR00001.json",'r') as f:
    lines = json.load(f);

ts = []
data = []
for i in lines['values']:
    date_from_ts = datetime.fromtimestamp(i[0]/1000,tz=timezone.utc)
    python_datetime = date_from_ts.strftime("%Y-%m-%d %H:%M:%S%z")
    ts.append(python_datetime)
    data.append(f"{float(i[1]):.1f}")

df = pd.DataFrame({'timestamp': ts, 'flow': data})
df.to_csv(filename, index=False)
