;---------------------------------------------------------------------------------------------------------
;SUBROUTINE TO CREATE NETCDF FILE
;INPUT: shiptrack_pixels structure
PRO CREATE_NETCDF_FILE,shiptrack_pixels,ncfile

 ;open file
 ncid=ncdf_create(ncfile, /CLOBBER, /NETCDF4_FORMAT)

  ncdf_attput, ncid, /global,'n_shiptracks',shiptrack_pixels.ntracks
  ncdf_attput, ncid, /global,'sigma_threshold',shiptrack_pixels.sigma_thresh
  ncdf_attput, ncid, /global,'n_thresh'       ,shiptrack_pixels.n_thresh
  ncdf_attput, ncid, /global,'separate_dist'  ,shiptrack_pixels.separate_dist
  ncdf_attput, ncid, /global,'along_length'   ,shiptrack_pixels.along_length
  ncdf_attput, ncid, /global,'perp_length'    ,shiptrack_pixels.perp_length
  ncdf_attput, ncid, /global,'global attributes','n_shiptracks is the number of ship tracks in the MODIS image, sigma_threshold is the standard deviation level above the least squares fit-line used to determine which pixels are considered polluted in a given segment, n_thresh is the # of acceptable pixes that are under threshold from the along-track pixel, separate_dist is the # of pixels separating ship from controls, perp_length is the # of pixels in across track segment, and along_length is the # of pixels in along track segment'


  ;Define dimensions
  trackGeo=ncdf_dimdef(ncid,'track_geolocation',(SIZE(shiptrack_pixels.TRACK_HAND_LOGGED_LOCATIONS))[1])
  track1ID=ncdf_dimdef(ncid,'n_logged_bends',(SIZE(shiptrack_pixels.TRACK_HAND_LOGGED_LOCATIONS))[2])
  track2ID=ncdf_dimdef(ncid,'n_ship_tracks',(SIZE(shiptrack_pixels.TRACK_HAND_LOGGED_LOCATIONS))[3])
  statID=ncdf_dimdef(ncid, 'stat', (SIZE(shiptrack_pixels.ship))[1])
  shipID=ncdf_dimdef(ncid, 'ship_pixels',(SIZE(shiptrack_pixels.ship))[2])
  con1ID=ncdf_dimdef(ncid, 'con1_pixels',(SIZE(shiptrack_pixels.con1))[2])
  con2ID=ncdf_dimdef(ncid, 'con2_pixels',(SIZE(shiptrack_pixels.con2))[2])

  ;Dimensions
  dims_track= [trackGeo,track1ID,track2ID]
  dims_stat = [statID]
  dims_ship = [statID,shipID]
  dims_con1 = [statID,con1ID]
  dims_con2 = [statID,con2ID]

  vIDtrack=ncdf_vardef(ncid, 'track_logged_locations', dims_track)
  ncdf_attput,ncid, vIDtrack,'long_name',shiptrack_pixels.track_hand_logged_str
  ncdf_attput,ncid, vIDtrack,'track_n_turns',shiptrack_pixels.track_hand_logged_n_turns
  ncdf_attput,ncid, vIDtrack,'fill_value',-999.
  ncdf_attput,ncid, vIDtrack,'description','contains all of the locations for each ship track in the granule: dimensions: {x,y},{turning points},{shiptrack number}'

  vIDship=ncdf_vardef(ncid, 'ship', dims_ship)
  ncdf_attput,ncid, vIDship,'long_name',shiptrack_pixels.str
  ncdf_attput,ncid, vIDship,'units',shiptrack_pixels.unit
  ncdf_attput,ncid, vIDship,'description',shiptrack_pixels.long

  vIDcon1=ncdf_vardef(ncid, 'con1', dims_con1)
  ncdf_attput,ncid, vIDcon1,'long_name',shiptrack_pixels.str
  ncdf_attput,ncid, vIDcon1,'units',shiptrack_pixels.unit
  ncdf_attput,ncid, vIDcon1,'description',shiptrack_pixels.long

  vIDcon2=ncdf_vardef(ncid, 'con2', dims_con2)
  ncdf_attput,ncid, vIDcon2,'long_name',shiptrack_pixels.str
  ncdf_attput,ncid, vIDcon2,'units',shiptrack_pixels.unit
  ncdf_attput,ncid, vIDcon2,'description',shiptrack_pixels.long

 ;END define mode
 ncdf_control, ncid, /endef

 ncdf_varput, ncid, vIDtrack, shiptrack_pixels.track_hand_logged_locations
 ncdf_varput, ncid, vIDship, shiptrack_pixels.ship
 ncdf_varput, ncid, vIDcon1, shiptrack_pixels.con1
 ncdf_varput, ncid, vIDcon2, shiptrack_pixels.con2

;close netcdf file
ncdf_close,ncid
print,'CREATED: ',ncfile
END
;---------------------------------------------------------------------------------------------------------



FUNCTION AUTO_FILTER_TRACK_PIXELS,hVar,OUTPUT_FILE=OUTPUT_FILE

trkct = hvar('trkct')

;Combine all ship tracks from granule
trk_pos_loc = MAKE_ARRAY( 2, 100, trkct, /FLOAT, VALUE=-9999. )
trk_pos_ct = FLTARR( trkct )
FOR tI=0,trkct-1 DO BEGIN
 track_hand_logged_locations = hVar('tnum_'+STRING(FORMAT='(I03)',tI)).TRACK_HAND_LOGGED_LOCATIONS
 trk_pos_ct[tI] = (SIZE(track_hand_logged_locations))(2)
 trk_pos_loc[ *, 0:trk_pos_ct[tI]-1, tI ] = hVar('tnum_'+STRING(FORMAT='(I03)',tI)).TRACK_HAND_LOGGED_LOCATIONS
ENDFOR
trk_pos_loc = trk_pos_loc[ *, 0:MAX(trk_pos_ct)-1, *]



;Flag pixels in locations where ship pixels intersect control pixels
;combine all pixels from all ship tracks into array
all_ship = FLTARR(5,50000*trkct)
 all_ship_track_num = FLTARR(50000*trkct)
 all_shipCT = 0l

all_con1 = FLTARR(5,50000*trkct)
 all_con1_track_num = FLTARR(50000*trkct)
 all_con1CT = 0l

all_con2 = FLTARR(5,50000*trkct)
 all_con2_track_num = FLTARR(50000*trkct)
 all_con2CT = 0l
FOR tI=0,trkct-1 do begin
 SZ=SIZE(hVar('tnum_'+STRING(FORMAT='(I03)',tI)).SHIP)
 FOR J=0,SZ[2]-1 DO BEGIN
  all_ship[*,all_shipCT] = hVar('tnum_'+STRING(FORMAT='(I03)',tI)).SHIP[*,J]
  all_ship_track_num[all_shipCT] = tI
  all_shipCT++
 ENDFOR

 SZ=SIZE(hVar('tnum_'+STRING(FORMAT='(I03)',tI)).CON1)
 FOR J=0,SZ[2]-1 DO BEGIN
  all_con1[*,all_con1CT] = hVar('tnum_'+STRING(FORMAT='(I03)',tI)).CON1[*,J]
  all_con1_track_num[all_con1CT] = tI
  all_con1CT++
 ENDFOR

 SZ=SIZE(hVar('tnum_'+STRING(FORMAT='(I03)',tI)).CON2)
 FOR J=0,SZ[2]-1 DO BEGIN
  all_con2[*,all_con2CT] = hVar('tnum_'+STRING(FORMAT='(I03)',tI)).CON2[*,J]
  all_con2_track_num[all_con2CT] = tI
  all_con2CT++
 ENDFOR

endfor
all_ship = all_ship[*,0:all_shipCT-1]
all_ship_track_num = all_ship_track_num[0:all_shipCT-1]

all_con1 = all_con1[*,0:all_con1CT-1]
all_con1_track_num = all_con1_track_num[0:all_con1CT-1]

all_con2 = all_con2[*,0:all_con2CT-1]
all_con2_track_num = all_con2_track_num[0:all_con2CT-1]

ship_flag = BYTARR( all_shipCT )
con1_flag = BYTARR( all_con1CT )
con2_flag = BYTARR( all_con2CT )

;Loop through all ship pixels
FOR I=0,all_shipCT-1 DO BEGIN
 shipX = all_ship[0,I]
 shipY = all_ship[1,I]

 ID_SHIP = WHERE( all_ship[0,*] EQ shipX and all_ship[1,*] EQ shipY, ID_SHIPCT)
 ID_CON1 = WHERE( all_con1[0,*] EQ shipX and all_con1[1,*] EQ shipY, ID_CON1CT)
 ID_CON2 = WHERE( all_con2[0,*] EQ shipX and all_con2[1,*] EQ shipY, ID_CON2CT)

 IF ID_SHIPCT GT 1 THEN ship_flag[I] = 1 ;ship contaminating ship (two-ship crossing)
 IF ID_CON1CT GT 0 THEN con1_flag[I] = 1 ;ship contaminating control 1
 IF ID_CON2CT GT 0 THEN con2_flag[I] = 1 ;ship contaminating control 2

ENDFOR


;Combine Arrays
ShipData = FLTARR( 7, all_shipCT )
 ShipData[0:4,*] = all_ship
 ShipData[5,*]   = all_ship_track_num
 ShipData[6,*]   = ship_flag

CON1Data = FLTARR( 7, all_con1CT )
 CON1Data[0:4,*] = all_con1
 CON1Data[5,*]   = all_con1_track_num
 CON1Data[6,*]   = con1_flag

CON2Data = FLTARR( 7, all_con2CT )
 CON2Data[0:4,*] = all_con2
 CON2Data[5,*]   = all_con2_track_num
 CON2Data[6,*]   = con2_flag

;Add additional elements to output array
str_px = [hvar('tnum_001').str,'track-number-in-image','filter-flag']

;Carry over contents from structure into new filtered output structure
sigma_thresh = hvar('tnum_001').sigma_thresh
n_thresh = hvar('tnum_001').n_thresh
separate_dist = hvar('tnum_001').separate_dist
along_length = hvar('tnum_001').along_length
perp_length = hvar('tnum_001').perp_length
track_hand_logged_str = hvar('tnum_001').track_hand_logged_str
str_px_loc_unit = hvar('tnum_001').unit
str_px_loc_long = hvar('tnum_001').long


;Write output to structure
shiptrack_pixels = { ntracks:trkct, TRACK_HAND_LOGGED_LOCATIONS:trk_pos_loc, TRACK_HAND_LOGGED_N_TURNS:TRK_POS_CT, TRACK_HAND_LOGGED_STR:TRACK_HAND_LOGGED_STR,$
ship:ShipData, con1:con1Data, con2:con2Data, str:str_px, unit:str_px_loc_unit, long:str_px_loc_long, $
sigma_thresh:sigma_thresh, n_thresh:n_thresh, separate_dist:separate_dist, along_length:along_length, perp_length:perp_length }


;Output NetCDF
IF N_ELEMENTS(OUTPUT_FILE) EQ 1 THEN CREATE_NETCDF_FILE,shiptrack_pixels,OUTPUT_FILE


RETURN,shiptrack_pixels
END
