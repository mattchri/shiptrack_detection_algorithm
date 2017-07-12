;+
;NAME:
;
;   Driver program to process all ship tracks in a satellite image
;
;PURPOSE:
;
;   This (top-level) procedure pre-processes the input data for the Automated Scheme
;   for Identifying Ship Tracks (AUTO_PIXEL_IDENTIFICATION_SCHEME.pro)
;
;Description:
;   The processor requires two external datasets.
;     1) hand-logged ship track location ascii file (see readme for more information)
;     2) MODIS calibrated radiances, geolocation, and cloud product
;        files. MODIS data can be obtained from ftp://ladsweb.nascom.nasa.gov/allData/6/
;
;   Next a series of functions are executed to identify ship track and
;   control pixels. All of the tracks are processed individually over 
;   MODIS granule then combined to remove pixels that are contaminated
;   by adjacent ship tracks. Finally, the MODIS cloud properties are
;   extracted from the native files for the selected pixels and saved to
;   a NetCDF file.
;
;INPUT: PREFIX (the tfile that contains hand-logged position data)
;	MODIS data (MOD02, MOD03, MOD04, MOD06)
;
;OUTPUT: NetCDF file containing the polluted and unpolluted pixel
;        locations and MODIS cloud properties for all ship tracks identified
;        in the tfile.
;
;EXAMPLE
;AUTO_MAIN_PROCESSOR,'20021501855'
;
;AUTHORS
;    Matthew Christensen
;    Colorado State University
;
;History
; 2014/01/14, MC: Initial development
; 2017/07/12, MC: Refactored code to include NetCDF output options
;###########################################################################
pro AUTO_MAIN_PROCESSOR,PREFIX,PLOT_TRACK=PLOT_TRACK


;Paths
tfilepath = '../test_data/'
ModisRoot = '../test_data/'
outpath = '../output/'
 FILE_MKDIR,outpath
 
;Fetch t-file containing hand-logged locations of the ship track
tfile = tfilepath+'t20021501855.dat'


;TIME
YYYY = STRMID(PREFIX,0,4)
DDD  = STRMID(PREFIX,4,3)
HHHH = STRMID(PREFIX,7,4)

;FETCH MODIS FILES
F02=file_search(ModisRoot+'MOD021KM.A'+YYYY+DDD+'.'+HHHH+'*.hdf',count=f02ct)
F03=file_search(ModisRoot+'MOD03.A'+YYYY+DDD+'.'+HHHH+'*.hdf',count=f03ct)
F04=file_search(ModisRoot+'MOD04_L2.A'+YYYY+DDD+'.'+HHHH+'*.hdf',count=f04ct)
F06=file_search(ModisRoot+'MOD06_L2.A'+YYYY+DDD+'.'+HHHH+'*.hdf',count=f06ct)

;READ MODIS CALIBRATED RADIANCES DATA 
read_mod02,f02(0),rad02,str2,str2_long,units2

;READ ship track MODIS locations
read_osu_shiptrack_file,tfile(0),year,jday,hour,month,mday,trkct,trk_pos_ct,txs,tys

;Select Channel for detection algorithm
channel = 3 ; 2.1 um image
rad02 = reform( rad02(*,*,channel) )


;###########################################################################
;Run Semi-Automated Pixel Identification Scheme
;###########################################################################
;Example for an individual ship track
 ;tnum = 2  ;track number in MODIS granule
 ;xDev = txs[tnum, 0:trk_pos_ct[tnum]-1] ;x-positions
 ;yDev = tys[tnum, 0:trk_pos_ct[tnum]-1] ;y-positions
 ; Main function to obtain polluted/unpolluted pixels
 ;TrackPixels = AUTO_PIXEL_IDENTIFICATION_SCHEME( xDev, yDev, ModisImage=rad02, PLOT_TRACK=PLOT_TRACK)


;Example for multiple ship tracks in MODIS granule
;All ship tracks in MODIS Image
hVar = hash() ;store structures into a hash array
 hVar('trkct') = trkct
FOR tI=0,trkct-1 do begin

 tnum = tI ;track number in MODIS granule
 xDev = txs[tnum, 0:trk_pos_ct[tnum]-1] ;x-positions
 yDev = tys[tnum, 0:trk_pos_ct[tnum]-1] ;y-positions

 ;Run algorithm
 TrackPixels = AUTO_PIXEL_IDENTIFICATION_SCHEME( xDev, yDev, ModisImage=rad02, PLOT_TRACK=PLOT_TRACK, OUTPUT_FILE=outPath+prefix+'_track_pixels_'+STRING(FORMAT='(I03)',tI)+'.nc')

 ;Save output
 hVar('tnum_'+STRING(FORMAT='(I03)',tI)) = TrackPixels

endfor

; Combine Ship Tracks from MODIS image and Apply Quality Control
; Filtering by flagging pixels where adjacent ship tracks contaminate controls
Filtered_TrackPixels = AUTO_FILTER_TRACK_PIXELS(hVar,OUTPUT_FILE=outPath+prefix+'_filtered_track_pixels'+'.nc')

; Fetch MODIS Cloud Properties
ncFile = outPath+prefix+'_track_pixels_and_MODIS_data.nc'
MODIS_Products = AUTO_FETCH_MODIS_PRODUCT( F02, F03, F06, Filtered_TrackPixels, OUTPUT_FILE=ncFile)

; Generic Plotting Routine
AUTO_PLOT_OUTPUT_DATA, ncFile, ModisImage=rad02

return
end
