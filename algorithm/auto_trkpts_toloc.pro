pro auto_trkpts_toloc,fname

;auto_trkpts_toloc,'/home/mattchri/osu_shiptrack_files/t2011_terra/t20112141855.dat'

tfile=fname
read_osu_shiptrack_file,tfile,year,jday,hour,month,mday,trkct,trk_pos_ct,txs,tys

npts=reform(trk_pos_ct(0))
ith=reform(txs(0,0:trk_pos_ct(0)-1))
jth=reform(tys(0,0:trk_pos_ct(0)-1))

junk=[ [ith], [jth]]
arr = [ith,jth]
arr(*)=0
for k=0,n_elements(arr)-1,2 do arr(k)=junk(k/2.,0) ;xs
for k=1,n_elements(arr),2 do arr(k)=junk(k/2.,1) ;ys


f03='/data2/mattchri/satellite/modis/MOD03.A2011214.1855.006.2012283193721.hdf'
hdf_sd_data,f03,'Latitude',mlat
hdf_sd_data,f03,'Longitude',mlon

sav_lat = mlat(ith,jth)
sav_lon = mlon(ith,jth)

junk=[ [sav_lat], [sav_lon]]
arr = [ith,jth]
arr(*)=0
for k=0,n_elements(arr)-1,2 do arr(k)=junk(k/2.,1) ;xs
for k=1,n_elements(arr),2 do arr(k)=junk(k/2.,0) ;ys


modis_file_info,f03,prefix,time,mtype
yr = strmid(prefix,0,4)
dy = strmid(prefix,4,3)
hr = strmid(prefix,8,2)
mn = strmid(prefix,10,2)
dn = strmid(prefix,0,4)
tfname = 't'+strmid(prefix,0,7)+strmid(prefix,8,4)+'.dat'
lfname = 'l'+strmid(prefix,0,7)+strmid(prefix,8,4)+'.dat'

 openw,1,lfname
 printf,1,string(format='(i5,i5,i5,i5)',dy,hr,mn,dn)
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


stop
return
end
