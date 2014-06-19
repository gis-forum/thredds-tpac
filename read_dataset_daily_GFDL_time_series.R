library(ncdf)
library(stringr)

##build list of urls. Simple example - change climate models, decades, months here

list.of.urls <- c()

  for(model in c("CCSM4", "GFDL-CM3","CNRM-CM5") ){
  for(decade in c("1960","1970") ){
    for(month in c("01","02","03") ){
      path.for.file <- sprintf("http://cfa0.rdsi.tpac.org.au/thredds/dodsC/products/Daily/C96-5k_%s_rcp85/cfa-C96-5k_%s_rcp85.%s%s.nc", model, model, decade, month) 
      list.of.urls <- append(list.of.urls, path.for.file)
      print(path.for.file)
    }
  }
}

 
# set working directory
setwd("~R")

#use above or this approach
#load in list of target files as characters.  The "[[1]]' at the end save it as a single dataframe, not as a list of dataframes...
#list.of.urls <- read.table("Saved_URL_C96-5k_GFDL.txt",colClasses="character")[[1]]
#check it loads correctly
##print(list.of.urls)

#test it is possible to read in one file
dataset <- open.ncdf(list.of.urls[1]) ##lu: I get an error here, but it works for the guys at UTAS
##Error in R_nc_open: Invalid argument


print(dataset$var$tmaxscr$dim[[1]]$name)
long <- dataset$var$tmaxscr$dim[[1]]
	print(long)

print(dataset$var$tmaxscr$dim[[2]]$name)
lat <- dataset$var$tmaxscr$dim[[2]]
	print(lat)

print(dataset$var$tmaxscr$dim[[3]]$name)
time <- dataset$var$tmaxscr$dim[[3]]
	print(time)

start.time <- as.POSIXct(str_split(time$units, pattern=" ")[[1]][3], format="%Y-%m-%d", tz="")
if(str_split(time$units, pattern=" ")[[1]][1]=="minutes"){
	print(paste("Time is in: ",time$units))
	print(paste("Converting to 'seconds since...' for better compatability with R"))
		time.vals.in.secs <- time$vals*60
} else {
	print(paste("The value of time$units is not 'minutes since %Y-%m-%d %H:%M:%S', please check 'time$units' to confirm value and use a new script accordingly (i.e. save-as this one with a new name and alter that)."))
}

time.to.plot <- as.POSIXct(time.vals.in.secs, origin=start.time, tz="")

print(paste("So far we have only downloaded the 'catelog' of what is in the netcdf file.  To access the actual variables of interest we need to use the 'get.var.ncdf(nc,varid=var.name)' function/command. "))
print(paste("Lets extract 'Maximum screen temperature' "))
	#to find out which variables are available, simply type "dataset" variable into the console (or the name of your 'variable <- open.ncdf("filename")' if you haven't used 'dataset' like I did above)

# get the maximum temperature screen attributes
tmaxscr.att <- dataset$var$tmaxscr
# get the maximum temperature screen values per time-step
tmaxscr.vals <- get.var.ncdf(dataset, varid="tmaxscr")

# values have been compressed from 'float' to a less dense data format 'short' and need to be rescaled back into 'float' before use to maintain precision.  
	####-----NOTE----------####
	#R auotmatically applies rescaling and offset conversion from short to float, IF present in the original netcdf file.  
	# If you need to do it manually for some reason, it would look like this:   		

		#get the offset
			#tmaxscr.offset <- tmaxscr.att$addOffset
		
		#get the scale factor
			#tmaxscr.scalefactor <- tmaxscr.att$scaleFact
		
		#apply model to return 'short' to 'float'
			#tscr_model=tmaxscr.scalefactor*tmaxscr.vals+tmaxscr.offset

print(paste("Lets plot the first layer with values (which happens to be the 4th timestep)"))

image(
	x=tmaxscr.att$dim[[1]]$vals, 
	y=tmaxscr.att$dim[[2]]$vals, 
	z= tmaxscr.vals[,,4],
	xlab="Longitude",
	ylab="Latitude",
	main=paste(tmaxscr.att$longname, time.to.plot[4])
	)

#-----------------------------------------------------------------------------------
#given the successful test, load in all the files
#-----------------------------------------------------------------------------------

# set the target cell to plot through time - select a lat long by index position (useful?)
	lat.index <- 20
	    target.lat <- lat$vals[lat.index]
	long.index <- 20
		target.long <- long$vals[long.index]

# search for a single point BUT MUST MATCH values exactly. Look in the environment pane
  my.target.lat <- -37 
  my.target.lat.index <- which(lat$vals==my.target.lat)

# search for a region
  my.target.region.lat <- data.frame(min=-37,max=-36)
  my.target.region.long <- data.frame(min=146,max=147)
  my.target.region.lat.index <- which(
                                     lat$vals>=my.target.region.lat$min &
                                     lat$vals<=my.target.region.lat$max
                                     )

  my.target.region.long.index <- which(
                                     long$vals>=my.target.region.long$min &
                                     long$vals<=my.target.region.long$max
                                     )

#plot region
image(
  x=tmaxscr.att$dim[[1]]$vals[my.target.region.long.index], 
  y=tmaxscr.att$dim[[2]]$vals[my.target.region.lat.index], 
  z= tmaxscr.vals[my.target.region.long.index,my.target.region.lat.index,4],
  xlab="Longitude",
  ylab="Latitude",
  main=paste(tmaxscr.att$longname, time.to.plot[4])
)

# remove existing tmaxscr.year and time.year variables
rm(tmaxscr.year)
rm(time.year)

# process each monthly file in a loop to get timeseries of whole year
  
for(i in 1:length(list.of.urls) ){
    print(paste("File Number ", i))
    print(paste(list.of.urls[i]))
    print(paste("Extract 'Tmaxscr' through time at lat=", target.lat,"; long=", target.long))
	
	dataset <- open.ncdf(list.of.urls[i])
	#extract the all time-steps of Maximum screen temperature variable at the target location 
	tmaxscr.month.raw <- get.var.ncdf(
		dataset,  #variable of the netcdf categlog
		varid="tmaxscr",  #name of the target layer/level
		start=c(long.index,lat.index,1),  #first value of dimensions of interest.  In this case we only want a single point through time, so we give that single point as the index of the target point.  
		count=c(1,1,-1)  #This is the number of points in each dimension of interest.  We only want 1 longitiude and 1 latitude value, through all time-steps.  There is a special case where -1='all values of a dimension' instead of having to define exactly how many (such 10 time steps, 120 timesteps).  
		)

	
	
	#Not all time steps have values in these data files, only every 4th layer has values.  The others are all NA.  It is convenient to exclude these for plotting and analysis.  
	
	not.na.index <- which(is.na(tmaxscr.month.raw)==FALSE)

	tmaxscr.month <- tmaxscr.month.raw[not.na.index]
	
	#add these monthly values to the yearly values
	if(exists("tmaxscr.year")==TRUE){
		tmaxscr.year <- c(tmaxscr.year, tmaxscr.month)		
		} else {
		tmaxscr.year <- tmaxscr.month
		}

    #lat and long are the same for all files, as they are on the same grid, so as we have extract those above already, these dont need to be re-done.  

    #HOWEVER, each file has a different starting time or "time origin", so this needs to be found/calculated.  
    
    time <- dataset$var$tmaxscr$dim[[3]]
		start.time <- as.POSIXct(str_split(time$units, pattern=" ")[[1]][3], format="%Y-%m-%d", tz="")
		print(start.time)
		
			if(str_split(time$units, pattern=" ")[[1]][1]=="minutes"){
				print(paste("Time is in: ",time$units))
				print(paste("Converting to 'seconds since...' for better compatability with R"))
					time.vals.in.secs <- time$vals*60
			} else {
				print(paste("The value of time$units is not 'minutes since %Y-%m-%d %H:%M:%S', please check 'time$units' to confirm value and use a new script accordingly (i.e. save-as this one with a new name and alter that)."))
			}

			time.month.raw <- as.POSIXct(time.vals.in.secs, origin=start.time)
				print(head(time.month.raw))
			# but this is all timesteps, including those that are just NA's.  So we only those that match real values these with the tmaxscr values we have already.  
			time.month <- time.month.raw[not.na.index]
				print(head(time.month))
				if(exists("time.year")==TRUE){
					time.year <- c(time.year, time.month)		
					} else {
					time.year <- time.month
					}
	
	}

tmaxscr.celsius <- tmaxscr.year-273
fractional.year <- difftime(
	as.POSIXct(time.year),
	as.POSIXct(time.year)[1], 
	units="days"
	)/365

plot(
	fractional.year, 
	tmaxscr.celsius, 
	xlab="Time (Fractional year)",
	ylab=paste("Temperature *C"),  #if you are a LaTeX user, you can use latex commands in the figures labels, but only on your own computer.  NECTAR instances DO NOT have LaTeX installed, as it is too big and gobbles up all the working storage space.  
	type="l", 
	col="forestgreen"
	)
