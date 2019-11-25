#python3.7 -i /home/users/mchristensen/python/HYSPLIT/auto_main.py /home/users/mchristensen/Desktop/dispersion/t20061171615.dat /home/users/mchristensen/Desktop/dispersion/MYD021KM.A2006117.1615.006.2012065235547.hdf /home/users/mchristensen/Desktop/dispersion/MYD03.A2006117.1615.006.2012065231334.hdf /home/users/mchristensen/Desktop/dispersion/MYD04_L2.A2006117.1615.006.2014038170619.hdf /home/users/mchristensen/Desktop/dispersion/MYD06_L2.A2006117.1615.006.2014038183310.hdf /home/users/mchristensen/Desktop/dispersion/python/ 0
#python3.7 -i /home/users/mchristensen/python/HYSPLIT/auto_main.py /home/users/mchristensen/Desktop/dispersion/t20061171615.dat /home/users/mchristensen/Desktop/dispersion/MYD021KM.A2006117.1615.006.2012065235547.hdf /home/users/mchristensen/Desktop/dispersion/MYD03.A2006117.1615.006.2012065231334.hdf /home/users/mchristensen/Desktop/dispersion/MYD04_L2.A2006117.1615.006.2014038170619.hdf /home/users/mchristensen/Desktop/dispersion/MYD06_L2.A2006117.1615.006.2014038183310.hdf /home/users/mchristensen/Desktop/dispersion/python/ 1

from modis_module import *
from shiptrack_module import *
import sys
import os
import pdb

TFILE = sys.argv[1]
F02 = sys.argv[2]
F03 = sys.argv[3]
F04 = sys.argv[4]
F06 = sys.argv[5]
OUTPATH = sys.argv[6]
PLOT_TRACK = int(sys.argv[7])

print('input: ',TFILE,F02,F03,F04,F06,OUTPATH)

os.system('mkdir -p '+OUTPATH)

PREFIX = (os.path.basename(TFILE))[len((os.path.basename(TFILE)))-15:len((os.path.basename(TFILE)))-15+11]

#READ MODIS CALIBRATED RADIANCES DATA 
#read_mod02,f02(0),rad02,str2,str2_long,units2
chnl4 = read_mod02_single(F02)
geo = read_mod03_single(F03)
lon = geo['lon']
lat = geo['lat']
xN = lon.shape[1]
yN = lon.shape[0]

#Read ship track MODIS locations
track_geo = read_osu_shiptrack_file(TFILE)
trkct = track_geo['ntracks']

#Select Channel for detection algorithm
#channel = 3 ; 2.1 um image
#channel = 4 ; 3.7 um image
xDim = (np.shape(chnl4))[1]
yDim = (np.shape(chnl4))[0]
#re-order array to be consistent with IDL version
rad02 = np.zeros( (xDim,yDim) )
for i in range(xDim):
    for j in range(yDim):
        rad02[i,j] = chnl4[j,i]

###############################################################################
# Run Semi-Automated Pixel Identification Scheme
###############################################################################
hVar = []
for tI in range(trkct):
    tnum = tI #track number in MODIS granule
    xDev = ((track_geo['xpt'])[tI]).astype(np.float)
    yDev = ((track_geo['ypt'])[tI]).astype(np.float)
    
    #Run algorithm (add dimension to hand-logged points to include lat & lon)
    TrackPixels = auto_pixel_identification_scheme( xDev, yDev, rad02, plot_data=PLOT_TRACK)
    
    #Save output
    hVar.append(TrackPixels)
    
#Combine Ship Tracks
ncFile = OUTPATH + PREFIX+'_filtered_track_pixels.nc'
Filtered_TrackPixels = auto_filter_track_pixels(hVar, trkct, OUTPUT_FILE=ncFile)

#Fetch MODIS Cloud Properties
ncFile = OUTPATH + PREFIX+'_track_pixels_and_MODIS_data.nc'
MODIS_Products = auto_fetch_modis_product(F02, F03, F06, Filtered_TrackPixels, OUTPUT_FILE=ncFile)

# Generic Plotting Routine
#err = auto_plot_output_data(ncFile)
