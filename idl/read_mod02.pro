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
;OUTPUT:  arad = ~(1354, 2030, 8)
;
;arad(*,*,0) = 0.64(um) (band 1)
;arad(*,*,1) = 0.84(um) (band 2)
;arad(*,*,2) = 1.6 (um) (band 6)
;arad(*,*,3) = 2.1 (um) (band 7)
;arad(*,*,4) = 3.7 (um) (band 20)
;arad(*,*,5) = 11.0(um) (band 31)     also 12 (um) (band 32) not included in arad
;arad(*,*,6) = Latitude
;arad(*,*,7) = Longitude
;arad(*,*,8) = Solar Zenith Angle
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
PRO READ_MOD02,filen,arad,astr,astr_long,astr_units

;250 aggragate
 modread,filen,'EV_250_Aggr1km_RefSB',tauarr,scale,offset,fill
 hdf_sd_data,filen,'Band_250M',band_250
 id1 = where(band_250 eq 1)
 id2 = where(band_250 eq 2)
 fill = 32767
 
 ;Channel 1
 maskg = tauarr(*,*,id1) lt fill
 maskb = tauarr(*,*,id1) gt fill
 s1 = scale(id1)
 chnl1 = maskg*tauarr(*,*,id1)*s1(0) + maskb*(-999.)
 
 ;Channel 2
 maskg = tauarr(*,*,id2) lt fill
 maskb = tauarr(*,*,id2) gt fill
 s1 = scale(id2)
 chnl2 = maskg*tauarr(*,*,id2)*s1(0) + maskb*(-999.)
 
;500 aggragate
 modread, filen, 'EV_500_Aggr1km_RefSB', tauarr, scale, offset
 hdf_sd_data,filen,'Band_500M',band_500
 id1 = where(band_500 eq 6)
 id2 = where(band_500 eq 7)

 ;Channel 3
 maskg = tauarr(*,*,id1) lt fill
 maskb = tauarr(*,*,id1) gt fill
 s1 = scale(id1)
 chnl3 = maskg*tauarr(*,*,id1)*s1(0) + maskb*(-999.)
 
 ;Channel 4
 maskg = tauarr(*,*,id2) lt fill
 maskb = tauarr(*,*,id2) gt fill
 s1 = scale(id2)
 chnl4 = maskg*tauarr(*,*,id2)*s1(0) + maskb*(-999.)
 
 ;Band 1KM Emissive
 modread, filen, 'EV_1KM_Emissive', tauarr, scale, offset, long_name, unit_name
 hdf_sd_data,filen,'Band_1KM_Emissive',band_1KM
 id1 = where(band_1KM eq 20)
 id2 = where(band_1KM eq 31)

 ;Channel 5
 maskg = tauarr(*,*,id1) lt fill
 maskb = tauarr(*,*,id1) gt fill
 s1 = scale(id1) & o1 = offset(id1)
 chnl5 = maskg*s1(0)*( tauarr(*,*,id1)-o1(0) )*1.0e7/(2667.*2667.) + maskb*(-999.)
 
 ;Channel 6
 maskg = tauarr(*,*,id2) lt fill
 maskb = tauarr(*,*,id2) gt fill
 s1 = scale(id2) & o1 = offset(id2)
 chnl6 = maskg*s1(0)*( tauarr(*,*,id2)-o1(0) )*1.0e7/(907.*907.) + maskb*(-999.)

res = size(chnl1)
arad = fltarr(res(1),res(2),6)
arad(*,*,0)  = chnl1
arad(*,*,1)  = chnl2
arad(*,*,2)  = chnl3
arad(*,*,3)  = chnl4
arad(*,*,4)  = chnl5
arad(*,*,5)  = chnl6

astr=['.64','.84','1.6','2.1','3.7','11']
astr_long=['reflectance at 0.64 um','reflectance at 0.84 um','reflectance at 1.6 um','reflectance at 2.1 um','reflectance at 3.7 um','emission at 11 um']
astr_units=['none', 'none', 'none', 'none', 'none','Watts/m^2/micrometer/steradian']
return
end
