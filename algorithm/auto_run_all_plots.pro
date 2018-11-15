;+
;NAME:
;
;   Plot all ship tracks
;
;PURPOSE:
;
;   This procedure runs the through the results of the auotmated detection 
;   algorithm and plots the pixels on a MODIS scene that is projected onto
;   a lat/lon grid.
;
;SUBROUTINES: auto_main.pro
;###########################################################################
PRO AUTO_RUN_ALL_PLOTS

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
 auto_plot_ship_pix,prefix
endfor

return
end
