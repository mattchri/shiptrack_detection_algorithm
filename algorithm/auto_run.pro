;+
;NAME:
;
;   Run Automated Routine for All Ship Tracks
;
;PURPOSE:
;
;   This procedure runs the auotmated detection algorithm for all ship tracks
;
;Instructions for bsub
;$chmod 777 wrap_auto_main.sh
;.r auto_main
;resolve_all
;save,/routines,filename='/home/users/mchristensen/idl/trunk/ship/a-train/shiptrack_algorithm/auto_main.sav'
;
;SUBRO&UTINES: auto_main.pro
;###########################################################################
PRO AUTO_RUN

;Paths
tfilepath = '/group_workspaces/jasmin2/aopp/mchristensen/shiptrack/shiptrack_logged_files/combined/'
modispath = '/group_workspaces/cems2/nceo_generic/satellite_data/modis_c61/'
outputPath = '/group_workspaces/jasmin2/acpc/public/mchristensen/shiptrack/tpls/'
FILE_MKDIR,outputPath

;Aquire t-file data
tfiles = file_search(tfilepath,'t*.dat',/EXPAND_ENVIRONMENT,count=llct)

;Loop over all ship track location files
for i=0,llct-1 do begin
tfile = tfiles[i]

ed = STRPOS(tfile,'.dat')
YYYY = STRMID(tfile,ed-12,4)
DDD = STRMID(tfile,ed-8,3)
HHHH = STRMID(tfile,ed-4,4)

if strpos(tfile,'MYD') GT -1 then satName='myd'
if strpos(tfile,'MOD') GT -1 then satName='mod'

F02 = FILE_SEARCH(modispath+satName+'021km/'+YYYY+'/'+DDD+'/'+'*.A'+YYYY+DDD+'.'+HHHH+'*.hdf',count=F02CT)
F03 = FILE_SEARCH(modispath+satName+'03/'+YYYY+'/'+DDD+'/'+'*.A'+YYYY+DDD+'.'+HHHH+'*.hdf',count=F03CT)
F04 = FILE_SEARCH(modispath+satName+'04_l2/'+YYYY+'/'+DDD+'/'+'*.A'+YYYY+DDD+'.'+HHHH+'*.hdf',count=F04CT)
F06 = FILE_SEARCH(modispath+satName+'06_l2/'+YYYY+'/'+DDD+'/'+'*.A'+YYYY+DDD+'.'+HHHH+'*.hdf',count=F06CT)

IF F02CT EQ 1 AND F03CT EQ 1 AND F04CT EQ 1 AND F06CT EQ 1 THEN BEGIN
PRINT,'PROCESSING: ',tfile

CaseNumber = STRING(FORMAT='(I05)',I)
;set up submission manager
wallTime = '12:00'
RES_ALLOCATE = '"select[maxmem > 16384] rusage[mem=16384]"'
jobName = CaseNumber
outFile = outputPath+'/'+CaseNumber+'.out'
errFile = outputPath+'/'+CaseNumber+'.err'

IF N_ELEMENTS(FILE_SEARCH(outFile)) EQ 1 THEN SPAWN,'rm '+outFile
IF N_ELEMENTS(FILE_SEARCH(errFile)) EQ 1 THEN SPAWN,'rm '+errFile

;Only input runFile for BSUB
bsubEXE='bsub -q short-serial -W '+wallTime+' -R '+RES_ALLOCATE+' -o '+outFile+' -e '+errFile+' -J '+jobName+' '+' ./wrap_auto_main.sh '+tfile+' '+F02[0]+' '+F03[0]+' '+F04[0]+' '+F06[0]+' '+outputPath
PRINT,bsubEXE
SPAWN,bsubEXE

 ;auto_main,TFILE=tfile,F02=F02[0],F03=F03[0],F04=F04[0],F06=F06[0],OUTPATH=outputPath;,/plot_track
ENDIF ELSE PRINT,'MISSING MODIS DATA'

endfor

return
end
