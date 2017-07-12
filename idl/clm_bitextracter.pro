function clm_bitextracter, MODFlag, MODFileName, ClMaskSDSName

;Example
;mask = clm_bitextracter(6, '/raid3/chrismat/modis/MYD06_L2.A2007220.2255.hdf', 'Cloud_Mask_1km')

; IDL routine
;
; ClM_BitExtracter.pro v 1.0
;
; ClM_BitExtracter.pro extracts the individual cloud mask tests from the full byte
;   cloud mask and places the results into an output array.  This routine
;   extracts bits from MOD06/35, but can be used as an example/template for 
;   other QA or bit flags extracted from byte arrays.
;
;
; Input: 
;    MODFlag	 	Integer	   : The MOD that is being read from.  In this case 6 for a MOD06 file
;    MODFileName	String	   : Full path and name of the ecosystem ancillary file
;    ClMaskSDSName	String	   : Name of the Cloud Mask SDS.
; 
; Output:
;    CloudMaskTests	Byte Array : The individual results of the cloud mask test,
;				     written as follows:
;					CloudMaskTest(*,*,0:8)
;					CloudMaskTest(*,*,0) = Determined or not
;					CloudMaskTest(*,*,1) = Percent Cloudy Test
;					CloudMaskTest(*,*,2) = Day/Night Flag
;					CloudMaskTest(*,*,3) = Sun Glint Flag
;					CloudMaskTest(*,*,4) = Snow/Ice Flag
;					CloudMaskTest(*,*,5) = Surface Type
;                   CloudMaskTest(*,*,6) = Heavy Aerosol 
;                   CloudMaskTest(*,*,7) = Thin Cirrus Det (Vis) 
;                   CloudMaskTest(*,*,8) = Shadow Found
;
; Required routines:
;    		ReadSDS
;
; Notes:
;  Until the new MOD06 L2QA plan is implemented, only MOD35 files can be read.
;
; Developer
;  v 1.0  03/20/2001
;		Eric Moody moody@climate.gsfc.nasa.gov
;		Jason Li 
;       Emergent IT
;       MODIS - Atmosphere Group
;

hdf_sd_data,modfilename,ClMaskSDSName,CloudMask

if (MODFlag eq 6) then begin
   ;Transpose the array from band,x,y to x,y,band:
   CloudMask = TRANSPOSE(CloudMask, [1, 2, 0])
endif

;Determine the size of the Cloud Mask array:
dims = size(CloudMask,/dimensions)
   xdim = dims(0)
   ydim = dims(1)

;Create the integer CloudMaskTests output array:
CloudMaskTests = IntArr(xdim,ydim,9)


;Extract the determined, or not test:
CloudMaskTests[*,*,0] =       (cloudMask[*,*,0] AND   1B)


;Extract the Cloudy Test:
CloudMaskTests[*,*,1] = ISHFT((cloudMask[*,*,0] AND   6B), -1)


;Extract the Day/Night Flag:
CloudMaskTests[*,*,2] = ISHFT((cloudMask[*,*,0] AND   8B), -3)


;Extract the Sun Glint Flag:
CloudMaskTests[*,*,3] = ISHFT((cloudMask[*,*,0] AND  16B), -4)


;Extract the Snow/Ice Flag:
CloudMaskTests[*,*,4] = ISHFT((cloudMask[*,*,0] AND  32B), -5)


;Extract the Surface Type:
CloudMaskTests[*,*,5] = ISHFT((cloudMask[*,*,0] AND 192B), -6)


;Extract the Heavy Aerosol Detection:
CloudMaskTests[*,*,6] =       (cloudMask[*,*,1] AND   1B)


;Extract the Thin Cirrus Detection (Visible):
CloudMaskTests[*,*,7] = ISHFT((cloudMask[*,*,1] AND   2B), -1)


;Extract the Shadow Found Flag:
CloudMaskTests[*,*,8] = ISHFT((cloudMask[*,*,1] AND   4B), -2)


;Convert the Int array into a byte array:
CloudMaskTests = BYTE(CloudMaskTests)


; Return the Extracted Cloud Mask Tests:
return, CloudMaskTests

end
