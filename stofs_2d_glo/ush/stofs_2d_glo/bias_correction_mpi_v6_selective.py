"""
Bias Correction Script for STOFS Data using MPI Parallel Processing

This script performs bias correction on STOFS (Storm Tide Operational Forecast System) data
using MPI parallel processing. It downloads STOFS files, processes them, and generates
corrected water level data.

Usage:
    mpirun -n <num_processors> python bias_correction_mpi_v3.py --date YYYYMMDD [options]

Examples:
    mpirun -n 2 python bias_correction_mpi_v5.py --date 20250923
    mpirun -n 2 python bias_correction_mpi_v5.py --date 20250923 --vtk
    mpirun -n 2 python bias_correction_mpi_v5.py --date 20250923 --no-vtk

Arguments:
    --date YYYYMMDD     Date for download in YYYYMMDD format (required)
    --vtk              Enable VTK file output for debugging
    --no-vtk           Explicitly disable VTK file output
    --help             Show this help message
"""

# standard libraries
import gc
import os
import pickle
import time
import datetime
import argparse
import re
# progress bar
#from tqdm import tqdm
# for downloading files
#import requests
#import boto3
#from botocore.exceptions import NoCredentialsError, ClientError
#from botocore import UNSIGNED
#from botocore.config import Config
# numerical libraries
from mpi4py import MPI
import numpy as np
import pandas as pd
# linear solver library and KD tree
# Set environment variables to restrict solver to one core
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['OPENBLAS_NUM_THREADS'] = '1'
os.environ['NUMEXPR_NUM_THREADS'] = '1'
import scipy
# file IO
import netCDF4 as nc
# for observed water levels
#from searvey.coops import COOPS_Station
# to write vtk for debugging
#import meshio
# for faster bookkeepping
import numba as nb
from numba.typed import Dict
from numba import types
from numba.typed import List
from numba.types import ListType
# path for WOCSS datatank
COM = os.environ.get('COM')
COMIN = os.environ.get('COMIN')
DCOMIN = os.environ.get('DCOMIN')

# NetCDF file names
# NetCDF file names
#NC_POINTS_CORRECTED = 'stofs_2d_glo.t06z.points.cwl.nc'
NC_POINTS_CORRECTED = 'fort.61.nc'
#NC_POINTS_UNCORRECTED = 'stofs_2d_glo.t06z.points.cwl.noanomaly.nc'
NC_POINTS_UNCORRECTED = 'fort.61.noanomaly.nc'
#NC_FIELDS_UNCORRECTED = 'stofs_2d_glo.t06z.fields.cwl.noanomaly.nc'
NC_FIELDS_UNCORRECTED = 'fort.63.nc'
NC_LEVELS_WITH_BIAS = 'levels_with_bias.63.nc'
NC_MAXELE_WITH_BIAS = 'maxele_with_bias.63.nc'

# Station matching functions
def extract_station_ids_from_txt(filename):
    """Extract 7-digit station IDs from the extracted_stations.txt file."""
    station_ids = set()
    
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Skip the header (first line)
    for line in lines[1:]:
        # Look for the station ID after identifiers like SOUS41, SOUS42, etc.
        # Pattern: identifier (like SOUS41) followed by space and 7-digit number
        # This avoids matching coordinates
        match = re.search(r'SOUS\d+\s+([1-9]\d{6})', line)
        if match:
            station_ids.add(match.group(1))
        else:
            # Fallback: look for 7-digit number in the comment section (after !)
            # This should be after the coordinates
            if '!' in line:
                comment_part = line.split('!')[1]
                match = re.search(r'\b([1-9]\d{6})\b', comment_part)
                if match:
                    station_ids.add(match.group(1))
    
    return station_ids


def extract_station_id_from_name(station_name):
    """Extract 7-digit station ID from a station name string."""
    # Pattern to find 7-digit numbers that don't start with 0
    match = re.search(r'\b[1-9]\d{6}\b', station_name)
    if match:
        return match.group()
    return None


def get_matching_station_indices(nc_file, txt_file):
    """
    Match station IDs from extracted_stations.txt with NetCDF station names
    and return the indices of matching stations in the NetCDF file.
    """
    # Extract station IDs from the text file
    print(f"Reading station IDs from {txt_file}...")
    txt_station_ids = extract_station_ids_from_txt(txt_file)
    print(f"Found {len(txt_station_ids)} unique station IDs in text file")
    
    # Read station names from NetCDF
    print(f"Reading station names from {nc_file}...")
    ds = nc.Dataset(nc_file, 'r')
    station_names = ds.variables['station_name'][:]
    num_stations = len(station_names)
    print(f"Found {num_stations} stations in NetCDF file")
    
    # Find matching indices
    print("Matching station IDs...")
    matching_indices = []
    
    for idx in range(num_stations):
        # Decode station name from bytes
        station_name = station_names[idx].tobytes().decode('utf-8').strip()
        
        # Extract 7-digit station ID from the name
        station_id = extract_station_id_from_name(station_name)
        
        if station_id and station_id in txt_station_ids:
            matching_indices.append(idx)
    
    ds.close()
    
    print(f"Found {len(matching_indices)} matching stations")
    return matching_indices


@nb.njit
def update_nodeid2elementid(nodeid2elementid, elements, num_nodes):

    # Initialize empty lists for each node
    for n in range(num_nodes):
        nodeid2elementid[n] = List.empty_list(nb.int64)

    # Populate the dictionary
    for j, element in enumerate(elements):
        for n in element:
            nodeid2elementid[n].append(j)
    
    return nodeid2elementid

@nb.njit
def generate_rows_cols(elements):
    num_elements = len(elements)
    num_edges = 3 * num_elements  # Each element has 3 edges

    # Pre-allocate arrays
    #rows = np.empty(2 * num_edges, dtype=np.int64)
    #cols = np.empty(2 * num_edges, dtype=np.int64)
    rows = []
    cols = []

    #index = 0
    for element in elements:
        for n1, n2 in [(element[0], element[1]), (element[1], element[2]), (element[0], element[2])]:
            rows.append(n1)
            cols.append(n2)
            
            rows.append(n2)
            cols.append(n1)
       
            #rows[index] = n1
            #cols[index] = n2
            #index += 1
            #rows[index] = n2
            #cols[index] = n1
            #index += 1

    return rows, cols

def download_file(url, filename):
    # Send a HTTP request to the server and get a response
    response = requests.get(url, stream=True)
    
    # Get total size in bytes.
    total_size = int(response.headers.get('content-length', 0))
    
    # Open a local file with write-binary mode.
    with open(filename, "wb") as file, tqdm(
        desc=filename,
        total=total_size,
        unit='B',
        unit_scale=True,
        unit_divisor=1024,
    ) as bar:
        for data in response.iter_content(chunk_size=1024):
            size = file.write(data)
            bar.update(size)

def download_stofs_files(date_str, output_dir='.'):
    """
    Download three STOFS files from AWS S3 for a given date.
    
    Parameters
    ----------
    date_str : str
        Date in YYYYMMDD format (e.g., '20250925')
    output_dir : str, optional
        Directory to save the downloaded files (default: current directory)
    
    Returns
    -------
    list
        List of successfully downloaded filenames
    """
    # Validate date format
    try:
        datetime.datetime.strptime(date_str, '%Y%m%d')
    except ValueError:
        raise ValueError("Date must be in YYYYMMDD format")
    
    # Initialize S3 client with unsigned configuration for public access
    s3_client = boto3.client('s3', config=Config(signature_version=UNSIGNED))
    bucket_name = 'noaa-gestofs-pds'
    
    # Define the three files to download with their new S3 keys
    files_to_download = [
        'stofs_2d_glo.t00z.points.cwl.noanomaly.nc',
        'stofs_2d_glo.t00z.points.cwl.nc',
        'stofs_2d_glo.t00z.fields.cwl.nc'
    ]
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    downloaded_files = []
    
    for filename in files_to_download:
        # Construct S3 key with new structure
        s3_key = f'stofs_2d_glo.{date_str}/{filename}'
        
        # Local file path
        local_filepath = os.path.join(output_dir, filename)
        
        try:
            print(f"Downloading {filename}...")
            
            # Get object size for progress bar
            response = s3_client.head_object(Bucket=bucket_name, Key=s3_key)
            file_size = response['ContentLength']
            
            # Download with progress bar
            with tqdm(total=file_size, unit='B', unit_scale=True, desc=filename) as pbar:
                def progress_callback(bytes_transferred):
                    pbar.update(bytes_transferred)
                
                s3_client.download_file(
                    bucket_name, 
                    s3_key, 
                    local_filepath,
                    Callback=progress_callback
                )
            
            downloaded_files.append(local_filepath)
            print(f"Successfully downloaded {filename}")
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                print(f"File {filename} not found for date {date_str}")
            else:
                print(f"Error downloading {filename}: {e}")
        except NoCredentialsError:
            print("AWS credentials not found. Please configure your AWS credentials.")
            break
        except Exception as e:
            print(f"Unexpected error downloading {filename}: {e}")
    
    return downloaded_files

def checkIfPointIsInTriangle(x1, y1, x2, y2, x3, y3, x, y):
    """
    Test if a point defined by x,y coordinates is within a triangle defined by verticies with x,y coordinates. 
    
    Parameters
    ----------
    x1 : float
        x coordindate of first point of the bounding triangle
    y1 : float
        y coordindate of first point of the bounding triangle           
    x2 : float
        x coordindate of second point of the bounding triangle
    y2 : float
        y coordindate of second point of the bounding triangle        
    x3 : float
        x coordindate of third point of the bounding triangle
    y3 : float
        y coordindate of third point of the bounding triangle
    x : float
        x coordinate of point being tested
    y : float
        y coordinate of point being tested
    
    Notes
    -----
    This method uses the barycentric method.
    See `http://totologic.blogspot.com/2014/01/accurate-point-in-triangle-test.html`
    """
    a = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3))
    b = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3))
    c = 1.0 - a - b
    epsilon = 1e-10

    aCondition = a + epsilon >= 0.0 and a - epsilon <= 1.0
    bCondition = b + epsilon >= 0.0 and b - epsilon <= 1.0
    cCondition = c + epsilon >= 0.0 and c - epsilon <= 1.0

    return aCondition and bCondition and cCondition

def update_mesh_and_nodes(nodes, elements, removed_nodes):
    """
    Update elements array by removing any elements with nodes that have been removed,
    and update node indices to be continuous from 0. Return new nodal coordinates that
    match the updated indices in elements.
    
    :param nodes: np.array, original array of node coordinates
    :param elements: np.array, original array of elements (each row is a list of node indices forming an element)
    :param removed_nodes: list or array, indices of nodes that have been removed
    :return: tuple (new_nodes, new_elements) where:
        - new_nodes is the updated array of node coordinates,
        - new_elements is the updated elements array with continuous indexing.
    """
    remaining_nodes_mask = np.ones(len(nodes), dtype=bool)
    remaining_nodes_mask[removed_nodes] = False
    
    valid_elements_mask = np.all(remaining_nodes_mask[elements], axis=1)
    valid_elements = elements[valid_elements_mask]

    remaining_node_indices = np.unique(valid_elements)
    node_map = {old_idx: new_idx for new_idx, old_idx in enumerate(remaining_node_indices)}
    
    new_elements = np.vectorize(node_map.get)(valid_elements)
    new_nodes = nodes[remaining_node_indices]

    return new_nodes, new_elements, remaining_node_indices


def adjust_laplacian(laplacian):
    """
    Regularize the Laplacian by adding a small constant to the diagonal
    
    :param laplacian: scipy.sparse matrix, the Laplacian matrix to be regularized
    :return: scipy.sparse matrix, the regularized Laplacian matrix
    """
    n = laplacian.shape[0]
    small_constant = 1e-7
    regularization = scipy.sparse.diags([small_constant], [0], shape=(n, n), format='csr')
    regularized_laplacian = laplacian + regularization
    return regularized_laplacian
    
def find_antimeridian_pairs(nodes_coordinates, lon_identification_threshold=1.0, lat_match_threshold=0.2, lon_match_threshold=1.0):
    """
    Identifies pairs of nodes that lie on opposite sides of the antimeridian
    but represent geographically close locations within given tolerances.

    Args:
        nodes_coordinates (np.array): Nx2 array of (longitude, latitude).
        lon_identification_threshold (float): Degrees from +/-180 to consider a node near the seam.
                                            e.g., 1.0 means longitudes < -180 + threshold and > 180 - threshold.
        lat_match_threshold (float): Maximum latitude difference for two nodes to be considered a pair (in degrees).
        lon_match_threshold (float): Maximum longitude difference (after shifting one by 360 deg)
                                     for two nodes to be considered a pair (in degrees).

    Returns:
        list: A list of tuples, where each tuple is (east_node_idx, west_node_idx) representing a pair
              across the antimeridian. East nodes have lon > 0, West nodes have lon < 0.
    """
    node_pairs = []
    
    # Identify nodes near the western seam (-180 degrees)
    west_indices = np.where(nodes_coordinates[:, 0] < -180.0 + lon_identification_threshold)[0]
    # Identify nodes near the eastern seam (+180 degrees)
    east_indices = np.where(nodes_coordinates[:, 0] > 180.0 - lon_identification_threshold)[0]

    if len(west_indices) == 0 or len(east_indices) == 0:
        return node_pairs

    # For KDTree search, west_nodes will have their longitudes shifted by +360.
    # The tree is built on [latitude, shifted_longitude] of west_nodes.
    west_coords_for_kdtree = np.array(
        [[nodes_coordinates[i, 1], nodes_coordinates[i, 0] + 360.0] for i in west_indices]
    )
    
    if west_coords_for_kdtree.shape[0] == 0:
        return node_pairs # Should be redundant due to earlier check but safe

    kdt = scipy.spatial.cKDTree(west_coords_for_kdtree)
    
    # Keep track of west nodes already paired to ensure one-to-one mapping from east to west
    # (though an east node could map to multiple west nodes if not careful, KDTree k=1 helps)
    # And a west node should not be paired with multiple east nodes.
    paired_west_indices = set()

    for idx_e in east_indices:
        lat_e, lon_e = nodes_coordinates[idx_e, 1], nodes_coordinates[idx_e, 0]
        
        # Query point for KD-tree is [latitude_east, longitude_east]
        # We are looking for a point in kdt (west_node with lon+360) that is close.
        # A generous search radius for the k-d tree query, followed by precise checks.
        search_radius = 0.5 # Degrees. Max distance for KD-tree search.
        
        # Find the single nearest west_node (in the kdtree's representation)
        dist, nearest_kdt_idx = kdt.query([lat_e, lon_e], k=1, distance_upper_bound=search_radius)

        if np.isfinite(dist): # A neighbor was found within the search_radius
            actual_west_idx = west_indices[nearest_kdt_idx]
            
            # Check if this west_idx has already been paired
            if actual_west_idx in paired_west_indices:
                continue

            lat_w, lon_w = nodes_coordinates[actual_west_idx, 1], nodes_coordinates[actual_west_idx, 0]
            
            # Precise check for latitude and longitude match
            if abs(lat_e - lat_w) < lat_match_threshold and \
               abs(lon_e - (lon_w + 360.0)) < lon_match_threshold:
                node_pairs.append((idx_e, actual_west_idx))
                paired_west_indices.add(actual_west_idx) # Mark this west node as paired
    
    return node_pairs




# Initialize the MPI communicator
comm = MPI.COMM_WORLD

# Get the rank of the current process (process ID)
rank = comm.Get_rank()

# Get the total number of processes
size = comm.Get_size()

# Check if running with MPI
if size == 1:
    print("Warning: This script is designed to run with MPI. Consider using:")
    print("Continuing with single process...")


if rank == 0:
    print(f"Starting bias correction with the following parameters:")
    print(f"  Processors: {size}")
    print("-" * 50)
    
    start = time.time()

    #download_stofs_files(args.date)

    ds_corrected = nc.Dataset(NC_POINTS_CORRECTED)
    ds_uncorrected = nc.Dataset(NC_POINTS_UNCORRECTED)

    # time x stations
    bias_array = ds_corrected['zeta'][...].data - ds_uncorrected['zeta'][...].data

    x = ds_corrected['x'][...].data
    y = ds_corrected['y'][...].data

    ds_corrected.close()
    ds_uncorrected.close()
    
    #
    # read fort.63 file
    #
    ds = nc.Dataset(NC_FIELDS_UNCORRECTED)
    
    DRY_NODE_FLAG = -99999.0

    min_x, max_x, min_y, max_y = -179.9999, 179.9999, -89.9999, 89.9999

    base_date = pd.to_datetime(ds['time'].base_date.split('!')[0])
    times = [base_date + datetime.timedelta(seconds=seconds) for seconds in ds['time'][...].data]
    times = np.array(times)  # Ensure times is a numpy array

    #
    # read fort.61 file and create times array
    #
    ds_61 = nc.Dataset(NC_POINTS_CORRECTED)
    base_date_61 = pd.to_datetime(ds_61['time'].base_date.split('!')[0])
    times_61 = [base_date_61 + datetime.timedelta(seconds=seconds) for seconds in ds_61['time'][...].data]
    times_61 = np.array(times_61)  # Ensure times_61 is a numpy array
    ds_61.close()


    # Find indices from times_61 that correspond to times in fort.63
    # Convert both to pandas datetime for easier comparison
    times_pd = pd.to_datetime(times)
    times_61_pd = pd.to_datetime(times_61)
    
    # Find matching indices (indices from times_61 that exist in times)
    matching_indices_61 = []
    for i, time_61 in enumerate(times_61_pd):
        # Check if this time_61 exists in the fort.63 times array
        matches = np.where(times_pd == time_61)[0]
        if len(matches) > 0:
            matching_indices_61.append(i)  # Store the index from times_61
        else:
            print(f"Warning: Time {time_61} from fort.61 not found in fort.63 times")
    
    matching_indices_61 = np.array(matching_indices_61)
    print(f"Found {len(matching_indices_61)} times from fort.61 that exist in fort.63")
    print(f"Fort.61 indices that match fort.63 times: {matching_indices_61}")

    common_datetimes = times_61[matching_indices_61]

    bias_array = bias_array[matching_indices_61,:]

    # Sanitize input data: filter out fill values, NaNs, and extreme outliers
    # This prevents bad boundary conditions from creating isolated high-value pockets
    ABS_LIMIT = 50.0  # Maximum reasonable bias correction value (meters)
    print(f"Sanitizing bias_array: filtering values outside [-{ABS_LIMIT}, {ABS_LIMIT}] and removing NaNs/fill values")
    
    # Count bad values before filtering
    n_bad_before = np.sum((np.abs(bias_array) >= ABS_LIMIT) | np.isnan(bias_array) | (bias_array == DRY_NODE_FLAG))
    if n_bad_before > 0:
        print(f"  Found {n_bad_before:,} invalid bias values (outliers, NaNs, or fill values)")
        print(f"  These will be filtered out to prevent spurious boundary conditions")
    
    # Create mask for valid data
    valid_data_mask = (np.abs(bias_array) < ABS_LIMIT) & (~np.isnan(bias_array)) & (bias_array != DRY_NODE_FLAG)
    
    # Get matching station indices from NetCDF file for extracted_stations.txt
    print(f"Getting station indices from extracted_stations.txt...")
    nc_points_file = NC_POINTS_UNCORRECTED
    txt_file = 'extracted_stations.txt'
    
    matching_station_indices = get_matching_station_indices(nc_points_file, txt_file)
    matching_station_indices_set = set(matching_station_indices)
    print(f"  Found {len(matching_station_indices_set)} stations in extracted_stations.txt")
    
    # Define geographic regions for other continents (excluding North America)
    def is_in_other_regions(lon, lat):
        """Check if coordinates are in Australia, Asia, Europe, Africa, South America, or Antarctica."""
        # Australia
        if (lon >= 110.0) and (lon <= 155.0) and (lat >= -45.0) and (lat <= -10.0):
            return True
        # Asia (east of 60E, but exclude North America region)
        # Handle both positive and negative longitude (antimeridian crossing)
        if (lat >= -10.0) and (lat <= 60.0):
            # Asia region: 60E to 180E (or -180E to -120W for some Pacific islands)
            if ((lon >= 60.0) and (lon <= 180.0)) or ((lon >= -180.0) and (lon <= -120.0)):
                # Exclude North America region (roughly -180 to -50, 15 to 75)
                if not ((lon >= -180.0) and (lon <= -50.0) and (lat >= 15.0) and (lat <= 75.0)):
                    return True
        # Europe
        if (lon >= -10.0) and (lon <= 60.0) and (lat >= 35.0) and (lat <= 75.0):
            return True
        # Africa
        if (lon >= -20.0) and (lon <= 55.0) and (lat >= -35.0) and (lat <= 37.0):
            return True
        # South America
        if (lon >= -85.0) and (lon <= -35.0) and (lat >= -60.0) and (lat <= 15.0):
            return True
        # Antarctica
        if lat < -60.0:
            return True
        return False
    
    dfs_corrections = []
    counter_ = 0
    for datetime_ in common_datetimes:
        # Create dataframe with all data first
        df_temp_all = pd.DataFrame(np.c_[np.arange(len(x)),x,y,bias_array[counter_,:],[counter_]*len(x),[datetime_]*len(x)], columns=['station_id','lon','lat','delta_low','index','datetime'])
        
        # Part 1: Stations from extracted_stations.txt (keep their delta_low values)
        # Apply strict filtering: remove outliers, NaNs, and fill values
        df_temp_matched = df_temp_all[
            (np.abs(df_temp_all['delta_low']) < ABS_LIMIT) & 
            (~df_temp_all['delta_low'].isna()) &
            (df_temp_all['delta_low'] != DRY_NODE_FLAG) &
            (df_temp_all['station_id'].isin(matching_station_indices_set))
        ].copy()
        
        # Part 2: Stations in other regions (set delta_low = 0)
        # Get all stations (including those with invalid delta_low)
        df_temp_other = df_temp_all[
            df_temp_all.apply(lambda row: is_in_other_regions(row['lon'], row['lat']), axis=1) &
            (~df_temp_all['station_id'].isin(matching_station_indices_set))  # Exclude stations already in txt file
        ].copy()
        
        # Set delta_low to 0 for these stations
        df_temp_other['delta_low'] = 0.0
        
        # Combine both sets
        df_temp = pd.concat([df_temp_matched, df_temp_other], ignore_index=True)
        
        dfs_corrections.append(df_temp)
        counter_ += 1
    
    df_corrections = pd.concat(dfs_corrections)
    
    n_stations_matched = len(df_corrections[df_corrections['station_id'].isin(matching_station_indices_set)])
    n_stations_other = len(df_corrections[~df_corrections['station_id'].isin(matching_station_indices_set)])
    
    print(f"  Stations from extracted_stations.txt: {n_stations_matched:,}")
    print(f"  Stations from other regions (delta_low=0): {n_stations_other:,}")
    print(f"  Total stations: {len(df_corrections):,}")
    
    df_corrections.to_csv('df_corrections_new.csv')
    
    # Report filtering results
    n_stations_after = len(df_corrections)
    n_stations_before = len(x) * len(common_datetimes)
    print(f"  After processing: {n_stations_after:,} stations (out of {n_stations_before:,} total)")


    #
    # get nodes and triangulation
    #
    coords = np.c_[ds['x'][...].data, ds['y'][...].data]
    connectivity = ds['element'][...].data - 1

    elem_idx = 0

    remove_element_idx = []

    for element in connectivity:

        n1_x = coords[element[0],0]
        n2_x = coords[element[1],0]
        n3_x = coords[element[2],0]

        if np.max([n1_x,n2_x,n3_x]) - np.min([n1_x,n2_x,n3_x]) > 10:
            
            remove_element_idx.append(elem_idx)

        elem_idx += 1

    if rank == 0 and remove_element_idx:
        print(f"Removing {len(remove_element_idx)} elements identified as crossing antimeridian (initial check)...")
    connectivity = np.delete(connectivity, remove_element_idx, axis=0)

    originalnumber_nodes = len(coords)

    #
    # create a temporary array for nodes
    #    
    points = coords
    points = np.c_[points,range(len(points))]   

    #
    # remove elements not in bounding box (note that we expand the bounding box, but later, we will clip the map to conform to
    # the bounding box - this avoids missing elements on the bounding box edges)
    #
    print('Processing global mesh')
    mask = (points[:,0]>min_x) & (points[:,0]<max_x) & (points[:,1]>min_y) & (points[:,1]<max_y)
    old_idxs = points[mask][:,2].astype(int)
    old_idxs_set = set(old_idxs)
    old_idxs_extraneous_set = set()
    # get all elements associated with nodes
    for element in connectivity:
        if (element[0] in old_idxs_set) or (element[1] in old_idxs_set) or (element[2] in old_idxs_set):
            old_idxs_extraneous_set.add(element[0])
            old_idxs_extraneous_set.add(element[1])
            old_idxs_extraneous_set.add(element[2])
    old_idxs_set = old_idxs_set | old_idxs_extraneous_set        
    new_idxs = np.array(range(len(old_idxs_set)))
    old_idxs_set_array = sorted(np.array(list(old_idxs_set)))
    old2new_idxs = {}
    for j in range(len(new_idxs)):
        old2new_idxs[old_idxs_set_array[j]] = new_idxs[j]
    new_elements = []
    for element in connectivity:
        n1_old = element[0]
        n2_old = element[1]
        n3_old = element[2]
        if (n1_old in old_idxs_set) and (n2_old in old_idxs_set) and (n3_old in old_idxs_set):
            new_elements.append([old2new_idxs[n1_old],old2new_idxs[n2_old],old2new_idxs[n3_old]])

    # get points in proper format for meshio
    points = points[old_idxs_set_array,:]        
    points = points[:,0:2]

    nodes = points.copy()
    elements = np.array(new_elements).copy()

    #
    # clean up some memory
    #
    del points, new_elements, old_idxs
    gc.collect()
    
    elements_original = elements.copy()
    nodes_original = nodes.copy()

    print('Writing files from mesh processing')

    elements_original.dump('elements_original.npy')
    nodes_original.dump('nodes_original.npy')
    df_corrections.to_pickle('df_corrections.p')
    pickle.dump(times, open('times.p','wb'))
    pickle.dump(old_idxs_set_array, open('old_idxs_set_array.p','wb'))

    del elements_original, nodes_original
    gc.collect()

comm.Barrier()

elements_original = np.load('elements_original.npy', allow_pickle=True)
nodes_original = np.load('nodes_original.npy', allow_pickle=True)
df_corrections = pd.read_pickle('df_corrections.p')
times = pickle.load(open('times.p','rb'))
old_idxs_set_array = pickle.load(open('old_idxs_set_array.p','rb'))

# Define the total number of entries
total_entries = len(times)

# Calculate how many entries each core will get
counts = np.array([total_entries // size + (1 if i < total_entries % size else 0) for i in range(size)], dtype='i')

# Calculate the displacements (starting index for each process)
displacements = np.array([sum(counts[:i]) for i in range(size)], dtype='i')

# Print the distribution on each process
if rank == 0:
    print(f"Process {rank} will scatter the indices with counts {counts} and displacements {displacements}")

# Create the indices array (only on root)
if rank == 0:
    indices = np.arange(total_entries, dtype='i')  # Array with indices [0, 1, 2, ..., 83]
else:
    indices = None

# Prepare a buffer for each process to receive its portion of the indices
recvbuf = np.empty(counts[rank], dtype='i')  # Allocate enough space for each process

# Scatter the indices to all processes
comm.Scatterv([indices, counts, displacements, MPI.INT], recvbuf, root=0)

# Each process prints its received indices
print(f"Process {rank} received indices: {recvbuf}")

DRY_NODE_FLAG = -99999.0

counter = 0

for i in recvbuf:

    df_corrections_ = df_corrections[df_corrections['index'] == i].copy()

    ds = nc.Dataset(NC_FIELDS_UNCORRECTED, 'r')

    print('Getting Original Elements and Nodes from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    elements = elements_original.copy()
    nodes = nodes_original.copy()

    print('Removing Dry Nodes from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    # remove dry nodes
    levels = ds['zeta'][i, :].data
    levels = levels[old_idxs_set_array]
    mask = levels == DRY_NODE_FLAG
    removed_node_indices = np.arange(len(nodes))[mask]
    nodes, elements, remaining_node_indices = update_mesh_and_nodes(nodes, elements, removed_node_indices)
    #original_zeta = levels[remaining_node_indices].copy()

    node_pairs = find_antimeridian_pairs(nodes)
    
    if len(node_pairs) > 0:
        print(f'  Found {len(node_pairs)} antimeridian pairs')
        # Check if any pairs are suspiciously far apart
        suspicious_pairs = []
        for pair in node_pairs[:10]:  # Check first 10 pairs
            node0_coord = nodes[pair[0]]
            node1_coord = nodes[pair[1]]
            # Calculate approximate distance
            lat_diff = abs(node0_coord[1] - node1_coord[1])
            lon_diff = abs(node0_coord[0] - node1_coord[0])
            if lon_diff > 180:
                lon_diff = 360 - lon_diff
            dist_approx = np.sqrt(lat_diff**2 + lon_diff**2)
            if dist_approx > 1.0:  # More than 1 degree apart
                suspicious_pairs.append((pair, dist_approx, node0_coord, node1_coord))
        if len(suspicious_pairs) > 0:
            print(f'  WARNING: Found {len(suspicious_pairs)} antimeridian pairs that are >1 degree apart!')
            for sp in suspicious_pairs[:5]:
                print(f'    Pair {sp[0]}: distance={sp[1]:.2f}°, coords: {sp[2]} <-> {sp[3]}')

    ds.close()


    print('Building KD Tree from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    # build kd tree
    tree = scipy.spatial.cKDTree(nodes)


    print('Building Reverse Connectivity from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    # reverse connectivity
    #nodeid2elementid = {}
    #for j, element in enumerate(elements):
    #    for n in element:
    #        nodeid2elementid.setdefault(n, []).append(j)

    nodeid2elementid = Dict.empty(
            key_type=nb.int64,              # Key type is int64
            value_type=ListType(nb.int64)   
    )
    nodeid2elementid = update_nodeid2elementid(nodeid2elementid, elements, len(nodes))
    
    print('Saving Indices for Laplacian from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    ## indices for laplacian
    #rows, cols = [], []
    #for j, element in enumerate(elements):
    #    for n1, n2 in [(element[0], element[1]), (element[1], element[2]), (element[0], element[2])]:
    #        rows.append(n1)
    #        cols.append(n2)
    #        rows.append(n2)
    #        cols.append(n1)

    rows, cols = generate_rows_cols(elements)

    for pair in node_pairs:

        rows.append(pair[0])
        cols.append(pair[1])

        rows.append(pair[1])
        cols.append(pair[0])

        #rows = np.append(rows, pair[0])
        #cols = np.append(cols, pair[1])

        #rows = np.append(rows, pair[1])
        #cols = np.append(cols, pair[0])

    rows = np.array(rows)
    cols = np.array(cols)


    print('Enforcing Artificial Stations to Constrain Diffusion from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    # read artificial stations to constrain diffusion
    df_constrain = pd.read_csv('cloned_stations.csv')
#    df_constrain = pd.read_csv('cloned_stations2.csv')
    df_constrain['delta_low'] = -99999.0
    df_constrain = df_constrain[df_constrain['station_id'] != 0] # remove artificial stations on shelf

    # combine with real stations with artificial stations
    df_corrections_.drop(columns=['index','datetime'], inplace=True)
    df_all_stations = pd.concat([df_corrections_, df_constrain])
    df_all_stations.index = range(len(df_all_stations))
    df_all_stations['station_id'] = df_all_stations['station_id'].astype(int)

    # assign artifiical stations a delta_low
    for idx, val in df_all_stations.iterrows():
        if pd.isna(val['delta_low']):
            station_id = val['station_id']
            if station_id == 0:
                df_all_stations.at[idx, 'delta_low'] = 0
            else:
                vals = df_all_stations[df_all_stations['station_id'] == station_id]['delta_low'].dropna().values
                df_all_stations.at[idx, 'delta_low'] = vals[0] if len(vals) > 0 else DRY_NODE_FLAG
    df_all_stations = df_all_stations[df_all_stations['delta_low'] != DRY_NODE_FLAG]

    df_all_stations['lon'] = df_all_stations['lon'].astype(float)
    df_all_stations['lat'] = df_all_stations['lat'].astype(float)
    df_all_stations['delta_low'] = df_all_stations['delta_low'].astype(float)

    print('Formulating Laplacian from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))

    # formulte laplacian
    data = np.ones(len(rows), dtype=np.float64)
    adjacency_matrix = scipy.sparse.csr_matrix((data, (rows, cols)), shape=(nodes.shape[0], nodes.shape[0]))

    degree_matrix = scipy.sparse.csr_matrix((adjacency_matrix.sum(axis=1).A1, (np.arange(nodes.shape[0]), np.arange(nodes.shape[0]))))
    laplacian = degree_matrix - adjacency_matrix

    print('Checking for disconnected mesh components from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    # Find connected components in the mesh
    n_components, labels = scipy.sparse.csgraph.connected_components(adjacency_matrix, directed=False, return_labels=True)
    
    if n_components > 1:
        print(f'  WARNING: Found {n_components} disconnected components in mesh. Will identify components with boundary conditions.')
    
    print('Implementing Boundary Conditions from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    # determine stations that are in mesh (disregard stations that are not inside mesh)
    mask_, known_indices = [], []
    for idx, val in df_all_stations.iterrows():
        surge_point = (val['lon'], val['lat'])
        res = tree.query(surge_point, k=10)
        element_ids = {eid for n in res[1] if res[0][res[1] == n] < np.inf for eid in nodeid2elementid[n]}
        inside_element = False
        for eid in element_ids:
            x1, y1 = nodes[elements[eid, 0], :2]
            x2, y2 = nodes[elements[eid, 1], :2]
            x3, y3 = nodes[elements[eid, 2], :2]
            if checkIfPointIsInTriangle(x1, y1, x2, y2, x3, y3, surge_point[0], surge_point[1]):
                inside_element = True
                known_indices.append(elements[eid, 0])
                mask_.append(True)
                break
        if not inside_element:
            mask_.append(False)

    station_values_all = df_all_stations['delta_low'].values

    # If there are disconnected components, identify which ones have boundary conditions
    isolated_nodes = []  # Initialize empty list for isolated nodes
    if n_components > 1:
        # Find which components contain boundary conditions
        components_with_bc = set()
        for node_idx in known_indices:
            components_with_bc.add(labels[node_idx])
        
        print(f'  Found boundary conditions in {len(components_with_bc)} out of {n_components} components')
        
        # Find nodes in components WITHOUT boundary conditions
        for node_idx in range(len(nodes)):
            if labels[node_idx] not in components_with_bc:
                isolated_nodes.append(node_idx)
        
        if len(isolated_nodes) > 0:
            print(f'  WARNING: Found {len(isolated_nodes)} nodes in isolated components (no boundary conditions)')
            print(f'  These nodes will be set to zero in the solution')

    # implement BCs
    for row in known_indices:
        laplacian.data[laplacian.indptr[row]:laplacian.indptr[row + 1]] = 0
        laplacian[row, row] = 1
    values = np.zeros(nodes.shape[0])
    values[known_indices] = station_values_all[mask_]
    
    # Set isolated nodes (those in components without BCs) to have zero value
    if n_components > 1 and len(isolated_nodes) > 0:
        for row in isolated_nodes:
            laplacian.data[laplacian.indptr[row]:laplacian.indptr[row + 1]] = 0
            laplacian[row, row] = 1
            values[row] = 0.0

    print('Cleaning Laplacian Matrix Structure from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    # Explicitly remove zeroed-out off-diagonal entries from the sparse matrix structure.
    # This physically disconnects BC nodes from the mesh in the matrix graph,
    # preventing numerical "leakage" or structural confusion during regularization.
    laplacian.eliminate_zeros()
    
    print('Making Laplacian Nonsingular from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    # make laplacian nonsingular
    laplacian = adjust_laplacian(laplacian)
    
    del rows, cols
    gc.collect()

    ## solve
    print('Solving from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    if counter == 0:
        solution = scipy.sparse.linalg.spsolve(laplacian, values)
    else:
        #solution =scipy.sparse.linalg.spsolve(laplacian, values)
        solution = scipy.sparse.linalg.minres(laplacian, values, x0=global_solution[remaining_node_indices])[0]
        
    # Create solution array for all nodes in nodes_original (filtered mesh)
    global_solution = np.zeros(len(nodes_original), dtype=float)
    # Map solution from reduced mesh back to filtered mesh
    # remaining_node_indices[i] gives the nodes_original index for reduced mesh index i
    # So solution[i] (reduced mesh) maps to global_solution[remaining_node_indices[i]]
    
    # Validate mapping: check for duplicates in remaining_node_indices
    if len(remaining_node_indices) != len(np.unique(remaining_node_indices)):
        print(f'  ERROR: remaining_node_indices has duplicates! This will cause incorrect mapping!')
        print(f'  This is a critical bug - please check update_mesh_and_nodes function')
    
    # Validate index ranges
    if np.any(remaining_node_indices < 0) or np.any(remaining_node_indices >= len(nodes_original)):
        print(f'  ERROR: remaining_node_indices contains out-of-bounds indices!')
        print(f'  Min: {np.min(remaining_node_indices)}, Max: {np.max(remaining_node_indices)}, nodes_original size: {len(nodes_original)}')
    
    global_solution[remaining_node_indices] = solution
    
    # Handle antimeridian pairs: ensure both nodes in a pair get consistent values
    # Note: node_pairs contains (east_idx, west_idx) where indices are in the REDUCED mesh
    # remaining_node_indices maps from reduced mesh index to nodes_original index
    # So for a pair (reduced_idx_0, reduced_idx_1) in the reduced mesh:
    #   - orig_idx_0 = remaining_node_indices[reduced_idx_0] maps to nodes_original
    #   - orig_idx_1 = remaining_node_indices[reduced_idx_1] maps to nodes_original
    if len(node_pairs) > 0:
        invalid_pairs = 0
        for pair in node_pairs:
            reduced_idx_0, reduced_idx_1 = pair[0], pair[1]
            
            # Check bounds - these indices must be valid in the reduced mesh
            if reduced_idx_0 >= len(remaining_node_indices) or reduced_idx_1 >= len(remaining_node_indices):
                invalid_pairs += 1
                if invalid_pairs <= 5:  # Only print first few
                    print(f'  WARNING: Antimeridian pair has invalid reduced mesh indices: {pair}')
                    print(f'    reduced_idx_0={reduced_idx_0}, reduced_idx_1={reduced_idx_1}, len(remaining_node_indices)={len(remaining_node_indices)}')
                continue
            
            orig_idx_0 = remaining_node_indices[reduced_idx_0]
            orig_idx_1 = remaining_node_indices[reduced_idx_1]
            
            # Check bounds in nodes_original
            if orig_idx_0 >= len(global_solution) or orig_idx_1 >= len(global_solution):
                invalid_pairs += 1
                if invalid_pairs <= 5:
                    print(f'  WARNING: Antimeridian pair maps to invalid nodes_original indices: orig_idx_0={orig_idx_0}, orig_idx_1={orig_idx_1}, len(global_solution)={len(global_solution)}')
                continue
            
            # Ensure both nodes in the pair have the same value (use the average)
            # This ensures consistency across the antimeridian
            pair_value = (global_solution[orig_idx_0] + global_solution[orig_idx_1]) / 2.0
            global_solution[orig_idx_0] = pair_value
            global_solution[orig_idx_1] = pair_value
        
        if invalid_pairs > 0:
            print(f'  WARNING: Found {invalid_pairs} invalid antimeridian pairs (out of {len(node_pairs)} total)')

    print('Saving Solution from rank %d for datetime %s'%(rank, times[i].strftime('%Y-%m-%d %H:%M:%S')))
    global_solution.dump('%d.npy'%(i))
    
    counter += 1


comm.Barrier()

if rank == 0:

    print('Writing levels_with_bias.63.nc')

    names = []
    for name in os.listdir('.'):
        if name.endswith('.npy') and name[0].isnumeric():
            names.append(name)
    bias_correction_array = np.zeros((len(names),originalnumber_nodes), dtype=float)
    for i in range(len(names)):
        data = np.load('%d.npy'%(i), allow_pickle=True)
        bias_correction_array[i,old_idxs_set_array] = data

    # Specify the input and output file names
    input_file = NC_FIELDS_UNCORRECTED   # original fort.63
    output_file = NC_LEVELS_WITH_BIAS  # new fort.63
    
    # Open the existing NetCDF file in read mode
    src = nc.Dataset(input_file, 'r')
    
    # Create a new NetCDF file in write mode
    dst = nc.Dataset(output_file, 'w', format='NETCDF4')
    
    # Copy global attributes from the source to the destination
    for attr_name in src.ncattrs():
        setattr(dst, attr_name, getattr(src, attr_name))
    
    # Copy dimensions from the source to the destination
    for name, dimension in src.dimensions.items():
        dst.createDimension(
            name, (len(dimension) if not dimension.isunlimited() else None))
    
    # Copy all variables from the source to the destination, excluding the original zeta
    for name, variable in src.variables.items():
        if name != 'zeta':  # Skip the original zeta variable
            x = dst.createVariable(name, variable.datatype, variable.dimensions)
            # Copy variable attributes
            x.setncatts({k: variable.getncattr(k) for k in variable.ncattrs()})
            # Copy variable data
            x[:] = variable[:]
    
    # Define the dimensions for the new variable
    time_dim = 'time'  # Replace with the actual name of your time dimension if different
    node_dim = 'node'  # Replace with the actual name of your node dimension
    
    # Check if the dimensions exist
    if time_dim not in dst.dimensions or node_dim not in dst.dimensions:
        raise ValueError("Required dimensions are not present in the NetCDF file.")
    
    # Note: bias_correction variable is no longer written to the .63 file
    # but bias_correction_array is still available for other uses
    
    # Create the new variable 'zeta' as the sum of original zeta and bias_correction_array
    zeta = dst.createVariable(
        'zeta', 'f4', (time_dim, node_dim))
    zeta.units = 'meters'  # Same units as original zeta
    zeta.long_name = 'Corrected Water Level (original zeta + bias_correction)'  # Descriptive name
    
    # Calculate zeta as the sum of original zeta and bias_correction_array
    temp = src['zeta'][:, :].data
    temp[temp==DRY_NODE_FLAG] = np.nan
    temp = temp + bias_correction_array
    # Convert all NaNs to DRY_NODE_FLAG
    temp[np.isnan(temp)] = DRY_NODE_FLAG
    # Also handle any inf values
    temp[~np.isfinite(temp)] = DRY_NODE_FLAG
    zeta[:, :] = temp

    dst.close()
    src.close()

    print(f"New NetCDF file '{output_file}' has been created with corrected 'zeta' variable.")
    
    # Create maxele.63.nc file
    print('Creating maxele_with_bias.63.nc file...')


    # Open the corrected levels file to get the zeta_corrected data
    corrected_file = nc.Dataset(output_file, 'r')

    # Open original fort.63.nc to get boundary information if available
    src_fort63 = nc.Dataset(input_file, 'r')

    # Create maxele.63.nc file
    maxele_file = nc.Dataset(NC_MAXELE_WITH_BIAS, 'w', format='NETCDF4')

    # Copy global attributes from source file
    for attr_name in src_fort63.ncattrs():
        attr_value = getattr(src_fort63, attr_name)
        setattr(maxele_file, attr_name, attr_value)

    # Get dimensions from source
    num_nodes = len(corrected_file['x'][:])
    num_elements = len(corrected_file['element'][:])

    # Check if boundary dimensions exist in source
    nbou = len(src_fort63.dimensions['nbou']) if 'nbou' in src_fort63.dimensions else 0
    nvel = len(src_fort63.dimensions['nvel']) if 'nvel' in src_fort63.dimensions else 0
    max_nvell = len(src_fort63.dimensions['max_nvell']) if 'max_nvell' in src_fort63.dimensions else 0

    # Create dimensions
    maxele_file.createDimension('time', None)  # unlimited time dimension
    maxele_file.createDimension('node', num_nodes)
    maxele_file.createDimension('nele', num_elements)
    maxele_file.createDimension('nfaces', num_elements)
    maxele_file.createDimension('nvertex', 3)
    maxele_file.createDimension('nbou', nbou)
    maxele_file.createDimension('nvel', nvel)
    maxele_file.createDimension('max_nvell', max_nvell)

    # Create time variable with NaN values
    time_var = maxele_file.createVariable('time', 'f8', ('time',))
    if 'time' in src_fort63.variables:
        src_time = src_fort63['time']
        time_var.setncatts({k: src_time.getncattr(k) for k in src_time.ncattrs()})
    else:
        # Set default attributes if time doesn't exist in source
        time_var.long_name = 'model time'
        time_var.standard_name = 'time'
        time_var.units = 'seconds since 1970-01-01 00:00:00'
        time_var.base_date = '1970-01-01 00:00:00'
    # Hardcode to write exactly three values (converted from NaN to -99999)
        #time_var[:] = np.full(3, -99999.0)
    time_var[:] = corrected_file['time'][1]

    # Create x coordinate variable
    x_var = maxele_file.createVariable('x', 'f8', ('node',))
    x_var.long_name = 'longitude'
    x_var.standard_name = 'longitude'
    x_var.units = 'degrees_east'
    x_var.positive = 'east'
    x_var[:] = corrected_file['x'][:]

    # Create y coordinate variable
    y_var = maxele_file.createVariable('y', 'f8', ('node',))
    y_var.long_name = 'latitude'
    y_var.standard_name = 'latitude'
    y_var.units = 'degrees_north'
    y_var.positive = 'north'
    y_var[:] = corrected_file['y'][:]

    # Create element connectivity variable
    element_var = maxele_file.createVariable('element', 'i4', ('nfaces', 'nvertex'))
    element_var.long_name = 'element'
    element_var.cf_role = 'face_node_connectivity'
    element_var.start_index = 1
    element_var.units = 'nondimensional'
    element_var[:] = corrected_file['element'][:]

    # Create adcirc_mesh scalar variable
    adcirc_mesh_var = maxele_file.createVariable('adcirc_mesh', 'i4', ())
    adcirc_mesh_var.long_name = 'mesh_topology'
    adcirc_mesh_var.cf_role = 'mesh_topology'
    adcirc_mesh_var.topology_dimension = 2
    adcirc_mesh_var.node_coordinates = 'x y'
    adcirc_mesh_var.face_node_connectivity = 'element'

    # Create boundary variables if they exist in source
    if nbou > 0 and 'nvell' in src_fort63.variables:
        nvell_var = maxele_file.createVariable('nvell', 'i4', ('nbou',))
        nvell_var.long_name = 'number of nodes in each normal flow specified boundary segment'
        nvell_var.units = 'nondimensional'
        nvell_var[:] = src_fort63['nvell'][:]

    if nbou > 0 and 'ibtype' in src_fort63.variables:
        ibtype_var = maxele_file.createVariable('ibtype', 'i4', ('nbou',))
        ibtype_var.long_name = 'type of normal flow (discharge) boundary'
        ibtype_var.units = 'nondimensional'
        ibtype_var[:] = src_fort63['ibtype'][:]

    if nvel > 0 and 'nbvv' in src_fort63.variables:
        nbvv_var = maxele_file.createVariable('nbvv', 'i4', ('nvel',))
        nbvv_var.long_name = 'node numbers on normal flow boundary segment'
        nbvv_var.units = 'nondimensional'
        nbvv_var[:] = src_fort63['nbvv'][:]

    if nvel > 0 and 'barsp' in src_fort63.variables:
        barsp_var = maxele_file.createVariable('barsp', 'f8', ('nvel',))
        barsp_var.long_name = 'external/internal barrier boundary weir coefficient of supercritical flow'
        barsp_var.units = 'nondimensional'
        barsp_data = src_fort63['barsp'][:].copy()
        barsp_data[np.isnan(barsp_data)] = -99999.0
        barsp_data[~np.isfinite(barsp_data)] = -99999.0
        barsp_var[:] = barsp_data

    if nvel > 0 and 'barht' in src_fort63.variables:
        barht_var = maxele_file.createVariable('barht', 'f8', ('nvel',))
        barht_var.long_name = 'external/internal barrier boundary height above geoid'
        barht_var.units = 'm'
        barht_data = src_fort63['barht'][:].copy()
        barht_data[np.isnan(barht_data)] = -99999.0
        barht_data[~np.isfinite(barht_data)] = -99999.0
        barht_var[:] = barht_data

    if nvel > 0 and 'ibconn' in src_fort63.variables:
        ibconn_var = maxele_file.createVariable('ibconn', 'i4', ('nvel',))
        ibconn_var.long_name = 'internal barrier nodal connections'
        ibconn_var.units = 'nondimensional'
        ibconn_var[:] = src_fort63['ibconn'][:]

    if nvel > 0 and 'barsb' in src_fort63.variables:
        barsb_var = maxele_file.createVariable('barsb', 'f8', ('nvel',))
        barsb_var.long_name = 'internal barrier boundary weir coefficient of subcritical flow'
        barsb_var.units = 'nondimensional'
        barsb_data = src_fort63['barsb'][:].copy()
        barsb_data[np.isnan(barsb_data)] = -99999.0
        barsb_data[~np.isfinite(barsb_data)] = -99999.0
        barsb_var[:] = barsb_data

    # Create depth variable
    depth_var = maxele_file.createVariable('depth', 'f8', ('node',))
    if 'depth' in corrected_file.variables:
        src_depth = corrected_file['depth']
        depth_var.setncatts({k: src_depth.getncattr(k) for k in src_depth.ncattrs()})
    else:
        depth_var.long_name = 'distance  below geoid'
        depth_var.standard_name = 'depth below geoid'
        depth_var.coordinates = 'time y x'
        depth_var.location = 'node'
        depth_var.mesh = 'adcirc_mesh'
        depth_var.units = 'm'
    depth_data = corrected_file['depth'][:].copy()
    # Convert any NaNs or inf values to -99999
    depth_data[np.isnan(depth_data)] = -99999.0
    depth_data[~np.isfinite(depth_data)] = -99999.0
    depth_var[:] = depth_data

    # Define dry node flag
    DRY_NODE_FLAG = -99999.0

    # Calculate zeta_max and time_of_zeta_max from zeta (the corrected zeta)
    zeta_data = corrected_file['zeta'][:, :]
    zeta_max_data = np.max(zeta_data, axis=0)  # Maximum along time axis
    time_indices = np.argmax(zeta_data, axis=0)  # Index of maximum along time axis

    # Get time values for time_of_zeta_max
    if 'time' in corrected_file.variables:
        time_values = corrected_file['time'][:]
        time_of_zeta_max_data = time_values[time_indices]
    else:
        # Fallback: use time indices as seconds
        time_of_zeta_max_data = time_indices.astype('f8')

    # Convert all NaNs and inf values to DRY_NODE_FLAG before writing
    zeta_max_data[np.isnan(zeta_max_data)] = DRY_NODE_FLAG
    zeta_max_data[~np.isfinite(zeta_max_data)] = DRY_NODE_FLAG
    zeta_max_data[zeta_max_data == DRY_NODE_FLAG] = -99999.  # Ensure consistent fill value
    
    time_of_zeta_max_data[np.isnan(time_of_zeta_max_data)] = -99999.0
    time_of_zeta_max_data[~np.isfinite(time_of_zeta_max_data)] = -99999.0
    # Set fill value where zeta_max is fill value
    time_of_zeta_max_data[zeta_max_data == -99999.] = -99999.

    # Create zeta_max variable
    zeta_max_var = maxele_file.createVariable('zeta_max', 'f8', ('node',), fill_value=-99999.)
    zeta_max_var.long_name = 'maximum water surface elevationabove geoid'
    zeta_max_var.standard_name = 'maximum_sea_surface_height_above_geoid'
    zeta_max_var.coordinates = 'y x'
    zeta_max_var.location = 'node'
    zeta_max_var.mesh = 'adcirc_mesh'
    zeta_max_var.units = 'm'
    zeta_max_var[:] = zeta_max_data

    # Create time_of_zeta_max variable
    time_of_zeta_max_var = maxele_file.createVariable('time_of_zeta_max', 'f8', ('node',), fill_value=-99999.)
    time_of_zeta_max_var.long_name = 'time of maximum water surface elevationabove geoid'
    time_of_zeta_max_var.standard_name = 'time_of_maximum_sea_surface_height_above_geoid'
    time_of_zeta_max_var.coordinates = 'y x'
    time_of_zeta_max_var.location = 'node'
    time_of_zeta_max_var.mesh = 'adcirc_mesh'
    time_of_zeta_max_var.units = 'sec'
    time_of_zeta_max_var[:] = time_of_zeta_max_data

    # Set input file parameters - copy from source if available, otherwise set to NaN
    input_params = ['dt', 'ihot', 'ics', 'nolibf', 'nolifa', 'nolica', 'nolicat', 
                    'nwp', 'ncor', 'ntip', 'nws', 'nramp', 'tau0', 'statim', 'reftim', 
                    'rnday', 'dramp', 'a00', 'b00', 'c00', 'h0', 'slam0', 'sfea0', 
                    'cf', 'eslm', 'cori', 'ntif', 'nbfr']
    for param in input_params:
        if param in src_fort63.ncattrs():
            # Copy from source file if it exists
            attr_value = getattr(src_fort63, param)
            # Convert NaN to -99999 if present
            if isinstance(attr_value, (float, np.floating)) and (np.isnan(attr_value) or not np.isfinite(attr_value)):
                setattr(maxele_file, param, -99999.0)
            else:
                setattr(maxele_file, param, attr_value)
        else:
            # Set to -99999 if not found in source file (instead of NaN)
            setattr(maxele_file, param, -99999.0)

    # Set _FillValue global attribute
    maxele_file._FillValue = -99999.

    # Close files
    corrected_file.close()
    src_fort63.close()
    maxele_file.close()

    print("maxele_with_bias.63.nc file has been created successfully.")

comm.Barrier()


if rank == 0:
    print('Extrapolation Done.  Duration (seconds):', time.time()-start)
