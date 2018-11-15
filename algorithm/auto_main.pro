;+
;NAME:
;
;   Automated Ship Track Pixel Detection Scheme (main program)
;
;PURPOSE:
;
;   This procedure is used to detect clouds that are polluted by oceangoing vessels by
;   comparing the near-infrared reflectances along hand-logged ship track locations to
;   the surrounding clouds.
;
;Description: Ship track pixels are detected following the method described in
; Segrin et al. (2007). 
; The routine works in several (complex) steps (simply put here):
; 1) Hand-logged ship track locations are expanded and smoothed
; 2) Ship tracks are divided into 20 km along track semgments and 30 km cross track segments
; 3) Least squres fit is determined from back ground pixel radiances perpendicular to the ship track
; 4) Pixel radiances above the least squares fit + 4sigma are considered polluted unless 
;    nearest neighbor pixels were already removed (e.g., bright clouds far away from the ship track
;    cannot be selected).
; 5) Width of the polluted pixels are projected on both sides of the ship track.
; 6) Repeated values in control and ship masks are removed.
;   
;
;INPUT: PREFIX (the tfile that contains hand-logged position data)
;	MODIS data (MOD02, MOD03, MOD04, MOD06)
;
;OUTPUT: sav file of polluted and unpolluted pixel locations
;
;SUBROUTINES: 
;1) auto_expand_track_positions.pro
;2) auto_construct_segment.pro
;
;EXAMPLE
;auto_main,'/home/users/mchristensen/idl/trunk/ship/dispersion/t20061171615.dat','/group_workspaces/jasmin2/aopp/mchristensen/shiptrack/dispersion/MYD021KM.A2006117.1615.006.2012065235547.hdf','/group_workspaces/jasmin2/aopp/mchristensen/shiptrack/dispersion/MYD03.A2006117.1615.006.2012065231334.hdf','/group_workspaces/jasmin2/aopp/mchristensen/shiptrack/dispersion/MYD04_L2.A2006117.1615.006.2014038170619.hdf','/group_workspaces/jasmin2/aopp/mchristensen/shiptrack/dispersion/MYD06_L2.A2006117.1615.006.2014038183310.hdf',OUTPATH='~/Desktop/ship/dispersion/',/plot_track
;
;AUTHOR:
;    Matthew Christensen
;    Colorado State University
;    1/17/14
;###########################################################################
PRO AUTO_MAIN,TFILE=TFILE,F02=F02,F03=F03,F04=F04,F06=F06,OUTPATH=OUTPATH,PLOT_TRACK=PLOT_TRACK

;Passing enviornmental variables
 if ~keyword_set(TFILE) then TFILE = getenv('TFILE')
 if ~keyword_set(F02) then F02 = getenv('F02')
 if ~keyword_set(F03) then F03 = getenv('F03')
 if ~keyword_set(F04) then F04 = getenv('F04')
 if ~keyword_set(F06) then F06 = getenv('F06')
 if ~keyword_set(OUTPATH) then OUTPATH = getenv('OUTPATH')

;Paths
FILE_MKDIR,outpath

;Fetch t-file containing hand-logged locations
tfile = file_search(tfile,count=ttct)
IF TTCT EQ 0 THEN STOP,'Track file does not exist'


;OSU format
IF STRMID(FILE_BASENAME(tfile),0,2) EQ 't2' THEN BEGIN
 PREFIX = STRMID(FILE_BASENAME(tfile),strlen(FILE_BASENAME(tfile))-15,11)
 ;TIME
 YYYY = STRMID(PREFIX,0,4)
 DDD  = STRMID(PREFIX,4,3)
 HHHH = STRMID(PREFIX,7,4)
ENDIF

IF STRMID(FILE_BASENAME(tfile),0,2) EQ 'tM' THEN BEGIN
PREFIX = STRMID(FILE_BASENAME(tfile),0,STRPOS(FILE_BASENAME(tfile),'.dat'))
;TIME
YYYY = STRMID(PREFIX,8,4)
DDD  = STRMID(PREFIX,12,3)
HHHH = STRMID(PREFIX,16,4)
ENDIF


;FETCH MODIS FILES
F02=file_search(F02,count=f02ct)
F03=file_search(F03,count=f03ct)
F04=file_search(F04,count=f04ct)
F06=file_search(F06,count=f06ct)

;READ MODIS CALIBRATED RADIANCES DATA 
read_mod02,f02(0),rad02,str2,str2_long,units2

;READ ship track MODIS locations
read_osu_shiptrack_file,tfile(0),year,jday,hour,month,mday,trkct,trk_pos_ct,txs,tys

;Select Channel for detection algorithm
channel = 3 ; 2.1 um image
channel = 4 ; 3.7 um image
rad02 = reform( rad02(*,*,channel) )

;###########################################################################
;Run Semi-Automated Pixel Identification Scheme
;###########################################################################
;Example for multiple ship tracks in MODIS granule
;All ship tracks in MODIS Image
hVar = hash() ;store structures into a hash array
hVar('trkct') = trkct
FOR tI=0,trkct-1 do begin

 tnum = tI ;track number in MODIS granule
 xDev = REFORM( txs[tnum, 0:trk_pos_ct[tnum]-1] ) ;x-positions
 yDev = REFORM( tys[tnum, 0:trk_pos_ct[tnum]-1] ) ;y-positions

 ;Run algorithm (add dimension to hand-logged points to include lat & lon)
 TrackPixels = AUTO_PIXEL_IDENTIFICATION_SCHEME( xDev, yDev, ModisImage=rad02);, PLOT_TRACK=PLOT_TRACK)

 ;Save output
 hVar('tnum_'+STRING(FORMAT='(I03)',tI)) = TrackPixels

endfor

; Combine Ship Tracks
Filtered_TrackPixels = AUTO_FILTER_TRACK_PIXELS(hVar,OUTPUT_FILE=outPath+prefix+'_filtered_track_pixels'+'.nc')

; Fetch MODIS Cloud Properties
ncFile = outPath+prefix+'_track_pixels_and_MODIS_data.nc'
MODIS_Products = AUTO_FETCH_MODIS_PRODUCT( F02, F03, F06, Filtered_TrackPixels, OUTPUT_FILE=ncFile)

; Generic Plotting Routine
IF KEYWORD_SET(PLOT_TRACK) THEN AUTO_PLOT_OUTPUT_DATA, ncFile, HDF_FILE=F02, HDF_CHANNEL=channel

return
end
