;---------------------------------------------------------------------------------------------------------
;SUBROUTINE TO CREATE NETCDF FILE
;INPUT: shiptrack_pixels structure
PRO CREATE_NETCDF_FILE,shiptrack_pixels,outDATA,ncfile

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
  MODISID=ncdf_dimdef(ncid,'modis_variables',N_ELEMENTS(MODIS_STR))

  ;Dimensions
  dims_track= [trackGeo,track1ID,track2ID]
  dims_stat = [statID]
  dims_ship = [statID,shipID]
  dims_con1 = [statID,con1ID]
  dims_con2 = [statID,con2ID]
   dims_ship_modis = [MODISID, shipID]
   dims_con1_modis = [MODISID, con1ID]
   dims_con2_modis = [MODISID, con2ID]

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

  vIDshipMODIS=ncdf_vardef(ncid, 'ship_modis', dims_ship_modis)
  ncdf_attput,ncid, vIDshipMODIS,'variables',outDATA.VARS
  ncdf_attput,ncid, vIDshipMODIS,'units',outDATA.UNITS
  ncdf_attput,ncid, vIDshipMODIS,'long',outDATA.VARS_LONG

  vIDcon1MODIS=ncdf_vardef(ncid, 'con1_modis', dims_con1_modis)
  ncdf_attput,ncid, vIDcon1MODIS,'variables',outDATA.VARS
  ncdf_attput,ncid, vIDcon1MODIS,'units',outDATA.UNITS
  ncdf_attput,ncid, vIDcon1MODIS,'long',outDATA.VARS_LONG

  vIDcon2MODIS=ncdf_vardef(ncid, 'con2_modis', dims_con2_modis)
  ncdf_attput,ncid, vIDcon2MODIS,'variables',outDATA.VARS
  ncdf_attput,ncid, vIDcon2MODIS,'units',outDATA.UNITS
  ncdf_attput,ncid, vIDcon2MODIS,'long',outDATA.VARS_LONG


 ;END define mode
 ncdf_control, ncid, /endef

 ncdf_varput, ncid, vIDtrack, shiptrack_pixels.track_hand_logged_locations
 ncdf_varput, ncid, vIDship, shiptrack_pixels.ship
 ncdf_varput, ncid, vIDcon1, shiptrack_pixels.con1
 ncdf_varput, ncid, vIDcon2, shiptrack_pixels.con2
 ncdf_varput, ncid, vIDshipMODIS, outDATA.ship
 ncdf_varput, ncid, vIDcon1MODIS, outDATA.con1
 ncdf_varput, ncid, vIDcon2MODIS, outDATA.con2

;close netcdf file
ncdf_close,ncid
print,'CREATED: ',ncfile
END
;---------------------------------------------------------------------------------------------------------






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


;Output NetCDF
IF N_ELEMENTS(OUTPUT_FILE) EQ 1 THEN CREATE_NETCDF_FILE,shiptrack_pixels,outDATA,OUTPUT_FILE

RETURN,outDATA
END
