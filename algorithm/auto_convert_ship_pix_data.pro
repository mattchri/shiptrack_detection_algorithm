;+
;NAME:
;
;   Convert Ship Pixel Sav Files to HDF files
;
;PURPOSE:
;
;   This procedure converts the sav file to an HDF file using structures
;   *Variables are hard coded, you need to change this program if any changes
;   are made to variable names in AUTO_MAIN.PRO
;###########################################################################
PRO AUTO_CONVERT_SHIP_PIX_DATA

;Convert to HDF
path = './output_mod_pix_algorithm/
files=file_search(path+'*.sav',count=fct)

;To change a single file
;id=where(files eq 'output_mod_pix_algorithm/auto_ship_px_20021461915_12.sav')
;id=where(files eq 'output_mod_pix_algorithm/auto_ship_px_20112141855_0.sav')
;files=files(id)
;fct=1

for i=0,fct-1 do begin
restore,files(i)

one_dvar = {con1_px_ct:con1_px_ct,con2_px_ct:con2_px_ct,ship_px_ct:ship_px_ct,$
n_thresh:n_thresh,separate_dist:separate_dist,sigma_thresh:sigma_thresh}
two_dvar = {con1_px_data:con1_px_data,con1_px_loc:con1_px_loc,con1_px_mean:con1_px_mean,$
con2_px_data:con2_px_data,con2_px_loc:con2_px_loc,con2_px_mean:con2_px_mean,$
ship_px_data:ship_px_data,ship_px_loc:ship_px_loc,ship_px_mean:ship_px_mean}

tags_one = tag_names(one_dvar)
tags_two = tag_names(two_dvar)

str_one_dvar = [$
'#control1 pixels',$
'#control2 pixels',$
'$ship pixels',$
'nearest neighbor pixel correlation distance',$
'polluted-unpolluted cloud separation distance',$
'polluted cloud sigma threshold']

str_two_dvar = [$
'control1 longitude/latitude location',$
'control1 x/y modis location and segment#',$
'control1 pixel average',$
'control2 longitude/latitude location',$
'control2 x/y modis location and segment#',$
'control2 pixel average',$
'ship longitude/latitude location',$
'ship x/y modis location',$
'ship pixel average']

st = strpos(files(i),'ship_px')
ed = strpos(files(i),'.sav')
if (ed-st) eq 21 then filename = strmid(files(i),ed-26,26)+'.hdf'
if (ed-st) eq 22 then filename = strmid(files(i),ed-27,27)+'.hdf'
print,filename,st,ed,ed-st
;Open HDF file for writing
file_id = hdf_open(filename,/CREATE)
fileID = HDF_SD_START(filename, /RDWR)

;Loop over each scientific variable
for j=0,n_elements(tags_one)-1 do begin
data=one_dvar.(j)
sz2=size(data)
vID = hdf_sd_create( fileID,tags_one(j),[1], /FLOAT)
hdf_sd_adddata,vID,data
HDF_SD_ATTRSET,vID,'long_name',str_one_dvar(j)
hdf_sd_endaccess,vID
endfor

;Loop over each scientific variable
for j=0,n_elements(tags_two)-1 do begin
data=two_dvar.(j)
sz2=size(data)
vID = hdf_sd_create( fileID,tags_two(j),[sz2(1),sz2(2)], /FLOAT)
hdf_sd_adddata,vID,data
HDF_SD_ATTRSET,vID,'long_name',str_two_dvar(j)
hdf_sd_endaccess,vID
endfor


data=str_px_data
sz2=size(data)
vID = hdf_sd_create( fileID,'MODIS_DATA_STRING',[sz2(1)], /STRING)
hdf_sd_adddata,vID,data
hdf_sd_endaccess,vID

;data=str_px_loc
;sz2=size(data)
;vID = hdf_sd_create( fileID,'LOCATION_DATA_STRING',[sz2(1)], /STRING)
;hdf_sd_adddata,vID,data
;hdf_sd_endaccess,vID

;data=str_px_data_long
;sz2=size(data)
;vID = hdf_sd_create( fileID,'DATA_LONG_STRING',[sz2(1)], /STRING)
;hdf_sd_adddata,vID,data
;hdf_sd_endaccess,vID

;data=str_px_data_units
;sz2=size(data)
;vID = hdf_sd_create( fileID,'DATA_UNITS_STRING',[sz2(1)], /STRING)
;hdf_sd_adddata,vID,data
;hdf_sd_endaccess,vID


HDF_SD_END, fileID
hdf_close,file_id

spawn,'mv '+filename+' '+path

endfor

stop

return
end
