;+
;NAME:
;
;   Subroutine for AUTO_MAIN.PRO
;
;PURPOSE:
;
;   This procedure is used to construct segments along the ship track
;   starting from the head. Cross track coordinates are determined from
;   the perpendicular angle between conjoining lines. 
;
;INPUT:
;1) along_length: along track segment length (# pixels --> 20 [Segrin et al. 2007])
;2) perp_length: perpendicular track segment length (#pixels --> 30 [Segrin et al. 2007])
;3) all_x: re-constructed ship track x-positions
;4) all_y: re-constructed ship track y-positions
;
;OUTPUT:
;1) seg_parl_npix: 1D array # of along track pixels for each segment
;2) seg_perp_npix: 1D array # of cross track pixels for each segment
;3) seg_dist: 1D array segment distance in equivalent pixels
;4) seg_re_x_all: 3D array # of x-pixel location in the cross track section for each along-track pixel in each segment
;5) seg_re_x_all: 3D array # of y-pixel location in the cross track section for each along-track pixel in each segment
;###########################################################################
PRO AUTO_CONSTRUCT_SEGMENT,yoff,along_length,perp_length,all_x,all_y,seg_parl_npix,seg_perp_npix,seg_dist,seg_re_x_all,seg_re_y_all,seg_dist_all
      
      segment_scl = 3. ;scale in which larger segment domain can be
            
      ;Construct output arrays based on segment counter
      seg_parl_npix = intarr(100)        ;#along track pixels
      seg_perp_npix = intarr(100)        ;#perpendicular track pixels
      seg_dist  = fltarr(100)        ;distance of segment
      seg_re_x_all = intarr(100,100,500) ;{segment#,along#,perp#)
      seg_re_y_all = intarr(100,100,500)
      seg_dist_all = fltarr(100,100,500)
      
      ;# of re-constructed track locations
      all_ct = n_elements(all_x)
      
      ;Array for along track pixels 
      along_x = fltarr(5000)
      along_y = fltarr(5000)
      
      ;Array for cross track pixels
      ;positive-x
      xp0=fltarr(5000,5000)  ;{along,cross}
      yp0=fltarr(5000,5000)
      ;negative-x
      xp1=fltarr(5000,5000)
      yp1=fltarr(5000,5000)     
      along_ct = 0       ;# pixels are used in current segment
      tdistc = 0.
      along_ct_all = 0.  ;# pixels along ship track
      segment_count = 0.
      for jjj=0,all_ct-3 do begin ;loop over reconstructed ship track points
       x0=all_x(jjj)
       y0=all_y(jjj)
       x1=all_x(jjj+1)
       y1=all_y(jjj+1)          
       ;print,x0,x1,y0,y1,tdistc,segment_count,along_ct
      
       ;Distance between data points      
       tdistc = tdistc + sqrt( (x1-x0)^2.+(y1-y0)^2.)

       ;Perpendicular Line at x0,y0
       mp=(x1-x0)/(y0-y1)
       bp=y0-mp*x0
       
       mp2=(all_x(jjj+1)-all_x(jjj+2))/(all_y(jjj+2)-all_y(jjj+1)) ;slope of next along-track pixel
       ;print,jjj,mp,mp2,x0,y0,x1,y1,abs( (mp2-mp)/mp )*100.
       
       ;Slope can be wildly different between successive points due to hand-logged track
       ;remove cases (very few) where the slopes differ by more than 5%
       if abs( (mp2-mp)/mp )*100. lt 5. then begin
       
             
       ;Get perpendicular pixels
       dx=.1
       nnnpts = 5000.
       ;Positive x
       xfp=x0
       yfp=y0
       all_cp = 0.
       all_xp0 = fltarr(nnnpts)
       all_yp0 = fltarr(nnnpts)
       all_ct0 = 0
       ;Loop over x-fine points to get y-values
       for jj=0,nnnpts-1 do begin
        xip = xfp
        yip = yfp
        xfp = xfp + dx
        bp=yip-mp*xip
        yfp = mp*xfp + bp
        c = sqrt( (xfp-xip)^2.+(yfp-yip)^2.)
        all_cp = all_cp + c
        ;Break out of loop if prependicular segment is greater than perp_length
        if all_cp gt perp_length*segment_scl then BREAK
        all_xp0(all_ct0) = xfp
        all_yp0(all_ct0) = yfp
        all_ct0++
        ;plots,xfp,yfp-yoff,psym=2,symsize=.01,/dev,color=3
       endfor
       all_xp0=all_xp0(0:all_ct0-1)
       all_yp0=all_yp0(0:all_ct0-1)

       ;Get perpendicular pixels
       ;negative x
       xfp=x0
       yfp=y0
       all_cp = 0.
       all_xp1 = fltarr(nnnpts)
       all_yp1 = fltarr(nnnpts)
       all_ct1 = 0
       for jj=0,nnnpts-1 do begin
        xip = xfp
        yip = yfp
        xfp = xfp - dx
        bp=yip-mp*xip
        yfp = mp*xfp + bp
        c = sqrt( (xfp-xip)^2.+(yfp-yip)^2.)
        all_cp = all_cp + c
        if all_cp gt perp_length*segment_scl then BREAK
        all_xp1(all_ct1) = xfp
        all_yp1(all_ct1) = yfp
        all_ct1++
        ;plots,xfp,yfp-yoff,psym=2,symsize=.01,/dev,color=4
       endfor
       all_xp1=all_xp1(0:all_ct1-1)
       all_yp1=all_yp1(0:all_ct1-1)
  
       ;Along track pixel
       along_x(along_ct) = all_x(jjj)
       along_y(along_ct) = all_y(jjj)
       
       ;Perpendicular pixels (positive)
       xp0(along_ct,0:all_ct0-1) = all_xp0
       yp0(along_ct,0:all_ct0-1) = all_yp0

       ;Perpendicular pixels (negative)
       xp1(along_ct,0:all_ct1-1) = all_xp1
       yp1(along_ct,0:all_ct1-1) = all_yp1
 
       ;print,jjj,all_ct     
       ;Length of segment reached or its the last possible segment
       if (tdistc gt along_length) or (jjj eq all_ct-2) then begin
                      
        ;resample along track index
        ;(because there are numerous repeated values)
        re_x = intarr(along_ct*100)
        re_y = intarr(along_ct*100)
        
        ;resample perpendicular index
        perp_ct  = fix(perp_length*(segment_scl+.2))    ;due to pixel oversampling
        re_x0    = intarr(along_ct*100,perp_ct)
        re_y0    = intarr(along_ct*100,perp_ct)
        re_x1    = intarr(along_ct*100,perp_ct)
        re_y1    = intarr(along_ct*100,perp_ct)
        re_dist0 = fltarr(along_ct*100,perp_ct)
        re_dist1 = fltarr(along_ct*100,perp_ct)
        
         ;Initialize first data point so that resampling strategy can work
         ;Along Track
         re_ct=0
         re_x(0) = fix(along_x(0))
         re_y(0) = fix(along_y(0))
         
         ;Cross-Track positive x
         kkk=0        
         tct=0
         for ik=0,all_ct0-2 do begin
          if tct lt perp_ct then begin
           ikdist1 = sqrt( (fix(xp0(kkk,ik))-fix(along_x(kkk)))^2.+(fix(yp0(kkk,ik))-fix(along_y(kkk)))^2. )
           ikdist2 = sqrt( (fix(xp0(kkk,ik+1))-fix(along_x(kkk)))^2.+(fix(yp0(kkk,ik+1))-fix(along_y(kkk)))^2. )
           if ikdist1 ne ikdist2 then begin
            re_x0(re_ct,tct) = xp0(kkk,ik)
            re_y0(re_ct,tct) = yp0(kkk,ik)
            re_dist0(re_ct,tct) = ikdist1
            tct++
	   endif
	  endif
	 endfor
         
         kkk=0
         ;Cross-track negative x
         tct=0
         for ik=0,all_ct1-2 do begin
          if tct lt perp_ct then begin
           ikdist1 = sqrt( (fix(xp1(kkk,ik))-fix(along_x(kkk)))^2.+(fix(yp1(kkk,ik))-fix(along_y(kkk)))^2. )
           ikdist2 = sqrt( (fix(xp1(kkk,ik+1))-fix(along_x(kkk)))^2.+(fix(yp1(kkk,ik+1))-fix(along_y(kkk)))^2. )
           if ikdist1 ne ikdist2 then begin
            re_x1(re_ct,tct) = xp1(kkk,ik)
            re_y1(re_ct,tct) = yp1(kkk,ik)
            re_dist1(re_ct,tct) = ikdist1
            tct++
	   endif
	  endif
	 endfor
                
        re_ct=1 ;set counter 1 since you initialized the first value    
        ;Loop over along track pixels
        for kkk=0,n_elements(along_x)-2 do begin
        
        ;Enter if either x or y along-track pixel changed
 	if (fix(along_x(kkk+1))-fix(along_x(kkk))) ne 0 or (fix(along_y(kkk+1))-fix(along_y(kkk))) ne 0 then begin
 	 re_x(re_ct)=along_x(kkk+1)
 	 re_y(re_ct)=along_y(kkk+1) 
 	 
         ;Discretize perpendicular parts
         ;positive x
         tct=0
         for ik=0,all_ct0-2 do begin
          if tct lt perp_ct then begin
           ikdist1 = sqrt( (fix(xp0(kkk,ik))-fix(along_x(kkk)))^2.+(fix(yp0(kkk,ik))-fix(along_y(kkk)))^2. )
           ikdist2 = sqrt( (fix(xp0(kkk,ik+1))-fix(along_x(kkk)))^2.+(fix(yp0(kkk,ik+1))-fix(along_y(kkk)))^2. )
           if ikdist1 ne ikdist2 then begin
            re_x0(re_ct,tct) = xp0(kkk,ik)
            re_y0(re_ct,tct) = yp0(kkk,ik)
            re_dist0(re_ct,tct) = ikdist1
            tct++
	   endif
	  endif
	 endfor

         ;negative x
         tct=0
         for ik=0,all_ct1-2 do begin
          if tct lt perp_ct then begin
           ikdist1 = sqrt( (fix(xp1(kkk,ik))-fix(along_x(kkk)))^2.+(fix(yp1(kkk,ik))-fix(along_y(kkk)))^2. )
           ikdist2 = sqrt( (fix(xp1(kkk,ik+1))-fix(along_x(kkk)))^2.+(fix(yp1(kkk,ik+1))-fix(along_y(kkk)))^2. )
           if ikdist1 ne ikdist2 then begin
            re_x1(re_ct,tct) = xp1(kkk,ik)
            re_y1(re_ct,tct) = yp1(kkk,ik)
            re_dist1(re_ct,tct) = ikdist1
            tct++
	   endif
	  endif
	 endfor
 	 
 	 re_ct++
 	endif
       endfor
       re_x_c=re_x(0:re_ct-1)
       re_y_c=re_y(0:re_ct-1)
       ;for is=0,n_elements(re_x_c)-1 do plots,re_x_c(is),re_y_c(is)-yoff,color=2,psym=3,symsize=.2,/dev
       
       re_x_n=re_x1(0:re_ct-1,*)
       re_y_n=re_y1(0:re_ct-1,*)
       re_x_p=re_x0(0:re_ct-1,*)
       re_y_p=re_y0(0:re_ct-1,*)
       re_distn=re_dist1(0:re_ct-1,*)*(-1.)
       re_distp=re_dist0(0:re_ct-1,*)
       
       ;reverse negative direction elements
       for ik=0,re_ct-1 do begin
        xtmp = reform( re_x_n(ik,*) )
        ytmp = reform( re_y_n(ik,*) )
        dtmp = reform( re_distn(ik,*) )
        re_x_n(ik,*) = reverse(xtmp)
        re_y_n(ik,*) = reverse(ytmp)
        re_distn(ik,*) = reverse(dtmp)
       endfor
       
       ;Combine negative and positive perpendicular pixels
       re_x_all = [ [re_x_n],[re_x_p] ]
       re_y_all = [ [re_y_n],[re_y_p] ]
       re_dist_all = [ [re_distn],[re_distp] ]
              
       ;Number of perpendicular and parallel pixels
       sz=size(re_x_all)
       parl_npix = sz(1)
       perp_npix = sz(2)

       seg_parl_npix(segment_count) = parl_npix
       seg_perp_npix(segment_count) = perp_npix
       seg_dist(segment_count)  = tdistc      
       seg_re_x_all(segment_count,0:parl_npix-1,0:perp_npix-1) = re_x_all
       seg_re_y_all(segment_count,0:parl_npix-1,0:perp_npix-1) = re_y_all
       seg_dist_all(segment_count,0:parl_npix-1,0:perp_npix-1) = re_dist_all
   ;Reset length
   tdistc = 0.
   ;Array for along track pixels 
   along_x = fltarr(5000)
   along_y = fltarr(5000)
   xp0=fltarr(5000,5000)  ;{along,cross}
   yp0=fltarr(5000,5000)
   xp1=fltarr(5000,5000)
   yp1=fltarr(5000,5000)
   along_ct = -1
   ;Bump segment #
   segment_count++
 endif
along_ct++

along_ct_all = along_ct_all+1

endif

endfor
seg_parl_npix = seg_parl_npix(0:segment_count-1)
seg_perp_npix = seg_perp_npix(0:segment_count-1)
seg_dist      = seg_dist(0:segment_count-1)
seg_re_x_all = seg_re_x_all(0:segment_count-1,*,*)
seg_re_y_all = seg_re_y_all(0:segment_count-1,*,*)
seg_dist_all = seg_dist_all(0:segment_count-1,*,*)

;print,segment_count,'  ',along_ct_all

return
end
