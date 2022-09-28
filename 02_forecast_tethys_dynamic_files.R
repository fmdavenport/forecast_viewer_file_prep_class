
#-------------------Base Setup--------------------------------------------------
rm(list=ls())



#---Set Project Directories

##--FIND THE PATH TO YOUR WORKING DIRECTORY-
##-IF YOU DON'T KNOW HOW- GO TO SESSION->SET WORKING DIRECTORY->CHOOSE DIRECTORY-> ##

dirBase<-'~/git/forecast_viewer_file_prep_class/'



#-Viewer Data Inputs and Outputs
dirViewer<-paste0(dirBase,'viewer/')
dirViewerOutStatic<-paste0(dirViewer,'viewer_static_shapes/')
dirViewerDynamic<-paste0(dirViewer,'viewer_dynamic_shapes/')

#-R data files
dirRdata<-paste0(dirBase,'rdata/')

library(stringr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(sf)

#========================================================================================

##-- Source Custom Functions
setwd(dirBase)  #set this to where scripts are located
source('999_forecast_tethys_custom_functions.R')




##-- SET UP PARAMETERS FOR SEASON, DEKAD, PRODUCT,and MODEL
SEASON<-'L'  #'L"
DEKADS_HIST<-c(3)  #We will focus on the 3rd dekad
PRODUCT<-'Maize'     #'Maize'  #Sorghum
MODEL<-'GB'  #'ET'

# Ingest Main CSV ---------------------------------------------------------
setwd(dirRdata)
load('00_viewer_data_clean_names.Rdata')

# Filter out for Key Variables
d<-filter(d,model==MODEL)
d<-filter(d,product==PRODUCT)
d<-filter(d,season==SEASON)
d<-filter(d,dekad %in% DEKADS_HIST)

# Historical Yield Forecasts ----------------------------------------------
fcast<-'yield_fcst'  #prefix for most yield variables
dfs<-filter(d,variable==fcast)
dfs<-droplevels(dfs)
dfs$value<-if_else(dfs$value<0,0,dfs$value)  #if negative values, make them 0
dfs<-dplyr::select(dfs,fnid:dekad,var_alias,out.of.sample,value)

#--Seperate and Merge Out of Sample and Model Forecasts
dfs1<-filter(dfs,out.of.sample==1) #forecasts done with 1 year ahead
dfs2<-filter(dfs,out.of.sample==2) #forecasts and hind casts done with current forecast model
dfs2<-filter(dfs2,year>=min(dfs1$year)) #only look at hind casts within same window as 1 year ahead

#Custom Function to reformat historical forecast frames
# This is pivot_wider with some convenience functions
fun.dfs.format<-function(dfs){
  dfs$var_alias<-'f'
  dfs$value<-round(dfs$value,3)
  
  dfw<-pivot_wider(dfs,names_from=c(var_alias,year,month,dekad),values_from=value,names_sep="",values_fill=NA)
  
  dfw<-dplyr::select(dfw,-out.of.sample)
  
  return(dfw)
  }

dfw<-fun.dfs.format(dfs1)  #standard historical forecasts
dfw2<-fun.dfs.format(dfs2) #hindcasts

#--Check the colunm names
fun.nl(dfw)
fun.nl(dfw2)

# Historical Yield Forecasts by Percent of Last 10 Years ----------------------------------------------


#Set Up Forecasts and Intervals Names
fcast_varsp10<-paste0(fcast,'_p10')

fcast_varsp10_low<-paste0(fcast,'low','_p10')
fcast_varsp10_high<-paste0(fcast,'high','_p10')

fcast_monthly<-c(fcast_varsp10,fcast_varsp10_low,fcast_varsp10_high)


#Select Variables

dfs<-filter(d,variable %in% c(fcast_monthly))
dfs<-droplevels(dfs)
dfs$value<-if_else(dfs$value<0,0,dfs$value)  #if there are negative forecasts, make them 0
dfs<-dplyr::select(dfs,fnid:dekad,var_alias,out.of.sample,value)
dfs<-filter(dfs,out.of.sample==1)

dfs$var_alias<-'f'
dfs$value<-round(dfs$value,3)


dfwp<-pivot_wider(dfs,names_from=c(var_alias,year,month,dekad),values_from=value,names_sep="",values_fill=NA)

dfwp<-dplyr::select(dfwp,-out.of.sample)


# Historical Yield Error --------------------------------------------------
dfe<-filter(d,variable==paste0(fcast,'_error'))
dfe<-droplevels(dfe)
dfe<-dplyr::select(dfe,fnid:dekad,var_alias,out.of.sample,value)
dfe<-filter(dfe,out.of.sample==1) #just focus on out of sample forecasts

dfe$var_alias<-'e'
dfe$value<-round(dfe$value,3)


dfe<-pivot_wider(dfe,names_from=c(var_alias,year,month,dekad),values_from=value,names_sep="")

dfe<-dplyr::select(dfe,-out.of.sample)




# MAPE Scores -------------------------------------------------------------
dmp<-dplyr::filter(d,variable=='yield_mape')
dmp<-dplyr::filter(dmp,out.of.sample==1)  
dmp<-dplyr::select(dmp,fnid:admin1,season,month:dekad,value)
dmp$value<-round(dmp$value,3)
dmp$var_alias<-'mp'
dmp<-pivot_wider(dmp,names_from=c(var_alias,month,dekad),values_from=value,names_sep="_")


# Read in a Shapefile and Join with Shape ---------------------------------
setwd(dirViewer)
dshp<-st_read('viewer_data.shp')
dshp<-dplyr::select(dshp,FNID,ADMIN0)



#--Current and Historical Forecasts and Errors
sdf<-fun.spjoin(dshp,dfw)
sdf2<-fun.spjoin(dshp,dfw2)

sdfp<-fun.spjoin(dshp,dfwp)
sde<-fun.spjoin(dshp,dfe)

#--MAPE Scores-----
sdmp<-fun.spjoin(dshp,dmp)

# Write Out ---------------------------------------------------------------
if(SEASON=='L'){DIR_sub<-'S1/'} #Main or long rains season
if(SEASON=='S'){DIR_sub<-'S2/'} # Secondary or Short rains season

#-Different Sub Directories if Product not Maize
DIR_sub<-paste0(DIR_sub,PRODUCT,'/')


#-Write Out to Dynamic Directories
setwd(paste0(dirViewerDynamic,MODEL,'/',DIR_sub))

st_write(sdf,paste0(SEASON,'_fcast_',MODEL,'.shp'),delete_dsn=TRUE)
st_write(sdf2,paste0(SEASON,'_fcast_',MODEL,'_HIND.shp'),delete_dsn=TRUE)
st_write(sdfp,paste0(SEASON,'_fcast_',MODEL,'_percent.shp'),delete_dsn=TRUE)

st_write(sde,paste0(SEASON,'_fcast_error_',MODEL,'.shp'),delete_dsn=TRUE)
st_write(sdmp,paste0(SEASON,'_fcast_MAPE_',MODEL,'.shp'),delete_dsn=TRUE)

