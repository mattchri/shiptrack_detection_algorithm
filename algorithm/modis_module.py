#MODIS routines

import os
import sys
import datetime as datetime
import numpy as np
from pyhdf.SD import SD, SDC
import matplotlib.pyplot as plt
from shapely.geometry import Point, Polygon
from earth_geometry_module import *
import pdb
import idl_module

def read_mod02_single(filename):
    # Read MODIS data
    print('reading: ',filename)
    file = SD(filename, SDC.READ)
    sds_obj = file.select('EV_500_Aggr1km_RefSB')
    data = sds_obj.get()

    attr = sds_obj.attributes()
    scale = attr['reflectance_scales']
    offset = attr['reflectance_offsets']
    fill = attr['_FillValue']

    band_500 = (file.select('Band_500M')).get()
    id1 = ((np.where(band_500 == 6))[0])[0]
    id2 = ((np.where(band_500 == 7))[0])[0]
    
    #Channel 3 - 1.6 um reflectance
    #maskg = data[id1,:,:] != fill
    #maskb = data[id1,:,:] == fill
    #chnl3 = maskg * data[id1,:,:]*scale[id1] + maskb*(-999.)

    #Channel 4 - 2.1 um reflectance
    maskg = data[id2,:,:] != fill
    maskb = data[id2,:,:] == fill
    chnl4 = maskg * data[id2,:,:]*scale[id2] + maskb*(-999.)

    #Band 1km Emissive
    #file = SD(filename, SDC.READ)
    #sds_obj = file.select('EV_1KM_Emissive')
    #data = sds_obj.get()

    #attr = sds_obj.attributes()
    #scale = attr['radiance_scales']
    #offset = attr['radiance_offsets']
    #fill = attr['_FillValue']

    #band_1KM = (file.select('Band_1KM_Emissive')).get()
    #id1 = ((np.where(band_1KM == 20))[0])[0]
    #id2 = ((np.where(band_1KM == 31))[0])[0]

    #Channel 5
    #maskg = data[id1,:,:] != fill
    #maskb = data[id1,:,:] == fill
    #chnl5 = maskg * data[id1,:,:]*scale[id1] + maskb*(-999.)
    return chnl4

def read_mod03_single(filename):
    file = SD(filename, SDC.READ)
    sds_obj = file.select('Latitude')
    lat = sds_obj.get()
    sds_obj = file.select('Longitude')
    lon = sds_obj.get()
    my_dict = {'lat':lat, 'lon':lon}
    return my_dict


#+
#NAME:
#
#   Read Level 2 Modis (Basic Calibrated Radiances)
#
#PURPOSE:
#
#   This procedure is used to read a mod02 hdf file and return the radiances, and geographic info
#
#DESCRIPTION:
#
#   The returned array contains 1354 pixels along the x-axis and ~2030 pixels along the y-axis
#   each pixel returned has information about the radiance and latitude and longitude stored in the
#   third dimension of arad.
#
#INPUT: mod02 hdf file
#
#OUTPUT:  arad = ~(1354, 2030, 3)
#
#arad(*,*,0) = Latitude
#arad(*,*,1) = Longitude
#arad(*,*,2) = Solar Zenith Angle
#
#EXAMPLE:
#
#read_mod02,'/raid3/chrismat/modis/MYD021KM.A2007220.2255.hdf',arad
#
#AUTHOR:
#    Matt Christensen
###########################################################################
def read_mod03(filename):
    print('reading: ',filename)
    file = SD(filename, SDC.READ)
    sds_obj = file.select('Latitude')
    lat = sds_obj.get()
    sds_obj = file.select('Longitude')
    lon = sds_obj.get()
    sds_obj = file.select('SolarZenith')
    solz = sds_obj.get()
    
    res = np.shape(lat)
    arad = np.zeros( (res[0],res[1],3) )
    arad[:,:,0] = lat
    arad[:,:,1] = lon
    arad[:,:,2] = solz*.01
    
    astr=['lat','lon','solz']
    astr_long=['latitude','longitude','solar zenith angle']
    astr_units=['degrees','degrees','degrees']
    
    dict={"arad":arad,"astr":astr,"astr_long":astr_long,"astr_units":astr_units}
    return dict


#+
#NAME:
#
#   Read Level 2 Modis (Basic Calibrated Radiances)
#
#PURPOSE:
#
#   This procedure is used to read a mod02 hdf file and return the radiances, and geographic info
#
#DESCRIPTION:
#
#   The returned array contains 1354 pixels along the x-axis and ~2030 pixels along the y-axis
#   each pixel returned has information about the radiance and latitude and longitude stored in the
#   third dimension of arad.
#
#INPUT: mod02 hdf file
#
#OUTPUT:  arad = ~(1354, 2030, 8)
#
#arad(*,*,0) = 0.64(um) (band 1)
#arad(*,*,1) = 0.84(um) (band 2)
#arad(*,*,2) = 1.6 (um) (band 6)
#arad(*,*,4) = 3.7 (um) (band 20)
#arad(*,*,3) = 2.1 (um) (band 7)
#arad(*,*,5) = 11.0(um) (band 31)     also 12 (um) (band 32) not included in arad
#arad(*,*,6) = Latitude
#arad(*,*,7) = Longitude
#arad(*,*,8) = Solar Zenith Angle
#
#EXAMPLE:
#
#read_mod02,'/raid3/chrismat/modis/MYD021KM.A2007220.2255.hdf',arad
#
#AUTHOR:
#    Matt Christensen
############################################################################
def read_mod02(filename):
    # Read MODIS data
    print('reading: ',filename)
    file = SD(filename, SDC.READ)
    sds_obj = file.select('EV_250_Aggr1km_RefSB')
    data = sds_obj.get()
    attr = sds_obj.attributes()
    scale = attr['reflectance_scales']
    offset = attr['reflectance_offsets']
    fill = attr['_FillValue']
    band_250 = (file.select('Band_250M')).get()
    id1 = ((np.where(band_250 == 1))[0])[0]
    id2 = ((np.where(band_250 == 2))[0])[0]    
    maskg = data[id1,:,:] != fill
    maskb = data[id1,:,:] == fill
    chnl1 = maskg * data[id1,:,:]*scale[id1] + maskb*(-999.)
    maskg = data[id2,:,:] != fill
    maskb = data[id2,:,:] == fill
    chnl2 = maskg * data[id2,:,:]*scale[id2] + maskb*(-999.)
    
    #Channel 3 & 4 - 1.6 & 2.1 um reflectance
    sds_obj = file.select('EV_500_Aggr1km_RefSB')
    data = sds_obj.get()
    attr = sds_obj.attributes()
    scale = attr['reflectance_scales']
    offset = attr['reflectance_offsets']
    fill = attr['_FillValue']
    band_500 = (file.select('Band_500M')).get()
    id1 = ((np.where(band_500 == 6))[0])[0]
    id2 = ((np.where(band_500 == 7))[0])[0]    
    maskg = data[id1,:,:] != fill
    maskb = data[id1,:,:] == fill
    chnl3 = maskg * data[id1,:,:]*scale[id1] + maskb*(-999.)
    maskg = data[id2,:,:] != fill
    maskb = data[id2,:,:] == fill
    chnl4 = maskg * data[id2,:,:]*scale[id2] + maskb*(-999.)

    #Band 1km Emissive
    file = SD(filename, SDC.READ)
    sds_obj = file.select('EV_1KM_Emissive')
    data = sds_obj.get()

    attr = sds_obj.attributes()
    scale = attr['radiance_scales']
    offset = attr['radiance_offsets']
    fill = attr['_FillValue']

    band_1KM = (file.select('Band_1KM_Emissive')).get()
    id1 = ((np.where(band_1KM == 20))[0])[0]
    id2 = ((np.where(band_1KM == 31))[0])[0]

    #Channel 5
    maskg = data[id1,:,:] != fill
    maskb = data[id1,:,:] == fill
    chnl5 = maskg * data[id1,:,:]*scale[id1] + maskb*(-999.)
    
    #Channel 6
    maskg = data[id2,:,:] != fill
    maskb = data[id2,:,:] == fill
    chnl6 = maskg * data[id2,:,:]*scale[id2] + maskb*(-999.)
    
    res = np.shape(chnl1)
    arad = np.zeros( (res[0],res[1],6) )
    arad[:,:,0] = chnl1
    arad[:,:,1] = chnl2
    arad[:,:,2] = chnl3
    arad[:,:,3] = chnl4
    arad[:,:,4] = chnl5
    arad[:,:,5] = chnl6
    
    astr=['.64','.84','1.6','2.1','3.7','11']
    astr_long=['reflectance at 0.64 um','reflectance at 0.84 um','reflectance at 1.6 um','reflectance at 2.1 um','reflectance at 3.7 um','emission at 11 um']
    astr_units=['none', 'none', 'none', 'none', 'none','Watts/m^2/micrometer/steradian']
    
    dict={"arad":arad,"astr":astr,"astr_long":astr_long,"astr_units":astr_units}
    return dict
    

#+
#NAME:
#
#   Read Level 2 Modis 06 (Cloud Product)
#
#PURPOSE:
#
#   This procedure is used to read a mod04 and 06 hdf file and return AOT and Cloud property info
#
#DESCRIPTION:
#
#   The returned array contains 1354 pixels along the x-axis and ~2030 pixels along the y-axis
#   each pixel returned has information about the AOT, cloud optical depth and effective radius 
#
#INPUT: MOD06 hdf file
#
#OUTPUT:  arad = ~(1354, 2030, 10)
#
#arad(*,*,0) = Cloud_Optical_Thickness
#arad(*,*,1) = Cloud Effective Radius at 1.6um
#arad(*,*,2) = Cloud Effective Radius at 2.1um
#arad(*,*,3) = Cloud Effective Radius at 3.7um
#arad(*,*,4) = Cloud Water Path at 2.1 um
#arad(*,*,5) = Cloud_Fraction
#arad(*,*,6) = Cloud Top Pressure
#arad(*,*,7) = Cloud Top Temperature
#arad(*,*,8) = Cloud Phase Optical Properties 0=fill, 1=clear, 2=liquid water cloud, 3=ice cloud, 4=undetermined phase cloud
#arad(*,*,9) = Cloud_Multi_Layer_Flag
#arad(*,*,10) = Sunglint_flag
#arad(*,*,11) = Brightness temperature 11 um
#
#astr(0) = 'ctau'  cloud optical thickness
#astr(1) = 're1.6' cloud effective radius at 1.6 um
#astr(2) = 're2.1' cloud effective radius at 2.1 um
#astr(3) = 're3.7' cloud effective radius at 3.7 um
#astr(4) = 'lwp'   cloud water path at 2.1 um
#astr(5) = 'fcc'   cloud cover fraction  
#astr(6) = 'ctp'   cloud top pressure    [hpa]
#astr(7) = 'ctt'   cloud top temperature [K]
#astr(8) = 'phase' cloud phase optical properties
#astr(9) = 'layer' cloud multi layer flag =1 single layer
#astr(10) = 'sgl'  Sunglint flag
#astr(11) = 'Tb11' Brightness temperature at 11 um
#
#AUTHOR:
#    Matt Christensen
#    Colorado State University
###########################################################################
def read_mod06_c6(filename):
    print('reading: ',filename)
    file = SD(filename, SDC.READ)
    sds_obj = file.select('Cloud_Effective_Radius')
    data = sds_obj.get()
    d1 = (np.shape(data))[1]
    d2 = (np.shape(data))[0]
    vname=['Cloud_Optical_Thickness_16',
           'Cloud_Optical_Thickness',
           'Cloud_Optical_Thickness_37',
           'Cloud_Effective_Radius_16',
           'Cloud_Effective_Radius',
           'Cloud_Effective_Radius_37',
           'Cloud_Water_Path_16',
           'Cloud_Water_Path',
           'Cloud_Water_Path_37',
           'Cloud_Fraction',
           'cloud_top_pressure_1km',
           'cloud_top_temperature_1km',
           'Cloud_Phase_Optical_Properties',
           'Cloud_Phase_Infrared_1km',
           'Cloud_Multi_Layer_Flag',
           'Brightness_Temperature']

    pclVar = [1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0]
    
    astr=['ctau1.6','ctau','ctau3.7',
          're1.6','re2.1','re3.7',
          'lwp1.6','lwp','lwp3.7',
          'fcc','ctp','ctt','phase','phase_ir','layer','Tb11']

    d3 = len(astr)
    arad = np.zeros( (d2,d1,d3) )
    for i in range(len(vname)):
        #print('reading: '+vname[i])
        if pclVar[i] == 1:
            sds_obj = file.select(vname[i])
            data = sds_obj.get()
            attr = sds_obj.attributes()
            scale = attr['scale_factor']
            offset = attr['add_offset']
            fill = attr['_FillValue']           
            sds_obj = file.select(vname[i]+'_PCL')
            pcl = sds_obj.get()
            attr_pcl = sds_obj.attributes()
            arr = ((data > 0) & (pcl < 0))*((data-offset)*scale) + ((data < 0) & (pcl > 0))*((pcl-offset)*scale) + ((data < 0) & (pcl < 0))*fill

        if pclVar[i] == 0:
            sds_obj = file.select(vname[i])
            data = sds_obj.get()
            attr = sds_obj.attributes()
            scale = attr['scale_factor']
            offset = attr['add_offset']
            fill = attr['_FillValue']
            if vname[i] != 'Brightness_Temperature':
                arr = (data != fill)*((data-offset)*scale) + (data == fill)*(fill)
            else:
                arr = (data[1,:,:] != fill)*((data[1,:,:]-offset)*scale) + (data[1,:,:] == fill)*(fill)
                
        sz = np.shape(arr)
        #print(sz)
        if (sz[1] == d1 and sz[0] == d2):
            arad[:,:,i] = arr
        else:
            narr = idl_module.rebin(arr, (d2,d1) )
            arad[:,:,i] = narr
        
        #MODIS Byte Flags - note the clm_bitextractor program has not yet been converted to Python
    astr_long = vname
    astr_units = ['1','1','1','um','um','um','g/m^2','g/m^2','g/m^2','1','hPa','K','1','1','1','K']
    
    dict={"arad":arad,"astr":astr,"astr_long":astr_long,"astr_units":astr_units}
    return dict


#Inputs
#satellite: "TERRA" OR "AQUA"
#year, month, day (day in month)
#lonb0: longitude coordinate of eastbound side of domain
#latb0: latitude coordinate of southbound side of domain
#lonb1: longitude coordinate of westbound side of domain
#latb1: latitude coordinate of eastbound side of domain
#note, if lonb0 = lonb1 then point source location is used
def get_modis_matched_granules(satellite, year, month, day, lonb0, latb0, lonb1, latb1, dnflag = 'D'):
    if (satellite == 'TERRA'): sat_prefix = 'MOD03'
    if (satellite == 'AQUA'): sat_prefix = 'MYD03'
    
    doy = (datetime.datetime(year,month,day,0,0)-datetime.datetime(year,1,1,0,0)).days + 1
    YYYY = str(year).zfill(4)
    DOY  = str(doy).zfill(3)
    MM   = str(month).zfill(2)
    DD   = str(day).zfill(2)
    
    geoMetaPath = '/gws/nopw/j04/eo_shared_data_vol1/satellite/modis/modis_c61/geoMeta/'+satellite+'/'+YYYY+'/'
    geoMetaFile = geoMetaPath + sat_prefix+'_'+YYYY+'-'+MM+'-'+DD+'.txt'
        
    print('PROCESSING: ',YYYY+'_'+DOY)
    
    # Read GEOMETA Data
    #STRvar=['GranuleID','StartDateTime','ArchiveSet','OrbitNumber','DayNightFlag','EastBoundingCoord','NorthBoundingCoord','SouthBoundingCoord','WestBoundingCoord','GRingLongitude1','GRingLongitude2','GRingLongitude3','GRingLongitude4','GRingLatitude1','GRingLatitude2','GRingLatitude3','GRingLatitude4']
    
    f=open(geoMetaFile, "r")
    lines = f.readlines()
    f.close()
    
    modisFiles = []
    dnFlag = []
    GRingLongitude1 = []
    GRingLongitude2 = []
    GRingLongitude3 = []
    GRingLongitude4 = []
    GRingLatitude1 = []
    GRingLatitude2 = []
    GRingLatitude3 = []
    GRingLatitude4 = []
    for i in range(3,len(lines)):
        txt = (lines[i]).split(',')
        modisFiles.append(txt[0])
        dnFlag.append(txt[4])
        GRingLongitude1.append(float(txt[9]))
        GRingLongitude2.append(float(txt[10]))
        GRingLongitude3.append(float(txt[11]))
        GRingLongitude4.append(float(txt[12]))
        GRingLatitude1.append(float(txt[13]))
        GRingLatitude2.append(float(txt[14]))
        GRingLatitude3.append(float(txt[15]))
        GRingLatitude4.append(float(txt[16]))
    
    GRingLongitude1 = np.asarray(GRingLongitude1)
    GRingLongitude2 = np.asarray(GRingLongitude2)
    GRingLongitude3 = np.asarray(GRingLongitude3)
    GRingLongitude4 = np.asarray(GRingLongitude4)
    GRingLatitude1 = np.asarray(GRingLatitude1)
    GRingLatitude2 = np.asarray(GRingLatitude2)
    GRingLatitude3 = np.asarray(GRingLatitude3)
    GRingLatitude4 = np.asarray(GRingLatitude4)
    
    # Loop over each grannule in the day
    matchedFiles = []
    matchedFiles_dn = []
    matchedDists = []
    mct=0
    for k in range(len(GRingLongitude1)):
        lon0 = GRingLongitude1[k]
        lon1 = GRingLongitude2[k]
        lon2 = GRingLongitude3[k]
        lon3 = GRingLongitude4[k]
        lat0 = GRingLatitude1[k]
        lat1 = GRingLatitude2[k]
        lat2 = GRingLatitude3[k]
        lat3 = GRingLatitude4[k]
        # compute distances to centre
        sdist1 = gc_distance(lat0, lon0, latb0, lonb0)
        sdist2 = gc_distance(lat1, lon1, latb0, lonb0)
        sdist3 = gc_distance(lat2, lon2, latb0, lonb0)
        sdist4 = gc_distance(lat3, lon3, latb0, lonb0)
        sdist5 = gc_distance(lat0, lon0, latb1, lonb1)
        sdist6 = gc_distance(lat1, lon1, latb1, lonb1)
        sdist7 = gc_distance(lat2, lon2, latb1, lonb1)
        sdist8 = gc_distance(lat3, lon3, latb1, lonb1)
        sdistMEAN = np.mean([sdist1,sdist2,sdist3,sdist4,sdist5,sdist6,sdist7,sdist8])
        sdistMIN  = np.min([sdist1,sdist2,sdist3,sdist4,sdist5,sdist6,sdist7,sdist8])
        sdistMAX  = np.max([sdist1,sdist2,sdist3,sdist4,sdist5,sdist6,sdist7,sdist8])
        if (sdistMIN < 2000.):
            xPTS = np.asarray([lon0,lon1,lon2,lon3])
            yPTS = np.asarray([lat0,lat1,lat2,lat3])
            # Check for international dateline
            if (np.min(np.abs(xPTS)) > 100.) and (np.min(xPTS)/np.max(xPTS) < 0.): #international dateline
                tmp_xPTS = (xPTS < 0.)*(360.+xPTS) + (xPTS > 0.)*(xPTS)
                tmp_yPTS = yPTS
                tmp_lonb0 = (lonb0 < 0.)*(360.+lonb0) + (lonb0 > 0.)*(lonb0)
                tmp_latb0 = latb0
                tmp_lonb1 = (lonb1 < 0.)*(360.+lonb1) + (lonb1 > 0.)*(lonb1)
                tmp_latb1 = latb1
                #plt.scatter(tmp_xPTS,tmp_yPTS)
                #plt.scatter([tmp_lonb0],[tmp_latb0],c='red')
                #plt.show()
                #input("Press Enter to continue...")

            else:
                tmp_xPTS = xPTS
                tmp_yPTS = yPTS
                tmp_lonb0 = lonb0
                tmp_latb0 = latb0
                tmp_lonb1 = lonb1
                tmp_latb1 = latb1
                
            # Single point at centre of box
            p1 = Point(tmp_lonb0,tmp_latb0)
            p2 = Point(tmp_lonb0,tmp_latb1)
            p3 = Point(tmp_lonb1,tmp_latb0)
            p4 = Point(tmp_lonb1,tmp_latb1)
            coords = [(tmp_xPTS[0],tmp_yPTS[0]), (tmp_xPTS[1],tmp_yPTS[1]), (tmp_xPTS[2],tmp_yPTS[2]), (tmp_xPTS[3],tmp_yPTS[3])]
            poly = Polygon(coords)
            
            #print(( (p1.within(poly) == True) or (p2.within(poly) == True) or (p3.within(poly) == True) or (p4.within(poly) == True)))
            #print(dnFlag[k])
            #plt.scatter(tmp_xPTS,tmp_yPTS)
            #plt.scatter([tmp_lonb0],[tmp_latb0],c='red')
            #plt.show()
            #input("Press Enter to continue...")
                        
            
            if ( (p1.within(poly) == True) or (p2.within(poly) == True) or (p3.within(poly) == True) or (p4.within(poly) == True)):
                print(k,sdistMEAN,sdistMIN,sdistMAX,modisFiles[k])
                matchedFiles.append(modisFiles[k])
                matchedFiles_dn.append(dnFlag[k])
                matchedDists.append(sdistMIN)
                mct=mct+1
                #plt.scatter([lon0,lon1,lon2,lon3],[lat0,lat1,lat2,lat3])
                #plt.scatter([lonPt],[latPt],c='red')
                #plt.show()
                #input("Press Enter to continue...")

    if (dnflag == 'D'):
        newFiles = []
        newFilesDN = []
        newFilesDist = []
        for i in range(len(matchedFiles)):
            if (matchedFiles_dn[i] == 'D'):
                newFiles.append(matchedFiles[i])
                newFilesDN.append(matchedFiles_dn[i])
                newFilesDist.append(matchedDists[i])
        matchedFiles = newFiles
        matchedFiles_dn = newFilesDN
        matchedDists = newFilesDist
                
    OUTDATA = {"files":matchedFiles, "daynight_flag":matchedFiles_dn, "distance":matchedDists}
    return OUTDATA

# MODIS file info
def modis_file_info(files):
    f = files
    year = []
    yday = []
    month= []
    mday = []
    hour = []
    minute = []
    jday   = []
    prefix = []
    mtype  = []
    for i in range(len(f)):
        basename = os.path.basename(f[i])
        prefix.append( (basename)[6:19] )
        mtype.append( (basename)[0:3] )
        yyyy   = int( (basename)[7:11] )
        ddd    = int( (basename)[11:14] )
        hr     = int( (basename)[15:17] )
        mn     = int( (basename)[17:19] )
        calday = datetime.datetime(yyyy,1,1,hr,mn)+datetime.timedelta(days=(ddd-1))
        mo     = calday.month
        dy     = calday.day
        year.append(yyyy)
        yday.append(ddd)
        month.append(mo)
        mday.append(dy)
        hour.append(hr)
        minute.append(mn)
        jday.append(calday)
    
    OUTDATA = {"prefix":prefix, "mtype":mtype, "year":year, "yday":yday, "month":month, "mday":mday, "hour":hour, "minute":minute, "jday":jday}
    return OUTDATA



# Download MODIS images
def download_modis_files(files,dnFlag,root_path,authkey):
    f=open(authkey, "r")
    keyName = (f.read()).strip('\n')
    f.close()
    modisVersion = '61'
    modispath=root_path
    f = files
    n = len(f)
    mInfo = modis_file_info(f)
    prods = ['021KM','03','04_L2','06_L2']
    for i in range(n):
        prefix = (mInfo['prefix'])[i]
        mtype = (mInfo['mtype'])[i]
        yyyy = str( (mInfo['year'])[i] ).zfill(4)
        ddd = str( (mInfo['yday'])[i] ).zfill(3)
        mm = str( (mInfo['month'])[i] ).zfill(2)
        dd = str( (mInfo['mday'])[i] ).zfill(2)
        hr= str( (mInfo['hour'])[i] ).zfill(2)
        mn = str( (mInfo['minute'])[i] ).zfill(2)
        for k in range(len(prods)):
            prd = mtype+prods[k]
            pathToSave = modispath+prd.lower()+'/'+yyyy+'/'+ddd+'/'
            os.system('mkdir -p '+pathToSave)
            # Check to see if file has already been downloaded
            flag=1
            file = ''
            listing = os.listdir(pathToSave)
            for j in range(len(listing)):
                txt = listing[j]
                if ((txt.find(prd+'.'+prefix)) > -1):
                    file = pathToSave + txt

            #Skip downloading aerosol data at night
            if (dnFlag[i] == 'N' and prods[k] == '04_L2'):
                file = 'skip'
            
            if (file == ''):
                print('DOWNLOADING: '+prd+prefix)
                filePrefixSTR = prd+'.A'+yyyy+ddd+'.'+hr+mn+'.061.'+'*.hdf'
                TSTR='wget -e robots=off -m -np -nd --accept='+filePrefixSTR+' -R .html,.tmp -nH --directory-prefix='+pathToSave+' https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/'+modisVersion+'/'+prd+'/'+yyyy+'/'+ddd+'/'+' --header "Authorization: Bearer '+keyName+'"'
                os.system(TSTR)
    OUTDATA = -9
    return OUTDATA

    
#modis_prefix: MYD03 or MOD03 format
def fetch_modis_files_from_prefix(files,root_path):
    #Determine which file system is being used
    fsys = ''
    if (root_path.find('neodc') > -1): fsys = 'neodc'
    if (root_path.find('eo_shared_data') > -1): fsys = 'eo_shared_data'
    print('modis files on system: '+fsys)
    f = files
    n = len(f)
    mInfo = modis_file_info(f)
    F02 = []
    F03 = []
    F04 = []
    F06 = []
    for i in range(n):
        print(i)
        prefix = (mInfo['prefix'])[i]
        mtype = (mInfo['mtype'])[i]
        yyyy = str( (mInfo['year'])[i] ).zfill(4)
        ddd = str( (mInfo['yday'])[i] ).zfill(3)
        mm = str( (mInfo['month'])[i] ).zfill(2)
        dd = str( (mInfo['mday'])[i] ).zfill(2)
        # MOD02
        if (fsys == 'neodc'): path = root_path + mtype+'021KM'+'/'+'collection61'+'/'+yyyy+'/'+mm+'/'+dd+'/'
        if (fsys == 'eo_shared_data'): path = root_path+(mtype+'021KM').lower()+'/'+yyyy+'/'+ddd+'/'
        listing = os.listdir(path)
        F02_file = ''
        if (os.path.isdir(path) == True):
            for j in range(len(listing)):
                txt = listing[j]
                if ((txt.find(mtype+'021KM.'+prefix)) > -1):
                    F02_file = path+txt
        if (F02_file == ''):
            print('warning: '+path+' does not exist')
        F02.append(F02_file)

        # MOD03
        if (fsys == 'neodc'): path = root_path + mtype+'03'+'/'+'collection61'+'/'+yyyy+'/'+mm+'/'+dd+'/'
        if (fsys == 'eo_shared_data'): path = root_path+(mtype+'03').lower()+'/'+yyyy+'/'+ddd+'/'
        listing = os.listdir(path)
        F03_file = ''
        if (os.path.isdir(path) == True):
            for j in range(len(listing)):
                txt = listing[j]
                if ((txt.find(mtype+'03.'+prefix)) > -1):
                    F03_file = path+txt
        if (F03_file == ''):
            print('warning: '+path+' does not exist')
        F03.append(F03_file)

        # MOD04
        if (fsys == 'neodc'): path = root_path + mtype+'04_L2'+'/'+'collection61'+'/'+yyyy+'/'+mm+'/'+dd+'/'
        if (fsys == 'eo_shared_data'): path = root_path+(mtype+'04_L2').lower()+'/'+yyyy+'/'+ddd+'/'
        listing = os.listdir(path)
        F04_file = ''
        if (os.path.isdir(path) == True):
            for j in range(len(listing)):
                txt = listing[j]
                if ((txt.find(mtype+'04_L2.'+prefix)) > -1):
                    F04_file = path+txt
        if (F04_file == ''):
            print('warning: '+path+' does not exist')
        F04.append(F04_file)

        # MOD06
        if (fsys == 'neodc'): path = root_path + mtype+'06_L2'+'/'+'collection61'+'/'+yyyy+'/'+mm+'/'+dd+'/'
        if (fsys == 'eo_shared_data'): path = root_path+(mtype+'06_L2').lower()+'/'+yyyy+'/'+ddd+'/'
        listing = os.listdir(path)
        F06_file = ''
        if (os.path.isdir(path) == True):          
            for j in range(len(listing)):
                txt = listing[j]
                if ((txt.find(mtype+'06_L2.'+prefix)) > -1):
                    F06_file = path+txt
        if (F06_file == ''):
            print('warning: '+path+' does not exist')
        F06.append(F06_file)

    OUTDATA = {"F02":F02,"F03":F03,"F04":F04,"F06":F06}
    return OUTDATA

#from modis_module import *
#download_modis_geometa('/gws/nopw/j04/eo_shared_data_vol1/satellite/modis/modis_c6/authkey','/gws/nopw/j04/eo_shared_data_vol1/satellite/modis/modis_c61/')
def download_modis_geometa(authkey,datapath):
    os.system('mkdir -p '+datapath+'geoMeta/')
    f=open(authkey, "r")
    keyName = (f.read()).strip('\n')
    f.close()
    #TSTR='wget -e robots=off -m -np -nd --accept='+filePrefixSTR+' -R .html,.tmp -nH --directory-prefix='+pathToSave+' https://ladsweb.modaps.eosdis.nasa.gov/archive/allData/'+modisVersion+'/'+prd+'/'+yyyy+'/'+ddd+'/'+' --header "Authorization: Bearer '+keyName+'"'

    SAT = 'AQUA'
    years = [2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019]
    os.system('mkdir -p '+datapath+'geoMeta/'+SAT+'/')
    for i in range(len(years)):
        yrstr = str(years[i]).zfill(4)
        tstr = 'mkdir -p '+datapath+'geoMeta/'+SAT+'/'+yrstr+'/'
        os.system(tstr)
        tstr ='wget -e robots=off -m -np -nd --accept=.txt -R .html,.tmp -nH --directory-prefix='+datapath+'geoMeta/'+SAT+'/'+yrstr+'/'+' '+'"'+'https://ladsweb.modaps.eosdis.nasa.gov/archive/geoMeta/61/'+SAT+'/'+yrstr+'/'+'"'+' --header '+'"'+'Authorization: Bearer '+keyName+'"'
        os.system(tstr)

    SAT = 'TERRA'
    years = [2000,20001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019]
    os.system('mkdir -p '+datapath+'geoMeta/'+SAT+'/')
    for i in range(len(years)):
        yrstr = str(years[i]).zfill(4)
        tstr = 'mkdir -p '+datapath+'geoMeta/'+SAT+'/'+yrstr+'/'
        os.system(tstr)
        tstr ='wget -e robots=off -m -np -nd --accept=.txt -R .html,.tmp -nH --directory-prefix='+datapath+'geoMeta/'+SAT+'/'+yrstr+'/'+' '+'"'+'https://ladsweb.modaps.eosdis.nasa.gov/archive/geoMeta/61/'+SAT+'/'+yrstr+'/'+'"'+' --header '+'"'+'Authorization: Bearer '+keyName+'"'
        os.system(tstr)    