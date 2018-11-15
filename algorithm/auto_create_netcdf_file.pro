;add option for MODIS keeping the same structure

;---------------------------------------------------------------------------------------------------------
;SUBROUTINE TO CREATE NETCDF FILE
;INPUT: shiptrack_pixels structure
PRO AUTO_CREATE_NETCDF_FILE,shiptrack_pixels,ncfile,SATELLITE_DATA=SATELLITE_DATA

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
  trackGeo=ncdf_dimdef(ncid,'track_geolocation',(SIZE(shiptrack_pixels.TRACK_HAND_LOGGED_LOCATIONS))[2])
  track1ID=ncdf_dimdef(ncid,'n_logged_bends',(SIZE(shiptrack_pixels.TRACK_HAND_LOGGED_LOCATIONS))[3])
  track2ID=ncdf_dimdef(ncid,'n_ship_tracks',(SIZE(shiptrack_pixels.TRACK_HAND_LOGGED_LOCATIONS))[1])
  statID=ncdf_dimdef(ncid, 'stat', (SIZE(shiptrack_pixels.ship))[1])
  shipID=ncdf_dimdef(ncid, 'ship_pixels',(SIZE(shiptrack_pixels.ship))[2])
  con1ID=ncdf_dimdef(ncid, 'con1_pixels',(SIZE(shiptrack_pixels.con1))[2])
  con2ID=ncdf_dimdef(ncid, 'con2_pixels',(SIZE(shiptrack_pixels.con2))[2])

  ;Dimensions
  ;dims_track= [trackGeo,track1ID,track2ID]
  dims_track= [track2ID,trackGeo,track1ID]
  dims_stat = [statID]
  dims_ship = [statID,shipID]
  dims_con1 = [statID,con1ID]
  dims_con2 = [statID,con2ID]

  IF N_ELEMENTS(SATELLITE_DATA) GT 0 THEN BEGIN
   MODISID=ncdf_dimdef(ncid,'modis_variables',N_ELEMENTS(MODIS_STR))
   dims_ship_modis = [MODISID, shipID]
   dims_con1_modis = [MODISID, con1ID]
   dims_con2_modis = [MODISID, con2ID]
  ENDIF

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

  IF N_ELEMENTS(SATELLITE_DATA) GT 0 THEN BEGIN
    vIDshipMODIS=ncdf_vardef(ncid, 'ship_modis', dims_ship_modis)
    ncdf_attput,ncid, vIDshipMODIS,'variables',SATELLITE_DATA.VARS
    ncdf_attput,ncid, vIDshipMODIS,'units',SATELLITE_DATA.UNITS
    ncdf_attput,ncid, vIDshipMODIS,'long',SATELLITE_DATA.VARS_LONG

    vIDcon1MODIS=ncdf_vardef(ncid, 'con1_modis', dims_con1_modis)
    ncdf_attput,ncid, vIDcon1MODIS,'variables',SATELLITE_DATA.VARS
    ncdf_attput,ncid, vIDcon1MODIS,'units',SATELLITE_DATA.UNITS
    ncdf_attput,ncid, vIDcon1MODIS,'long',SATELLITE_DATA.VARS_LONG

    vIDcon2MODIS=ncdf_vardef(ncid, 'con2_modis', dims_con2_modis)
    ncdf_attput,ncid, vIDcon2MODIS,'variables',SATELLITE_DATA.VARS
    ncdf_attput,ncid, vIDcon2MODIS,'units',SATELLITE_DATA.UNITS
    ncdf_attput,ncid, vIDcon2MODIS,'long',SATELLITE_DATA.VARS_LONG
  ENDIF

 ;END define mode
 ncdf_control, ncid, /endef

 ncdf_varput, ncid, vIDtrack, shiptrack_pixels.track_hand_logged_locations
 ncdf_varput, ncid, vIDship, shiptrack_pixels.ship
 ncdf_varput, ncid, vIDcon1, shiptrack_pixels.con1
 ncdf_varput, ncid, vIDcon2, shiptrack_pixels.con2

 IF N_ELEMENTS(SATELLITE_DATA) GT 0 THEN BEGIN
  ncdf_varput, ncid, vIDshipMODIS, SATELLITE_DATA.ship
  ncdf_varput, ncid, vIDcon1MODIS, SATELLITE_DATA.con1
  ncdf_varput, ncid, vIDcon2MODIS, SATELLITE_DATA.con2
 ENDIF

;close netcdf file
ncdf_close,ncid
print,'CREATED: ',ncfile
END
;---------------------------------------------------------------------------------------------------------
