;+
;NAME:
;
;   Read Level 2 Modis 06 (Cloud Product)
;
;PURPOSE:
;
;   This procedure is used to read a mod04 and 06 hdf file and return AOT and Cloud property info
;
;DESCRIPTION:
;
;   The returned array contains 1354 pixels along the x-axis and ~2030 pixels along the y-axis
;   each pixel returned has information about the AOT, cloud optical depth and effective radius 
;
;INPUT: MOD06 hdf file
;
;OUTPUT:  arad = ~(1354, 2030, 10)
;
;arad(*,*,0) = Cloud_Optical_Thickness
;arad(*,*,1) = Cloud Effective Radius at 1.6um
;arad(*,*,2) = Cloud Effective Radius at 2.1um
;arad(*,*,3) = Cloud Effective Radius at 3.7um
;arad(*,*,4) = Cloud Water Path at 2.1 um
;arad(*,*,5) = Cloud_Fraction
;arad(*,*,6) = Cloud Top Pressure
;arad(*,*,7) = Cloud Top Temperature
;arad(*,*,8) = Cloud Phase Optical Properties 0=fill, 1=clear, 2=liquid water cloud, 3=ice cloud, 4=undetermined phase cloud
;arad(*,*,9) = Cloud_Multi_Layer_Flag
;arad(*,*,10) = Sunglint_flag
;arad(*,*,11) = Brightness temperature 11 um
;
;astr(0) = 'ctau'  cloud optical thickness
;astr(1) = 're1.6' cloud effective radius at 1.6 um
;astr(2) = 're2.1' cloud effective radius at 2.1 um
;astr(3) = 're3.7' cloud effective radius at 3.7 um
;astr(4) = 'lwp'   cloud water path at 2.1 um
;astr(5) = 'fcc'   cloud cover fraction  
;astr(6) = 'ctp'   cloud top pressure    [hpa]
;astr(7) = 'ctt'   cloud top temperature [K]
;astr(8) = 'phase' cloud phase optical properties
;astr(9) = 'layer' cloud multi layer flag =1 single layer
;astr(10) = 'sgl'  Sunglint flag
;astr(11) = 'Tb11' Brightness temperature at 11 um
;
;SUB PROGRAMS
;
;a)  runhdf.pro
;
;AUTHOR:
;    Matt Christensen
;    Colorado State University
;###########################################################################
PRO READ_MOD06_C6,FILE06,ARAD,ASTR,ASTR_LONG,ASTR_UNITS

;MOD06
; Cell_Across_Swath_Sampling:   3 1348 5
; Cell_Along_Swath_Sampling:    3 2028 5 

hdf_sd_data,file06,'Cloud_Effective_Radius',data
res = size(data)
d1 = fix(res(1)) & d2 = fix(res(2))

vname=[$
'Cloud_Optical_Thickness_16',$
'Cloud_Optical_Thickness',$
'Cloud_Optical_Thickness_37',$
'Cloud_Effective_Radius_16',$
'Cloud_Effective_Radius',$
'Cloud_Effective_Radius_37',$
'Cloud_Water_Path_16',$
'Cloud_Water_Path',$
'Cloud_Water_Path_37',$
'Cloud_Optical_Thickness_16_PCL',$
'Cloud_Optical_Thickness_PCL',$
'Cloud_Optical_Thickness_37_PCL',$
'Cloud_Effective_Radius_16_PCL',$
'Cloud_Effective_Radius_PCL',$
'Cloud_Effective_Radius_37_PCL',$
'Cloud_Water_Path_16_PCL',$
'Cloud_Water_Path_PCL',$
'Cloud_Water_Path_37_PCL',$
'Cloud_Fraction',$
'cloud_top_pressure_1km',$
'cloud_top_temperature_1km',$
'Cloud_Phase_Optical_Properties',$
'Cloud_Phase_Infrared_1km',$
'Cloud_Multi_Layer_Flag']

astr = [$
'ctau1.6','ctau','ctau3.7',$
're1.6','re2.1','re3.7',$
'lwp1.6','lwp','lwp3.7',$
'ctau1.6_PCL','ctau2.1_PCL','ctau3.7_PCL',$
're1.6_PCL','re2.1_PCL','re3.7_PCL',$
'lwp1.6_PCL','lwp2.1_PCL','lwp3.7_PCL',$
'fcc','ctp','ctt','phase','phase_ir','layer','sgl','Tb11']

d3 = n_elements(astr)
arad = fltarr(d1,d2,d3)
 
 for kk=0,n_elements(vname)-1 do begin
  ;print,kk
  rdata,file06,vname(kk),arr
  sz=size(arr)
  if sz(1) eq d1 and sz(2) eq d2 then arad(*,*,kk) = arr
  if sz(1) lt d1 then begin
   narr = congrid(arr,d1,d2)
   arad(*,*,kk) = narr
  endif
 endfor
 kid=kk
 ;print,kid
 
 ;MODIS Byte Flags
 cmlflag = clm_bitextracter(6,file06,'Cloud_Mask_1km')
 sunglint_flag = cmlflag(*,*,3)
 arad(*,*,kid) = sunglint_flag
 kid=kid+1
 
 ;print,kid
 ;Brightness Temperature
 modread,file06,'Brightness_Temperature',arr,scale,offset,fill
 arr = reform( ((arr(*,*,1)-offset(0))*scale(0)) )
 ctt = congrid(arr,d1,d2)
 arad(*,*,kid) = ctt

astr_long = [vname,'sunglint','Brightness_Temperature']
astr_units = ['1','1','1','um','um','um','g/m^2','g/m^2','g/m^2','1','1','1','um','um','um','g/m^2','g/m^2','g/m^2','1','hPa','K','1','1','1','1','K']

return
end
