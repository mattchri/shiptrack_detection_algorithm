;Required
;F02: calibrated radiances file (e.g. MYD021KM)
;F03: geolocation file (e.g. MYD03)
;F06: cloud file (e.g. MYD06)
;Filtered_TrackPixels: locations of polluted and unpolluted cloud pixels

FUNCTION AUTO_FETCH_MODIS_PRODUCT,F02,F03,F06,Filtered_TrackPixels,OUTPUT_FILE=OUTPUT_FILE

;READ MODIS CALIBRATED RADIANCES DATA 
read_mod02,f02[0],rad02,str2,str2_long,units2
 nvar2 = N_ELEMENTS(str2)

;READ MODIS GEOLOCATION DATA
read_mod03,f03[0],rad03,str3,str3_long,units3
 nvar3 = N_ELEMENTS(str3)

;READ MODIS CLOUD DATA
READ_MOD06_C6,f06[0],rad06,str6,str6_long,units6
 nvar6 = N_ELEMENTS(str6)

;Combine MODIS Datasets
xDim = (SIZE( rad02 ))[1]
yDim = (SIZE( rad02 ))[2]
nVars = N_ELEMENTS(str2) + N_ELEMENTS(str3) + N_ELEMENTS(str6)

MODIS_DATA = FLTARR( xDim, yDim, nVars )

;Fill Array
MODIS_DATA[*,*,0:nvar2-1] = rad02
MODIS_DATA[*,*,nvar2:nvar2+nvar3-1] = rad03
MODIS_DATA[*,*,nvar2+nvar3:nvars-1] = rad06

MODIS_STR = [str2,str3,str6]
MODIS_STR_LONG = [str2_long,str3_long,str6_long]
MODIS_units    = [units2,units3,units6]

;Fetch MODIS Product for SHIP Pixels
SHIP_MODIS_DATA = FLTARR( nVars, (SIZE(Filtered_TrackPixels.SHIP))[2] )
 xDev = REFORM( Filtered_TrackPixels.SHIP[0,*] )
 yDev = REFORM( Filtered_TrackPixels.SHIP[1,*] )
 FOR J=0,N_ELEMENTS(xDev)-1 DO SHIP_MODIS_DATA[ *, J ] = MODIS_DATA[ xDev[J], yDev[J], * ]
 
;Fetch MODIS Product for CON1 Pixels
CON1_MODIS_DATA = FLTARR( nVars, (SIZE(Filtered_TrackPixels.CON1))[2] )
 xDev = REFORM( Filtered_TrackPixels.CON1[0,*] )
 yDev = REFORM( Filtered_TrackPixels.CON1[1,*] )
 FOR J=0,N_ELEMENTS(xDev)-1 DO CON1_MODIS_DATA[ *, J ] = MODIS_DATA[ xDev[J], yDev[J], * ]


;Fetch MODIS Product for CON2 Pixels
CON2_MODIS_DATA = FLTARR( nVars, (SIZE(Filtered_TrackPixels.CON2))[2] )
 xDev = REFORM( Filtered_TrackPixels.CON2[0,*] )
 yDev = REFORM( Filtered_TrackPixels.CON2[1,*] )
 FOR J=0,N_ELEMENTS(xDev)-1 DO CON2_MODIS_DATA[ *, J ] = MODIS_DATA[ xDev[J], yDev[J], * ]

outDATA = {SHIP:SHIP_MODIS_DATA, CON1:CON1_MODIS_DATA, CON2:CON2_MODIS_DATA,$
           MOD02_FILE:F02, MOD03_FILE:F03, MOD06_FILE:F06,$
           VARS:MODIS_STR, VARS_LONG:MODIS_STR_LONG, UNITS:MODIS_UNITS}

;Switch name to be consistent with netCDF routine
shiptrack_pixels = Filtered_TrackPixels

;Fetch latitude and longitude of the hand-logged locations
FOR iT=0,shiptrack_pixels.ntracks-1 DO FOR I=0,shiptrack_pixels.track_hand_logged_n_turns[iT]-1 DO shiptrack_pixels.track_hand_logged_locations[iT,2,I] = MODIS_DATA[shiptrack_pixels.track_hand_logged_locations[iT,0,I],shiptrack_pixels.track_hand_logged_locations[iT,1,I],7]

FOR iT=0,shiptrack_pixels.ntracks-1 DO FOR I=0,shiptrack_pixels.track_hand_logged_n_turns[iT]-1 DO shiptrack_pixels.track_hand_logged_locations[iT,2,I] = MODIS_DATA[shiptrack_pixels.track_hand_logged_locations[iT,0,I],shiptrack_pixels.track_hand_logged_locations[iT,1,I],6]

;Output NetCDF
IF N_ELEMENTS(OUTPUT_FILE) EQ 1 THEN AUTO_CREATE_NETCDF_FILE,shiptrack_pixels,OUTPUT_FILE,SATELLITE_DATA=outDATA

RETURN,outDATA
END
