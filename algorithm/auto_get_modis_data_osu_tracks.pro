;+
;NAME:
;
;   Get MODIS DATA by FTP
;
;PURPOSE:
;
;   This procedure runs through the osu ship track files
;   and downloads MODIS calibrated radiances, geo data, and cloud product
;###########################################################################
PRO AUTO_GET_MODIS_DATA_OSU_TRACKS

data_link_path = '/data2/mattchri/satellite/modis_51/'
data_path = '/data2/mattchri/satellite/modis/'
tfilepath = '~/osu_shiptrack_files'

;FTP Site
oUrl = OBJ_NEW('IDLnetUrl')  
oUrl->SetProperty, VERBOSE = 1  
oUrl->SetProperty, URL_SCHEME = 'ftp'
oUrl->SetProperty, URL_HOST = 'ladsweb.nascom.nasa.gov'
oUrl->SetProperty, URL_USERNAME = 'anonymous'
oUrl->SetProperty, URL_PASSWORD = ''
oUrl->SetProperty, FTP_CONNECTION_MODE = 0

;Get pfiles from sub-directories
tlists = file_search(tfilepath,'t*.dat',/EXPAND_ENVIRONMENT,count=ttct)
tlists = file_search(tfilepath,'l*.dat',/EXPAND_ENVIRONMENT,count=ttct)

prefixs = strarr(10000)
mtypes  = strarr(10000)
cnt = 0
for i=0,ttct-1 do begin
 ed=strpos(tlists(i),'.dat')
 prefixs(i) = strmid(tlists(i),ed-11,11)
 st=strpos(tlists(i),'osu_shiptrack_files')
 aqua_str = strmid(tlists(i),st+26,4)
 terra_str = strmid(tlists(i),st+26,5)
 if aqua_str eq 'aqua' then mtypes(i) = 'MYD'
 if terra_str eq 'terra' then mtypes(i) = 'MOD' 
 cnt=cnt+1
endfor
prefixs = prefixs(0:cnt-1)
mtypes  = mtypes(0:cnt-1)
print,'Number of MODIS FILES',cnt

for i=0,cnt-1 do begin
 prefix=strmid(prefixs(i),0,7)+'.'+strmid(prefixs(i),7,4)
 print,prefix
 
 datatype = '021KM'
 mtype = mtypes(i)+datatype
 a=file_search(data_link_path+mtype+'*'+prefix+'*',count=act)
 print,a
 if act eq 0 then begin  ;get data from modis website
  oUrl->SetProperty, URL_PATH = 'allData/51/'+mtype+'/'+strmid(prefix,0,4)+'/'+strmid(prefix,4,3)+'/'
  dirList = oUrl->GetFtpDirList()
  for j=0,n_elements(dirlist)-1 do begin
   st=strpos(dirlist(j),mtype+'.A')
   dfile = strmid(dirlist(j),st,22)+'.hdf'
   ftpfile = strmid(dirlist(j),st,44)
   modis_file_info,dfile,dp,dt
   if prefix eq dp then begin    
     oUrl->SetProperty, URL_PATH = 'allData/51/'+mtype+'/'+strmid(prefix,0,4)+'/'+strmid(prefix,4,3)+'/'+ftpfile
     print,'Downloading File:  ',dfile
     fn = oUrl->Get(FILENAME = data_path+ftpfile)
   endif
  endfor
 endif

 ;Check for MOD03
 datatype = '03'
 mtype = mtypes(i)+datatype
 a=file_search(data_link_path+mtype+'*'+prefix+'*',count=act)
 print,a
 if act eq 0 then begin  ;get data from modis website
  oUrl->SetProperty, URL_PATH = 'allData/51/'+mtype+'/'+strmid(prefix,0,4)+'/'+strmid(prefix,4,3)+'/'
  dirList = oUrl->GetFtpDirList()
  for j=0,n_elements(dirlist)-1 do begin
   st=strpos(dirlist(j),mtype+'.A')
   dfile = strmid(dirlist(j),st,22)+'.hdf'
   ftpfile = strmid(dirlist(j),st,44)
   modis_file_info,dfile,dp,dt
   if prefix eq dp then begin    
     oUrl->SetProperty, URL_PATH = 'allData/51/'+mtype+'/'+strmid(prefix,0,4)+'/'+strmid(prefix,4,3)+'/'+ftpfile
     print,'Downloading File:  ',dfile
     fn = oUrl->Get(FILENAME = data_path+ftpfile)
   endif
  endfor
 endif

 ;Check for MOD04
 datatype = '04_L2'
 mtype = mtypes(i)+datatype
 a=file_search(data_link_path+mtype+'*'+prefix+'*',count=act)
 print,a
 if act eq 0 then begin  ;get data from modis website
  oUrl->SetProperty, URL_PATH = 'allData/51/'+mtype+'/'+strmid(prefix,0,4)+'/'+strmid(prefix,4,3)+'/'
  dirList = oUrl->GetFtpDirList()
  for j=0,n_elements(dirlist)-1 do begin
   st=strpos(dirlist(j),mtype+'.A')
   dfile = strmid(dirlist(j),st,22)+'.hdf'
   ftpfile = strmid(dirlist(j),st,44)
   modis_file_info,dfile,dp,dt
   if prefix eq dp then begin    
     oUrl->SetProperty, URL_PATH = 'allData/51/'+mtype+'/'+strmid(prefix,0,4)+'/'+strmid(prefix,4,3)+'/'+ftpfile
     print,'Downloading File:  ',dfile
     fn = oUrl->Get(FILENAME = data_path+ftpfile)
   endif
  endfor
 endif


 ;Check for MOD06
 datatype = '06_L2'
 mtype = mtypes(i)+datatype
 a=file_search(data_link_path+mtype+'*'+prefix+'*',count=act)
 print,a
 if act eq 0 then begin  ;get data from modis website
  oUrl->SetProperty, URL_PATH = 'allData/51/'+mtype+'/'+strmid(prefix,0,4)+'/'+strmid(prefix,4,3)+'/'
  dirList = oUrl->GetFtpDirList()
  for j=0,n_elements(dirlist)-1 do begin
   st=strpos(dirlist(j),mtype+'.A')
   dfile = strmid(dirlist(j),st,22)+'.hdf'
   ftpfile = strmid(dirlist(j),st,44)
   modis_file_info,dfile,dp,dt
   if prefix eq dp then begin    
     oUrl->SetProperty, URL_PATH = 'allData/51/'+mtype+'/'+strmid(prefix,0,4)+'/'+strmid(prefix,4,3)+'/'+ftpfile
     print,'Downloading File:  ',dfile
     fn = oUrl->Get(FILENAME = data_path+ftpfile)
   endif
  endfor
 endif


endfor

stop

return
end
