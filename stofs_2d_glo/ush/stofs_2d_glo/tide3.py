'''
Contains the C code that does the actual tide calculations...
This code was based on astrti.f... We needed to re-write the code
so that we didn't need a fortran compiler.  In the process several
inefficiencies were discovered.

For algorithm information see tide.txt

Copyright (c) 2002 Arthur Taylor.

Notes:
  We could have difficulties switching from one year to the next, since
  there is a small discontinuity there.

  Main equation is:
     H(T) += Xode * Am * cos (PI/180 * (T * Ang + VP - EP))

NOS TIDE DATA IS STORRED FOR THE FORMULA:
Z=SUM(NODE(J)*AMP(J)*COS(ANG(J)*T+VPU(J)-EPOC(J))).
'''

import os
import argparse
from datetime import datetime
from functools import partial
from math import pi as PI
from pathlib import Path
from dataclasses import dataclass, field
from typing import Literal

import pytz
import numpy as np
import pandas as pd


LINE_LEN = 1000
NUMT = 37
MAX_RES = 0.05





@dataclass
class TideConstitType:
    mllw: int = 0
    nsta: int = -1
    year: int = -1
    xode: np.ndarray = field(default_factory=partial(np.empty, (NUMT,)))
    vpu: np.ndarray = field(default_factory=partial(np.empty, (NUMT,)))
    ang: np.ndarray = field(default_factory=partial(np.empty, (NUMT,)))
    amp: np.ndarray = field(default_factory=partial(np.empty, (NUMT,)))
    epoc: np.ndarray = field(default_factory=partial(np.empty, (NUMT,)))


@dataclass
class SecondaryType:
    secSta: int = -1  # init to -1, Which station
    maxTime: int = 0  # minutes, time additive.
    minTime: int = 0  # minutes, time additive.
    maxAdj: float = 0 # for multiplicative to max or min
    minAdj: float = 0 # for multiplicative to max or min
    maxInc: float = 0 # not read (set to 0)... for additive to max or min.
    minInc: float = 0 # not read (set to 0)... for additive to max or min.
    # Station location info ... not tide related.
    tc: TideConstitType = field(default_factory=TideConstitType)
    name1: str = ""
    name2: str = ""
    lat: float = 0
    lon: float = 0
    bsn: str = ""  # Which SLOSH ExtraTrop is it in.
    i: int = 0  # SLOSH ExtraTrop Grid Cell. */
    j: int = 0  # SLOSH ExtraTrop Grid Cell. */


@dataclass
class TideType:
    tc: TideConstitType = field(default_factory=TideConstitType)
    st: SecondaryType = field(default_factory=SecondaryType)
    ft03: os.PathLike = 'ft03.dta'
    ft07: os.PathLike = 'ft07.dta'
    ft08: os.PathLike = 'ft08.dta'
#    data: float


def read_format_ft03(
    line: str,
    beg: int,
    end: int,
    xode = np.ndarray,
    vpu = np.ndarray,
):
    '''
    Helper function to read_ft03.

    Variables:
      ptr      Current line that has been read in from file.
      beg      Where in arrays to start storing data read
      end      Where in arrays to stop storing data read
      xode     place to store the xodes (yearly constants)
      vpu      place to store the vpu (yearly constants)

    Returns:
      iyr      place to store the year

    Notes:
      ft03.dta updated in 2024 by Huiqing, we will run out in 2045.
            VPU = V + U, ANOTHER PHASE LEAD (DEG)
           XODE = NODE FACTOR
    '''

    iyr = int(line[:4])
    line = line[8:]

    for i in range(beg, end + 1):
        xode[i - 1] = int(line[:4]) / 1000
        vpu[i - 1] = int(line[4:8]) / 10
        line = line[8:]

    return iyr



def read_ft03(ft03_path, iyear, xode, vpu):
    '''
    Reads in the data from file ft03.dta... used to be called "rnos2"
    The file contains xode and vpu
        VPU = V + U, ANOTHER PHASE LEAD (DEG)
        XODE = NODE FACTOR
    
    Variables:
        ft03     Name of the file that contains the yearly constants.
        iyear    Year we are interested in
        xode     place to store the xodes (yearly constants)
        vpu      place to store the vpu (yearly constants)
    
    Returns:
        True on success, raises on error
    
    Notes:
        ft03.dta updated in 2024 by Huiqing, we will run out in 2045.
    '''

    with open(ft03_path, 'rt') as fp:
        line = fp.readline()

        iyr1 = int(line.split()[0])

        if iyear < iyr1:
            raise ValueError(f'Invalid year from ft03: <{iyr1}>')

        # Skip some lines (5 lines per year, 1st line already read)
        for _ in range((iyear-iyr1) * 5 - 1):
            fp.readline()

        # If year of interest is different, read first year row:
        if iyear != iyr1:
            line = fp.readline()

        iyr1 = read_format_ft03(line, 1, 8, xode, vpu)
        # if iyr1 != iyr now, then we have problems...
        if iyear != iyr1:
            raise ValueError("Encountered unexpected year entry!")

        for beg, end in [(9, 16), (17, 24), (25, 32), (33, NUMT)]:
            line = fp.readline()
            if line == "": 
                raise ValueError("Encountered unexpected EOF!")
            iyr1 = read_format_ft03(line, beg, end, xode, vpu)
            
    return True


def read_ang_ft07 (
    line: str,
    beg: int,
    end: int,
    ang: np.ndarray
):
    '''
    Helper function to read_ft07.  Handles the formatted reads dealing
    with angle. (see beginning of ft07 file)

    Variables:
      ptr      Current line that has been read in from file.
      beg      Where in arrays to start storing data read
      end      Where in arrays to stop storing data read
      ang      place to store the angle (or speed)

    Notes:
      To verify these angles see:
      http://www.co-ops.nos.noaa.gov/data_retrieve.shtml?input_code=100201001har
      This is the "speed" column.
    '''

    for i in range(beg, end + 1):
        ang[i - 1] = int(line[:10]) / 10000000
        line = line[10:]


def read_amp_epoc_ft07(
    line: str,
    beg: int,
    end: int,
    amp: np.ndarray,
    epoc: np.ndarray,
):
    '''
    Helper function to read_ft07.  Handles the formatted reads dealing
    with amplitude and epoch.

    Variables:
      ptr      Current line that has been read in from file.
      beg      Where in arrays to start storing data read
      end      Where in arrays to stop storing data read
      amp      place to store the amplitude
      epoch    place to store the epoch

    Notes:
      To verify these numbers see:
      http://www.co-ops.nos.noaa.gov/data_retrieve.shtml?input_code=100201001har
      This is the "ampl" and "epoch" columns.
    '''

    line = line[8:]
    for i in range(beg, end + 1):
        amp[i - 1] = int(line[:5]) / 1000
        epoc[i - 1] = int(line[5:9]) / 10
        line = line[9:]


def read_ft07(
    ft07_path,
    nsta: int,
    ang: np.ndarray,
    amp: np.ndarray,
    epoc: np.ndarray,
):
    '''
    Reads in the data from file ft07.dta
    The file contains MLLW, speeds (angles), and station specific epochs,
    and amplitudes.
     
     Variables:
       ft07     Name of the file that contains the station specific constants
       nsta     Which station to look for.
       ang      place to store the speed adjustments.
       amp      place to store the amplitude
       epoch    place to store the epoch
     
     Returns:
       mllw on success, raises on error
       mllw     place to store the mean lower low water adjustment.
     
     Notes:
       To verify these numbers see:
       http://www.co-ops.nos.noaa.gov/data_retrieve.shtml?input_code=100201001har
       This is the "ampl" and "epoch" columns.
     
       Originally f_seasonal was sent in here, and we did:
       if (! f_seasonal) {
         amp[15-1] = 0;
         amp[17-1] = 0;
       }
    '''

    # Assert that NUMT == 37.  Not necessary but a good safety check.
    # If NUMT != 37 some of the loops would be different.
#    assert(NUMT == 37)

    with open(ft07_path, 'rt') as fp:

        # Read in the angle data
        for i in range(1, 7):
            j1 = 1 + (i-1) * 7;
            j2 = NUMT if (NUMT < j1+6) else j1+6
            line = fp.readline()
            if line == "": 
                raise ValueError("Encountered unexpected EOF!")
            read_ang_ft07(line, j1, j2, ang)

        # Get to correct station.
        nrec = 8 * (nsta - 1);
        for i in range(1, nrec + 1):
            line = fp.readline()
            if line == "": 
                raise ValueError("Encountered unexpected EOF!")

        line = fp.readline()
        if line == "": 
            raise ValueError("Encountered unexpected EOF!")
        # Make sure we are at the right station.
        if nsta != int(line[:3]):
            raise ValueError("Encountered unexpected station ID!")

        # Get the mllw refrence datum.
        line = fp.readline()
        if line == "": 
            raise ValueError("Encountered unexpected EOF!")
        mllw = int(line[:6])

        # Read in the station constants.
        read_tuples = [
            (1, 7), (8, 14), (15, 21), (22, 28), (29, 35), (36, 37)
        ]
        for beg, end in read_tuples:
            line = fp.readline()
            if line == "": 
                raise ValueError("Encountered unexpected EOF!")
            read_amp_epoc_ft07(line, beg, end, amp, epoc)

    return mllw



def LoadConstit(
    tc: TideConstitType,
    ft03_path,
    ft07_path,
    year: int,
    nsta: int
):
    '''
    Reads in the constituent data needed to predict tides at a primary
    tidal station.
    
    Variables:
      tc       A pointer to the structure to read the constituents into
      ft03     Name of the file that contains the ft03 data (yearly stuff)
      ft07     Name of the file that contains the ft07 data (station stuff)
      year     The year we are interested in.
      nsta     The station we are interested in.
    
    Returns:
      True on success, raises on error
    
    Notes:
      We could have difficulties switching from one year to the next.
    '''

    if tc.year != year:
        tc.year = year
        read_ft03(ft03_path, year, tc.xode, tc.vpu)

    if tc.nsta != nsta:
        tc.nsta = nsta
        tc.mllw = read_ft07(ft07_path, nsta, tc.ang, tc.amp, tc.epoc)
    
    return True


def LoadSecond(
    st: SecondaryType,
    ft03_path,
    ft07_path,
    ft08_path,
    year: int,
    secSta: int,
):
    '''
    Reads in the constituent data needed to predict tides at a secondary
    tidal station.

    Variables:
      st       A pointer to the structure to read the constituents into
      ft03     Name of the file that contains the ft03 data (yearly stuff)
      ft07     Name of the file that contains the ft07 data (station stuff)
      ft08     Name of the file that contains the adjustments to the secondary
               station from the primary.
      year     The year we are interested in.
      secSta   The station we are interested in.

    Returns:
      True on success, raises on error

    Notes:
      We could have difficulties switching from one year to the next.
    '''

    # Check if we already have this station loaded.
    # May need to change ft03 or ft07...
    if st.secSta == secSta:
        return LoadConstit(st.tc, ft03_path, ft07_path, year, st.tc.nsta)

    work_line = ""
    with open(ft08_path, 'rt') as fp:
        # search for the correct station.
        for line in fp:
            if line[0] == '#':
                continue

            idx = line.find('|')
            if idx == -1:
                continue

            num = int(line[:idx])
            if num != secSta:
                continue

            st.secSta = secSta
            work_line = line[idx + 1:]
            break

        else:
            raise ValueError("Couldn't find the station in FT08 file!")

    # Parse the line
    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    st.name1 = work_line[:idx].strip()
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    st.name2 = work_line[:idx].strip()
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    st.bsn = work_line[:idx].strip()
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    st.i = int(work_line[:idx])
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    st.j = int(work_line[:idx])
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    st.lat = float(work_line[:idx])
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    st.lon = float(work_line[:idx])
    work_line = work_line[idx + 1:]
    
    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    refSta = int(work_line[:idx])
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    idx2 = work_line[:idx].find(':')
    if idx2 == -1:
        raise ValueError("Invalid line formatting for station!")
    hr = int(work_line[:idx][:idx2])
    minm = int(work_line[:idx][idx2 + 1:])
    st.maxTime = hr * 60 + minm
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    idx2 = work_line[:idx].find(':')
    if idx2 == -1:
        raise ValueError("Invalid line formatting for station!")
    hr = int(work_line[:idx][:idx2])
    minm = int(work_line[:idx][idx2 + 1:])
    st.minTime = hr * 60 + minm
    work_line = work_line[idx + 1:]

    idx = work_line.find('|')
    if idx == -1:
        raise ValueError("Invalid line formatting for station!")
    st.maxAdj = float(work_line[:idx])
    work_line = work_line[idx + 1:]

    st.minAdj = float(work_line);

    st.maxInc = 0
    st.minInc = 0

    return LoadConstit(st.tc, ft03_path, ft07_path, year, refSta);


def tide_t(
    tc: TideConstitType,
    t: float,
    z0: float,
    f_seasonal: bool,
):
    '''
    Compute the tide at time t where:
    t is a double in hours since beginning of year
         1hr 3 min since begining of year is t = 1.05
         18 seconds would be .005, 3 min would be .05,

    Variables:
      tc       A pointer that contains all the tidal constits.
      t        The time in hours from beginning of year loaded into tc that
               we want to compute the tide for.
      z0       What to init the water level to.

    Returns:
      z on success, raises on error
      z        Where to store the answer

    Notes:
      We could have difficulties switching from one year to the next.

                    NOS TIDE DATA IS STORRED FOR THE FORMULA:
                      Z=SUM(NODE(J)*AMP(J)*COS(ANG(J)*T+VPU(J)-EPOC(J))).
    '''

    if tc.nsta < 1 or tc.year == -1:
        raise ValueError("Invalid tide constituent info input!")

    z = z0;
    eqn = tc.xode * tc.amp * np.cos(PI/180 * (tc.ang * t + tc.vpu - tc.epoc))
    if f_seasonal:
        z = z + np.sum(eqn)
        
    else:
        # Skip constituent 14, and 16.
        z = z + np.sum(eqn[:14]) + eqn[15] + np.sum(eqn[17:])

    return z


def tide_hours(
    tc: TideConstitType,
    initHour: float,
    z0: float,
    f_seasonal: bool,
    numHours: int,
    delt: float
):
    '''
    Compute a number of hours of tide, from inital hour (hours since
    beginning of the year that is loaded into tc) to numHours later, storing
    the result in zhr, (which is allocated by caller to contain numHours + 1
    values).

    Variables:
      tc       A pointer that contains all the tidal constits.
      initHour The hour since the begining of the year at which to start.
      z0       What to init the water level to.
      f_seasonal If we want Seasonal adjusments or not.
      numHours How many hours to compute.
      delt     Usually 1, but we allow < 1 if delt * numHours < 24.

    Returns:
      zhr on success, raises on error
      zhr      where to store the answers.

    Notes:
      We could have difficulties switching from one year to the next.

                    NOS TIDE DATA IS STORRED FOR THE FORMULA:
                      Z=SUM(NODE(J)*AMP(J)*COS(ANG(J)*T+VPU(J)-EPOC(J))).
    '''

    if tc.nsta < 1 or tc.year == -1:
        raise ValueError("Invalid tide constituent info input!")

    zhr = z0 * np.ones((numHours,))

    # Using broadcasting
    ts = initHour + np.arange(numHours) * delt
    eqn = tc.xode * tc.amp * np.cos(
        PI/180 * (np.outer(ts, tc.ang) + tc.vpu - tc.epoc)
    )
    if f_seasonal:
        zhr = zhr + np.sum(eqn, axis=1)
        
    else:
        # Skip constituent 14, and 16.
        zhr = (
            zhr
            + np.sum(eqn[:, :14], axis=1)
            + eqn[:, 15]
            + np.sum(eqn[:, 17:], axis=1)
        )

    return zhr


def tide_MaxMin(
    tc: TideConstitType,
    t: float,
    z0: float,
    f_seasonal: bool,
):
    '''
    Compute the values of the Max and Min that surround a given time t.

    Variables:
      tc       A pointer that contains all the tidal constits.
      t        The hour since the begining of the year which defines where
               to start looking for the min/max.
      z0       What to init the water level to.
      f_seasonal If we want Seasonal adjusments or not.

    Returns:
      (hMax, tMax, hMin, tMin) on success, raises on error
      hMax     Where to store the Max value.
      tMax     Where to store the time of the Max (hours since beg of year)
      hMin     Where to store the Min value.
      tMin     Where to store the time of the Min (hours since beg of year)

    Notes:
      Current algorithm: steps away from t in intervals of .05 hours (3 min)
      Could switch to using MAX_RES to denote direction instead of having
        a big if section, but this adds complexity and computations.

      Would prefer a newton-raphon method of finding the min/max, but we
        would need to blend the tides to handle the end of year discontinuity
        and that adds too much complexity for too little improvement.
      One idea might be to do newton-raphon method when not near the end of
        the year (say 2 or 3 days from end of year?).
    '''

    hMax = np.inf
    tMax = np.inf
    hMin = -np.inf
    tMin = -np.inf

    # The only error check in tide_t is as follows...
    # If we check it now, we don't have to check error returns for
    # all the calls to tide_t.
    if tc.nsta < 1 or tc.year == -1:
        raise ValueError("Invalid tide constituent info input!")

    z = tide_t(tc, t, z0, f_seasonal)
    t1 = t - MAX_RES
    z1 = tide_t(tc, t1, z0, f_seasonal)
    # If they are equal, keep going to left.
    while z1 == z:
        t1 -= MAX_RES
        z1 = tide_t(tc, t1, z0, f_seasonal)

    if z1 < z:
        z2 = z
        while z1 < z2:
            z2 = z1
            t1 -= MAX_RES;
            z1 = tide_t(tc, t1, z0, f_seasonal)
        
        hMin = z2
        tMin = t1 + MAX_RES
        z1 = z
        t1 = t
        while z1 > z2:
            z2 = z1
            t1 += MAX_RES
            z1 = tide_t(tc, t1, z0, f_seasonal)
        
        hMax = z2
        tMax = t1 - MAX_RES

    else:
        z2 = z
        while z1 > z2:
            z2 = z1
            t1 -= MAX_RES
            z1 = tide_t(tc, t1, z0, f_seasonal)
        hMax = z2
        tMax = t1 + MAX_RES
        z1 = z
        t1 = t
        while z1 < z2:
            z2 = z1;
            t1 += MAX_RES;
            z1 = tide_t(tc, t1, z0, f_seasonal)
        
        hMin = z2
        tMin = t1 - MAX_RES

    return (hMax, tMax, hMin, tMin)


def secTide_t(
    st: SecondaryType,
    locT: float,
    z0: float,
    f_seasonal: bool,
):
    '''
    Compute the values of a secondary tidal station at time t where:
    t is a double in hours since beginning of year.
    1hr 3 min since begining of year is t = 1.05
    18 seconds would be .005, 3 min would be .05,

    Variables:
      st       A pointer to the secondary tidal constants.
      locT     The time in hours from beginning of (year loaded into st) that
               we want to compute the tide for.
      z0       What to init the water level to.
      f_seasonal If we want Seasonal adjusments or not.

    Returns:
      locZ on success, raises on error
      locZ     Where to store the answer (overwrites what is in here)

    Notes:
      Algorithm is as follows (see tide.txt) :
        1) Initial Guess for refT from locT
        2) Compute ref_hMin, ref_hMax surrounding refT
        3) Repeat 5 times (arbitrary, original version was 1): Make new guess
           of refT using ref_hMin/Max, and h(refT)
        4) Calc LocZ from h(refT): Adjust to mllw from mean tide level.
        5) multiply by multiplicative Adjustment
        6) add Additive Adjustment
    '''
    # Make sure user initialized st and that LoadSecond initialized
    # st->tc correctly.
    if st.secSta < 1:
        raise ValueError("secSta not initialized correctly!")

    if st.tc.nsta < 1 or st.tc.year == -1:
        raise ValueError("Invalid tide constituent info input!")

    # Inital guess for T and Z in refStation space.
    # The 60 is because maxTime, minTime are in minutes
    refT = locT - ((st.maxTime + st.minTime) / 2.) / 60.
    refZ = tide_t(st.tc, refT, z0, f_seasonal)

    # Compute ref_hMin, ref_hMax surrounding refT
    hMax, tMax, hMin, tMin = tide_MaxMin(st.tc, refT, z0, f_seasonal)

    # New guess for refT is : locT - TimeAdj
    # TimeAdj = (TL * (HH - Z) / (HH - HL) + TH * (Z - HL) / (HH - HL)
    for i in range(5):
        # The 60 is because maxTime, minTime are in minutes
        refT = locT - (
            st.minTime * (hMax - refZ) + st.maxTime * (refZ - hMin)
        ) / ((hMax - hMin) * 60.)
        refZ = tide_t(st.tc, refT, z0, f_seasonal)
    

    # Calc LocZ from h(refT): Adjust to mllw from mean tide level.
    locZ = refZ + (st.tc.mllw / 1000.);

    # Multiply by multiplicative Adjustment
    locZ = locZ * (
        st.minAdj * (hMax - refZ) + st.maxAdj * (refZ - hMin)
    ) / (hMax - hMin)

    # Add Additive Adjustment
    locZ = locZ + (
        st.maxInc * (hMax - refZ) + st.minInc * (refZ - hMin)
    ) / (hMax - hMin)

    return locZ


def secTide_hours(
    st: SecondaryType,
    initHour: float,
    z0: float,
    f_seasonal: bool,
    numHours: int,
    delt: float
):
    '''
    Compute a number of hours of a secondary tidal station, from inital
    hour (hours since beginning of the year that is loaded into tc) to
    numHours later, storing the result in zhr, (which is allocated by caller
    to contain numHours + 1 values).

    Variables:
      st       A pointer to the secondary tidal constants.
      initHour The hour since the begining of the year at which to start.
      z0       What to init the water level to.
      numHours How many hours to compute.
      delt     Usually 1, but we allow < 1 if delt * numHours < 24.

    Returns:
      zhr on success, raises on error
      zhr      where to store the answers.

    Notes:
      General Idea: Do it the same as secTide_t once, and then use that info
      for the rest...
    '''
    # Make sure user initialized st and that LoadSecond initialized
    # st->tc correctly.
    if st.secSta < 1:
        raise ValueError("secSta not initialized correctly!")

    if st.tc.nsta < 1 or st.tc.year == -1:
        raise ValueError("Invalid tide constituent info input!")

    zhr = np.empty((numHours,))
    i = 0
    locT = initHour

    # Repeat secTide_t here for i = 0.
    refT = locT - ((st.maxTime + st.minTime) / 2.) / 60.;
    refZ = tide_t(st.tc, refT, z0, f_seasonal);
    hMax, tMax, hMin, tMin = tide_MaxMin(st.tc, refT, z0, f_seasonal)
    for j in range(5):
        refT = locT - (
            st.minTime * (hMax - refZ) + st.maxTime * (refZ - hMin)
        ) / ((hMax - hMin) * 60.)
        refZ = tide_t(st.tc, refT, z0, f_seasonal)
    
    zhr[i] = refZ + (st.tc.mllw / 1000.)
    zhr[i] = zhr[i] * (
        st.minAdj * (hMax - refZ) + st.maxAdj * (refZ - hMin)
    ) / (hMax - hMin)
    zhr[i] += (
        st.maxInc * (hMax - refZ) + st.minInc * (refZ - hMin)
    ) / (hMax - hMin)

    locT += delt;
    for i in range(1, numHours):
        # Inital guess for new locT in refStation space is old refT + 1.
        refT += delt
        refZ = tide_t(st.tc, refT, z0, f_seasonal)

        # Compute ref_hMin, ref_hMax surrounding refT
        if refT > tMax and refT > tMin:
            hMax, tMax, hMin, tMin = tide_MaxMin(st.tc, refT, z0, f_seasonal);
        

        # New guess for refT is : locT - TimeAdj
        # TimeAdj = (TL * (HH - Z) / (HH - HL) + TH * (Z - HL) / (HH - HL)
        for j in range(5):
            # The 60 is because maxTime, minTime are in minutes
            refT = locT - (
                st.minTime * (hMax - refZ) + st.maxTime * (refZ - hMin)
            ) / ((hMax - hMin) * 60.)
            refZ = tide_t(st.tc, refT, z0, f_seasonal)

        zhr[i] = refZ + (st.tc.mllw / 1000.);
        zhr[i] = zhr[i] * (
            st.minAdj * (hMax - refZ) + st.maxAdj * (refZ - hMin)
        ) / (hMax - hMin)
        zhr[i] += (
            st.maxInc * (hMax - refZ) + st.minInc * (refZ - hMin)
        ) / (hMax - hMin)
        locT += delt;
    
    return zhr


def TideC_stn(
    cmd: Literal['hourly', 'single', 'mllw', 'config'],
    station: int = -1,
    date: datetime = pd.NaT,
    numHour: int = 4 * 24,
    initHeight: float = 0.0,
    ft03_path: os.PathLike = 'ft03.dta',
    ft07_path: os.PathLike = 'ft07.dta',
    ft08_path: os.PathLike = 'ft08.dta',
    is_seasonal: bool = True,
    is_secondary: bool = False,
    add_mllw: bool = False,
    delt: float = 1,
):

    # TideC_stn takes data in Local Standard Time (for station) 
    assert(date.tzinfo is not None)

    cmd = cmd.lower()

    if cmd != 'hourly':
        raise NotImplementedError('Only hourly is implemented for now!')

    # From tide.c tcl wrapper code
    tt = TideType(ft03=ft03_path, ft07=ft07_path, ft08=ft08_path)

    if delt != 1:
        if delt > 1 or delt * numHour > 24:
            raise ValueError(
                'If not 1, `delt` should be less than 1, and multipled'
                + ' by `numHour` it should be less than 24'
            )

    # Validate `station` and `date`
    if cmd != 'config':
        if date is pd.NaT:
            raise ValueError(
                'To run hourly tide calculation `date` must be provided'
            )

        if station == -1:
            raise ValueError('Station input must be provided!')

    elif station == -1 or date is pd.NaT:
        return True

    if not 1800 <= date.year <= 2045:
        raise ValueError('Date must be between year 1800 and 2045!')
    initHour = int(
        (date - datetime(year=date.year, month=1, day=1, tzinfo=date.tzinfo))
        .total_seconds()
        / 3600
    )



    if not is_secondary:
        if not LoadConstit(tt.tc, tt.ft03, tt.ft07, date.year, station):
            raise IOError("Unable to load primary contituents!")
        if add_mllw:
            initHeight += tt.tc.mllw / 1000
    else:
        if not LoadSecond(tt.st, tt.ft03, tt.ft07, tt.ft08, date.year, station):
            raise IOError("Unable to load secondary tides!")
        if not add_mllw:
            initHeight -= tt.st.tc.mllw / 1000
    

    # For hourly:
    if cmd == 'hourly':
        data = np.empty((numHour,))

        # Make sure they don't cross the year boundary.
        if numHour + initHour < 365 * 24:
            if not is_secondary:
                data = tide_hours(
                    tt.tc,
                    initHour,
                    initHeight,
                    is_seasonal,
                    numHour,
                    delt,
                )
            else:
                data = secTide_hours(
                    tt.st,
                    initHour,
                    initHeight,
                    is_seasonal,
                    numHour,
                    delt,
                )


        else:
            # Do it in 1 day chunks.
            # First get to end of day, then...
            # While numHour > 0
            # Copy the data, then go to next day by:
            # add 24 to initHour, subtract 24 from numHour
            #
            # If next day is over the year boundary, then update year,
            # Reload the constituents, and subtract from initHour
            year = date.year

            # Get to end of first day...
            endHour = 24 - int(initHour) % 24
            if endHour > numHour:
                # TODO: Does it ever hit this?
                endHour = numHour

            if not is_secondary:
                zhr = tide_hours(
                    tt.tc,
                    initHour,
                    initHeight,
                    is_seasonal,
                    endHour,
                    delt,
                )
            else:
                zhr = secTide_hours(
                    tt.st,
                    initHour,
                    initHeight,
                    is_seasonal,
                    endHour,
                    delt,
                )

            # store the data.
            data = zhr.copy()
            
            initHour += endHour;
            numHour -= endHour;

            if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
                totHour = 366 * 24
            else:
                totHour = 365 * 24
            
            while numHour > 0:
                # check if we crossed the year boundary.
                if initHour >= totHour:
                    initHour -= totHour;
                    year += 1
                    if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
                        totHour = 366 * 24
                    else:
                        totHour = 365 * 24

                    if not is_secondary:
                        if not LoadConstit(
                            tt.tc, tt.ft03, tt.ft07, year, station
                        ):
                            raise IOError("Unable to load primary contituents!")
                    else:
                        if not LoadSecond(
                            tt.st, tt.ft03, tt.ft07, tt.ft08, year, station
                        ):
                            raise IOError("Unable to load secondary tides!")
                
                if not is_secondary:
                    zhr = tide_hours(
                        tt.tc,
                        initHour,
                        initHeight,
                        is_seasonal,
                        24 if numHour > 24 else numHour,
                        delt,
                    )
                else:
                    zhr = secTide_hours(
                        tt.st,
                        initHour,
                        initHeight,
                        is_seasonal,
                        24 if numHour > 24 else numHour,
                        delt,
                    )

                
                # store the data
                data = np.hstack((data, zhr))

                numHour -= 24;
                initHour += 24;

        return data



def parse_cli():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--type',
        required=True,
        choices=['primary', 'secondary'],
        help='Secondary or Primary tidal staion')
    parser.add_argument(
        '--station', type=int, required=True, help='Which station?'
    )
    parser.add_argument(
        '--datetime',
        type=pd.to_datetime,
        required=True,
        help='Inital Year to compute tides for.'
    )
    parser.add_argument(
        '--numHours',
        type=int,
        required=True,
        help='How many hours to compute.'
    )
    parser.add_argument(
        '--mllw', action='store_true', help='Add mean lower low water?'
    )
    parser.add_argument(
        '--seasonal', action='store_true', help='Add seasonal adjustments?'
    )

    args = parser.parse_args()
    return args


def main(args):
    '''
    Main routine, used for testing, and as an example of how one might
    use Tcl/Tk to call this.

    Variables:
      args (argv array)
          <type>     Secondary or Primary tidal staion.
          <station>  Which station?
          <datetime> Inital datetime (yr, mo, dy, hr)
          <numHours> How many hours to compute.
          <mllw>     Add mean lower low water?
          <seasonal> Add seasonal adjustments?

    Returns:
      0 on success, -1 on error
    '''
    tc = TideConstitType()
    st = SecondaryType()
    z0 = 0


    if args.type == 'primary':
        type = 1
    elif args.type == 'secondary':
        type = 2
    else:
        raise ValueError(f'Type {args.type} is not supported!')

    nsta = args.station
    year = args.datetime.year
    month = args.datetime.month
    day = args.datetime.day
    hour = args.datetime.hour
    # TODO: integer + 1?
    ih = int(
        (args.datetime - datetime(year=year, month=1, day=1))
        .total_seconds()
        / 3600
    )
    numHours = args.numHours

    # reason for this is that the secondary tides already have mllw added to
    # them.  So responsibility for when to add mllw should be here
    f_mllw = args.mllw
    f_seasonal = args.seasonal

    zhr = np.empty((numHours,))
    if type == 1:
        if not LoadConstit(tc, "ft03.dta", "ft07.dta", year, nsta ):
            raise IOError("Unable to load primary contituents!")


        if f_mllw:
            z0 += tc.mllw / 1000.

        zhr = tide_hours(tc, ih, z0, f_seasonal, numHours, 1);

        for i in range(12):
            print(f'{i} {zhr[i]}')

        for i in range(11):
            z = tide_t(tc, ih + i * 0.1, z0, f_seasonal)
            print(f'{i * 0.1} {z}')

    else:
        if not LoadSecond(st, "ft03.dta", "ft07.dta", "ft08.dta", year, nsta):
            raise IOError("Unable to load secondary tides!")

        # Don't add mllw to secondary stations, because it was added to
        # the primary station prior to multiplying..
        if not f_mllw:
            z0 -= tc.mllw / 1000.

        zhr = secTide_hours(st, ih, z0, f_seasonal, numHours, 1)
        for i in range(24):
            print(f'{i} {zhr[i]}')

        for i in range(11):
            z = secTide_t(st, ih + i * 0.1, z0, f_seasonal)
            print(f'{i * 0.1} {z}')




if __name__ == '__main__':
      args = parse_cli()
      main(args)
