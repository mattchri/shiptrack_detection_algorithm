;---------------------------------------------------------------------------------------------------------
;SUBROUTINE TO CREATE NETCDF FILE for auto_pixel_identification_scheme.pro
;INPUT: shiptrack_pixels structure
PRO CREATE_NETCDF_FILE,shiptrack_pixels,ncfile
 ;open file
 ncid=ncdf_create(ncfile, /CLOBBER, /NETCDF4_FORMAT)

  ncdf_attput, ncid, /global,'sigma_threshold',shiptrack_pixels.sigma_thresh
  ncdf_attput, ncid, /global,'n_thresh'       ,shiptrack_pixels.n_thresh
  ncdf_attput, ncid, /global,'separate_dist'  ,shiptrack_pixels.separate_dist
  ncdf_attput, ncid, /global,'along_length'   ,shiptrack_pixels.along_length
  ncdf_attput, ncid, /global,'perp_length'    ,shiptrack_pixels.perp_length
  ncdf_attput, ncid, /global,'segment_count'  ,shiptrack_pixels.segment_count
  ncdf_attput, ncid, /global,'global attributes','sigma_threshold is the standard deviation level above the least squares fit-line used to determine which pixels are considered polluted in a given segment, n_thresh is the # of acceptable pixes that are under threshold from the along-track pixel, separate_dist is the # of pixels separating ship from controls, perp_length is the # of pixels in across track segment, and along_length is the # of pixels in along track segment'

  ;Define dimensions
  trackID=ncdf_dimdef(ncid,'n_logged_locations',n_elements(shiptrack_pixels.track_hand_logged_locations[0,*]))
  trackGeo=ncdf_dimdef(ncid,'track_geolocation',2)
  statID=ncdf_dimdef(ncid, 'stat', (SIZE(shiptrack_pixels.ship))[1])
  shipID=ncdf_dimdef(ncid, 'ship_pixels',(SIZE(shiptrack_pixels.ship))[2])
  con1ID=ncdf_dimdef(ncid, 'con1_pixels',(SIZE(shiptrack_pixels.con1))[2])
  con2ID=ncdf_dimdef(ncid, 'con2_pixels',(SIZE(shiptrack_pixels.con2))[2])

  ;Dimensions
  dims_track= [trackGeo,trackID]
  dims_stat = [statID]
  dims_ship = [statID,shipID]
  dims_con1 = [statID,con1ID]
  dims_con2 = [statID,con2ID]

  vIDtrack=ncdf_vardef(ncid, 'track_logged_locations', dims_track)
  ncdf_attput,ncid, vIDtrack,'long_name',shiptrack_pixels.track_hand_logged_str

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




;#########################################################################################################
;+
;NAME:
;
;   Automated Scheme for Identifying Ship Tracks
;
;PURPOSE:
;
;   This procedure is used to detect clouds that are polluted by oceangoing vessels through
;   comparing thresholding near-infrared reflectances along hand-logged ship track locations
;   from surrounding clouds.
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
;INPUTS:
;Required
; xDev: hand-logged x postions 1D-array (in imager coordinates) of the ship
;       tracks from the satellite image
; yDev: hand-logged y positions 1D-array (in imager coordinates) of
;       the ship tracks from the satellite image
;
;Requires one of the following optinal inputs:
; ModisImage: 2D array (typically 1354 x 2030) containing the near-infrared reflectances
;  OR
; HDF_FILE: MODIS calibrated radiances file (021KM)
;   note, if HDF_FILE option is specified the near infrared channel
;   being used needs to be specified using HDF_CHANNEL (typically 3 or
;   4; for 2.1 or 3.7 um data)
;
;Optional:
; PLOT_TRACK: images of the ship track and resulting pixel data are displayed in a window
; OUTPUT_FILE: NETCDF filename to include locations of the ship track pixels
;
;SUBROUTINES: 
;1) auto_expand_track_positions.pro
;2) auto_construct_segment.pro
;3) lstqf.pro
;
;EXAMPLE
;TrackPixels = AUTO_PIXEL_IDENTIFICATION_SCHEME( [496,525,556,578,625,673,723,780],[683,711,736,756,791,816,842,874],HDF_FILE='../test_data/MOD021KM.A2002150.1855.006.2014231005506.hdf',HDF_CHANNEL=3, OUTPUT_FILE='../output/20021501855_track_test.nc',/PLOT_TRACK)
;
;AUTHORS
;    Matthew Christensen
;    Colorado State University
;
;History
; 2014/01/14, MC: Initial development
; 2017/07/12, MC: Refactored code to include NetCDF output options
;#########################################################################################################
FUNCTION AUTO_PIXEL_IDENTIFICATION_SCHEME,xDev,yDev,ModisImage=ModisImage,HDF_FILE=HDF_FILE,HDF_CHANNEL=HDF_CHANNEL,PLOT_TRACK=PLOT_TRACK,OUTPUT_FILE=OUTPUT_FILE

;Define Setup conditions for Shiptrack Pixel Detection Algorithm
sigma_thresh = 4.
n_thresh = 1         ;# of acceptable pixes that are under threshold from the along-track pixel
separate_dist = 2.   ;# of pixels separating ship from controls
perp_length = 30.    ;# of pixels in across track segment
along_length = 20.   ;# of pixels in along track segment

;---------------------------------------------------------------------------------------------------------
; Set Defaults (keywords)
IF KEYWORD_SET(PLOT_TRACK) EQ 1 THEN BEGIN
 ; Keep 24 bit graphics and retain window content
 device, true_color=24
 device, decompose=0, retain=2, bypass_translation=0
 loadct, 39
 !except = 0 ;ignore arithmetic error reporting
 !p.color = 0
 !p.background = 255
 MULTI_COLORBAR
ENDIF

IF N_ELEMENTS(HDF_FILE) EQ 0 AND N_ELEMENTS(ModisImage) EQ 0 THEN $
   STOP,'NEED TO INPUT EITHER A MODIS CALIBRATED RADIANCES FILE OR THE MODIS IMAGE ARRAY'
IF N_ELEMENTS(HDF_FILE) GT 0 AND N_ELEMENTS(ModisImage) GT 0 THEN $
   STOP,'ONE INPUT REQUIRED: EITHER A MODIS CALIBRATED RADIANCES FILE OR THE MODIS IMAGE ARRAY'

;HDF File is used as Input to fetch MODIS radiances
IF N_ELEMENTS(HDF_FILE) GT 0 THEN BEGIN
;PRINT,'HDF FILE INPUT'
 ;Get MODIS DATA 
 read_mod02,HDF_FILE,rad02,str2,str2_long,units2
 ;Select Channel for detection algorithm
 channel = HDF_CHANNEL ; 2.1 um image
 rad02 = reform( rad02(*,*,channel) )
ENDIF 

;MODIS radiances are directly input into scheme
IF N_ELEMENTS(ModisImage) GT 0 THEN BEGIN
;PRINT,'MODIS IMAGE ARRAY INPUT'
 rad02 = ModisImage
ENDIF

;---------------------------------------------------------------------------------------------------------
;Dimensions of image
SZ = SIZE(RAD02)
xDim = SZ[1]
yDim = SZ[2]

;hand-logged ship track locations
trk_pos_ct = N_ELEMENTS( xDev ) ;# of track bends
trackDevStr = ['x','y']
trackDev = INTARR(N_ELEMENTS(trackDevStr),N_ELEMENTS(xDev))
trackDev[0,*] = xDev
trackDev[1,*] = yDev
 
 ;Setup Plotting
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
 
 dims = get_screen_size()
 if n_elements(PLOT_TRACK) gt 0. then window,0,xsize=1354,ysize=800,title=F02,xpos=dims(0)-1354      
 if n_elements(PLOT_TRACK) gt 0. then tv,satellite_mask(*,yoff:ymax)
 
 ;plot hand-logged track locations onto window
 if n_elements(PLOT_TRACK) gt 0. then for ij=0,trk_pos_ct-1 do plots,xDev[ij],yDev[ij]-yoff,/dev,color=2,psym=2,symsize=1
      
 ;Step 1: Re-construct ship track postion (increase resolution between hand-logged locations) 
 tpts = auto_expand_track_positions(xDev,yDev)
  all_x = tpts.xTrack
  all_y = tpts.yTrack
  ;if n_elements(PLOT_TRACK) gt 0. then for is=0,n_elements(all_x)-1 do plots,all_x(is),all_y(is)-yoff,/dev,color=2,psym=3
 
 ;Step 2: calculate coordinate locations (along track and cross track) for each segment
 auto_construct_segment,yoff,along_length,perp_length,all_x,all_y,seg_parl_npix,seg_perp_npix,seg_dist,seg_re_x_all,seg_re_y_all,seg_dist_all
 segment_count = n_elements(seg_parl_npix)


 ;Step 3: process pixels in each segment
 ;Define arrays to store masks for ship & control pixels
 ;Detected pixel mask
 shipmask = fltarr(xDim,yDim)
 con1mask = fltarr(xDim,yDim)
 con2mask = fltarr(xDim,yDim)
 segmask  = fltarr(xDim,yDim) ;tells which segment
 segpixl   = fltarr(xDim,yDim) ;tells along track pixel location
 widthpixl   = fltarr(xDim,yDim) ;tells ship track width at along track pixel location
 ;Loop over each segment
 for j=0,segment_count-1 do begin
  parl_npix = seg_parl_npix(j)
  perp_npix = seg_perp_npix(j)
  
  if parl_npix gt 0. and perp_npix gt 0 then begin ;need to have a valid segment (this happens near the edge of granules)
  re_x_all  = reform( seg_re_x_all(j,0:parl_npix-1,0:perp_npix-1) )
  re_y_all  = reform( seg_re_y_all(j,0:parl_npix-1,0:perp_npix-1) )
  dist_all  = reform( seg_dist_all(j,0:parl_npix-1,0:perp_npix-1) )
  
  if min(re_x_all) ge 0. and max(re_x_all) le xDim then begin
  if min(re_y_all) ge 0. and max(re_y_all) le yDim then begin
     
  ;1D Array for radiances and locations of perpendicular pixels within +/-30 km
  seg_radiance = fltarr(parl_npix*perp_npix)
  seg_re_x = fltarr(parl_npix*perp_npix)
  seg_re_y = fltarr(parl_npix*perp_npix)
  seg_along = fltarr(parl_npix*perp_npix)
  seg_perp  = fltarr(parl_npix*perp_npix)
  seg_dist = fltarr(parl_npix*perp_npix)
  seg_allct = 0.
  
  ;Loop over along section
  for kkk=0,parl_npix-1 do begin      
   
   ;Loop over perpendicular section
   for ik=0,perp_npix-1 do begin
    if re_x_all(kkk,ik) gt 0. and re_y_all(kkk,ik) gt 0. then begin
     ;plots,re_x_all(kkk,ik),re_y_all(kkk,ik)-yoff,psym=2,symsize=.1,/dev
     if dist_all(kkk,ik) ne 0. and dist_all(kkk,ik) gt perp_length*(-1.) and dist_all(kkk,ik) lt perp_length*1. then begin     
     if rad02(re_x_all(kkk,ik),re_y_all(kkk,ik)) gt 0. then begin
      ;print,kkk,ik,re_x_all(kkk,ik),re_y_all(kkk,ik),dist_all(kkk,ik)
      seg_radiance(seg_allct) = rad02(re_x_all(kkk,ik),re_y_all(kkk,ik))
      seg_re_x(seg_allct) = re_x_all(kkk,ik)
      seg_re_y(seg_allct) = re_y_all(kkk,ik)
      seg_along(seg_allct) = kkk
      seg_perp(seg_allct) = ik     
      seg_dist(seg_allct) = dist_all(kkk,ik) 
      seg_allct++
     endif
     endif
    endif
   endfor
  endfor ;section-loop

  
  ;1D arrays for polluted cloud detection
  seg_re_x=seg_re_x(0:seg_allct-1)
  seg_re_y=seg_re_y(0:seg_allct-1) 
  seg_re_radiance = seg_radiance(0:seg_allct-1)
  seg_along = seg_along(0:seg_allct-1)
  seg_perp  = seg_perp(0:seg_allct-1)
  seg_dist  = seg_dist(0:seg_allct-1)

  if n_elements(PLOT_TRACK) gt 0. then window,12,xsize=400,ysize=400
  if n_elements(PLOT_TRACK) gt 0. then plot,seg_perp,seg_re_radiance,psym=1,/nodata,yrange=[0,max(seg_re_radiance)+stddev(seg_re_radiance)]
  if n_elements(PLOT_TRACK) gt 0. then for iii=0,n_elements(seg_perp)-1 do plots,seg_perp(iii),seg_re_radiance(iii),psym=2,symsize=.25
 
  ;Convert to pixel groups as a function of perpendicular line number
  bfrac = 0.65
  rads  = fltarr(2500,perp_npix)
  xs   = fltarr(2500,perp_npix)
  ys   = fltarr(2500,perp_npix)
  as   = fltarr(2500,perp_npix) ;along track pixel
  dists = fltarr(perp_npix)
  xpts = fltarr(perp_npix)
  all_xpts = fltarr(perp_npix)
  ypts = fltarr(perp_npix)
  bpts = fltarr(perp_npix)
  rank_5 = fltarr(perp_npix)
  run_mean = fltarr(perp_npix)
  cts = 0
  ;Loop over each perpendicular line
  for iii=0,perp_npix-1 do begin
   ;Get background of the cross track pixels that fall into perpendicular line
   junk=where(seg_perp eq iii and abs(seg_dist) ge perp_length*bfrac,bct)

   ;Get all of the cross track pixels that fall into perpendicular line
   junk=where(seg_perp eq iii,junkct)
   if junkct gt 0. then begin
    vals = reform( seg_re_radiance(junk) )
    rads(0:junkct-1,cts) = vals
    as(0:junkct-1,cts) = reform( seg_along(junk) )
    xs(0:junkct-1,cts) = seg_re_x(junk)
    ys(0:junkct-1,cts) = seg_re_y(junk)
    dists(cts) = mean( seg_dist(junk) )
    xpts(cts) = iii
    ypts(cts) = junkct
    bpts(cts) = bct

    ;Rank 5 of the perpendicular bin
    if junkct gt 10. then begin
     tmp=sort(vals)
     valsr=reverse(vals(tmp))
     rank_5(cts)   = valsr(4)
    endif
  
    ;Average of the perpendicular bin
    run_mean(cts) = mean(vals)
  
    cts++
   endif
   all_xpts(iii) = iii
  endfor ;perpendicular line-loop
  rads = rads(0:max(ypts)-1,0:cts-1)
  xs = xs(0:max(ypts)-1,0:cts-1)
  ys = ys(0:max(ypts)-1,0:cts-1)
  as = as(0:max(ypts)-1,0:cts-1)
  dists= dists(0:cts-1)
  xpts = xpts(0:cts-1)
  ypts = ypts(0:cts-1)
  bpts = bpts(0:cts-1)
  rank_5 = rank_5(0:cts-1)
  run_mean = run_mean(0:cts-1)

  ;Get least squres fit of background clouds
  bid=where(bpts gt 10.,bidct) ;only take perpendicular lines with background data (+/-35% of window from edges)

  ;Need to have at least 10 radiances in a perpendicular line to obtain a reprsentative 5th %rank
  if bidct gt 0. then begin
   bxpts=xpts(bid)
   brank_5=rank_5(bid)
   a=linfit(bxpts,brank_5)
   r_sig = stddev(brank_5)
   lstqf,bxpts,brank_5,stats,statn
   r_sig = stats(3)
   xxarr = findgen(perp_npix)
   if n_elements(PLOT_TRACK) gt 0. then oplot,bxpts,brank_5,psym=1,color=6
   if n_elements(PLOT_TRACK) gt 0. then oplot,xxarr,a(1)*xxarr+a(0)+sigma_thresh*r_sig,linestyle=2,color=2
   if n_elements(PLOT_TRACK) gt 0. then oplot,xxarr,a(1)*xxarr+a(0),linestyle=2,color=3

   ;Aquire threshold pixels marching outward from center pixel
   ;1st pixel (2 neighbors away) to dip below standard deviation threshold STOP
   good_pixels = fltarr(parl_npix,n_elements(xpts))
   n_neighbor_ct = 0

   ;Center index for current along-track pixel
   i0=where( abs(dists) eq min(abs(dists)))
   
   if n_elements(PLOT_TRACK) gt 0. then plots,[xpts(i0(0)),xpts(i0(0))],!y.(7)
   
   ;positive direction
   for nnn=i0(0),n_elements(xpts)-1 do begin 
    thresh = a(1)*xpts(nnn)+a(0)+sigma_thresh*r_sig
    thresh = thresh(0)
    ;print,nnn,thresh(0)
    rvals = rads(0:ypts(nnn)-1,nnn)
    junk=where( rvals gt thresh,junkct)
    if junkct gt 0. then begin    
     if n_elements(PLOT_TRACK) gt 0. then for iik=0,junkct-1 do plots,xpts(nnn),rad02( xs(junk(iik),nnn), ys(junk(iik),nnn) ),psym=2,color=2,symsize=.25
     good_pixels(as(junk,nnn),nnn)=1
    endif else begin
     n_neighbor_ct++
    endelse
    if n_neighbor_ct gt n_thresh then BREAK
   endfor
 
   n_neighbor_ct = 0
   ;negative direction
   for nnn=i0(0),0,-1 do begin 
    thresh = a(1)*xpts(nnn)+a(0)+sigma_thresh*r_sig
    thresh = thresh(0)
    ;print,nnn,thresh(0)
    rvals = rads(0:ypts(nnn)-1,nnn)
    junk=where( rvals gt thresh,junkct)
    if junkct gt 0. then begin    
     if n_elements(PLOT_TRACK) gt 0. then for iik=0,junkct-1 do plots,xpts(nnn),rad02( xs(junk(iik),nnn), ys(junk(iik),nnn) ),psym=2,color=2,symsize=.25
     good_pixels(as(junk,nnn),nnn)=1
    endif else begin
     n_neighbor_ct++
    endelse
    if n_neighbor_ct gt n_thresh then BREAK
   endfor
      
   ;Reset plotting screen to satellite image
   if n_elements(PLOT_TRACK) gt 0. then wset,0

   ;Now run back through segment in the along-track dimension
   ;determine perpendicular width for each along-track pixel
   ;Loop over along-track pixels
   for iii=0,parl_npix-1 do begin
       
    ;Determine width of ship track region
    width_px = fltarr(perp_npix)
    width_ct = fltarr(perp_npix)
    width_ct(*) = -999
    tempct=0
    ;Loop over perpendicular section
    for kkk=0,n_elements(xpts)-1 do begin
     if good_pixels(iii,kkk) eq 1 then begin ;a good pixel is one where the radiance is above sigma threshold
      width_px(kkk)=kkk
      width_ct(kkk)=tempct         
      tempct++
     endif        
    endfor
     
     re_size = size(re_x_all)
     ;Start only if a suitable ship track width was determined
     if tempct gt 0. then begin
      ;Define width
      junk=where(width_ct eq 0.)
      e3_id = width_px(junk)
      e3_id = e3_id(0)
      junk=where(width_ct eq tempct-1.)
      e4_id = width_px(junk)
      e4_id = e4_id(0)
      width=e4_id-e3_id
      
      ;print,j,along_length,iii,parl_npix,width,j*along_length + iii * along_length*1./parl_npix*1.
      
      ;Define Ship
      for kkk=e3_id,e4_id do begin
       if n_elements(PLOT_TRACK) gt 0. then plots,re_x_all(iii,kkk+xpts(0)),re_y_all(iii,kkk+xpts(0))-yoff,psym=2,symsize=.1,/dev,color=2
        ;print,j,iii,along_length*1./parl_npix*1.,j*along_length + iii * along_length*1./parl_npix*1.
        shipmask(re_x_all(iii,kkk+xpts(0)),re_y_all(iii,kkk+xpts(0) ))=1
        segmask(re_x_all(iii,kkk+xpts(0)),re_y_all(iii,kkk+xpts(0) ))=j
        segpixl(re_x_all(iii,kkk+xpts(0)),re_y_all(iii,kkk+xpts(0) ))=j*along_length + iii * along_length*1./parl_npix*1.
        widthpixl(re_x_all(iii,kkk+xpts(0)),re_y_all(iii,kkk+xpts(0) ))=width
      endfor

      ;Define Control 1 (negative)
      e1_id = e3_id-separate_dist-width
      e2_id = e3_id-separate_dist       
      for kkk=e1_id,e2_id do begin
       if (kkk+xpts(0)) lt re_size(2) then begin
        if n_elements(PLOT_TRACK) gt 0. then plots,re_x_all(iii,kkk+xpts(0)),re_y_all(iii,kkk+xpts(0))-yoff,psym=2,symsize=.1,/dev,color=3
        con1mask(re_x_all(iii,kkk+xpts(0) ),re_y_all(iii,kkk+xpts(0) ))=1
        segmask(re_x_all(iii,kkk+xpts(0) ),re_y_all(iii,kkk+xpts(0) ))=j
        segpixl(re_x_all(iii,kkk+xpts(0) ),re_y_all(iii,kkk+xpts(0) ))=j*along_length + iii * along_length*1./parl_npix*1.
        widthpixl(re_x_all(iii,kkk+xpts(0) ),re_y_all(iii,kkk+xpts(0) ))=width
       endif
      endfor

      ;Define Control 2 (positive)
      e5_id = e4_id+separate_dist
      e6_id = e4_id+separate_dist+width
      for kkk=e5_id,e6_id do begin
       if (kkk+xpts(0)) lt re_size(2) then begin
        if n_elements(PLOT_TRACK) gt 0. then plots,re_x_all(iii,kkk+xpts(0)),re_y_all(iii,kkk+xpts(0))-yoff,psym=2,symsize=.1,/dev,color=4
        con2mask(re_x_all(iii,kkk+xpts(0) ),re_y_all(iii,kkk+xpts(0) ))=1
        segmask(re_x_all(iii,kkk+xpts(0) ),re_y_all(iii,kkk+xpts(0) ))=j
        segpixl(re_x_all(iii,kkk+xpts(0) ),re_y_all(iii,kkk+xpts(0) ))=j*along_length + iii * along_length*1./parl_npix*1.
        widthpixl(re_x_all(iii,kkk+xpts(0) ),re_y_all(iii,kkk+xpts(0) ))=width
       endif
      endfor
       
     endif ;end ship track pixels detected               
    endfor ;end along-track pixel location
    ;print,'Enter to go to NEXT segment'
    ;aaa=get_kbrd(1)
  
  endif ;need sufficient # radiances in each perpendicular line
  endif ;segment is outside of MODIS bounds
  endif ;segment is outside of MODIS bounds
 endif  ;no parallel or perpendicular pixels 
 endfor ;end segment loop

;---------------------------------------------------------------------------------------------------------
; Filtering
;---------------------------------------------------------------------------------------------------------
 ;Remove repeated values in control and ship masks
 ;set all repeats to 0
 for iii=0,xDim-1 do begin
 for jjj=0,yDim-1 do begin
  if con1mask(iii,jjj) eq 1 and shipmask(iii,jjj) eq 1 then begin
   ;print,'c1,ship',iii,jjj
   con1mask(iii,jjj) = 0
   shipmask(iii,jjj) = 0
   segmask(iii,jjj) = 0
   segpixl(iii,jjj) = 0
   widthpixl(iii,jjj) = 0
  endif

  if con2mask(iii,jjj) eq 1 and shipmask(iii,jjj) eq 1 then begin
   ;print,'c2,ship',iii,jjj
   con2mask(iii,jjj) = 0
   shipmask(iii,jjj) = 0
   segmask(iii,jjj) = 0
   segpixl(iii,jjj) = 0
   widthpixl(iii,jjj) = 0
  endif

  if con2mask(iii,jjj) eq 1 and con1mask(iii,jjj) eq 1 then begin
   ;print,'c1,c2',iii,jjj
   con2mask(iii,jjj) = 0
   con1mask(iii,jjj) = 0
   segmask(iii,jjj) = 0
   segpixl(iii,jjj) = 0
   widthpixl(iii,jjj) = 0
  endif

  if con2mask(iii,jjj) eq 1 and con1mask(iii,jjj) eq 1 and shipmask(iii,jjj) eq 1 then begin
   ;print,'c1,ship,c2',iii,jjj
   con2mask(iii,jjj) = 0
   con1mask(iii,jjj) = 0
   shipmask(iii,jjj) = 0
   segmask(iii,jjj) = 0
   segpixl(iii,jjj) = 0
   widthpixl(iii,jjj) = 0
  endif
 endfor
 endfor



;---------------------------------------------------------------------------------------------------------
; Writing Data to Structure
;---------------------------------------------------------------------------------------------------------
 str_px_loc = ['modis-x','modis-y','seg#','along-track distance','ship-track width at along-track pixel']
 str_px_loc_long = ['x across MODIS image pixl','y-along MODIS image pixel','segment number','distance from the head of the ship track to pixel','width of the ship track at pixel location']
 ship_px_loc = fltarr(n_elements(str_px_loc),50000)
 ship_px_ct = 0
 con1_px_loc = fltarr(n_elements(str_px_loc),50000)
 con1_px_ct = 0
 con2_px_loc = fltarr(n_elements(str_px_loc),50000)
 con2_px_ct = 0
 for iii=0,xDim-1 do begin
 for jjj=0,yDim-1 do begin
  if shipmask(iii,jjj) eq 1 then begin
   ship_px_loc(0,ship_px_ct) = iii
   ship_px_loc(1,ship_px_ct) = jjj
   ship_px_loc(2,ship_px_ct) = segmask(iii,jjj)
   ship_px_loc(3,ship_px_ct) = segpixl(iii,jjj)
   ship_px_loc(4,ship_px_ct) = widthpixl(iii,jjj)+1
   ship_px_ct++
  endif
  if con1mask(iii,jjj) eq 1 then begin
   con1_px_loc(0,con1_px_ct) = iii
   con1_px_loc(1,con1_px_ct) = jjj
   con1_px_loc(2,con1_px_ct) = segmask(iii,jjj)
   con1_px_loc(3,con1_px_ct) = segpixl(iii,jjj)
   con1_px_loc(4,con1_px_ct) = widthpixl(iii,jjj)+1
   con1_px_ct++
  endif
  if con2mask(iii,jjj) eq 1 then begin
   con2_px_loc(0,con2_px_ct) = iii
   con2_px_loc(1,con2_px_ct) = jjj
   con2_px_loc(2,con2_px_ct) = segmask(iii,jjj)
   con2_px_loc(3,con2_px_ct) = segpixl(iii,jjj)
   con2_px_loc(4,con2_px_ct) = widthpixl(iii,jjj)+1
   con2_px_ct++
  endif
 endfor
 endfor
 if ship_px_ct gt 0. then ship_px_loc=ship_px_loc(*,0:ship_px_ct-1) else ship_px_loc=-999.
 if con1_px_ct gt 0. then con1_px_loc=con1_px_loc(*,0:con1_px_ct-1) else con1_px_loc=-999.
 if con2_px_ct gt 0. then con2_px_loc=con2_px_loc(*,0:con2_px_ct-1) else con2_px_loc=-999.
 
 ;Re-order array so that it is based on increasing distance from track head
 if ship_px_ct gt 0. then begin
  junk=sort(ship_px_loc(3,*))
  ship_px_loc = ship_px_loc(*,junk)
 endif
 if con1_px_ct gt 0. then begin
  junk=sort(con1_px_loc(3,*))
  con1_px_loc = con1_px_loc(*,junk)
 endif
 if con2_px_ct gt 0. then begin
  junk=sort(con2_px_loc(3,*))
  con2_px_loc = con2_px_loc(*,junk)
 endif

 
 ;Plot final rendered image
 if n_elements(PLOT_TRACK) eq 1 then begin
  window,0,xsize=1354,ysize=800,title=F02,xpos=dims(0)-1354 
  tv,satellite_mask(*,yoff:ymax)
  ;Plot locations of polluted and unpolluted pixels
  for iii=0,ship_px_ct-1 do plots,ship_px_loc(0,iii),ship_px_loc(1,iii)-yoff,symsize=.1,color=2,psym=2,/dev
  for iii=0,con1_px_ct-1 do plots,con1_px_loc(0,iii),con1_px_loc(1,iii)-yoff,symsize=.1,color=3,psym=2,/dev
  for iii=0,con2_px_ct-1 do plots,con2_px_loc(0,iii),con2_px_loc(1,iii)-yoff,symsize=.1,color=4,psym=2,/dev

  ;Plot width of ship track by color scale 
  ;;for iii=0,ship_px_ct-1 do plots,ship_px_loc(0,iii),ship_px_loc(1,iii)-yoff,symsize=.1,color=bytscl(ship_px_loc(4,iii),min=0.,max=50.,top=199)+20,psym=2,/dev
  ;;for iii=0,con1_px_ct-1 do plots,con1_px_loc(0,iii),con1_px_loc(1,iii)-yoff,symsize=.1,color=bytscl(con1_px_loc(4,iii),min=0.,max=50.,top=199)+20,psym=2,/dev
  ;;for iii=0,con2_px_ct-1 do plots,con2_px_loc(0,iii),con2_px_loc(1,iii)-yoff,symsize=.1,color=bytscl(con2_px_loc(4,iii),min=0.,max=50.,top=199)+20,psym=2,/dev

  ;Segment number by color plot
  ;window,0,xsize=1354,ysize=800,title=F02,xpos=dims(0)-1354 
  ;tv,satellite_mask(*,yoff:ymax)
  ;for iii=0,ship_px_ct-1 do plots,ship_px_loc(0,iii),ship_px_loc(1,iii)-yoff,symsize=.1,color=ship_px_loc(2,iii),psym=2,/dev
  ;for iii=0,con1_px_ct-1 do plots,con1_px_loc(0,iii),con1_px_loc(1,iii)-yoff,symsize=.1,color=con1_px_loc(2,iii),psym=2,/dev
  ;for iii=0,con2_px_ct-1 do plots,con2_px_loc(0,iii),con2_px_loc(1,iii)-yoff,symsize=.1,color=con2_px_loc(2,iii),psym=2,/dev
 endif


;Write output to structure
shiptrack_pixels = { track_hand_logged_locations:trackDev, track_hand_logged_str:trackDevStr, $
ship:ship_px_loc, con1:con1_px_loc, con2:con2_px_loc, str:str_px_loc, unit:['1','1','1','km','km'], long:str_px_loc_long,$
sigma_thresh:sigma_thresh, n_thresh:n_thresh, separate_dist:separate_dist, along_length:along_length, perp_length:perp_length, segment_count:segment_count }


;Output NetCDF
IF N_ELEMENTS(OUTPUT_FILE) EQ 1 THEN CREATE_NETCDF_FILE,shiptrack_pixels,OUTPUT_FILE

RETURN,shiptrack_pixels
END
