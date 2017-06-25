####################################################################################
####### Object:  Processing chain                
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/06/05                                      
####################################################################################

# ############# Loop through all available quarters
# for(quarter in list.files(rootdir)){
#   dir_qi <- paste0(rootdir,quarter,"/")
#   
#   ############# List Dates available for the quarter
#   list_acqu <- list.files(path=dir_qi)
#   
#   for(date in list_acqu){
#     dir_qi_li <- paste0(dir_qi,date,"/")
#     
#     ############# List all archives available for the date
#     list_zip <- list.files(path = dir_qi_li,pattern = ".zip")
#     
#     ############# Unzip each archive in the folder
#     for(zip in list_zip){
#       
#       system(sprintf("echo A | unzip %s -d %s",
#                      paste0(dir_qi_li,zip),
#                      paste0(dir_qi_li)
#       ))
#       ##### End of the unzipping loop
#     }
#     
#     ############# List all bands available in all imagery for the date
#     list_b <- list.files(path=dir_qi_li,pattern=glob2rx("K3*.TIF"))
#     
#   }  #### End of the Date loop
# }  #### End of the Quarter loop


##########################################################################################
#### Create index of existing imagery

# setwd(rawimgdir)
# 
# system(sprintf("gdaltindex %s %s",
#                paste0(workdir,"imagery_index/index_B.shp"),
#                paste0("*/*/K3*PB.TIF")
#                ))
# 
# 
# index <- readOGR(paste0(workdir,"imagery_index/index_B.shp"),"index_B")
# tt <- data.frame(t(data.frame(strsplit(index@data$location,"/"))))
# 
# index@data$quarter <- tt[,1]
# index@data$date    <- tt[,2]
# index@data$image   <- tt[,3]
# 
# plot(index[index@data$quarter == "K3A_1st_quarter_images",])
# lines(index[index@data$quarter == "K3A_2nd_quarter_images",],col="red")
# 
# ##########################################################################################
# #### Read camp limits
# camps <- readOGR(paste0(workdir,"camps_aoi/Gambella_camps_7-5km_buffer_center.shp"),"Gambella_camps_7-5km_buffer_center")
# cmp_utm <- spTransform(camps,proj4string(index))
# 
# lines(cmp_utm,col="blue")
# 
# cmp_utm$Name <- c("Kule_Tierkidi","Pugnido","Jewi")
# 
# ##########################################################################################
# #### Add camp attribute to the index file
# index@data$camp <- over(x = index,y=cmp_utm)$Name
# 
#write.dbf(index@data,paste0(workdir,"imagery_index/index_B.dbf"))
index <- readOGR(paste0(workdir,"imagery_index/index_B.shp"),"index_B")

quarter_date <- index@data[index@data$quarter == "K3A_2nd_quarter_images" & index@data$camp == "Pugnido",]

(prints <- quarter_date$location)
print <- prints
paths <- unique(paste0(quarter_date[,c("quarter")],"/",quarter_date[,c("date")],"/"))