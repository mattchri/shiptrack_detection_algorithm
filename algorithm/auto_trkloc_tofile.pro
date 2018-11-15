pro auto_trkloc_tofile,fname

;This program is to be used if the lat/lon positions of the ship track
;are already known from say using MISR or other data.
;Nearest neighbor MODIS pixels are saved to a new file

;auto_trkloc_tofile,'MOD03.A2002146.1915.005.2010083143937.hdf'
lat=[39.455, 39.358, 39.277, 39.192, 39.072, 38.966, 38.844, 38.672, 38.491, 38.237, 37.921, 37.681]
lon=[-125.394, -125.303, -125.287, -125.240, -125.189, -125.152, -125.105, -125.060, -124.976, -124.856, -124.679, -124.593]

modis_path = '/data2/mattchri/satellite/modis_51/'
f03=modis_path+fname

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


;Write locations to t & l files
modis_file_info,f03,prefix,time,mtype
yr = strmid(prefix,0,4)
dy = strmid(prefix,4,3)
hr = strmid(prefix,8,2)
mn = strmid(prefix,10,2)
dn = strmid(prefix,0,4)
tfname = 't'+strmid(prefix,0,7)+strmid(prefix,8,4)+'.dat'
lfname = 'l'+strmid(prefix,0,7)+strmid(prefix,8,4)+'.dat'

;Check to make sure file is not already created
junk=file_search('~/osu_shiptrack_files/',tfname,/EXPAND_ENVIRONMENT,count=junkct)
if junkct eq 0 then begin
 openw,1,tfname
 printf,1,string(format='(i5,i5,i5,i5)',dy,hr,mn,dn)
 printf,1,string(format='(i5)',1)
 printf,1,string(format='(i5)',npts)
 
 ;Construct concatenated array
 junk=[ [ith], [jth]]
 arr = [ith,jth]
 arr(*)=0
 for k=0,n_elements(arr)-1,2 do arr(k)=junk(k/2.,0) ;xs
 for k=1,n_elements(arr),2 do arr(k)=junk(k/2.,1) ;ys
 printf,1,format='('+string(n_elements(arr))+'i5)',arr
 close,1
endif else begin

 print,'Append the following to'+tfname
 openw,1,tfname
 printf,1,string(format='(i5)',1)
 printf,1,string(format='(i5)',npts)
 
 ;Construct concatenated array
 junk=[ [ith], [jth]]
 arr = [ith,jth]
 arr(*)=0
 for k=0,n_elements(arr)-1,2 do arr(k)=junk(k/2.,0) ;xs
 for k=1,n_elements(arr),2 do arr(k)=junk(k/2.,1) ;ys
 printf,1,format='('+string(n_elements(arr))+'i5)',arr
 close,1

 print,'Append the following to'+lfname
 openw,1,lfname
 printf,1,string(format='(i5)',1)
 printf,1,string(format='(i5)',npts)
 
 ;Construct concatenated array
 junk=[ [sav_lat], [sav_lon]]
 arr = [ith,jth]
 arr(*)=0
 for k=0,n_elements(arr)-1,2 do arr(k)=junk(k/2.,1) ;xs
 for k=1,n_elements(arr),2 do arr(k)=junk(k/2.,0) ;ys
 printf,1,format='('+string(n_elements(arr))+'f10.2)',arr
 close,1

endelse

stop
return
end
