pro rdata,file06,name,arr,long_name_unit_name

 modread,file06,name,tauarr,scale,offset,fill,long_name,unit_name
 res=size(tauarr)
 dn=fix(res(0))
 d1=fix(res(1))
 d2=fix(res(2))
 d3=fix(res(3))
 
 if dn eq 2 then arr=fltarr(d1,d2)
 if dn eq 3 then arr=fltarr(d1,d2,d3)
 arr(*,*,*)=-999
 for k=0,d3-1 do begin
  if dn eq 2 then begin
   for i=0,d1-1 do for j=0,d2-1 do if tauarr(i,j) ne fill(0) then arr(i,j)=(tauarr(i,j)-offset(0))*scale(0)
  endif
  if dn eq 3 then begin
   for i=0,d1-1 do for j=0,d2-1 do if tauarr(i,j,k) ne fill(0) then arr(i,j,k)=(tauarr(i,j,0)-offset(0))*scale(0)
  endif
 endfor
 
 if n_elements(scale) gt 1 then stop
 
return
end
