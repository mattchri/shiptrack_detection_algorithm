;+
;NAME:
;
;   Ship track logging procedure
;
;PURPOSE:
;
;   This procedure is used to aid in the logging of ship tracks
;
;DESCRIPTION:
;
;   Reads the Modis calibrated radiances (mod02) and the user
;   can choose to input a pre-made tfile containing track locations
;   with which to either reject or keep tracks. Then the code
;   runs logtrack which allows the user to add tracks to the tfile
;   which is written to a new directory. 
;
;INPUT:  modis file
;OPTIONAL: TFILE (if tfile already exists you can modify/add to it)
;
;OUTPUT:  TEXT FILE AND SAVE FILE
;  FORMAT:   (P)(YEAR)(DAY)(HOUR).dat  or   .sav
;
;EXAMPLE
;logtrack_basic,'/group_workspaces/cems2/nceo_generic/satellite_data/modis_c61/myd021km/2008/230/MYD021KM.A2008230.2125.061.2018035191627.hdf',TFILE='/group_workspaces/jasmin2/aopp/mchristensen/shiptrack/shiptrack_logged_files/combined/tMYD03.A2008230.2125.dat'
;
;
;
;AUTHOR:
;    Matt Christensen
;    University of Oxford
;###########################################################################
PRO LOGTRACK_BASIC,MOD02FILE,TFILE=TFILE

;read MODIS satellite image data
read_mod02, MOD02FILE, arad, radSTR
s = size(arad)

;read handlogged positions
IF KEYWORD_SET(TFILE) EQ 1 THEN BEGIN
 read_osu_shiptrack_file,tfile,year,jday,hour,month,mday,tnum,PTS,Xi,Yi
ENDIF

MULTI_colorbar
window,0,xsize=s[1],ysize=800

trk_pos = intarr(50,2,100) ;trk_pos(trknum,{x,y},0=head,1=1st curve down track from head,2=2ndcurve,ect....)
trk_pos_ct = intarr(50)    ;trk_pos_ct(trknum)  number of ship track curves
trk_head_flag = bytarr(50) ;byte flag indicating whether the track confidently has a head
trkct=0

;read handlogged positions
IF KEYWORD_SET(TFILE) EQ 1 THEN BEGIN
 ;check valid tracks from existing tfile (some may be bad)
 ;include them here before logging more tracks
 chk = check_tracks(mod02file,tfile)
 TRK_POS = chk.trk_pos
 TRK_POS_CT = chk.trk_pos_ct
 TRKCT = chk.trkct
ENDIF

for i=0,2 do begin ;LOOPING OVER SEGMENTS IN Y
 check = 1
 while check eq 1 do begin     
   if i eq 0 then begin
     yoff=0 & ymax = 800
   endif
   if i eq 1 then begin
     yoff=650
     ymax = 1450
   endif
   if i eq 2 then begin
     yoff=1300
     ymax = s(2)-1
   endif
   

   satmask = ARAD_TO_BYTE(ARAD,0,s[1]-1,yoff,ymax)
   flag=1
   print,'Number of Tracks Logged = ',trkct
   wset,0
   wshow,0

   img = satmask.micro
   DISPLAY_TRACKS,img,yoff,ymax,trkct,trk_pos,trk_pos_ct

      print,'Do you see a ship track? no = 0 yes = 1'
      check=get_kbrd(1)
      if check eq 1 then begin
        wset,0

        print,'Click on a ship track near the head'
        wait,.25
        cursor,xClick,yClick,/dev

        ;Magnify region around clicked location
        dM   = 4.0 ;magnification ratio
        dX_m = fix( s[1]/dM) ;size of window x range 
        dY_m = fix( 800./dM) ;size of window y range

        xoff_mag = xClick - dX_m/2. ;xoff global location
        xmax_mag = xClick + dX_m/2. ;xmax global location
        yoff_mag = yClick + yoff - dY_m/2. ;new_yoff global location
        ymax_mag = yClick + yoff + dY_m/2. ;new_ymax global location
        if yoff_mag lt 0. then yoff_mag = 0.
        if ymax_mag ge s[2]-1 then ymax_mag=s[2]-1
        if xoff_mag lt 0. then xoff_mag = 0.
        if xmax_mag ge s[1]-1 then xmax_mag = s[1]-1

        ;store coordinates for shifting
        TMPxM = mean([xoff_mag,xmax_mag])
        TMPyM = mean([yoff_mag,ymax_mag])

        satmask = ARAD_TO_BYTE(ARAD,xoff_mag,xmax_mag,yoff_mag,ymax_mag)
        imgM  = satmask.micro
        imgSZ = size(imgM)
        imgMr = congrid(imgM,imgSZ(1)*4,imgSZ(2)*4)
        window,8,xsize=imgSZ(1)*4,ysize=imgSZ(2)*4
        tv,imgMr
        
        print,'Click on the head'
        cursor,xClick,yClick,/dev
        plots,xClick,yClick,psym=5,symsize=1.25,/dev,color=5
        trk_pos(trkct,0,0) = ROUND( xoff_mag + xClick/dM ) 
        trk_pos(trkct,1,0) = ROUND( yoff_mag + yClick/dM )

        ;!mouse.button = 0  no click yet
		;!mouse.button = 1  left click
		;!mouse.button = 2  two
		;!mouse.button = 4  three
        curve_ct = 1
        print,'Left to continue Right for left and right bound and center click to quit'
        while !mouse.button eq 1 or !mouse.button eq 4 do begin
         ;Plot all of the points
         FOR K = 0,curve_ct-1 DO BEGIN
            xK = ROUND( ( trk_pos(trkct,0,K) - xoff_mag)*dM ) 
            yK = ROUND( ( trk_pos(trkct,1,K) - yoff_mag)*dM ) 
            IF K EQ 0 THEN plots,xK,yK,/dev,psym=5,symsize=1.25,color=5
            IF K GT 0 THEN plots,xK,yK,/dev,psym=2,symsize=1.25,color=7
         ENDFOR

         print,'Click on curve: ',curve_ct
         wait,.25
         cursor,xClick,yClick,/dev         
         if !mouse.button eq 2 or !mouse.button eq 8 or !mouse.button eq 16 then BREAK
         if !mouse.button eq 1 then plots,xClick,yClick,symsize=1.25,/dev,color=7
         if !mouse.button eq 4 then plots,xClick,yClick,symsize=1.25,/dev,color=7
         trk_pos(trkct,0,curve_ct) = xoff_mag + round(xClick/dM)
         trk_pos(trkct,1,curve_ct) = yoff_mag + round(yClick/dM)

         x = xoff_mag + round(xClick/dM)
         y = yoff_mag + round(yClick/dM)

         ;reproject satellite image if distance 
         ;from origin is > 75 km
         if SQRT((x-TMPXm)^2+(Y-tmpyM)^2) gt 75. then begin
          print,x,y,TMPxM,TMPyM,SQRT((x-TMPXm)^2+(Y-tmpyM)^2)
          TMPXm = x & TMPYm = y
          xoff_mag = x - dX_m/2. ;xoff global location
          xmax_mag = x + dX_m/2. ;xmax global location
          yoff_mag = y - dY_m/2. ;new_yoff global location
          ymax_mag = y + dY_m/2. ;new_ymax global location
          if yoff_mag lt 0. then yoff_mag = 0.
          if ymax_mag ge s[2]-1 then ymax_mag=s[2]-1
          if xoff_mag lt 0. then xoff_mag = 0.
          if xmax_mag ge s[1]-1 then xmax_mag = s[1]-1

          print,xoff_mag,xmax_mag,yoff_mag,ymax_mag
          satmask = ARAD_TO_BYTE(ARAD,xoff_mag,xmax_mag,yoff_mag,ymax_mag)
          imgM  = satmask.micro
          imgSZ = size(imgM)
          imgMr = congrid(imgM,imgSZ(1)*4,imgSZ(2)*4)
          window,8,xsize=imgSZ(1)*4,ysize=imgSZ(2)*4
          tv,imgMr
         endif

         curve_ct=curve_ct+1
        endwhile
        trk_pos_ct(trkct) = curve_ct
        
        DISPLAY_TRACKS,img,yoff,ymax,trkct,trk_pos,trk_pos_ct

        print,'Does the Ship Track Layout Look okay? yes=1 no=0'
        check_layout = get_kbrd(1)      
        if check_layout eq 1 then flag=0
        
        if flag eq 0 then begin
         print,'Does the ship track have a confident head location? yes=1, no=0'
         tmp = get_kbrd(1)
         trk_head_flag[trkct] = tmp
         trkct = trkct+1
        endif

     endif
  ENDWHILE

ENDFOR


;write to text file
outpath = '/group_workspaces/jasmin2/aopp/mchristensen/shiptrack/shiptrack_logged_files/combined_filled_in/'
FILE_MKDIR,outPath
;tfile
tNUM = trkct
tPTS = trk_pos_ct
xPTS = reform(trk_pos[0:trkct-1,0,0:49],tNUM,50)
yPTS = reform(trk_pos[0:trkct-1,1,0:49],tNUM,50)
 tmpFile = mod02file
 MODIS_FILE_INFO,tmpFile,prefix,time,mtype,timeSTR

 ;Make a text file in OSU format for all tracks
 txtName=outPath+'t'+STRMID(file_basename(mod02file),0,4)+'3.A'+timeSTR[0]+timeSTR[1]+'.'+timeSTR[4]+timeSTR[5]+'.dat'
 day = time[1] & hr = time[3] & min = time[4]  & seconds=0.0
 b = WRITE_TRACK_LOCATIONS_ASCII_FILE(txtName,day,hr,min,seconds,TNUM,tPTS,xPTS,yPTS)

;Run final sanity check from generated file
chk = check_tracks(mod02file,txtName)

END
