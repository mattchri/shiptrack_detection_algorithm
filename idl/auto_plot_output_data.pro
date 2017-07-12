;Generic routine to read the output ship track pixel file
;and plots the results of each ship track in the granule
;- also plots the histogram of droplet effective radius for the polluted and unpolluted clouds
;
;Inputs:
; Required:
;  ncfile: NetCDF file name
;
; Optional
; Requires either the near-infrared MODIS image used to find ship
;track pixels (2D array) OR the HDF_FILE name and HDF_CHANNEL
;
;Example
;AUTO_PLOT_OUTPUT_DATA,'../output/20021501855_track_pixels_and_MODIS_data.nc',HDF_FILE='../test_data/MOD021KM.A2002150.1855.006.2014231005506.hdf',HDF_CHANNEL=3
;
;AUTHORS
;    Matthew Christensen
;    Colorado State University
;
;History:
; 2017/07/12, MC: Initial development
;##############################################################################################
PRO AUTO_PLOT_OUTPUT_DATA,ncFile,ModisImage=ModisImage,HDF_FILE=HDF_FILE,HDF_CHANNEL=HDF_CHANNEL

; Keep 24 bit graphics and retain window content
device, true_color=24
device, decompose=0, retain=2, bypass_translation=0
loadct, 39
!except = 0 ;ignore arithmetic error reporting
!p.color = 0
!p.background = 255


; Set Defaults (keywords)
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

;Dimensions of image
SZ = SIZE(RAD02)
xDim = SZ[1]
yDim = SZ[2]

MULTI_COLORBAR

;Read Input File
STAT=READ_NCDF(ncFile,DAT,/ATT)

TrackData = DAT.track_logged_locations.DATA
SZ=SIZE(TrackData)
trkct =SZ[3] 
PRINT,'NUMBER OF SHIP TRACKS: ',trkct

;Loop Through Each Track
FOR tI=0,trkct-1 DO BEGIN

xDev = REFORM( TrackData[0,*,tI] )
yDev = REFORM( TrackData[1,*,tI] )
trk_pos_ct = N_ELEMENTS( WHERE(xDev GE 0.) )
xDev = xDev[0:trk_pos_ct-1]
yDev = yDev[0:trk_pos_ct-1]
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
 
 window,0,xsize=1354,ysize=ymax-yoff,title=F02
 tv,satellite_mask(*,yoff:ymax)
 
 ;plot hand-logged track locations onto window
 for ij=0,trk_pos_ct-1 do plots,xDev[ij],yDev[ij]-yoff,/dev,color=2,psym=2,symsize=1


;Select only ship pixels and use filtering
shipID = WHERE( DAT.SHIP.DATA[5,*] EQ tI AND DAT.SHIP.DATA[6,*] EQ 0 )
ship_px_loc = DAT.SHIP.DATA[*,shipID]
ship_px_ct  = N_ELEMENTS(shipID)

con1ID = WHERE( DAT.CON1.DATA[5,*] EQ tI AND DAT.CON1.DATA[6,*] EQ 0 )
con1_px_loc = DAT.CON1.DATA[*,con1ID]
con1_px_ct  = N_ELEMENTS(con1ID)

con2ID = WHERE( DAT.CON2.DATA[5,*] EQ tI AND DAT.CON2.DATA[6,*] EQ 0 )
con2_px_loc = DAT.CON2.DATA[*,con2ID]
con2_px_ct  = N_ELEMENTS(con2ID)

;Plot locations of polluted and unpolluted pixels
 window,1,xsize=1354,ysize=ymax-yoff,title=F02
 tv,satellite_mask(*,yoff:ymax)
for iii=0,ship_px_ct-1 do plots,ship_px_loc(0,iii),ship_px_loc(1,iii)-yoff,symsize=.1,color=2,psym=2,/dev
  for iii=0,con1_px_ct-1 do plots,con1_px_loc(0,iii),con1_px_loc(1,iii)-yoff,symsize=.1,color=3,psym=2,/dev
  for iii=0,con2_px_ct-1 do plots,con2_px_loc(0,iii),con2_px_loc(1,iii)-yoff,symsize=.1,color=4,psym=2,/dev


;Plot Histogram of Effective Radius
  ;Combine MODIS overcast & partly cloudy pixels
  ;Combine controls
  RAW=DAT.SHIP_MODIS.DATA[14,shipID]
  PCL=DAT.SHIP_MODIS.DATA[23,shipID]
  x1=(RAW GT 0. AND PCL LT 0.)*RAW + (RAW LT 0. AND PCL GT 0.)*PCL + (RAW GT 0. AND PCL GT 0.)*( (RAW+PCL)/2.) + (RAW LT 0. AND PCL LT 0.)*(-999.)
   x1=reform(x1)

  RAW=DAT.CON1_MODIS.DATA[14,con1ID]
  PCL=DAT.CON1_MODIS.DATA[23,con1ID]
  xcon1=(RAW GT 0. AND PCL LT 0.)*RAW + (RAW LT 0. AND PCL GT 0.)*PCL + (RAW GT 0. AND PCL GT 0.)*( (RAW+PCL)/2.) + (RAW LT 0. AND PCL LT 0.)*(-999.)
   xcon1=reform(xcon1)

  RAW=DAT.CON2_MODIS.DATA[14,con2ID]
  PCL=DAT.CON2_MODIS.DATA[23,con2ID]
  xcon2=(RAW GT 0. AND PCL LT 0.)*RAW + (RAW LT 0. AND PCL GT 0.)*PCL + (RAW GT 0. AND PCL GT 0.)*( (RAW+PCL)/2.) + (RAW LT 0. AND PCL LT 0.)*(-999.)
  xcon2=reform(xcon2)

  x2=[xcon1,xcon2]


  ID1=WHERE(X1 GT 0.)
  ID2=WHERE(X2 GT 0.)
  X1=X1[ID1]
  X2=X2[ID2]
  h1=HISTOGRAM(x1,min=0,max=30,binsize=1,locations=x)
  h2=HISTOGRAM(x2,min=0,max=30,binsize=1,locations=x)

  window,3,xsize=400,ysize=400
  PLOT,x,h1,YRANGE=[0,MAX( [h1/total(h1),h2/total(h2)])*1.1],/nodata,xtitle='Effective Radius 3.7 um channel (um)',ytitle='FREQUENCY'
  OPLOT,X,h1/total(h1),color=2
  OPLOT,X,h2/total(h2),color=3

  XYOUTS,.2,.86,'SHIP',/NORM,COLOR=2
  XYOUTS,.2,.81,'CONTROLS',/NORM,COLOR=3

PRINT,'ENTER to plot next track'
AA=GET_KBRD(1)

ENDFOR

STOP

END
