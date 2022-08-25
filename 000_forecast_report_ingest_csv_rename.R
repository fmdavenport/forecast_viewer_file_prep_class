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




# Ingest Main CSV ---------------------------------------------------------
setwd(dirViewer)

##d<-read.csv('viewer_data.csv')


#--NOT RUN--
# setwd(dirRdata)
# d<-filter(d,country=='Kenya')
# save(d,file='000_viewer_data_csv_Kenya.Rdata')

##--IF THE VIEWER_DATA.CSV WILL NOT LOAD OR TAKES TOO LONG TO LOAD- TRY THIS:
setwd(dirRdata)
load('000_viewer_data_csv_Kenya.Rdata')  #MORE COMPRESSED VERSION OF FILE WITH JUST KENYA

d<-dplyr::select(d,-X)
#Recode Seasons
d$season<-recode_factor(d$season,Gu='L',Deyr='S',Long='L',Short='S',Main='L')


# Create Variable Aliases -------------------------------------------------
#Make Variable names shorter so that we can use them for shapefiles
d$variable<-str_replace(d$variable,'production','prod') #make consistent
d$var_alias<-d$variable
d$var_alias<-str_replace(d$var_alias,'area','a')
d$var_alias<-str_replace(d$var_alias,'production','p')
d$var_alias<-str_replace(d$var_alias,'prod','p')
d$var_alias<-str_replace(d$var_alias,'yield','y')
d$var_alias<-str_replace(d$var_alias,'fcst','f')
d$var_alias<-str_replace(d$var_alias,'last10','10')
d$var_alias<-str_replace(d$var_alias,'error','e')
d$var_alias<-str_replace(d$var_alias,'mean','mn')
d$var_alias<-str_replace(d$var_alias,'mape','mp')
d$var_alias<-str_replace(d$var_alias,'percent','pc')
d$var_alias<-str_replace(d$var_alias,'crop','cp')

#Reorder and rename to keep start month variables out of shapefiles
d<-dplyr::select(d,fnid:season,month,dekad,day,everything())
d<-dplyr::rename(d,f_start=forecast_start_month,s_start=season_start_month)

met_d<-base::date()  #add a date-time stamp to the metadata
setwd(dirRdata)
save(d,met_d,file='00_viewer_data_clean_names.Rdata')
