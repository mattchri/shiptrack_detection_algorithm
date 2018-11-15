;+
;NAME:
;
;   Run Automated Routine for All Ship Tracks
;
;PURPOSE:
;
;   This procedure runs the auotmated detection algorithm for all of the osu ship track files
;
;SUBRO&UTINES: auto_main.pro
;###########################################################################
PRO AUTO_RUN_ALL

;Paths
tfilepath = '~/osu_shiptrack_files'
modispath = '/data2/mattchri/satellite/modis_51/'

;Aquire t-file data
tfiles = file_search(tfilepath,'t*.dat',/EXPAND_ENVIRONMENT,count=llct)

;Loop over all ship track location files
for i=0,llct-1 do begin
 ed=strpos(tfiles(i),'.dat')
 prefix=strmid(tfiles(i),ed-11,11)
 print,i,'  ',prefix
 auto_main,prefix
 ;auto_main,prefix,plot_it=1
endfor

return
end
