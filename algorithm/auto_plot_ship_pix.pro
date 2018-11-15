;+
;NAME:
;
;   Visualizing routine for AUTO_MAIN.PRO
;
;PURPOSE:
;
;   This procedure is used to project satellite image onto lat/lon grid
;   and overlay the polluted and unpolluted pixels for the ship tracks.
;
;INPUT: PREFIX
;
;EXAMPLE:auto_plot_ship_pix,'20021501855'
;###########################################################################
PRO AUTO_PLOT_SHIP_PIX,prefix

tfilepath = '~/osu_shiptrack_files'
modispath = '/data2/mattchri/satellite/modis_51/'
outputpath = './output_mod_pix_algorithm/'

;Aquire t-file data
lfile = file_search(tfilepath,'l'+prefix+'*',/EXPAND_ENVIRONMENT,count=llct)
tfile = file_search(tfilepath,'t'+prefix+'*',/EXPAND_ENVIRONMENT,count=ttct)
if llct gt 0 and ttct gt 0 then begin


;Satellite Type (Aqua or Terra)
st=strpos(lfile(0),'osu_shiptrack_files')
aqua_str = strmid(lfile(0),st+26,4)
terra_str = strmid(lfile(0),st+26,5)
if aqua_str eq 'aqua' then mtype = 'MYD'
if terra_str eq 'terra' then mtype = 'MOD' 
 
;Aquire MODIS data
nprefix = strmid(prefix,0,7)+'.'+strmid(prefix,7,4)
datatype = '021KM'
temp = mtype+datatype
F02=file_search(modispath+temp+'*'+nprefix+'*',count=f02ct)

datatype = '03'
temp = mtype+datatype
F03=file_search(modispath+temp+'*'+nprefix+'*',count=f03ct)

;MODIS data missing
if f02ct eq 0 or f03ct eq 0 then begin
print,'MODIS DATA IS NOT AVAILABLE'
print,'Please run:auto_get_modis_data_osu_tracks.pro' 
STOP
endif

;Open MODIS data
read_mod02,f02(0),rad02,str2
read_mod03,f03(0),rad03,str3

;Get ship track MODIS locations
read_osu_shiptrack_file,tfile(0),year,jday,hour,month,mday,trkct,trk_pos_ct,txs,tys

;Get ship track geo locations
read_osu_shiptrack_file,lfile(0),year,jday,hour,month,mday,trkct,trk_pos_ct,tlons,tlats

lon = reform(rad03(*,*,1))
lat = reform(rad03(*,*,0))
dat = reform(rad02(*,*,3))
cmask = bytscl(dat,min=0.,max=.4,top=35)+220

color_bar
map_set,/cont,limit=[min(lat),min(lon),max(lat),max(lon)],pos=[.05,.1,.95,.95],$
/hires,/grid,latlab=157.5,lonlab=42.5,/label,color=9,charsize=3

;Project data
sz=size(lon)
for i=0,sz(1)-4 do begin
for j=0,sz(2)-4 do begin
 x0=lon(i,j)
 x1=lon(i+3,j+3)
 y0=lat(i,j)
 y1=lat(i+3,j+3)
 polyfill,[x0,x1,x1,x0],[y0,y0,y1,y1],color=cmask(i,j)
endfor
endfor

map_set,/cont,limit=[min(lat),min(lon),max(lat),max(lon)],pos=[.05,.1,.95,.95],$
/hires,/grid,latlab=157.5,lonlab=42.5,/label,color=9,charsize=3,/noerase

;Save satellite image
tstr = 'auto_ship_px_'+prefix+'_satellite'
void = TVREAD(/png, Filename=tstr,/nodialog)
print,'mv '+tstr+' '+outputpath
spawn,'mv '+tstr+' '+outputpath

;Overlay hand-logged positions
tstr = 'auto_ship_px_'+prefix+'_track_locations'
for ii=0,trkct-1 do plots,tlons(ii,0),tlats(ii,0),color=1,psym=1  ;plot the head
for ii=0,trkct-1 do for ij=1,trk_pos_ct(ii)-1 do plots,tlons(ii,ij),tlats(ii,ij),color=1,psym=2,symsize=.5 ;plot the rest
for ii=0,trkct-1 do for ij=0,trk_pos_ct(ii)-2 do plots,[tlons(ii,ij),tlons(ii,ij+1)],[tlats(ii,ij),tlats(ii,ij+1)],color=1 ;connect lines
void = TVREAD(/png, Filename=tstr,/nodialog)
print,'mv '+tstr+' '+outputpath
spawn,'mv '+tstr+' '+outputpath

;Overlay pixels for each track
for ii=0,trkct-1 do begin
 ;with save file
 file= outputpath+'auto_ship_px_'+prefix+'_'+string(format='(i1)',ii)+'.sav'
 restore,file
 ;file= './output_mod_pix_algorithm/auto_ship_px_20021501855_2.hdf'
 ;hdf_sd_data,file,'CON1_PX_CT',con1_px_ct
 ;con1_px_ct=con1_px_ct(0)
 ;hdf_sd_data,file,'CON1_PX_GEO',con1_px_geo
 ;hdf_sd_data,file,'CON2_PX_CT',con2_px_ct
 ;con2_px_ct=con2_px_ct(0)
 ;hdf_sd_data,file,'CON2_PX_GEO',con2_px_geo
 ;hdf_sd_data,file,'SHIP_PX_CT',SHIP_px_ct
 ;ship_px_ct=ship_px_ct(0)
 ;hdf_sd_data,file,'SHIP_PX_GEO',SHIP_px_geo

 lonid=where(str_px_data eq 'lon')
 latid=where(str_px_data eq 'lat')
 for k=0,con1_px_ct-1 do plots,con1_px_data(7,k),con1_px_data(6,k),color=3,psym=1,symsize=.01
 for k=0,con2_px_ct-1 do plots,con2_px_data(7,k),con2_px_data(6,k),color=4,psym=1,symsize=.01
 for k=0,ship_px_ct-1 do plots,ship_px_data(7,k),ship_px_data(6,k),color=2,psym=1,symsize=.01
endfor
map_set,/cont,limit=[min(lat),min(lon),max(lat),max(lon)],pos=[.05,.1,.95,.95],$
/hires,/grid,latlab=157.5,lonlab=42.5,/label,color=9,charsize=3,/noerase
tstr = 'auto_ship_px_'+prefix+'_pixels'
void = TVREAD(/png, Filename=tstr,/nodialog)
print,'mv '+tstr+' '+outputpath
spawn,'mv '+tstr+' '+outputpath





;Show Segment #'s
map_set,/cont,limit=[min(lat),min(lon),max(lat),max(lon)],pos=[.05,.1,.95,.95],$
/hires,/grid,latlab=157.5,lonlab=42.5,/label,color=9,charsize=3

;Project data
sz=size(lon)
for i=0,sz(1)-4 do begin
for j=0,sz(2)-4 do begin
 x0=lon(i,j)
 x1=lon(i+3,j+3)
 y0=lat(i,j)
 y1=lat(i+3,j+3)
 polyfill,[x0,x1,x1,x0],[y0,y0,y1,y1],color=cmask(i,j)
endfor
endfor
;Overlay segment pixels for each track
for ii=0,trkct-1 do begin
 file= outputpath+'auto_ship_px_'+prefix+'_'+string(format='(i1)',ii)+'.sav'
 restore,file
 lonid=where(str_px_data eq 'lon')
 latid=where(str_px_data eq 'lat')
 for k=0,con1_px_ct-1 do plots,con1_px_data(7,k),con1_px_data(6,k),color=con1_px_loc(2,k),psym=1,symsize=.01
 for k=0,con2_px_ct-1 do plots,con2_px_data(7,k),con2_px_data(6,k),color=con2_px_loc(2,k),psym=1,symsize=.01
 for k=0,ship_px_ct-1 do plots,ship_px_data(7,k),ship_px_data(6,k),color=ship_px_loc(2,k),psym=1,symsize=.01
endfor
map_set,/cont,limit=[min(lat),min(lon),max(lat),max(lon)],pos=[.05,.1,.95,.95],$
/hires,/grid,latlab=157.5,lonlab=42.5,/label,color=9,charsize=3,/noerase
tstr = 'auto_ship_px_'+prefix+'_segment'
void = TVREAD(/png, Filename=tstr,/nodialog)
print,'mv '+tstr+' '+outputpath
spawn,'mv '+tstr+' '+outputpath




endif

return
end
