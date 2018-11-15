; Filtering by flagging pixels where adjacent ship tracks contaminate controls
FUNCTION AUTO_FILTER_TRACK_PIXELS,hVar,OUTPUT_FILE=OUTPUT_FILE

trkct = hvar('trkct')

;Combine all ship tracks from granule
;trk_pos_loc = MAKE_ARRAY( 4, 100, trkct, /FLOAT, VALUE=-9999. )
trk_pos_loc = MAKE_ARRAY( trkct, 4, 100, /FLOAT, VALUE=-9999. )
trk_pos_ct = FLTARR( trkct )
FOR tI=0,trkct-1 DO BEGIN
 track_hand_logged_locations = hVar('tnum_'+STRING(FORMAT='(I03)',tI)).TRACK_HAND_LOGGED_LOCATIONS
 trk_pos_ct[tI] = (SIZE(track_hand_logged_locations))(2)
 trk_pos_loc[ tI, 0:1, 0:trk_pos_ct[tI]-1 ] = hVar('tnum_'+STRING(FORMAT='(I03)',tI)).TRACK_HAND_LOGGED_LOCATIONS[0:1,*]
ENDFOR
trk_pos_loc = trk_pos_loc[ *, *, 0:MAX(trk_pos_ct)-1]


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
str_px = [hvar('tnum_000').str,'track-number-in-image','filter-flag']

;Carry over contents from structure into new filtered output structure
sigma_thresh = hvar('tnum_000').sigma_thresh
n_thresh = hvar('tnum_000').n_thresh
separate_dist = hvar('tnum_000').separate_dist
along_length = hvar('tnum_000').along_length
perp_length = hvar('tnum_000').perp_length
track_hand_logged_str = hvar('tnum_000').track_hand_logged_str
str_px_loc_unit = hvar('tnum_000').unit
str_px_loc_long = hvar('tnum_000').long


;Write output to structure
shiptrack_pixels = { ntracks:trkct, TRACK_HAND_LOGGED_LOCATIONS:trk_pos_loc, TRACK_HAND_LOGGED_N_TURNS:TRK_POS_CT, TRACK_HAND_LOGGED_STR:TRACK_HAND_LOGGED_STR,$
ship:ShipData, con1:con1Data, con2:con2Data, str:str_px, unit:str_px_loc_unit, long:str_px_loc_long, $
sigma_thresh:sigma_thresh, n_thresh:n_thresh, separate_dist:separate_dist, along_length:along_length, perp_length:perp_length }


;Output NetCDF
IF N_ELEMENTS(OUTPUT_FILE) EQ 1 THEN AUTO_CREATE_NETCDF_FILE,shiptrack_pixels,OUTPUT_FILE


RETURN,shiptrack_pixels
END
