;+
;NAME:
;
;   Read Level 2 Modis (Basic Calibrated Radiances)
;
;PURPOSE:
;
;   This procedure is used to read a mod02 hdf file and return the radiances, and geographic info
;
;DESCRIPTION:
;
;   The returned array contains 1354 pixels along the x-axis and ~2030 pixels along the y-axis
;   each pixel returned has information about the radiance and latitude and longitude stored in the
;   third dimension of arad.
;
;INPUT: mod02 hdf file
;
;OUTPUT:  arad = ~(1354, 2030, 3)
;
;arad(*,*,0) = Latitude
;arad(*,*,1) = Longitude
;arad(*,*,2) = Solar Zenith Angle
;
;SUB PROGRAMS
;
;a)  hdf_sd_data.pro
;b)  modis_fill_array.pro
;
;EXAMPLE:
;
;read_mod02,'/raid3/chrismat/modis/MYD021KM.A2007220.2255.hdf',arad
;
;AUTHOR:
;    Matt Christensen
;    Colorado State University
;###########################################################################
PRO READ_MOD03,filen,arad,astr,astr_long,astr_units

hdf_sd_data,filen,'Latitude',lat
hdf_sd_data,filen,'Longitude',lon
hdf_sd_data,filen,'SolarZenith',solz

res = size(lat)
arad = fltarr(res(1),res(2),3)
arad(*,*,0)  = lat
arad(*,*,1)  = lon
arad(*,*,2)  = solz*.01

astr=['lat','lon','solz']
astr_long=['latitude','longitude','solar zenith angle']
astr_units=['degrees','degrees','degrees']
return
end
