
#-------------------Base Setup--------------------------------------------------
rm(list=ls())

LAPTOP<-TRUE #WORKING ON LAPTOP?

#---Set Project Directories
dirBase<-'/Volumes/GoogleDrive/'
dirBaseL<-'/Volumes/GoogleDrive-116109725918193733454/' #diff on Laptop?

if(LAPTOP==TRUE){dirBase<-dirBaseL}

#---Set Project Directories

##--FIND THE PATH TO YOUR WORKING DIRECTORY-
##-IF YOU DON'T KNOW HOW- GO TO SESSION->SET WORKING DIRECTORY->CHOOSE DIRECTORY-> ##

dirBase<-paste0(dirBase,"Shared drives/Forecast Viewer/")

#dirBase<-"~/git/forecast_viewer_file_prep_class/"
dirGit<-"~/git/forecast_viewer_file_prep_class/"



#-Viewer Data Inputs and Outputs
dirViewer<-paste0(dirBase,'viewer/')
dirViewerOutStatic<-paste0(dirViewer,'viewer_static_shapes/')
dirViewerDynamic<-paste0(dirViewer,'viewer_dynamic_shapes/')

#-R data files
#dirRdata<-paste0(dirBase,'rdata/')
dirBase2<-paste0(dirBase,'Shared drives/CHC Team Drive /')
dirProj<-paste0(dirBase2,'project_machine_learning_forecasting/') #project directory
dirReport<-paste0(dirProj,'forecast_reporting/')
dirReportRdata<-paste0(dirReport,'forecast_reporting_Rdata/')

library(stringr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(sf)

#========================================================================================

##-- Source Custom Functions
setwd(dirGit)  #set this to where scripts are located
source('999_forecast_tethys_custom_functions.R')


##-- SET UP PARAMETERS FOR SEASON DEKAD AND Product
SEASON<-'L'  #'S'  Pick a Season 
PRODUCT<-'Maize'     #'Maize'  #'Sorghum'  Pick a Crop

# Ingest Main Formatted Viewer File ---------------------------------------------------------
setwd(dirRdata)
load('00_viewer_data_clean_names.Rdata')



# Filter for Product and Season and then ditch product variable
d<-filter(d,product==PRODUCT)
d<-dplyr::select(d,-product)  #we exclude the 'product' from the col. names of the shapefile
d<-filter(d,season==SEASON)


#--Set up Names for Static Variables
static_vars<-c('area','prod','yield')
static_vars_obs<-paste0(static_vars,'_obs')
static_vars_mean<-paste0(static_vars,'_mean')
static_vars_mean_all<-paste0(static_vars_mean,'_all')
static_vars_mean_last10<-paste0(static_vars_mean,'_last10')

static_vars_all<-c(static_vars_obs,static_vars_mean,static_vars_mean_all,static_vars_mean_last10)

static_vars_all  #Have a look at the varialbes

# Create Annual Ag Stats Shapes -------------------------------------------

#--Select out Ag Stats
dt<-filter(d,variable %in% c(static_vars_all))
dt<-select(dt,fnid:season,variable,var_alias,value)
dt<-droplevels(dt)

dt<-dplyr::select(dt,fnid:season,var_alias,value)

#--Create a dataframe with just the mean values
dtm<-filter(dt,is.na(year)) # for mean values take out values that do not have years

#--Values by Year
dt<-filter(dt,!is.na(year))  #
head(dt)

dtw<-pivot_wider(dt,names_from=c(var_alias,year),values_from=value,names_sep="")  #MAKE A "WIDE" version to be a shapefile

#Examine the file-- there should be 1 row for each admin unit
head(dtw)

##-If above command gives duplicates Warning do the following:
# dups<-dt %>%
#   dplyr::group_by(fnid, country, admin1, admin2, var_alias, year, season) %>%
#   dplyr::summarise(n = dplyr::n(), .groups = "drop") %>%
#   dplyr::filter(n > 1L) 

#--Values Aggregated Over Time
dtm<-dplyr::select(dtm,-year)
dtmw<-pivot_wider(dtm,names_from=c(var_alias),values_from=value,names_sep="")


#--Check that Names are not more than 10 Characters Long
#--This function is in 999_forecast_tethys_custom_functions.R
#--It will print out the names of any colunms more than 10 characters long
fun.nl(dtw)
fun.nl(dtmw)


#--Use fun.join to create seperate lists for each main variable
#--This function is in 999_forecast_tethys_custom_functions.R
#--The resulting list will have 2 data frames- one named 'obs' for observed values and one names 'means' for mean values

### $obs has observations, $means has means
dsa<-fun.join(dtmw,dtw,var='a') #area stats
dsp<-fun.join(dtmw,dtw,var='p') #production stats
dsy<-fun.join(dtmw,dtw,var='y') #yield stats

#--Explore These
names(dsa)
head(dsa$means)
head(dsa$obs)

# Read in a Shapefile and Join with Shape ---------------------------------
setwd(dirViewer)
dshp<-st_read('viewer_data.shp')  #shapefile with the all of the admin units we forecast for
dshp<-dplyr::select(dshp,FNID,ADMIN0) #we will join on 'fnid'
#dshp$ADMIN2<-dshp$ADMIN1


#--Create Shapefiles
#--Observed Area, Production, and Yields 
#-- fun.spjoin() is standard 'inner_join'- but also prints the number of colunms and x2 checks in any colunm names are 2 long
#-- this is importance- shapefiles (usually) cannot have more than 256 colunms.  If colunm names are 2 long, they could get cut off and the viewer will not map them correctly.
sda<-fun.spjoin(dshp,dsa$obs)
sdp<-fun.spjoin(dshp,dsp$obs)
sdy<-fun.spjoin(dshp,dsy$obs)

#--Area, Production, and Yield Means
sdam<-fun.spjoin(dshp,dsa$means)
sdpm<-fun.spjoin(dshp,dsp$means)
sdym<-fun.spjoin(dshp,dsy$means)

# Write Out ---------------------------------------------------------------
##- These if() statements will make sure that the shapefile goes in the correct directory
if(SEASON=='L'){DIR_sub<-'S1/'} #Main or long rains season
if(SEASON=='S'){DIR_sub<-'S2/'} # Secondary or Short rains season

#-Make sure this goes in the correct product sub-directory
DIR_sub<-paste0(DIR_sub,PRODUCT,'/')

#-Write out to Static Directories
setwd(paste0(dirViewerOutStatic,DIR_sub))

#delete_dsn will delete the existing shapefile- if the shapefile does not exist, you will get a warning, but it will still write it out
st_write(sda,paste0(SEASON,'_area.shp'),delete_dsn=TRUE)  
st_write(sdp,paste0(SEASON,'_prod.shp'),delete_dsn=TRUE)
st_write(sdy,paste0(SEASON,'_yield.shp'),delete_dsn=TRUE)

st_write(sdam,paste0(SEASON,'_area_mn.shp'),delete_dsn=TRUE)
st_write(sdpm,paste0(SEASON,'_prod_mn.shp'),delete_dsn=TRUE)
st_write(sdym,paste0(SEASON,'_yield_mn.shp'),delete_dsn=TRUE)

#----Explore the shapefiles
head(sda)
summary(sda)