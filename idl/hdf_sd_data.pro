pro hdf_sd_data,fname,tstr,data

file_id = hdf_open(fname,/read)
sd_id = hdf_sd_start(fname,/read)
Result = HDF_SD_NAMETOINDEX(sd_id,tstr)
w_id = hdf_sd_select(sd_id,Result)
hdf_sd_getinfo, w_id, type=w_type, dims=w_dims,$
                ndims=w_ndims,name=w_name,natts=w_natts
;print,w_name
hdf_sd_getdata,w_id,data

hdf_sd_end,sd_id
hdf_close,file_id

return
end
