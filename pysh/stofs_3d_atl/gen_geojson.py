'''
A combined netCDF file is needed for this script:
ncrcat out2d_?.nc out2d_all.nc

Example usage:
python gen_geojson.py --input_filename ./outputs/out2d_all.nc
'''

import os
import argparse
import copy
from time import time
import multiprocessing as mp

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import netCDF4 as nc
from netCDF4 import Dataset
from shapely.geometry import Polygon, MultiPolygon
from shapely.validation import make_valid
from geopandas import GeoDataFrame

#from STOFS3D_scripts.Utility import utils
import utils as utils

def get_disturbance(elevation, depth, levels, fill_value, out_filename):

    #set mask on dry nodes
    idxs_dry = np.where(elevation + depth <= 1.e-6)
    elevation[idxs] = fill_value

    #disturbance
    disturbance = copy.deepcopy(elevation)
    idxs_land_node = depth < 0
    disturbance[idxs_land_node] = np.maximum(0, elevation[idxs_land_node] + depth[idxs_land_node])

    #set mask on dry nodes and nodes with small max disturbance (<0.3 m) on land
    idxs_small = disturbance < 0.3
    idxs_mask_maxdist = idxs_small * idxs_land_node
    disturbance[idxs_mask_maxdist] = fill_value

    gdf = contour_to_gdf(disturbance, levels, triangulation)

    gdf.to_file(out_filename, driver="GeoJSON")


def contour_to_gdf(disturbance, levels, triangulation):

    MinVal = levels[0]
    MaxVal = levels[-1]

    #if True:
    #    MinVal = max(MinVal, 0.5)
    #    MaxVal = min(MaxVal, 3.0)

    print(f'MinVal is {MinVal}')
    print(f'MaxVal is {MaxVal}')

    #levels = [0.5, 0.7, 0.9, 1.1, 1.3, 1.5, 1.7, 1.9, 2.1, 2.3, 2.5, 2.7, 2.9]
    MinMax = []
    for i in range(len(levels)-1): 
        MinMax.append((levels[i], levels[i+1]))
    #MinMax.append((2.9, np.max(disturbance)))
    print(f'MinMax is {MinVal}, {MaxVal}')

    fig = plt.figure()
    ax = fig.add_subplot()

    my_cmap = plt.cm.jet
    contour = ax.tricontourf(triangulation, disturbance, vmin=MinVal, vmax=MaxVal,
        levels=levels, cmap=my_cmap, extend='neither')

    #Transform a `matplotlib.contour.QuadContourSet` to a GeoDataFrame
    polygons, colors = [], []
    data = []
    for i, polygon in enumerate(contour.collections):
        mpoly = []
        print(f'polygon {i}')
        for path in polygon.get_paths():
            try:
                path.should_simplify = False
                poly = path.to_polygons()
                # Each polygon should contain an exterior ring + maybe hole(s):
                exterior, holes = [], []
                if len(poly) > 0 and len(poly[0]) > 3:
                    # The first of the list is the exterior ring :
                    exterior = poly[0]
                    # Other(s) are hole(s):
                    if len(poly) > 1:
                        holes = [h for h in poly[1:] if len(h) > 3]
                mpoly.append(make_valid(Polygon(exterior, holes)))
            except:
                print('Warning: Geometry error when making polygon #{}'.format(i))

        if len(mpoly) > 1:
            mpoly = MultiPolygon(mpoly)
            polygons.append(mpoly)
            colors.append(polygon.get_facecolor().tolist()[0])
            data.append({'id': i+1, 'minWaterLevel': MinMax[i][0], 'maxWaterLevel': MinMax[i][1], 
                    'verticalDatum': 'NAVD88', 'units': 'meters', 'geometry': mpoly})
        elif len(mpoly) == 1:
            polygons.append(mpoly[0])
            colors.append(polygon.get_facecolor().tolist()[0])
            data.append({'id': i+1, 'minWaterLevel': MinMax[i][0], 'maxWaterLevel': MinMax[i][1], 
                    'verticalDatum': 'NAVD88', 'units': 'meters', 'geometry': mpoly[0]})
    plt.close('all')

    gdf = GeoDataFrame(data)

    #Get color in Hex
    colors_elev = []
    my_cmap = plt.cm.jet

    for i in range(len(gdf)):
        color = my_cmap(i/len(gdf))
        colors_elev.append(mpl.colors.to_hex(color))

    gdf['rgba'] = colors_elev

    #set crs
    gdf = gdf.set_crs('epsg: 4326')

    return  gdf

if __name__ == "__main__":

    my_fillvalue = -99999.0

    #input arguments
    argparser = argparse.ArgumentParser()
    argparser.add_argument('--input_filename', help='file name in SCHISM format')
    args = argparser.parse_args()

    input_filename = args.input_filename
    input_fileindex = os.path.basename(input_filename).replace("_", ".").split(".")[1]    

    #reading netcdf dataset
    ds = Dataset(input_filename)

    #get coordinates/bathymetry
    x = ds['SCHISM_hgrid_node_x'][:]
    y = ds['SCHISM_hgrid_node_y'][:]
    depth = ds['depth'][:]

    #get elements and split quads into tris
    elements = ds['SCHISM_hgrid_face_nodes'][:, :]
    t0 = time()
    tris = utils.split_quads(elements)
    print(f'Spliting quads took {time()-t0} seconds')

    #get triangulation for contour plot
    triangulation = utils.triangulation(x, y, tris)

    #get time
    times = ds['time'][:]
    dates = nc.num2date(times, ds['time'].units)

    #get elevation
    elev = ds['elevation'][:, :]
    idxs = np.where(elev > 100000)
    elev[idxs] = my_fillvalue

    #calculate max elevation for this stack
    maxelev = np.max(elev, axis=0)
    idxs = np.argmax(elev, axis=0)
    time_maxelev = times[idxs]

    filename_output = f'./stofs_3d_atl_atlantic_max_disturbance_{dates[0].strftime("%Y%m%d")}'  \
        + f't01z_{dates[-1].strftime("%Y%m%d")}t00z.json'

    t0 = time()
    #levels = [0.5, 0.7, 0.9, 1.1, 1.3, 1.5, 1.7, 1.9, 2.1, 2.3, 2.5, 2.7, 2.9]
    levels = [round(0.5 + i*0.2, 1 ) for i in range(13)]
    levels.append(10)
    print(levels)
    get_disturbance(maxelev, depth, levels, my_fillvalue, filename_output)
    print(f'Calculating and masking disturbance took {time()-t0} seconds')


    #calculate hourly disturbance
    npool = len(times) if len(times) < mp.cpu_count() else mp.cpu_count()-1
    print(npool)

    filenames = [f'./stofs_3d_atl_atlantic_disturbance_{dates[0].strftime("%Y%m%d")}' \
        + f't00z_{dates[i].strftime("%Y%m%d")}t{dates[i].strftime("%H")}z.json' for i in range(len(times))]
    print(filenames)

    t0 =  time()
    #for it in range(len(times)):
    #    print(it)
    #    get_disturbance(np.squeeze(elev[it,:]), depth, levels, my_fillvalue, filenames[it])

    #print(f'Calculating and masking disturbance for all times took {time()-t0} seconds')

    pool = mp.Pool(npool)
    pool.starmap(get_disturbance, [(np.squeeze(elev[i,:]), depth, levels, my_fillvalue, filenames[i]) for i in range(len(times))])

    pool.close()
    del pool

    print(f'Calculating and masking disturbance for all times took {time()-t0} seconds')
