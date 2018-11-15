;+
;NAME:
;
;   Subroutine for AUTO_MAIN.PRO
;
;PURPOSE:
;
;   This procedure is used to increase the number of pixels between hand-logged locations
;   throughught the ship track skeleton
;
;INPUT:
;1) s: size of satellite image
;2) i: ship track number
;3) trk_pos: hand-logged ship track locations
;4) trk_pos_ct: number of hand-logged locations
;
;OUTPUT:
;1) all_x: 1D array containing all of the x-positions along ship track
;2) all_y: 1D array containing all of the y-positions along ship track
;###########################################################################
FUNCTION AUTO_EXPAND_TRACK_POSITIONS,xDev,yDev

trk_pos_ct = N_ELEMENTS(xDev)

      ;Correct errors in hand-logged tracks
      ;sometimes the slopes are too large or they fall to close to an edge
      for im=0,10 do begin
      flag=0
      for jjj=0,trk_pos_ct-2 do begin
       x0=xDev[jjj]*1.
       y0=yDev[jjj]*1.
       x1=xDev[jjj+1]*1.
       y1=yDev[jjj+1]*1.      
       
       m=(y1-y0)/(x1-x0)
       ;print,jjj,im,flag,m
           
       if abs(x0-x1) eq 0. then begin
        flag=1
        xDev[jjj] = x0+2.
       endif
       if abs(x0-x1) eq 1. then begin
        flag=1
        xDev[jjj] = x0+1.
       endif
       if abs(y0-y1) eq 0. then begin
        flag=1
        yDev[jjj] = y0+2.
       endif
       if abs(y0-y1) eq 1. then begin
        flag=1
        yDev[jjj] = y0+1.
       endif
      endfor
       if flag eq 0 then BREAK
      endfor
      
      ;Determine approximate number of points needed for a dx=0.1
      all_x = fltarr(50000)
      all_y = fltarr(50000)
      all_m = dblarr(50000) ;all slopes
      all_ct = 0.
      ;Loop over hand-logged segments
      for jjj=0,trk_pos_ct-2 do begin
       x0=xDev[jjj]*1.
       y0=yDev[jjj]*1.
       x1=xDev[jjj+1]*1.
       y1=yDev[jjj+1]*1.      
            
       ;Conjoining Lines
       m=(y1-y0)/(x1-x0)
       b=y0-m*x0
       
       ;print,jjj,m,y1,y0,x1,x0,y1-y0,x1-x0
       
       ;Define array with number of new ship track points
       nnpts = 5000.
       overshoot = 1.5 ;(fraction to overshoot)
       npts = nnpts*overshoot
       delp = (x1-x0)/nnpts
       offset = (x1-x0)*.25
       xarr=findgen(npts)*delp+x0-offset

       ;Direction
       if x1-x0 gt 0. then direct = 1.
       if x1-x0 lt 0. then direct = -1.
       if x1-x0 eq 0. then begin
        print,'PROBLEM WITH COORDINATES'
        direct=1.
        x1=x1+delp*2.
       endif

       npts = n_elements(xarr) ;total number of points
       xf=x0
       yf=y0
       dx=0.1 ;step in x direction
       all_c = fltarr(npts)
       for ii=0,npts-1 do begin ;loop over total number of points
        xi = xf
        yi = yf
        xf = xf + direct*dx
        yf = m*xf + b

        all_c(ii) = sqrt( (xi-x1)^2.+(yi-y1)^2.)
        if ii gt 0. and all_c(ii) ge all_c(ii-1) then BREAK  ;no need to go past the segment marker
        
         all_x(all_ct) = xf
         all_y(all_ct) = yf
         all_m(all_ct) = m
         all_ct++
       
       endfor ;ship track fine points between sections
      endfor  ;ship track sections
      all_x=all_x(0:all_ct-1)
      all_y=all_y(0:all_ct-1)

TPTS = { xTrack:all_x, yTrack:all_y }

return,TPTS
end
