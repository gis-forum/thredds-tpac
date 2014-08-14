import numpy as np
import pydap
from pydap.client import open_url
import re
#import matplotlib as plt

f = open("Saved_URL_C96-5k_GFDL.txt")
lines = [line.rstrip() for line in f]
f.close()
#
# better to prepare the txt file here and strip of excess lines with len zero
#
# Removed newline character already
#
#
#dataset=open_url('http://cfa0.rdsi.tpac.org.au/thredds/dodsC/products/Daily/C96-5k_ACCESS1-0_rcp85/cfa-v4-C96-5k_ACCESS1-0_rcp85.196001.nc')
dataset=open_url(lines[1])
lat=dataset.lat[:]
long=dataset.lon[:]
print lat[20], long[20]
print 'Latitude '
print lat
print 'Longitude '
print long
time=dataset.time[:]
print 'Time'
print time
#
# lets read the time series from the point 20 20
count=12
length=len(dataset.tmaxscr.array[:,20,20])
tscr_model=np.zeros(length)

#inc=0                
#for line in lines:
#dataset=open_url(line)
#print 'Dataset ', lines[1]
#      print dataset
#print 'Tmaxscr long request '
#tscrmax=dataset.tmaxscr.array[:,20,20]
#tscrmax=np.reshape(tscrmax,(length,1))


time=[]
tscrmax=[]

for line in lines:
    print "Line ", line
    dataset=open_url(line)
    print 'Tmaxscr long request ' 
    tscrmax_temporary=dataset.tmaxscr.array[:,20,20]
    time_offset_string=dataset.time.attributes['units']
   
    time_offset=re.search('\d\d\d\d-\d\d-\d\d', time_offset_string).group()
    year=float(time_offset[0:4])
    month=float(time_offset[5:7])
    print year, month
    time_temp=dataset.time[:]
#    time_temp = np.array(time_temp)/(24*60*365)+ year + month/(30*24*60)
    time_temp = np.array(time_temp)/(24*60*360)+ year + (month-1)/(12)

    time.extend(time_temp)
    tscrmax.extend(tscrmax_temporary[:,0,0])
    
#
# from the web apply scale factors for this variable and make in kelvin
#
tscr_model=0.005078125*np.array(tscrmax)+262.5
print 'Got all of Tmaxscr'
#      tscr=tscr+tscrmonthmax
#
# convert to degrees C
#
#tscr_celsius=tscr_model-273
tscr_celsius=tscr_model-273*np.ones(np.shape(tscr_model))
#
#
# now plot the results
#
# convert time to fractional years from minutes (from metadata)
#
#new_time= np.array(time)/(24*60*365)+ 1960
#
close('all')
hold(False)
#upper_bound=tscr_mean+tscr_rms
#lower_bound=tscr_mean-tscr_rms
plot(time[3::4],tscr_celsius[3::4],'g-',linewidth=2)
hold(True)
#plot(upper_bound, 'g--', linewidth=1)
#plot(lower_bound, 'g--', linewidth=1)
xlabel('Years ')
ylabel('Temperature T max screen C')

# save the plot
