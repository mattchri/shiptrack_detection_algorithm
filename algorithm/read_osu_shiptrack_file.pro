pro read_osu_shiptrack_file,tfile,year,jday,hour,month,mday,tnum,all_pts,all_lons,all_lats

ed = strpos(tfile,'.dat')
year = strmid(tfile,ed-11,4)*1.
jday  = strmid(tfile,ed-7,3)*1.
hour  = strmid(tfile,ed-4,4)*1.
CALDAT,JULDAY(1,jday,year),month,mday

openr,1,tfile

 junk=strarr(1)
 tinfo = fltarr(3)
 readf,1,tinfo
 readf,1,junk
 tnum = junk*1.
 tnum = tnum(0)
 
 all_lons = fltarr(50,100)   ;max 50 ship tracks with max 100 points
 all_lats = fltarr(50,100)
 all_pts  = fltarr(50)
 ;Loop over each ship track
 for ii=0,tnum-1 do begin
  readf,1,junk
  pts = junk*1.
  pts = pts(0)
  geo = fltarr( pts*2 )
  readf,1,geo
  lons = fltarr(pts)
  lats = fltarr(pts)
  ;Longitude
  ct=0
  for iii=0,pts*2-1,2 do begin
   ;print,iii,geo(iii)
   lons(ct) = geo(iii)
   all_lons(ii,ct) = geo(iii)
   ct=ct+1
  endfor 
  
  ;Latitude
  ct=0
  for iii=1,pts*2-1,2 do begin
   ;print,iii,geo(iii)
   lats(ct) = geo(iii)
   all_lats(ii,ct) = geo(iii)
   ct=ct+1
  endfor
  
  all_pts(ii) = pts

 endfor 

close,1

return
end
