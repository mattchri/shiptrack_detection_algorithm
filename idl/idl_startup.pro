; Keep 24 bit graphics and retain window content
device, true_color=24
device, decompose=0, retain=2, bypass_translation=0
loadct, 39
!except = 0 ;ignore arithmetic error reporting
!p.color = 0
!p.background = 255
pref_set, 'IDL_PATH', '~/:<IDL_DEFAULT>', /COMMIT
!PATH = '~/idl/trunk:' + !PATH
!PATH = '~/idl/trunk/orac:' + !PATH
!PATH = '~/idl/trunk/aci:' + !PATH
!PATH = '~/idl/trunk/ats:' + !PATH
!PATH = '~/idl/trunk/coyote:' + !PATH
!PATH = '~/idl/trunk/Generic:' + !PATH
!PATH = '~/idl/trunk/grb:' + !PATH
!PATH = '~/idl/trunk/hdf:' + !PATH
!PATH = '~/idl/trunk/ncdf:' + !PATH
!PATH = '~/idl/trunk/plotting:' + !PATH
!PATH = '~/idl/trunk/theory_aci:' + !PATH
!PATH = '~/idl/trunk/theory_aci/mie:' + !PATH
!PATH = '~/idl/trunk/statistics:' + !PATH
!PATH = '~/idl/trunk/modis:' + !PATH

; For Arctic dataset analysis
;  !PATH =  '~/idl/trunk/ArORIS:' + !PATH 
;  !PATH =  '~/idl/trunk/ArORIS:' + !PATH 
;  !PATH =  '~/idl/trunk/ArORIS/main:' + !PATH 
;  !PATH =  '~/idl/trunk/ArORIS/main/arcticts:' + !PATH 
;  !PATH =  '~/idl/trunk/ArORIS/main/ncdf:' + !PATH 
;  !PATH =  '~/idl/trunk/ArORIS/main/arcticts/full_process:' + !PATH 
;  !PATH =  '~/idl/trunk/ArORIS/main/arcticts/full_process/bin:' + !PATH 


print,'Welcome Matt!'
