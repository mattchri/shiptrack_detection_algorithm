;test_plot_single_track,'test.nc','/group_workspaces/cems2/nceo_generic/satellite_data/modis_c6/mod021km/2002/150/MOD021KM.A2002150.1855.006.2014231005506.hdf'
pro test_plot_single_track,ncfile,modis_hdf_radiances

;read netcdf file
STAT=READ_NCDF(ncfile,shiptrack_pixels)

xDev = REFORM( shiptrack_pixels.track_logged_locations[0,*] )
yDev = REFORM( shiptrack_pixels.track_logged_locations[1,*] )
trk_pos_ct = N_ELEMENTS(xDev)

ship_px_loc = shiptrack_pixels.ship
ship_px_ct  = N_ELEMENTS(shiptrack_pixels.ship[0,*])

con1_px_loc = shiptrack_pixels.con1
con1_px_ct  = N_ELEMENTS(shiptrack_pixels.con1[0,*])

con2_px_loc = shiptrack_pixels.con2
con2_px_ct  = N_ELEMENTS(shiptrack_pixels.con2[0,*])

 ;Get MODIS DATA 
 read_mod02,modis_hdf_radiances,rad02,str2,str2_long,units2

 ;Select Channel for detection algorithm
 channel = 3
 rad02 = reform( rad02(*,*,channel) )

;Dimensions of image
SZ = SIZE(RAD02)
xDim = SZ[1]
yDim = SZ[2]

 ;window projection coordinates     
 new_y = median( yDev )
 if new_y - 400. lt 0. then yoff = 0. else yoff = new_y-400.
 if new_y + 400. ge yDim then ymax=yDim-1 else ymax = new_y+400.

 ;colorize satellite data
 omin = median(rad02(*,yoff:ymax)) - stddev(rad02(*,yoff:ymax))*2.5
 if omin lt 0. then omin = 0.
 omax = median(rad02(*,yoff:ymax)) + stddev(rad02(*,yoff:ymax))*2.5
 if omax gt max(rad02(*,yoff:ymax)) then omax = max(rad02(*,yoff:ymax))
 satellite_mask  = bytscl(rad02(*,*),min=omin,max=omax,top=35)+220

 MULTI_COLORBAR
 dims = get_screen_size()
 window,0,xsize=1354,ysize=800,title=F02,xpos=dims(0)-1354      
 tv,satellite_mask(*,yoff:ymax)

 ;plot hand-logged track locations onto window
 for ij=0,trk_pos_ct-1 do plots,xDev[ij],yDev[ij]-yoff,/dev,color=2,psym=2,symsize=1

  ;Plot locations of polluted and unpolluted pixels
  for iii=0,ship_px_ct-1 do plots,ship_px_loc(0,iii),ship_px_loc(1,iii)-yoff,symsize=.1,color=2,psym=2,/dev
  for iii=0,con1_px_ct-1 do plots,con1_px_loc(0,iii),con1_px_loc(1,iii)-yoff,symsize=.1,color=3,psym=2,/dev
  for iii=0,con2_px_ct-1 do plots,con2_px_loc(0,iii),con2_px_loc(1,iii)-yoff,symsize=.1,color=4,psym=2,/dev

stop
end
