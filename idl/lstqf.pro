pro lstqf,Xarr,Yarr,stats,statn,dof=dof,errors=e

;Xarr = [150,175,200,225,250,275,300,325,350,375]
;Yarr = [18 ,24 ,26 ,23 ,30 ,27 ,34 ,35 ,33 ,40]
;lstqf,[150,175,200,225,250,275,300,325,350,375],[18 ,24 ,26 ,23 ,30 ,27 ,34 ,35 ,33 ,40],stats,statn
;optional - dof: degrees of freedom to replace N

statn_long = ['slope','intercept','correlation','standard_error_estimate','sum_squares_regression','residual_sum_squares','standard_error_regression_slope','covarianceXY','varianceX','varianceY']
statn = [ ['m','b','r','SEE','SSR','SSE','sb','covXY','varX','varY'], [statn_long] ]
stats = fltarr(n_elements(statn_long)) ;slope,intercept,correlation,standard error estimate, sum of squares regression, residual sum of squres, total sum of squares

N = n_elements(xarr)*1.
IF KEYWORD_SET(dof) EQ 1 THEN N=DOF
Xarr_Yarr   = Xarr*Yarr
Xarr_2  = xarr^2.
x    = Xarr - mean(Xarr)
y    = Yarr - mean(Yarr)
x2  = x^2
y2  = y^2
xy   = x*y

covXY = total(xy) / (N-1.)
varX  = total(x2) / (N-1.)
varY  = total(y2) / (N-1.)

b2 = total(xy)/total(x2)
b1 = mean(yarr) - b2*mean(xarr)

m = b2
b = b1

yfit = b1 + b2*Xarr
SSR = yfit - mean(yarr)
e = yarr - yfit
e2 = e^2.

;plot,xarr,yarr,psym=1,xrange=[100,400],yrange=[15,45],xstyle=1,ystyle=1
;print,xarr
;print,yarr
;print,Xarr_Yarr
;print,xarr_2
;print,x
;print,y
;print,x2
;print,xy
;print,'Slope = ',b2
;print,'Y-int = ',b1
;print,yfit
;print,e
;print,total(e)
;print,e^2.

;print,'residual sum of squares = ',total(e^2.)
SEE = sqrt( total(e^2.) / (N-2.) )
;print,'Standard Error of Estimate = ',SEE

;Manually Calculate r
SSR = total((yfit - mean(yarr) )^2.)
SSE = total(e^2.)
SST = SSR + SSE

;print,'ESS = ',SSR
;print,'Residual Sum of Squares (RSS) = ',SSE
;print,'TSS = ',SST
MSREG = SSR/1.
MSRES = SSE/(N-2.)
;print,'Mean Sum of Squares on Regression (MS) = ',MSREG
;print,'Mean Sum of Squares on Residual (MS) = ',MSRES
;print,'F ratio = ',MSREG/MSRES

r2  = ssr/sst
r   = sqrt(ssr/sst)
IF m lt 0. then r = r*(-1.)
;print,'Correlation Coefficient (r^2, r) = ',r2,r

;Tstat_int = b1/SEE
;print,'T-stat-Int = ',tstat_int
;Tstat_slope = b2/SEE
;print,'T-stat-slope = ',tstat_slope

stats(0) = m
stats(1) = b
stats(2) = r
stats(3) = SEE
stats(4) = SSR
stats(5) = SSE

SSx = (n-1.)*variance(xarr)
SSy = (n-1.)*variance(yarr)
sb = sqrt( ( (SSy/SSx)-b2^2.)/(n-2.))
stats(6) = sb

stats(7) = covXY
stats(8) = varX
stats(9) = varY

return
end
