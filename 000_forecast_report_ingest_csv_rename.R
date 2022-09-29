#-------------------Base Setup--------------------------------------------------
rm(list=ls())

LAPTOP<-FALSE #WORKING ON LAPTOP?

#---Set Project Directories
dirBase<-'/Volumes/GoogleDrive/'
dirBaseL<-'/Volumes/GoogleDrive-116109725918193733454/' #diff on Laptop?

if(LAPTOP==TRUE){dirBase<-dirBaseL}

#---Set Project Directories

##--FIND THE PATH TO YOUR WORKING DIRECTORY-
##-IF YOU DON'T KNOW HOW- GO TO SESSION->SET WORKING DIRECTORY->CHOOSE DIRECTORY-> ##

dirBase1<-paste0(dirBase,"Shared drives/Forecast Viewer/")
dirBase2<-paste0(dirBase,'Shared drives/CHC Team Drive /')

#dirBase<-"~/git/forecast_viewer_file_prep_class/"
dirGit<-"~/git/forecast_viewer_file_prep_class/"



#-Viewer Data Inputs and Outputs
dirViewer<-paste0(dirBase1,'viewer/')
dirViewerOutStatic<-paste0(dirViewer,'viewer_static_shapes/')
dirViewerDynamic<-paste0(dirViewer,'viewer_dynamic_shapes/')

#-R data files
#dirRdata<-paste0(dirBase,'rdata/')
dirProj<-paste0(dirBase2,'project_machine_learning_forecasting/') #project directory
dirReport<-paste0(dirProj,'forecast_reporting/')
dirReportRdata<-paste0(dirReport,'forecast_reporting_Rdata/')

#-R data files
dirRdata<-dirReportRdata

library(stringr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(sf)

#========================================================================================




# Ingest Main CSV ---------------------------------------------------------
setwd(dirReportRdata)

#--NOT RUN--
#-Replace with download file instead?
#If you want to ingest "full" csv

#--TRY
#download.file("http://data.chc.ucsb.edu/people/dlee/viewer/viewer_data.csv",destfile='viewer_data.csv')
#--OR
#d<-read.csv("http://data.chc.ucsb.edu/people/dlee/viewer/viewer_data.csv")
d<-read.csv('viewer_data.csv')
#or download to your machine first
#--Not recommended on machines with <32G RAM

#--NOT RUN--
setwd(dirReportRdata)
# d<-filter(d,country=='Kenya')
save(d,file='000_viewer_data_csv.Rdata')

##--IF THE VIEWER_DATA.CSV WILL NOT LOAD OR TAKES TOO LONG TO LOAD- TRY THIS:
setwd(dirRdata)
load('000_viewer_data_csv.Rdata')  #MORE COMPRESSED VERSION OF FILE WITH JUST KENYA

d<-dplyr::select(d,-X)  #get rid of an extra colunm


#Recode Seasons with to have shorter and more consistent names
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

#-Create Variables f_start (month when a forecast starts) and s_start (month when a )
d<-dplyr::rename(d,f_start=forecast_start_month,s_start=season_start_month)

met_d<-base::date()  #add a date-time stamp to the metadata
setwd(dirRdata)
save(d,met_d,file='00_viewer_data_clean_names.Rdata')

#-----Let's Examine Some of the Variables in the CSV File
names(d)  #get the colunm names
head(d)  #look at the first five rows


#Lets discuss the variables and colunm names.
#Most should be self-explanatory
# The column 'variable' contains the forecast variables used in the viewer-- Let's examine the the content of that colunm

unique(d$variable)
#table(d$variable) #this might be slow on a laptop 
# The spread sheeet 'viewer_csv_variables_names_descriptions' (included in training materials)  describes most of the variables:  
#"https://docs.google.com/spreadsheets/d/1ezkOSMpGB0o0hO4adVuh-pJonYMnz8nH/edit?usp=sharing&ouid=116109725918193733454&rtpof=true&sd=true"



