

# Custom Functions --------------------------------------------------------

#-- Test Colunm name and length
fun.nl<-function(df,filt=TRUE){  #filter out longer names?
  df2<-data.frame('colnames'=names(df))
  df2$name_len<-str_length(df2$colnames)
  
  if(filt==TRUE){df2<-filter(df2,name_len>10)}
  return(df2)
}


# Join Annual Observed with Long Term Means Together----------------------------------------------------
fun.join<-function(df1,df2,var='a'){
  df1<-dplyr::select(df1,fnid:admin1,starts_with(var))
  df2<-dplyr::select(df2,fnid:admin1,starts_with(var))
  #df<-inner_join(df1,df2)  #--used for joining together
  
  #-Strip out the identifier
  var_rep<-paste0(var,'_')
  
  #Shorten names and make them generic
  names(df1)<-str_replace(names(df1),var_rep,'') #these do not need a prefix
  names(df2)<-str_replace(names(df2),var_rep,'o')
  
  names(df2)<-str_replace(names(df2),'obs','') #take out the 'obs' prefix
  
  #--Check # of colunms and colunm names
  #print(paste(ncol(df),'colunms')) #print # of colunms
  #print(fun.nl(df)) #print colunm names >10 characters
  
  dflist<-list('means'=df1,'obs'=df2)
  
  return(dflist)
}

#--Conveince function for Joining Shape Files, Checking Colunm names, and number colunms
fun.spjoin<-function(shp,df){
  names(df)<-toupper(names(df))
  shp<-inner_join(shp,df)
  
  #--Check # of colunms and colunm names
  print(paste(ncol(shp),'colunms')) #print # of colunms
  print(fun.nl(shp)) #print colunm names >10 characters
  
  return(shp)
}

## End Custom Functions========================================================================================