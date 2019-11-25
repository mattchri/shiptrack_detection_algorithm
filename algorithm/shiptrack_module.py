#Ship Track Routines

import os
import numpy as np
import pdb
import matplotlib.pyplot as plt
from stats_module import *
import datetime
from netCDF4 import Dataset
from modis_module import *

#Function to extract track positions from ascii file
def read_osu_shiptrack_file(tfilename):
    f = open(tfilename,'r')
    lines = f.readlines()
    f.close()
    #Number of ship tracks in granule
    tnum = int((lines[1].split())[0])
    all_xvals = []
    all_yvals = []
    all_pts   = []
    ival = 0
    for i in range(tnum):
        ival = ival+2
        pts = int(lines[ival].split()[0]) #track bends
        geo = np.array(lines[ival+1].split())
        xvals = geo[ np.arange(0,pts*2,2) ]
        yvals = geo[ np.arange(1,pts*2,2) ]
        all_xvals.append(xvals)
        all_yvals.append(yvals)
        all_pts.append(pts)
    track_points = { 'ntracks':tnum, 'pts':all_pts, 'xpt':all_xvals, 'ypt':all_yvals, 'names':['ntracks: number of ship tracks','pts: number of bends in ship track','xpt: x-position of nth bend in ship track','ypt: y-position of nth bend in ship track'] }
    return track_points

#Function to create track position ascii file
def write_track_locations_ascii_file(txtName,day,hr,minute,seconds,TNUM,tPTS,xPTS,yPTS):
    print('writing track locations to file: ',txtName)
    TYPE='x-y'
   
    if ( (os.path.basename(txtName))[0] == 't'):
        TYPE='x-y'
    if ( (os.path.basename(txtName))[0] == 'l'):
        TYPE='l-l'

    f = open(txtName, 'w')
    f.write("{:5d}".format(day)+"{:5d}".format(hr)+"{:5d}".format(minute)+"{:7.1f}".format(seconds)+"    day    hr    min    second starttime of pass\n")
    f.write("{:5d}".format(TNUM)+" number of tracks\n")
    for j in range(TNUM):
        nPTS = tPTS[j]
        nX   = xPTS[j,0:nPTS]
        nY   = yPTS[j,0:nPTS]
        
        f.write("{:5d}".format(nPTS)+"\n")
        arrFt = np.zeros(nPTS*2)
        arrIn = np.zeros(nPTS*2, dtype=int)
        arrct=0
        for k in range(nPTS):
            arrFt[arrct] = nX[k]
            arrIn[arrct] = int(nX[k])
            arrct = arrct + 1
            arrFt[arrct] = nY[k]
            arrIn[arrct] = int(nY[k])
            arrct = arrct + 1
                
        if (TYPE == 'x-y'):
            tmp = (np.array2string(arrIn,max_line_width=5000,separator='     '))
            tmp = '     '+tmp[1:len(tmp)-1]
            f.write(tmp+"\n")
        if (TYPE == 'l-l'):
            tmp = (np.array2string(arrFt,max_line_width=5000,separator='     '))
            tmp = '     '+tmp[1:len(tmp)-1]
            f.write(tmp+"\n")
            
    f.write("\n")
    f.write(",,,,|,,,,1,,,,|,,,,2,,,,|,,,,3,,,,|,,,,4,,,,|,,,,5,,,,|,,,,6,,,,|,,,,7,,,,|,,,,8,,,,|,,,,9,,,,|,,,,0,,,,|,,,,1,,,,|,,,, ")
    f.close()
    err=0
    return err


def auto_expand_track_positions(xDev,yDev):
    trk_pos_ct = len(xDev)
    
    #Correct errors in hand-logged tracks sometimes the slopes are too large or they fall to close to an edge
    for im in range(11):
        flag=0
        for jjj in range(trk_pos_ct-1):
            x0=xDev[jjj]
            y0=yDev[jjj]
            x1=xDev[jjj+1]
            y1=yDev[jjj+1]
            m=(y1-y0)/(x1-x0)
            if (abs(x0-x1) == 0):
                flag=1
                xDev[jjj] = x0+2.
            if (abs(x0-x1) == 1):
                flag=1
                xDev[jjj] = x0+1.
            if (abs(y0-y1) == 0):
                flag=1
                yDev[jjj] = y0+2.
            if (abs(y0-y1) == 1):
                flag=1
                yDev[jjj] = y0+1.
        if (flag == 0):
            break
    
    all_x = np.zeros(50000)
    all_y = np.zeros(50000)
    all_m = np.zeros(50000) #all slopes
    all_ct = 0
    #Loop over hand-logged segments
    for jjj in range(trk_pos_ct-1):
        x0=xDev[jjj]
        y0=yDev[jjj]
        x1=xDev[jjj+1]
        y1=yDev[jjj+1]   
        
        #Conjoining Lines
        m=(y1-y0)/(x1-x0)
        b=y0-m*x0
        
        #Define array with number of new ship track points
        nnpts = 5000.
        overshoot = 1.5 #(fraction to overshoot)
        npts = nnpts*overshoot
        delp = (x1-x0)/nnpts
        offset = (x1-x0)*.25
        xarr=np.arange(0,npts,1)*delp+x0-offset
        
        #Direction
        if (x1-x0 > 0.):
            direct = 1.
        if (x1-x0 < 0.):
            direct = -1.
        if (x1-x0 == 0.):
            print('PROBLEM WITH COORDINATES')
            direct=1.
            x1=x1+delp*2.

        npts = len(xarr)
        xf=x0
        yf=y0
        dx=0.1 #step in x direction
        all_c = np.zeros(npts)
        for ii in range(npts):
            xi = xf
            yi = yf
            xf = xf + direct*dx
            yf = m*xf + b
            
            all_c[ii] = np.sqrt( (xi-x1)*(xi-x1) + (yi-y1)*(yi-y1))
            if (ii > 0. and all_c[ii] >= all_c[ii-1]):
                break
            
            all_x[all_ct] = xf
            all_y[all_ct] = yf
            all_m[all_ct] = m
            all_ct = all_ct + 1
            
    all_x = all_x[0:all_ct]
    all_y = all_y[0:all_ct]
    TPTS = {"xtrack":all_x, "ytrack":all_y}
    return TPTS

def auto_construct_segment(yoff,along_length,perp_length,all_x,all_y):
    segment_scl = 3. #scale in which larger segment domain can be
    
    #Construct output arrays based on segment counter
    seg_parl_npix = np.zeros(100)        #along track pixels
    seg_perp_npix = np.zeros(100)        #perpendicular track pixels
    seg_dist  = np.zeros(100)        #distance of segment
    seg_re_x_all = np.zeros( (100,100,500) ) #{segment#,along#,perp#)
    seg_re_y_all = np.zeros( (100,100,500) )
    seg_dist_all = np.zeros( (100,100,500) )
    # of re-constructed track locations
    all_ct = len(all_x)
    #Array for along track pixels 
    along_x = np.zeros(5000)
    along_y = np.zeros(5000)
    #Array for cross track pixels
    #positive-x
    xp0=np.zeros((5000,5000))  #{along,cross}
    yp0=np.zeros((5000,5000))
    #negative-x
    xp1=np.zeros((5000,5000))
    yp1=np.zeros((5000,5000))    
    along_ct = 0       ;# pixels are used in current segment
    tdistc = 0.
    along_ct_all = 0.  ;# pixels along ship track
    segment_count = 0
    for jjj in range(all_ct-2):
        x0=all_x[jjj]
        y0=all_y[jjj]
        x1=all_x[jjj+1]
        y1=all_y[jjj+1]
        #print(x0,x1,y0,y1,tdistc,segment_count,along_ct)
        
        #Distance between data points
        tdistc = tdistc + np.sqrt( ((x1-x0)*(x1-x0)) + ((y1-y0)*(y1-y0)) )
        
        #Perpendicular Line at x0,y0
        mp=(x1-x0)/(y0-y1)
        bp=y0-mp*x0
        
        mp2=(all_x[jjj+1]-all_x[jjj+2])/(all_y[jjj+2]-all_y[jjj+1]) #slope of next along-track pixel
        
        #Slope can be wildly different between successive points due to hand-logged track
        #remove cases (very few) where the slopes differ by more than 5%
        if ( abs( (mp2-mp)/mp )*100. < 5. ):
            
            #Get perpendicular pixels
            dx=.1
            nnnpts = 5000
            #Positive x
            xfp=x0
            yfp=y0
            all_cp = 0.
            all_xp0 = np.zeros(nnnpts)
            all_yp0 = np.zeros(nnnpts)
            all_ct0 = 0
            #Loop over x-fine points to get y-values
            for jj in range(nnnpts):
                xip = xfp
                yip = yfp
                xfp = xfp + dx
                bp=yip-mp*xip
                yfp = mp*xfp + bp
                c = np.sqrt( ((xfp-xip)*(xfp-xip)) + ((yfp-yip)*(yfp-yip)) )
                all_cp = all_cp + c
                #Break out of loop if prependicular segment is greater than perp_length
                if (all_cp > perp_length*segment_scl):
                    break
                all_xp0[all_ct0] = xfp
                all_yp0[all_ct0] = yfp
                all_ct0=all_ct0+1
            all_xp0=all_xp0[0:all_ct0]
            all_yp0=all_yp0[0:all_ct0]
            
            #Get perpendicular pixels
            #negative x
            xfp=x0
            yfp=y0
            all_cp = 0.
            all_xp1 = np.zeros(nnnpts)
            all_yp1 = np.zeros(nnnpts)
            all_ct1 = 0
            for jj in range(nnnpts):
                xip = xfp
                yip = yfp
                xfp = xfp - dx
                bp=yip-mp*xip
                yfp = mp*xfp + bp
                c = np.sqrt( ((xfp-xip)*(xfp-xip)) + ((yfp-yip)*(yfp-yip)) )
                all_cp = all_cp + c
                if (all_cp > perp_length*segment_scl):
                    break
                all_xp1[all_ct1] = xfp
                all_yp1[all_ct1] = yfp
                all_ct1=all_ct1+1
            all_xp1=all_xp1[0:all_ct1]
            all_yp1=all_yp1[0:all_ct1]
            
            #Along track pixel
            along_x[along_ct] = all_x[jjj]
            along_y[along_ct] = all_y[jjj]

            #Perpendicular pixels (positive)
            xp0[along_ct,0:all_ct0] = all_xp0
            yp0[along_ct,0:all_ct0] = all_yp0
            
            #Perpendicular pixels (negative)
            xp1[along_ct,0:all_ct1] = all_xp1
            yp1[along_ct,0:all_ct1] = all_yp1
            
            #Length of segment reached or its the last possible segment
            if (tdistc > along_length or jjj == all_ct-1):
                #resample along track index (because there are numerous repeated values)
                re_x = np.zeros(along_ct*100)
                re_y = np.zeros(along_ct*100)
                
                #resample perpendicular index
                perp_ct  = int(perp_length*(segment_scl+.2))    #due to pixel oversampling
                re_x0    = np.zeros((along_ct*100,perp_ct))
                re_y0    = np.zeros((along_ct*100,perp_ct))
                re_x1    = np.zeros((along_ct*100,perp_ct))
                re_y1    = np.zeros((along_ct*100,perp_ct))
                re_dist0 = np.zeros((along_ct*100,perp_ct))
                re_dist1 = np.zeros((along_ct*100,perp_ct))
                
                #Initialize first data point so that resampling strategy can work
                #Along Track
                re_ct=0
                re_x[0] = int(along_x[0])
                re_y[0] = int(along_y[0])
                
                #Cross-Track positive x
                kkk=0        
                tct=0
                for ik in range(all_ct0-1):
                    if (tct < perp_ct):
                        ikdist1 = np.sqrt( (int(xp0[kkk,ik])-int(along_x[kkk]))*((int(xp0[kkk,ik])-int(along_x[kkk]))) + (int(yp0[kkk,ik])-int(along_y[kkk]) )*(int(yp0[kkk,ik])-int(along_y[kkk]) ) )
                        ikdist2 = np.sqrt( (int(xp0[kkk,ik+1])-int(along_x[kkk]))*((int(xp0[kkk,ik+1])-int(along_x[kkk]))) + (int(yp0[kkk,ik+1])-int(along_y[kkk]) )*(int(yp0[kkk,ik+1])-int(along_y[kkk]) ) )
                        if (ikdist1 != ikdist2):
                            re_x0[re_ct,tct] = xp0[kkk,ik]
                            re_y0[re_ct,tct] = yp0[kkk,ik]
                            re_dist0[re_ct,tct] = ikdist1
                            tct=tct+1
                
                #Cross-track negative x
                kkk=0
                tct=0
                for ik in range(all_ct1-1):
                    #print(ik,tct,perp_ct)
                    if (tct < perp_ct):
                        ikdist1 = np.sqrt( (int(xp1[kkk,ik])-int(along_x[kkk]))*((int(xp1[kkk,ik])-int(along_x[kkk]))) + (int(yp1[kkk,ik])-int(along_y[kkk]) )*(int(yp1[kkk,ik])-int(along_y[kkk]) ) )
                        ikdist2 = np.sqrt( (int(xp1[kkk,ik+1])-int(along_x[kkk]))*((int(xp1[kkk,ik+1])-int(along_x[kkk]))) + (int(yp1[kkk,ik+1])-int(along_y[kkk]) )*(int(yp1[kkk,ik+1])-int(along_y[kkk]) ) )
                        if (ikdist1 != ikdist2):
                            re_x1[re_ct,tct] = xp1[kkk,ik]
                            re_y1[re_ct,tct] = yp1[kkk,ik]
                            re_dist1[re_ct,tct] = ikdist1
                            tct=tct+1
                
                re_ct=1 #set counter 1 since you intiialized the first value
                #Loop over along track pixels
                for kkk in range(len(along_x)-1):
                    #Enter if either x or y along-track pixel changed
                    if ( (int(along_x[kkk+1])-int(along_x[kkk])) != 0 or (int(along_y[kkk+1])-int(along_y[kkk])) != 0):
                        re_x[re_ct]=along_x[kkk+1]
                        re_y[re_ct]=along_y[kkk+1] 
                        
                        #Discretize perpendicular parts
                        #positive x
                        tct=0
                        for ik in range(all_ct0-1):
                            if (tct < perp_ct):
                                ikdist1 = np.sqrt( (int(xp0[kkk,ik])-int(along_x[kkk]) )*(int(xp0[kkk,ik])-int(along_x[kkk]) ) + (int(yp0[kkk,ik])-int(along_y[kkk]) )*(int(yp0[kkk,ik])-int(along_y[kkk]) ) )
                                ikdist2 = np.sqrt( (int(xp0[kkk,ik+1])-int(along_x[kkk]) )*(int(xp0[kkk,ik+1])-int(along_x[kkk]) ) + (int(yp0[kkk,ik+1])-int(along_y[kkk]) )*(int(yp0[kkk,ik+1])-int(along_y[kkk]) ) )
                                if (ikdist1 != ikdist2):
                                    re_x0[re_ct,tct] = xp0[kkk,ik]
                                    re_y0[re_ct,tct] = yp0[kkk,ik]
                                    re_dist0[re_ct,tct] = ikdist1
                                    tct=tct+1
                        
                        #negative x
                        tct=0
                        for ik in range(all_ct1-1):
                            if (tct < perp_ct):
                                ikdist1 = np.sqrt( (int(xp1[kkk,ik])-int(along_x[kkk]) )*(int(xp1[kkk,ik])-int(along_x[kkk]) ) + (int(yp1[kkk,ik])-int(along_y[kkk]) )*(int(yp1[kkk,ik])-int(along_y[kkk]) ) )
                                ikdist2 = np.sqrt( (int(xp1[kkk,ik+1])-int(along_x[kkk]) )*(int(xp1[kkk,ik+1])-int(along_x[kkk]) ) + (int(yp1[kkk,ik+1])-int(along_y[kkk]) )*(int(yp1[kkk,ik+1])-int(along_y[kkk]) ) )
                                if (ikdist1 != ikdist2):
                                    re_x1[re_ct,tct] = xp1[kkk,ik]
                                    re_y1[re_ct,tct] = yp1[kkk,ik]
                                    re_dist1[re_ct,tct] = ikdist1
                                    tct=tct+1
                        re_ct=re_ct+1
                
                #ended along-track pixel loop
                re_x_c=re_x[0:re_ct]
                re_y_c=re_y[0:re_ct]
                
                re_x_n=re_x1[0:re_ct,:]
                re_y_n=re_y1[0:re_ct,:]
                re_x_p=re_x0[0:re_ct,:]
                re_y_p=re_y0[0:re_ct,:]
                re_distn=(re_dist1[0:re_ct,:])*(-1.)
                re_distp=re_dist0[0:re_ct,:]
                
                #reverse negative direction elements
                for ik in range(re_ct):
                    xtmp = (re_x_n[ik,:]).flatten()
                    ytmp = (re_y_n[ik,:]).flatten()
                    dtmp = (re_distn[ik,:]).flatten()
                    re_x_n[ik,:] = xtmp[::-1]
                    re_y_n[ik,:] = ytmp[::-1]
                    re_distn[ik,:] = dtmp[::-1]
                
                #Combine negative and positive perpendicular pixels
                re_x_all = (np.concatenate( ([re_x_n],[re_x_p]), axis=2))[0,:,:]
                re_y_all = (np.concatenate( ([re_y_n],[re_y_p]), axis=2))[0,:,:]
                re_dist_all = (np.concatenate( ([re_distn],[re_distp]), axis=2))[0,:,:]
                
                #Number of perpendicular and parallel pixels
                sz = np.shape(re_x_all)
                parl_npix = sz[0]
                perp_npix = sz[1]
                
                seg_parl_npix[segment_count] = parl_npix
                seg_perp_npix[segment_count] = perp_npix
                seg_dist[segment_count]  = tdistc                
                seg_re_x_all[segment_count,0:parl_npix,0:perp_npix] = re_x_all
                seg_re_y_all[segment_count,0:parl_npix,0:perp_npix] = re_y_all
                seg_dist_all[segment_count,0:parl_npix,0:perp_npix] = re_dist_all
                
                #Reset Length
                tdistc = 0.
                
                #Array for along track pixels
                along_x = np.zeros(5000)
                along_y = np.zeros(5000)
                xp0=np.zeros( (5000,5000) )  #{along,cross}
                yp0=np.zeros( (5000,5000) )
                xp1=np.zeros( (5000,5000) )
                yp1=np.zeros( (5000,5000) )
                along_ct = -1
                #Bump segment #
                segment_count=segment_count+1
            
            along_ct = along_ct+1
            along_ct_all = along_ct_all+1
    
    
    seg_parl_npix = seg_parl_npix[0:segment_count]
    seg_perp_npix = seg_perp_npix[0:segment_count]
    seg_dist      = seg_dist[0:segment_count]
    seg_re_x_all = seg_re_x_all[0:segment_count,:,:]
    seg_re_y_all = seg_re_y_all[0:segment_count,:,:]
    seg_dist_all = seg_dist_all[0:segment_count,:,:]

    SEG = {"parl_npix":seg_parl_npix, "perp_npix":seg_perp_npix, "dist":seg_dist, "re_x_all":seg_re_x_all, "re_y_all":seg_re_y_all, "dist_all":seg_dist_all}
    return SEG

def auto_pixel_identification_scheme(xDev,yDev,rad02,plot_data=0):    
    #Define Setup for Shiptrack Pixel Detection Algorithm
    sigma_thresh = 4.
    n_thresh = 1         # number of acceptable pixes that are under threshold from the along-track pixel
    separate_dist = 2.   # number of pixels separating ship from controls
    perp_length = 30.    # number of pixels in across track segment
    along_length = 20.   # number of pixels in along track segment

    #Dimensions of image
    SZ = np.shape(rad02)
    xDim = SZ[0]
    yDim = SZ[1]

    #hand-logged ship track locations
    trk_pos_ct = len( xDev ) ;# of track bends
    trackDevStr = ['x','y','lon','lat']
    trackDev = np.zeros( (len(trackDevStr),len(xDev) ) )
    trackDev[0,:] = xDev
    trackDev[1,:] = yDev
    
    #Setup Plotting - window projection coordinates
    new_y = np.median( yDev )
    if (new_y - 550 < 0.):
        yoff = 0
    else:
        yoff = new_y-550
    if (new_y + 550 >= yDim):
        ymax=yDim-1
    else:
        ymax = new_y+550
    
    #colorize satellite data
    omin = np.median(rad02[:,int(yoff):int(ymax)]) - np.std(rad02[:,int(yoff):int(ymax)])*2.5
    if (omin < 0.):
        omin = 0.
    omax = np.median(rad02[:,int(yoff):int(ymax)]) + np.std(rad02[:,int(yoff):int(ymax)])*2.5
    if (omax > np.max( rad02[:,int(yoff):int(ymax)] ) ):
        omax = np.max( rad02[:,int(yoff):int(ymax)] )
    print('yoff = ',yoff,'  ymax = ',ymax,'  omin = ',omin,'  omax = ',omax)

    #Step 1: Re-construct ship track postion (increase resolution between hand-logged locations) 
    tpts = auto_expand_track_positions(xDev,yDev)
    all_x = tpts['xtrack']
    all_y = tpts['ytrack']

    if (plot_data == 1):
        pltData = rad02[:,int(yoff):int(ymax)]
        my_dpi=96
        margin = 0.05
        deltaY = ymax-yoff
        deltaX = 1354
        xpixels, ypixels = deltaY*1.05, deltaX*1.05
        figsize = (1 + margin) * ypixels / my_dpi, (1 + margin) * xpixels / my_dpi
        fig = plt.figure(figsize=figsize, dpi=my_dpi)
        # Make the axis the right size...
        ax = fig.add_axes([margin, margin, 1 - 2*margin, 1 - 2*margin])
        ax.set_ylim([0,deltaY])
        ax.imshow(pltData, cmap=plt.get_cmap('gray'), vmin=omin, vmax = omax, interpolation='bilinear')
        #Plot hand-logged track locations
        #for ij in range(len(all_x)):
        #    plt.plot(all_y[ij]-yoff,all_x[ij],'*',color='blue')
        #for ij in range(trk_pos_ct):
        #    plt.plot(yDev[ij]-yoff,xDev[ij],'*',color='red')
        #plt.show()
    
    #Step 2: calculate coordinate locations (along track and cross track) for each segment
    SEG = auto_construct_segment(yoff,along_length,perp_length,all_x,all_y)
    seg_parl_npix = SEG['parl_npix']
    seg_perp_npix = SEG['perp_npix']
    seg_dist = SEG['dist']
    seg_re_x_all = SEG['re_x_all']
    seg_re_y_all = SEG['re_y_all']
    seg_dist_all = SEG['dist_all']
    segment_count = len(seg_parl_npix)
    
    #Step 3: process pixels in each segment
    #Define arrays to store masks for ship & control pixels
    #Detected pixel mask
    shipmask = np.zeros( (xDim,yDim) )
    con1mask = np.zeros( (xDim,yDim) )
    con2mask = np.zeros( (xDim,yDim) )
    segmask  = np.zeros( (xDim,yDim) ) #tells which segment
    segpixl   = np.zeros( (xDim,yDim) ) #tells along track pixel location
    widthpixl   = np.zeros( (xDim,yDim) )  #tells ship track width at along track pixel location
    #Loop over each segment
    for j in range(segment_count):
        parl_npix = int(seg_parl_npix[j])
        perp_npix = int(seg_perp_npix[j])
        #need to have a valid segment (this happens near the edge of granules)
        if (parl_npix > 0. and perp_npix > 0):
            re_x_all  = seg_re_x_all[j,0:parl_npix,0:perp_npix]
            re_y_all  = seg_re_y_all[j,0:parl_npix,0:perp_npix]
            dist_all  = seg_dist_all[j,0:parl_npix,0:perp_npix]            
            if ( (np.min(re_x_all) >= 0. and np.max(re_x_all) <= xDim) and (np.min(re_y_all) >= 0. and np.max(re_y_all) <= yDim) ):                
                #1D Array for radiances and locations of perpendicular pixels within +/-30 km                
                seg_radiance = np.zeros(parl_npix*perp_npix)
                seg_re_x = np.zeros(parl_npix*perp_npix)
                seg_re_y = np.zeros(parl_npix*perp_npix)
                seg_along = np.zeros(parl_npix*perp_npix)
                seg_perp  = np.zeros(parl_npix*perp_npix)
                seg_dist = np.zeros(parl_npix*perp_npix)
                seg_allct = 0
                for kkk in range(parl_npix):
                    for ik in range(perp_npix):
                        if (re_x_all[kkk,ik] > 0. and re_y_all[kkk,ik] > 0.):
                            if (dist_all[kkk,ik] != 0. and dist_all[kkk,ik] > perp_length*(-1.) and dist_all[kkk,ik] < perp_length*1.):
                                if ( rad02[int(re_x_all[kkk,ik]),int(re_y_all[kkk,ik])] > 0.):
                                    #print(kkk,ik,re_x_all[kkk,ik],re_y_all[kkk,ik],dist_all[kkk,ik])
                                    seg_radiance[seg_allct] = rad02[int(re_x_all[kkk,ik]),int(re_y_all[kkk,ik])]
                                    seg_re_x[seg_allct] = re_x_all[kkk,ik]
                                    seg_re_y[seg_allct] = re_y_all[kkk,ik]
                                    seg_along[seg_allct] = kkk
                                    seg_perp[seg_allct] = ik
                                    seg_dist[seg_allct] = dist_all[kkk,ik]
                                    seg_allct=seg_allct+1

                seg_re_x=seg_re_x[0:seg_allct-1]
                seg_re_y=seg_re_y[0:seg_allct-1]
                seg_re_radiance = seg_radiance[0:seg_allct-1]
                seg_along = seg_along[0:seg_allct-1]
                seg_perp  = seg_perp[0:seg_allct-1]
                seg_dist  = seg_dist[0:seg_allct-1]
                if (plot_data ==2):
                    plt.scatter(seg_perp,seg_re_radiance,s=.1,marker='o',c='black')
                    plt.xlim(np.min(seg_perp)-10,np.max(seg_perp)+10)
                                
                # Convert to pixel groups as a function of perpendicular line number
                bfrac = 0.65
                rads  = np.zeros( (2500,perp_npix) )
                xs   = np.zeros( (2500,perp_npix) )
                ys   = np.zeros( (2500,perp_npix) )
                Tas   = np.zeros( (2500,perp_npix) ) #along track pixel
                dists = np.zeros( (perp_npix) )
                xpts = np.zeros( (perp_npix) )
                all_xpts = np.zeros( (perp_npix) )
                ypts = np.zeros( (perp_npix) )
                bpts = np.zeros( (perp_npix) )
                rank_5 = np.zeros( (perp_npix) )
                run_mean = np.zeros( (perp_npix) )
                cts = 0
                
                #Loop over each perpendicular line
                for iii in range(perp_npix):
                    #Get background of the cross track pixels that fall into perpendicular line
                    junk=np.where( (seg_perp == iii) & (abs(seg_dist) >= perp_length*bfrac) )
                    bct = (np.shape(junk))[1]
                    
                    #Get all of the cross track pixels that fall into perpendicular line
                    junk=np.where( seg_perp == iii )
                    junkct = (np.shape(junk))[1]
                    if (junkct > 0.):
                        vals = seg_re_radiance[junk]
                        rads[0:junkct,cts] = vals
                        Tas[0:junkct,cts] = seg_along[junk]
                        xs[0:junkct,cts] = seg_re_x[junk]
                        ys[0:junkct,cts] = seg_re_y[junk]
                        dists[cts] = np.mean( seg_dist[junk] )
                        xpts[cts] = iii
                        ypts[cts] = junkct
                        bpts[cts] = bct
                        #Rank 5 of the perpendicular bin
                        if (junkct > 10.):
                            tmp=np.sort(vals)
                            valsr=tmp[::-1]
                            rank_5[cts] = valsr[4]
                        #Average of the perpendicular bin
                        run_mean[cts] = np.mean(vals)
                        cts = cts+1
                    all_xpts[iii] = iii
                rads = rads[0:int(np.max(ypts)),0:cts]
                xs = xs[0:int(np.max(ypts)),0:cts]
                ys = ys[0:int(np.max(ypts)),0:cts]
                Tas = Tas[0:int(np.max(ypts)),0:cts]
                dists= dists[0:cts]
                xpts = xpts[0:cts]
                ypts = ypts[0:cts]
                bpts = bpts[0:cts]
                rank_5 = rank_5[0:cts]
                run_mean = run_mean[0:cts]
                
                #Get least squres fit of background clouds
                bid=np.where(bpts > 10.)
                bidct=(np.shape(bid))[1]
                
                #Need to have at least 10 radiances in a perpendicular line to obtain a reprsentative 5th %rank
                if (bidct > 0.):
                    bxpts=xpts[bid]
                    brank_5=rank_5[bid]
                    A = np.vstack( [bxpts, np.ones(len(bxpts))]).T
                    m5, c5 = np.linalg.lstsq(A, brank_5, rcond=None)[0]
                    r_sig = np.std(brank_5)
                    rstats = lstqf(bxpts,brank_5)
                    r_sig = rstats[3]
                    xxarr = np.arange(perp_npix)
                    if (plot_data == 2):
                        plt.scatter(bxpts,brank_5,s=.1,marker='o',c='yellow')
                        plt.plot(xxarr, c5 + m5 * xxarr, '--', c='red', linewidth=.75)
                        plt.plot(xxarr, c5 + m5 * xxarr + sigma_thresh*r_sig, '--', c='blue', linewidth=.75)
                    
                    #Aquire threshold pixels marching outward from center pixel
                    #1st pixel (2 neighbors away) to dip below standard deviation threshold STOP
                    good_pixels = np.zeros( (parl_npix,len(xpts) ) )
                    n_neighbor_ct = 0
                    i0, =np.where( abs(dists) == np.min(abs(dists)))
                    if (plot_data ==2):
                        plt.plot( np.asarray([xpts[i0[0]],xpts[i0[0]]]), plt.gca().get_ylim(), c='black', linewidth=.5)

                    #positive direction
                    for nnn in range(i0[0],len(xpts),1):
                        #print('forward: ',nnn)
                        thresh = m5*xpts[nnn]+c5+sigma_thresh*r_sig
                        rvals = rads[0:int(ypts[nnn]),nnn]
                        junk=np.where( rvals > thresh)
                        junkct=(np.shape(junk))[1]
                        if (junkct > 0.):
                            XXvs = (((xs[ [junk], nnn ].astype(int))[0])[0])
                            YYvs = (((ys[ [junk], nnn ].astype(int))[0])[0])
                            RRvs = rad02[XXvs,YYvs]
                            PTX  = XXvs
                            PTX[:] = xpts[nnn]
                            if (plot_data == 2):
                                plt.scatter( PTX, RRvs, s=.5, c='red', marker='o')
                            TTvs = ((Tas[junk,nnn].astype(int))[0])
                            good_pixels[ TTvs, nnn ] = 1
                        else:
                            n_neighbor_ct = n_neighbor_ct+1
                        if (n_neighbor_ct > n_thresh):
                            break

                    #negative direction
                    n_neighbor_ct = 0
                    for nnn in range(i0[0],0,-1):
                        thresh = m5*xpts[nnn]+c5+sigma_thresh*r_sig
                        rvals = rads[0:int(ypts[nnn]),nnn]
                        junk=np.where( rvals > thresh)
                        junkct=(np.shape(junk))[1]
                        if (junkct > 0.):
                            XXvs = (((xs[ [junk], nnn ].astype(int))[0])[0])
                            YYvs = (((ys[ [junk], nnn ].astype(int))[0])[0])
                            RRvs = rad02[XXvs,YYvs]
                            PTX  = XXvs
                            PTX[:] = xpts[nnn]
                            if (plot_data == 2):
                                plt.scatter( PTX, RRvs, s=.5, c='red', marker='o')
                            TTvs = ((Tas[junk,nnn].astype(int))[0])
                            good_pixels[ TTvs, nnn ] = 1
                        else:
                            n_neighbor_ct = n_neighbor_ct+1
                        if (n_neighbor_ct > n_thresh):
                            break

                    if (plot_data == 2):
                        plt.show()
                    
                    #Reset plotting screen to satellite image
                    if (plot_data == 3):
                        pltData = rad02[:,int(yoff):int(ymax)]
                        my_dpi=96
                        margin = 0.05
                        deltaY = ymax-yoff
                        deltaX = 1354
                        xpixels, ypixels = deltaY*1.05, deltaX*1.05
                        figsize = (1 + margin) * ypixels / my_dpi, (1 + margin) * xpixels / my_dpi
                        fig = plt.figure(figsize=figsize, dpi=my_dpi)
                        # Make the axis the right size...
                        ax = fig.add_axes([margin, margin, 1 - 2*margin, 1 - 2*margin])
                        ax.set_ylim([0,deltaY])
                        ax.imshow(pltData, cmap=plt.get_cmap('gray'), vmin=omin, vmax = omax, interpolation='bilinear')
                    
                    #Now run back through segment in the along-track dimension
                    #determine perpendicular width for each along-track pixel
                    #Loop over each along-track pixel section (note this is where you could estimate clear-gaps!!!!)
                    for iii in range(parl_npix):
                        #Determine width of ship track region
                        width_px = np.zeros(perp_npix)
                        width_ct = np.zeros(perp_npix)
                        width_ct[:] = -999
                        tempct=0
                        #Loop over perpendicular section
                        for kkk in range(len(xpts)):
                            if (good_pixels[iii,kkk] == 1):
                                width_px[kkk] = kkk
                                width_ct[kkk] = tempct
                                tempct = tempct + 1
                        
                        re_size = np.shape(re_x_all)
                        #Start only if a suitable ship track width was determined
                        e3_id=0
                        e4_id=0
                        if (tempct > 0.):
                            #Define width
                            junk=np.where(width_ct == 0.)
                            e3_id = width_px[junk]
                            e3_id = e3_id[0]
                            junk = np.where(width_ct == tempct-1.)
                            e4_id = width_px[junk]
                            e4_id = e4_id[0]
                            width = e4_id-e3_id
                            
                            #Define Ship
                            for kkk in range(int(e3_id),int(e4_id),1):
                                shipmask[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=1
                                segmask[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=j
                                segpixl[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=(j*along_length+iii*along_length*1./parl_npix*1.)
                                widthpixl[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=width                                
                                if (plot_data ==3):
                                    plt.scatter( re_y_all[iii,kkk+int(xpts[0])]-yoff, re_x_all[iii,kkk+int(xpts[0])], s=.1, c='red', marker='o')
                            
                            #Define Control 1 (negative)
                            e1_id = e3_id-separate_dist-width
                            e2_id = e3_id-separate_dist
                            for kkk in range(int(e1_id),int(e2_id),1):
                                if ( (kkk+int(xpts[0]) < re_size[1]) ):
                                    con1mask[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=1
                                    segmask[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=j
                                    segpixl[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=(j*along_length+iii*along_length*1./parl_npix*1.)
                                    widthpixl[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=width
                                    if (plot_data==3):
                                        plt.scatter( re_y_all[iii,kkk+int(xpts[0])]-yoff, re_x_all[iii,kkk+int(xpts[0])], s=.1, c='blue', marker='o')
                            #Define Control 2 (positive)
                            e5_id = e4_id+separate_dist
                            e6_id = e4_id+separate_dist+width
                            for kkk in range(int(e5_id),int(e6_id),1):
                                if ( (kkk+int(xpts[0]) < re_size[1]) ):
                                    con2mask[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=1
                                    segmask[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=j
                                    segpixl[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=(j*along_length+iii*along_length*1./parl_npix*1.)
                                    widthpixl[ int(re_x_all[iii,kkk+int(xpts[0])]), int(re_y_all[iii,kkk+int(xpts[0])]) ]=width
                                    if (plot_data==3):
                                        plt.scatter( re_y_all[iii,kkk+int(xpts[0])]-yoff, re_x_all[iii,kkk+int(xpts[0])], s=.1, c='green', marker='o')
                    print('Next Segment')
    #---------------------------------------------------------------------------------------------------------
    # Filtering
    #---------------------------------------------------------------------------------------------------------
    #Remove repeated values in control and ship masks
    #set all repeats to 0
    for iii in range(xDim):
        for jjj in range(yDim):
            if (con1mask[iii,jjj] == 1 and shipmask[iii,jjj] == 1):
                con1mask[iii,jjj] = 0
                shipmask[iii,jjj] = 0
                segmask[iii,jjj] = 0
                segpixl[iii,jjj] = 0
                widthpixl[iii,jjj] = 0

            if (con2mask[iii,jjj] == 1 and shipmask[iii,jjj] == 1):
                con2mask[iii,jjj] = 0
                shipmask[iii,jjj] = 0
                segmask[iii,jjj] = 0
                segpixl[iii,jjj] = 0
                widthpixl[iii,jjj] = 0

            if (con2mask[iii,jjj] == 1 and con1mask[iii,jjj] == 1):
                con2mask[iii,jjj] = 0
                con1mask[iii,jjj] = 0
                segmask[iii,jjj] = 0
                segpixl[iii,jjj] = 0
                widthpixl[iii,jjj] = 0

            if (con2mask[iii,jjj] == 1 and con1mask[iii,jjj] == 1 and shipmask[iii,jjj] == 1):
                con2mask[iii,jjj] = 0
                con1mask[iii,jjj] = 0
                shipmask[iii,jjj] = 0
                segmask[iii,jjj] = 0
                segpixl[iii,jjj] = 0
                widthpixl[iii,jjj] = 0

    #---------------------------------------------------------------------------------------------------------
    # Writing Data to Dictionary
    #---------------------------------------------------------------------------------------------------------
    str_px_loc = ['modis-x','modis-y','seg#','along-track distance','ship-track width at along-track pixel']
    str_px_loc_long = ['x across MODIS image pixl','y-along MODIS image pixel','segment number','distance from the head of the ship track to pixel','width of the ship track at pixel location']
    ship_px_loc = np.zeros( (len(str_px_loc),50000 ) )
    ship_px_ct = 0
    con1_px_loc = np.zeros( (len(str_px_loc),50000) )
    con1_px_ct = 0
    con2_px_loc = np.zeros( (len(str_px_loc),50000) )
    con2_px_ct = 0
    for iii in range(xDim):
        for jjj in range(yDim):
            if (shipmask[iii,jjj] == 1):
                ship_px_loc[0,ship_px_ct] = iii
                ship_px_loc[1,ship_px_ct] = jjj
                ship_px_loc[2,ship_px_ct] = segmask[iii,jjj]
                ship_px_loc[3,ship_px_ct] = segpixl[iii,jjj]
                ship_px_loc[4,ship_px_ct] = widthpixl[iii,jjj]+1
                ship_px_ct=ship_px_ct+1
            if (con1mask[iii,jjj] == 1):
                con1_px_loc[0,con1_px_ct] = iii
                con1_px_loc[1,con1_px_ct] = jjj
                con1_px_loc[2,con1_px_ct] = segmask[iii,jjj]
                con1_px_loc[3,con1_px_ct] = segpixl[iii,jjj]
                con1_px_loc[4,con1_px_ct] = widthpixl[iii,jjj]+1
                con1_px_ct=con1_px_ct+1
            if (con2mask[iii,jjj] == 1):
                con2_px_loc[0,con2_px_ct] = iii
                con2_px_loc[1,con2_px_ct] = jjj
                con2_px_loc[2,con2_px_ct] = segmask[iii,jjj]
                con2_px_loc[3,con2_px_ct] = segpixl[iii,jjj]
                con2_px_loc[4,con2_px_ct] = widthpixl[iii,jjj]+1
                con2_px_ct=con2_px_ct+1
    if ship_px_ct > 0.:
        ship_px_loc=ship_px_loc[:,0:ship_px_ct]
    else:
        ship_px_loc=-999.
    if con1_px_ct > 0.:
        con1_px_loc=con1_px_loc[:,0:con1_px_ct]
    else:
        con1_px_loc=-999.
    if con2_px_ct > 0.:
        con2_px_loc=con2_px_loc[:,0:con2_px_ct]
    else:
        con2_px_loc=-999.

    #Re-order array so that it is based on increasing distance from track head
    if ship_px_ct > 0.:
        junk=np.argsort(ship_px_loc[3,:])
        ship_px_loc = ship_px_loc[:,junk]
    if con1_px_ct > 0.:
        junk=np.argsort(con1_px_loc[3,:])
        con1_px_loc = con1_px_loc[:,junk]
    if con2_px_ct > 0.:
        junk=np.argsort(con2_px_loc[3,:])
        con2_px_loc = con2_px_loc[:,junk]
        
    #Plot final rendered image
    if (plot_data == 4.):
        pltData = rad02[:,int(yoff):int(ymax)]
        my_dpi=96
        margin = 0.05
        deltaY = ymax-yoff
        deltaX = 1354
        xpixels, ypixels = deltaY*1.05, deltaX*1.05
        figsize = (1 + margin) * ypixels / my_dpi, (1 + margin) * xpixels / my_dpi
        fig = plt.figure(figsize=figsize, dpi=my_dpi)
        # Make the axis the right size...
        ax = fig.add_axes([margin, margin, 1 - 2*margin, 1 - 2*margin])
        ax.set_ylim([0,deltaY])
        ax.imshow(pltData, cmap=plt.get_cmap('gray'), vmin=omin, vmax = omax, interpolation='bilinear')
        xVals = np.asarray([i for i in ship_px_loc[0,:] ])
        yVals = np.asarray([i for i in ship_px_loc[1,:]-yoff ])
        plt.scatter(yVals,xVals, s=.1, c='red', marker='o')       
        xVals = np.asarray([i for i in con1_px_loc[0,:] ])
        yVals = np.asarray([i for i in con1_px_loc[1,:]-yoff ])
        plt.scatter(yVals,xVals, s=.1, c='blue', marker='o')        
        xVals = np.asarray([i for i in con2_px_loc[0,:] ])
        yVals = np.asarray([i for i in con2_px_loc[1,:]-yoff ])
        plt.scatter(yVals,xVals, s=.1, c='green', marker='o')
        
    shiptrack_pixels={"track_hand_logged_locations":trackDev, "track_hand_logged_str":trackDevStr,"ship":ship_px_loc, "con1":con1_px_loc, "con2":con2_px_loc,"str":str_px_loc, "unit":['1','1','1','km','km'],"long":str_px_loc_long,"sigma_thresh":sigma_thresh,"n_thresh":n_thresh,"separate_dist":separate_dist,"along_length":along_length,"perp_length":perp_length,"segment_count":segment_count}
    return shiptrack_pixels

def auto_create_netcdf_file(shiptrack_pixels,OUTPUT_FILE,SATELLITE_DATA=''):
    f = Dataset(OUTPUT_FILE,'w', format='NETCDF4_CLASSIC')
    f.createDimension('track_geolocation',(np.shape(shiptrack_pixels['track_hand_logged_locations']))[1] )
    f.createDimension('n_logged_bends',(np.shape(shiptrack_pixels['track_hand_logged_locations']))[2] )
    f.createDimension('n_ship_tracks',(np.shape(shiptrack_pixels['track_hand_logged_locations']))[0] )
    f.createDimension('stat',(np.shape(shiptrack_pixels['ship']))[0] )
    f.createDimension('ship_pixels',(np.shape(shiptrack_pixels['ship']))[1] )
    f.createDimension('con1_pixels',(np.shape(shiptrack_pixels['con1']))[1] )
    f.createDimension('con2_pixels',(np.shape(shiptrack_pixels['con2']))[1] )
    
    if len(SATELLITE_DATA) > 0:
        f.createDimension('modis_variables', len(SATELLITE_DATA['vars']))
    
    temp = f.createVariable('track_logged_locations', 'f4', ('n_ship_tracks','track_geolocation','n_logged_bends'), zlib=True)
    temp[:,:,:] = shiptrack_pixels['track_hand_logged_locations']
    temp.long_name = ','.join(shiptrack_pixels['track_hand_logged_str'])
    temp.track_n_turns = (shiptrack_pixels['track_hand_logged_n_turns'])[0]
    temp.fill_value = -999.
    temp.description = 'contains all of the locations for each ship track in the granule: dimensions: {x,y},{turning points},{shiptrack number}'
    
    temp = f.createVariable('ship', 'f4', ('stat','ship_pixels'), zlib=True)
    temp[:,:] = shiptrack_pixels['ship']
    temp.long_name = ','.join(shiptrack_pixels['str'])
    temp.units = ','.join(shiptrack_pixels['unit'])
    temp.description = ','.join(shiptrack_pixels['long'])

    temp = f.createVariable('con1', 'f4', ('stat','con1_pixels'), zlib=True)
    temp[:,:] = shiptrack_pixels['con1']
    temp.long_name = ','.join(shiptrack_pixels['str'])
    temp.units = ','.join(shiptrack_pixels['unit'])
    temp.description = ','.join(shiptrack_pixels['long'])

    temp = f.createVariable('con2', 'f4', ('stat','con2_pixels'), zlib=True)
    temp[:,:] = shiptrack_pixels['con2']
    temp.long_name = ','.join(shiptrack_pixels['str'])
    temp.units = ','.join(shiptrack_pixels['unit'])
    temp.description = ','.join(shiptrack_pixels['long'])

    if len(SATELLITE_DATA) > 0:
        temp = f.createVariable('ship_modis', 'f4', ('modis_variables','ship_pixels'), zlib=True)
        temp[:,:] = SATELLITE_DATA['ship']
        temp.variables = ','.join(SATELLITE_DATA['vars'])
        temp.units = ','.join(SATELLITE_DATA['units'])
        temp.long = ','.join(SATELLITE_DATA['vars_long'])

        temp = f.createVariable('con1_modis', 'f4', ('modis_variables','con1_pixels'), zlib=True)
        temp[:,:] = SATELLITE_DATA['con1']
        temp.variables = ','.join(SATELLITE_DATA['vars'])
        temp.units = ','.join(SATELLITE_DATA['units'])
        temp.long = ','.join(SATELLITE_DATA['vars_long'])

        temp = f.createVariable('con2_modis', 'f4', ('modis_variables','con2_pixels'), zlib=True)
        temp[:,:] = SATELLITE_DATA['con2']
        temp.variables = ','.join(SATELLITE_DATA['vars'])
        temp.units = ','.join(SATELLITE_DATA['units'])
        temp.long = ','.join(SATELLITE_DATA['vars_long'])
         
    #global attributes
    today = datetime.datetime.today()
    f.n_shiptracks = shiptrack_pixels['ntracks']
    f.sigma_threshold = shiptrack_pixels['sigma_thresh']
    f.n_thresh = shiptrack_pixels['n_thresh']
    f.separate_dist = shiptrack_pixels['separate_dist']
    f.along_length = shiptrack_pixels['along_length']
    f.perp_length = shiptrack_pixels['perp_length']
    f.description = "n_shiptracks is the number of ship tracks in the MODIS image, sigma_threshold is the standard deviation level above the least squares fit-line used to determine which pixels are considered polluted in a given segment, n_thresh is the # of acceptable pixes that are under threshold from the along-track pixel, separate_dist is the # of pixels separating ship from controls, perp_length is the # of pixels in across track segment, and along_length is the # of pixels in along track segment"
    f.history = "Created " + today.strftime("%d/%m/%y")
    f.close()
    
    
def auto_filter_track_pixels(hVar, trkct, OUTPUT_FILE='./_track_pixels_data.nc'):
    #Combine all ship tracks from granule    
    trk_pos_loc = np.zeros( (trkct, 4, 100) )
    trk_pos_loc[:,:,:] = -9999. 
    trk_pos_ct = np.zeros(trkct, int)
    for tI in range(trkct):
        track_hand_logged_locations = (hVar[tI])["track_hand_logged_locations"]
        trk_pos_ct[tI] = np.shape(track_hand_logged_locations)[1]
        trk_pos_loc[ tI, 0:2, 0:trk_pos_ct[tI] ] = ( (hVar[tI])["track_hand_logged_locations"] )[0:2,:]
    trk_pos_loc = trk_pos_loc[ :, :, 0:np.max(trk_pos_ct) ]
    
    #Flag pixels in locations where ship pixels intersect control pixels
    #combine all pixels from all ship tracks into array
    all_ship = np.zeros( (5,50000*trkct) )
    all_ship_track_num = np.zeros(50000*trkct)
    all_shipCT = 0
    
    all_con1 = np.zeros( (5,50000*trkct) )
    all_con1_track_num = np.zeros(50000*trkct)
    all_con1CT = 0
    
    all_con2 = np.zeros( (5,50000*trkct) )
    all_con2_track_num = np.zeros(50000*trkct)
    all_con2CT = 0
    for tI in range(trkct):
        npx = (np.shape((hVar[tI])['ship']))[1]
        for J in range(npx):
            all_ship[:,all_shipCT] = ((hVar[tI])['ship'])[:,J]
            all_ship_track_num[all_shipCT] = tI
            all_shipCT = all_shipCT + 1
        
        npx = (np.shape((hVar[tI])['con1']))[1]
        for J in range(npx):
            all_con1[:,all_con1CT] = ((hVar[tI])['con1'])[:,J]
            all_con1_track_num[all_con1CT] = tI
            all_con1CT = all_con1CT + 1
        npx = (np.shape((hVar[tI])['con2']))[1]
        for J in range(npx):
            all_con2[:,all_con2CT] = ((hVar[tI])['con2'])[:,J]
            all_con2_track_num[all_con2CT] = tI
            all_con2CT = all_con2CT + 1

    #Fill arrays    
    all_ship = all_ship[:,0:all_shipCT]
    all_ship_track_num = all_ship_track_num[0:all_shipCT]
    all_con1 = all_con1[:,0:all_con1CT]
    all_con1_track_num = all_con1_track_num[0:all_con1CT]
    all_con2 = all_con2[:,0:all_con2CT]
    all_con2_track_num = all_con2_track_num[0:all_con2CT]

    ship_flag = np.zeros( all_shipCT , int)
    con1_flag = np.zeros( all_con1CT , int)
    con2_flag = np.zeros( all_con2CT , int)
    #Loop through all ship pixels
    for I in range(all_shipCT):
        shipX = all_ship[0,I]
        shipY = all_ship[1,I]
        
        ID_SHIP, = np.where( (all_ship[0,:] == shipX) & (all_ship[1,:] == shipY) )
        ID_CON1, = np.where( (all_con1[0,:] == shipX) & (all_con1[1,:] == shipY) )
        ID_CON2, = np.where( (all_con2[0,:] == shipX) & (all_con2[1,:] == shipY) )
        
        if len(ID_SHIP) > 1:
            ship_flag[I] = 1 #ship contaminating ship (two-ship crossing)
        if len(ID_CON1) > 0:
            con1_flag[I] = 1 #ship contaminating control 1
        if len(ID_CON2) > 1:
            con2_flag[I] = 1 #ship contaminating control 2
    
    #Combine Arrays
    ShipData = np.zeros( (7, all_shipCT) )
    ShipData[0:5,:] = all_ship
    ShipData[5,:]   = all_ship_track_num
    ShipData[6,:]   = ship_flag

    Con1Data = np.zeros( (7, all_con1CT) )
    Con1Data[0:5,:] = all_con1
    Con1Data[5,:]   = all_con1_track_num
    Con1Data[6,:]   = con1_flag

    Con2Data = np.zeros( (7, all_con2CT) )
    Con2Data[0:5,:] = all_con2
    Con2Data[5,:]   = all_con2_track_num
    Con2Data[6,:]   = con2_flag
    
    #Add additional elements to output array
    str_px = (hVar[0])['str'] + ['track-number-in-image','filter-flag']

    #Carry over contents from structure into new filtered output structure
    sigma_thresh = (hVar[0])['sigma_thresh']
    n_thresh     = (hVar[0])['n_thresh']
    separate_dist= (hVar[0])['separate_dist']
    along_length = (hVar[0])['along_length']
    perp_length  = (hVar[0])['perp_length']
    track_hand_logged_str = (hVar[0])['track_hand_logged_str']
    str_px_loc_unit = (hVar[0])['unit']
    str_px_loc_long = (hVar[0])['long']

    #Write output to structure
    shiptrack_pixels = {"ntracks":trkct,"track_hand_logged_locations":trk_pos_loc,"track_hand_logged_n_turns":trk_pos_ct,"track_hand_logged_str":track_hand_logged_str,"ship":ShipData,"con1":Con1Data,"con2":Con2Data,"str":str_px,"unit":str_px_loc_unit,"long":str_px_loc_long,"sigma_thresh":sigma_thresh,"n_thresh":n_thresh,"separate_dist":separate_dist,"along_length":along_length,"perp_length":perp_length}
    
    err = auto_create_netcdf_file(shiptrack_pixels,OUTPUT_FILE)    
    
    return shiptrack_pixels
    
def auto_fetch_modis_product(F02,F03,F06,Filtered_TrackPixels,OUTPUT_FILE='./_track_pixels_and_MODIS_data.nc'):
    #READ MODIS CALIBRATED RADIANCES    
    F02_DATA = read_mod02(F02)
    rad02 = F02_DATA['arad']
    nvar2 = len(F02_DATA['astr'])

    #READ MODIS GEOLOCATION DATA
    F03_DATA = read_mod03(F03)
    rad03 = F03_DATA['arad']
    nvar3 = len(F03_DATA['astr'])
    
    #READ MODIS CLOUD DATA
    F06_DATA = read_mod06_c6(F06)    
    rad06 = F06_DATA['arad']
    nvar6 = len(F06_DATA['astr'])
    
    #Combine MODIS Datasets
    xDim = (np.shape(rad02))[1]
    yDim = (np.shape(rad02))[0]
    nvars = nvar2+nvar3+nvar6
    
    MODIS_DATA = np.zeros( (yDim, xDim, nvars) )
    
    #Fill Array
    MODIS_DATA[:,:,0:nvar2] = rad02
    MODIS_DATA[:,:,nvar2:nvar2+nvar3] = rad03
    MODIS_DATA[:,:,nvar2+nvar3:nvars] = rad06

    MODIS_STR = F02_DATA['astr'] + F03_DATA['astr'] + F06_DATA['astr']
    MODIS_STR_LONG = F02_DATA['astr_long'] + F03_DATA['astr_long'] + F06_DATA['astr_long']
    MODIS_UNITS    = F02_DATA['astr_units'] + F03_DATA['astr_units'] + F06_DATA['astr_units']
    
    #Fetch MODIS product for Ship Pixels
    SHIP_MODIS_DATA = np.zeros( ( nvars, (np.shape(Filtered_TrackPixels['ship']))[1] ) )
    xDev = (Filtered_TrackPixels['ship'])[0,:]
    yDev = (Filtered_TrackPixels['ship'])[1,:]
    for jjj in range(len(xDev)):
        SHIP_MODIS_DATA[ :, jjj ] = MODIS_DATA[ int(yDev[jjj]), int(xDev[jjj]), : ]

    #Fetch MODIS product for CON1 Pixels
    CON1_MODIS_DATA = np.zeros( ( nvars, (np.shape(Filtered_TrackPixels['con1']))[1] ) )
    xDev = (Filtered_TrackPixels['con1'])[0,:]
    yDev = (Filtered_TrackPixels['con1'])[1,:]
    for jjj in range(len(xDev)):
        CON1_MODIS_DATA[ :, jjj ] = MODIS_DATA[ int(yDev[jjj]), int(xDev[jjj]), : ]
    
    #Fetch MODIS product for CON1 Pixels
    CON2_MODIS_DATA = np.zeros( ( nvars, (np.shape(Filtered_TrackPixels['con2']))[1] ) )
    xDev = (Filtered_TrackPixels['con2'])[0,:]
    yDev = (Filtered_TrackPixels['con2'])[1,:]
    for jjj in range(len(xDev)):
        CON2_MODIS_DATA[ :, jjj ] = MODIS_DATA[ int(yDev[jjj]), int(xDev[jjj]), : ]

    outDATA={'ship':SHIP_MODIS_DATA,'con1':CON1_MODIS_DATA,'con2':CON2_MODIS_DATA,
             'mod02_file':F02, 'mod03_file':F03, 'mod06_file':F06,
             'vars':MODIS_STR, 'vars_long':MODIS_STR_LONG, 'units':MODIS_UNITS}
    
    #Switch name to be consistent with netCDF routine
    shiptrack_pixels = Filtered_TrackPixels

    #Fetch latitude and longitude of the hand-logged locations
    for iT in range(shiptrack_pixels['ntracks']):
        for I in range( (shiptrack_pixels['track_hand_logged_n_turns'])[iT]):
            (shiptrack_pixels['track_hand_logged_locations'])[iT,2,I] = MODIS_DATA[ int( (shiptrack_pixels['track_hand_logged_locations'])[iT,1,I] ), int( (shiptrack_pixels['track_hand_logged_locations'])[iT,0,I]), 7]
            (shiptrack_pixels['track_hand_logged_locations'])[iT,2,I] = MODIS_DATA[ int( (shiptrack_pixels['track_hand_logged_locations'])[iT,1,I] ), int( (shiptrack_pixels['track_hand_logged_locations'])[iT,0,I]), 6]
            
    #Output NetCDF
    err = auto_create_netcdf_file(shiptrack_pixels,OUTPUT_FILE,SATELLITE_DATA=outDATA)

    return outDATA
    
def auto_plot_output_data(ncFile):
    #Plot histogram of re
    f = Dataset(ncFile) #https://iescoders.com/reading-netcdf4-data-in-python/
    ship = (f.variables['ship_modis'])[:,:]
    con1 = (f.variables['con1_modis'])[:,:]
    con2 = (f.variables['con2_modis'])[:,:]
    f.close
    
    id=np.where(ship[14,:] > 0)
    x = (ship[14,:])[id]

    id=np.where(con1[14,:] > 0)
    y = (con1[14,:])[id]

    id=np.where(con2[14,:] > 0)
    z = (con2[14,:])[id]

    xLab = 'ship ( '+"{:d}".format(len(x))+'):  '+"{:.1f}".format(np.mean(x))+" ({:.1f})".format(np.std(x))
    yLab = 'con1 ( '+"{:d}".format(len(y))+'):  '+"{:.1f}".format(np.mean(y))+" ({:.1f})".format(np.std(y))
    zLab = 'con2 ( '+"{:d}".format(len(z))+'):  '+"{:.1f}".format(np.mean(z))+" ({:.1f})".format(np.std(z))

    x_w = np.empty(x.shape)
    x_w.fill(1/x.shape[0])
    y_w = np.empty(y.shape)
    y_w.fill(1/y.shape[0])
    z_w = np.empty(z.shape)
    z_w.fill(1/z.shape[0])
    
    bins = np.linspace(0, 25, 25)

    fig, ax1 = plt.subplots()
    #ax1.hist(xShip, bins, alpha=0.333, label='ship', color='red')
    #ax1.hist(xCon1, bins, alpha=0.333, label='con1', color='blue')
    #ax1.hist(xCon2, bins, alpha=0.333, label='con2', color='green')
    ax1.hist([x,y,z], bins, weights=[x_w, y_w, z_w], label=[xLab,yLab,zLab], color=['red','blue','green'])
    ax1.legend(loc='upper left')
    ax1.set_ylabel("Relative Frequency")
    ax1.set_xlabel("Effective Radius (um)")
    plt.show()
    
    err = -9
    return err
    