import numpy as np
import pdb

#Least Squares Fit
#Xarr = [150,175,200,225,250,275,300,325,350,375]
#Yarr = [18 ,24 ,26 ,23 ,30 ,27 ,34 ,35 ,33 ,40]
#res = lstqf(Xarr,Yarr,-1)
#res = lstqf([150,175,200,225,250,275,300,325,350,375],[18 ,24 ,26 ,23 ,30 ,27 ,34 ,35 ,33 ,40])
def lstqf(Xarr,Yarr):
    Xarr = np.asarray(Xarr)
    Yarr = np.asarray(Yarr)
    statn_long = ['slope','intercept','correlation','standard_error_estimate','sum_squares_regression','residual_sum_squares','standard_error_regression_slope','covarianceXY','varianceX','varianceY']
    statn = [ ['m','b','r','SEE','SSR','SSE','sb','covXY','varX','varY'], [statn_long] ]
    stats = np.zeros(len(statn_long)) #slope,intercept,correlation,standard error estimate, sum of squares regression, residual sum of squres, total sum of squares
    N = len(Xarr)*1.

    x    = Xarr - np.mean(Xarr)
    y    = Yarr - np.mean(Yarr)
    x2  = x*x
    y2  = y*y
    xy   = x*y

    covXY = np.sum(xy) / (N-1.)
    varX  = np.sum(x2) / (N-1.)
    varY  = np.sum(y2) / (N-1.)

    b2 = np.sum(xy)/np.sum(x2)
    b1 = np.mean(Yarr) - b2*np.mean(Xarr)

    m = b2
    b = b1

    yfit = b1 + b2*Xarr
    SSR = yfit - np.mean(Yarr)
    e = Yarr - yfit

    SEE = np.sqrt( np.sum(e*e) / (N-2.) )    

    #Manually Calculate r
    SSR = np.sum( (yfit - np.mean(Yarr) ) * (yfit - np.mean(Yarr) ))
    SSE = np.sum(e*e)
    SST = SSR + SSE
    
    r   = np.sqrt(SSR/SST)
    if (m < 0.):
        r = r*(-1.)

    stats[0] = m
    stats[1] = b
    stats[2] = r
    stats[3] = SEE
    stats[4] = SSR
    stats[5] = SSE

    SSx = (N-1.)*np.var(Xarr)
    SSy = (N-1.)*np.var(Yarr)
    sb = np.sqrt( ( (SSy/SSx)-b2*b2)/(N-2.))
    stats[6] = sb

    stats[7] = covXY
    stats[8] = varX
    stats[9] = varY

    return stats
