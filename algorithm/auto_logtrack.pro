pro auto_logtrack,file

;auto_logtrack,'MOD021KM.A2002146.1915.005.2010083150115.hdf'

;auto_logtrack,'MOD021KM.A2011214.1855.006.2012285111400.hdf'
f03='/data2/mattchri/satellite/modis/MOD03.A2011214.1855.006.2012283193721.hdf'

modispath = '/data2/mattchri/satellite/modis_51/'

f02=modispath+file

read_mod02,f02,rad02,str2,str2_long,units2

color_bar
;Select Channel for detection algorithm
channel = 3
rad02 = reform( rad02(*,*,channel) )

yoff=500
ymax=yoff+1000

 ;colorize satellite data
 omin = median(rad02(*,yoff:ymax)) - stddev(rad02(*,yoff:ymax))*2.5
 if omin lt 0. then omin = 0.
 omax = median(rad02(*,yoff:ymax)) + stddev(rad02(*,yoff:ymax))*2.5
 if omax gt max(rad02(*,yoff:ymax)) then omax = max(rad02(*,yoff:ymax))
 m3  = bytscl(rad02(*,*),min=omin,max=omax,top=35)+220

 dims = get_screen_size()
 window,0,xsize=1354,ysize=1000,title=F02,xpos=dims(0)-1354      
 tv,m3(*,yoff:ymax)



lat=[37.0,37.16]
lon=[-122.98, -123.01] 

hdf_sd_data,f03,'Latitude',mlat
hdf_sd_data,f03,'Longitude',mlon

s=size(mlat)
npts = n_elements(lat)

ith = fltarr(npts)
jth = fltarr(npts)
for i=0,npts-1 do begin
 id=where( abs(mlat-lat(i)) lt .05 and abs(mlon-lon(i)) lt .05,idct)
 if idct gt 0 then begin
  sdist=fltarr(idct)
  sindex=fltarr(idct)
  for j=0,idct-1 do begin
   sdist(j)=MAP_2POINTS( mlon(id(j)), mlat(id(j)), lon(i), lat(i),/METERS)/1000.
   sindex(j)=id(j)
  endfor
  ij=where(sdist eq min(sdist))
  index = sindex(ij)
  
  ncol = s(1)
  col = index mod ncol
  row = index / ncol
  
  ith(i) = fix(col)
  jth(i) = fix(row)
  
 endif else STOP
endfor

sav_lat = mlat(ith,jth)
sav_lon = mlon(ith,jth)

plots,ith(0),jth(0)-yoff,psym=7,color=2,/dev
plots,ith(1),jth(1)-yoff,psym=7,color=3,/dev
xyouts,mean(ith),mean(jth)-yoff,'ship track',/dev,color=2

stop
return
end
