
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
dirViewerCurrent<-paste0(dirViewer,'viewer_current_season_shapes/')

#-R data files¢
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



#Set Parameters
CURRENT_YEAR<-2022  #Year that Planting Season Starts
MONTH<-2  #Month when forecasts start, 2 for Kenya & Somalia Long,  9 for K & Somalia short, 10 for Malawi
DEKAD<-3
MODEL<-'ET'
PRODUCT<-'Maize'    #'Maize'  #Sorghum
SEASON<-'S1'  #SET TO S1 FOR 'LONG' AND 'S2' FOR SHORT- NEED THIS TO WRITE OUT TO DIRECTORIES



# Ingest Clean Data Frames ------------------------------------------------
setwd(dirRdata)
load('00_viewer_data_clean_names.Rdata')

#--x2 Check when Forecast Starts by Country and Season
#table(d$country,d$season,d$f_start)

#--Filter and Select Variables
dfs<-dplyr::filter(d,product==PRODUCT,out.of.sample==2)
dfs<-dplyr::filter(dfs,model==MODEL)
dfs<-dplyr::select(dfs,-product,-out.of.sample)


#--Filter for Current Period
dfsc<-dplyr::filter(dfs,year >= CURRENT_YEAR,f_start>= MONTH, dekad %in% DEKAD)  #current forecast  

##Test if forecast crosses calendar year and exclude forecasts from prior year ##
#Still Working on this
# Need to make we don't get forecasts from prior year-- Only a concern for Malawi
nyears<-length(unique(dfsc$year))
if(nyears>1){
  min_year<-min(dfsc$year)
  dfsc<-dplyr::filter(dfsc,!(year==min_year & month<MONTH)) #no forecasts from end of prior ag-year
}


# Forecasts ---------------------------------------------------------------
dfsc<-dplyr::filter(dfsc,variable %in% c('yield_fcst_high_p10','yield_fcst_low_p10','yield_fcst_p10')) #grab the percent of 10 year mean forecast
dfsc<-dplyr::select(dfsc,fnid:season,model,month,dekad,variable,value)

dfsc$value<-if_else(dfsc$value<0,0,dfsc$value)  #if forecast is negative, change to 0


#--Recode Variables for Shorter Names
dfsc$variable<-str_replace(dfsc$variable,'yield_fcst_','')
dfsc$variable<-str_replace(dfsc$variable,'p10','f')
dfsc$variable<-str_replace(dfsc$variable,'_','')
dfsc$variable<-str_replace(dfsc$variable,'high','hi')
dfsc$variable<-str_replace(dfsc$variable,'low','lo')



#--Convert to Wide Format
dfw<-pivot_wider(dfsc,names_from=c(variable,year,month,dekad),values_from=value,names_sep="",values_fill=NA)


fun.nl(dfw)


# Read in a Shapefile and Join with Shape ---------------------------------
setwd(dirViewer)

dshp<-st_read('viewer_data.shp')
dshp<-dplyr::select(dshp,FNID,ADMIN0)
#dshp$ADMIN2<-dshp$ADMIN1



sdfc<-fun.spjoin(dshp,dfw)


# Write Out ---------------------------------------------------------------
dirCur<-paste0(dirViewerCurrent,MODEL,'/',SEASON,'/',PRODUCT,'/')  #directory for current season forecasts

setwd(dirCur)
#--PUT L/S PREFIX HERE BASED ON SEASON
if(SEASON=='S1'){PRE<-'L_'}
if(SEASON=='S2'){PRE<-'S_'}

filnam<-paste0(PRE,'current_fcast_',MODEL,'.shp')
st_write(sdfc,filnam,delete_dsn=TRUE)


