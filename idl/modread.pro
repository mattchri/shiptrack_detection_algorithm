pro modread,filename, variablename, variable, scale, offset, fill, long_name, unit_name

 unitstr   = 'units'
 scalestr  = 'scale_factor'
 offsetstr = 'add_offset'
 fillstr   = '_FillValue'
 longname  = 'long_name'

if variablename eq 'EV_250_RefSB' then begin
 scalestr  = 'reflectance_scales'
 offsetstr = 'reflectance_offsets'
 unitstr   = 'radiance_units'
endif

if variablename eq 'EV_250_Aggr1km_RefSB' then begin
 scalestr  = 'reflectance_scales'
 offsetstr = 'reflectance_offsets'
endif

if variablename eq 'EV_500_Aggr1km_RefSB' then begin
 scalestr  = 'reflectance_scales'
 offsetstr = 'reflectance_offsets'
endif

if variablename eq 'EV_1KM_Emissive' then begin
 scalestr  = 'radiance_scales'
 offsetstr = 'radiance_offsets'
endif

;--- assign file ID ---
fileID = hdf_sd_start(filename,/read)

;--- using fileID and the variable name, --
;--- assign variable ID, and extract data -- 
varindex = hdf_sd_nametoindex(fileID,variablename)
varID = hdf_sd_select(fileID,varindex)
hdf_sd_getdata, varID, variable

;--- find the scale and offset ---
scaleindex = hdf_sd_attrfind(varID,scalestr)
hdf_sd_attrinfo, varID, scaleindex, data=scale
offsetindex = hdf_sd_attrfind(varID,offsetstr)
hdf_sd_attrinfo, varID, offsetindex, data=offset
fillindex = hdf_sd_attrfind(varID,fillstr)
hdf_sd_attrinfo, varID, fillindex, data=fill
;print,'scale=',scale,'offset=',offset

unit_id = hdf_sd_attrfind(varID,unitstr)
hdf_sd_attrinfo, varID, unit_id, data=unit_name

longname_id = hdf_sd_attrfind(varID,longname)
hdf_sd_attrinfo, varID, longname_id, data=long_name

;--- close data file --
hdf_sd_endaccess, varID
hdf_sd_end, fileID

end
