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
#     ############# Convert each band into Byte
#     for(band in list_b){
#       print(band)
#       system(sprintf("gdal_translate -scale -ot Byte -co COMPRESS=LZW %s %s",
#                      paste0(dir_qi_li,band),
#                      paste0(dir_qi_li,"byte_",substr(band,1,nchar(band)-4),".tif")
#       ))
#     }  #### End of the Band loop
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


##########################################################################################
#### Shift imagery when necessary. Shift is VISUALLY ASSESSED (v1 and v2 in QGIS)


#list_to_shift <- list.files(paste0(rawimgdir,paths[1]),pattern=glob2rx("K3*.TIF"))
list_no_shift <- list.files(paste0(rawimgdir,paths),pattern=glob2rx("K3*.TIF"))

v1 <- c(633252,835673,633256,835675)
v2 <- c(633314,835687,633317,835688)

shift_x <- average(v1-v2)[1,3]
shift_y <- average(v1-v2)[2,4]

for(im in list_to_shift){
  print(file <- paste0(rawimgdir,paths[1],im))
  
  e <- extent(raster(file))
  system(sprintf("gdal_translate -co COMPRESS=LZW -a_ullr %s %s %s %s %s %s",
                 e@xmin+61,
                 e@ymax+13,
                 e@xmax+61,
                 e@ymin+13,
                 file,
                 paste0(dirname(file),"/shift_",basename(file))
  ))
}



##########################################################################################
#### Delineate clouds for each archive


##########################################################################################
#### USE THE SHIFTED ARCHIVES, RASTERIZE CLOUDS AND MASK OUT

for(print in list_to_shift[grep("_PB.TIF",list_to_shift)][2]){
  base <- substr(basename(print),1,nchar(basename(print))-7)
  path <- paste0(rawimgdir,paths)[1]
  
  ###################################################################################
  #######          RASTERIZE CLOUD MASK (done by hand on the BLUE band)
  ###################################################################################
  system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
                 paste0(cloud_dir,"cloud_mask_shift_",base,"_PB.shp"),
                 paste0(path,print),
                 paste0(cloud_dir,"cloud_mask_shift_",base,".tif"),
                 "id"
  ))
  
  ###################################################################################
  #######          Mask each band to create a GoodData band
  ###################################################################################
  for(band in c("B","G","N","R")){
    system(sprintf("gdal_calc.py -A %s -B %s --outfile=%s --co COMPRESS=LZW --calc=\"%s\"",
                   paste0(cloud_dir,"cloud_mask_shift_",base,".tif"),
                   paste0(path,"/","shift_",base,"_P",band,".TIF"),
                   paste0(path,"/","gd_shift_",base,"_P",band,".tif"),
                   "(1-A)*B"))
  }
}

##########################################################################################
#### USE THE ORIGINAL ARCHIVES, RASTERIZE CLOUDS AND MASK OUT

for(print in list_no_shift[grep("_PB.TIF",list_no_shift)][1]){
  base <- substr(basename(print),1,nchar(basename(print))-7)
  path <- paste0(rawimgdir,paths)[1]
  
  # ###################################################################################
  # #######          RASTERIZE CLOUD MASK (done by hand on the BLUE band)
  # ###################################################################################
  # system(sprintf("oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
  #                paste0(cloud_dir,"cloud_mask_",base,"_PB.shp"),
  #                paste0(path,print),
  #                paste0(cloud_dir,"cloud_mask_",base,".tif"),
  #                "id"
  # ))

  # ###################################################################################
  # #######          Mask each band to create a GoodData band
  # ###################################################################################
  for(band in c("B","G","N","R")){
    
    min_image <- 500
    
    system(sprintf("gdal_calc.py -A %s -B %s --outfile=%s --NoDataValue=0 --co COMPRESS=LZW --calc=\"%s\"",
                   paste0(cloud_dir,"cloud_mask_",base,".tif"),
                   paste0(path,"/",base,"_P",band,".TIF"),
                   paste0(path,"/","gd_",base,"_P",band,".tif"),
                   paste0("(1-A)*(B>",min_image,")*B")
                   ))
  }
}

path1 <- paste0(rawimgdir,paths)[1]
path2 <- paste0(rawimgdir,paths)[2]

quarter <- paste0(rawimgdir,unique(paste0(quarter_date[,c("quarter")],"/")))
date <- 20170307
band <- "B"
for(band in c("B","G","N","R")){
  e <- extent(raster(paste0(path2,"merge_",date,"_gd_P",band,".tif")))
  
  system(sprintf("gdal_translate -a_nodata 0 -co COMPRESS=LZW -projwin %s %s %s %s %s %s",
                 e@xmin,
                 e@ymax,
                 e@xmax,
                 e@ymin,
                 paste0(path1,"gd_K3A_20170204110457_10299_00079197_L1G_P",band,".tif"),
                 paste0(path1,"tmp_gd_K3A_20170204110457_10299_00079197_L1G_P",band,".tif")
  ))
  

  system(sprintf("gdal_calc.py -A %s -B %s --outfile=%s --NoDataValue=0 --co COMPRESS=LZW --calc=\"%s\"",
                 paste0(path2,"merge_",date,"_gd_P",band,".tif"),
                 paste0(path1,"tmp_gd_K3A_20170204110457_10299_00079197_L1G_P",band,".tif"),
                 paste0(path2,"all_merge_",date,"_gd_P",band,".tif"),
                 paste0("A+(A==0)*B")
  ))
  
  # system(sprintf("gdal_merge.py -n 0 -co COMPRESS=LZW -v -o %s %s %s",
  #              paste0(path2,"all_merge_",date,"_gd_P",band,".tif"),
  #              paste0(path2,"merge_",date,"_gd_P",band,".tif"),
  #              paste0(path1,"gd_K3A_20170204110457_10299_00079197_L1G_P",band,".tif")
  # ))

}

aoi <- c(634162.94331,850232.08961,640230.204777,845113.194813)
setwd(rawimgdir)

list <- list.files(".",pattern=glob2rx("aoi*.TIF"),recursive = T)

for(file in list){
  base <- basename(file)
  path <- dirname(file)
  system(sprintf("gdal_translate -co COMPRESS=LZW -projwin %s %s %s %s %s %s",
                 aoi[1],
                 aoi[2],
                 aoi[3],
                 aoi[4],
                 file,
                 paste0(path,"/tmp_aoi_",base)
  ))
}

for(band in c("B","G","N","R")){
  system(sprintf("gdal_merge.py -n 0 -co COMPRESS=LZW -v -o %s %s %s",
               paste0("K3A_2nd_quarter_images/aoi_K3A_20170302111649_10692_L1G_P",band,".TIF"),
               paste0("K3A_2nd_quarter_images/20170307/tmp_aoi_K3A_20170302111649_10692_00004060_L1G_P",band,".TIF"),
               paste0("K3A_2nd_quarter_images/20170307/tmp_aoi_K3A_20170302111649_10692_00025151_L1G_P",band,".TIF")
  ))
  
}
system(sprintf("gdal_merge.py -n 0 -separate -co COMPRESS=LZW -v -o %s %s ",
               paste0("K3A_1st_quarter_images/merge_aoi_time1.TIF"),
               paste0("K3A_1st_quarter_images/aoi_*.TIF")
))

system(sprintf("gdal_merge.py -n 0 -separate -co COMPRESS=LZW -v -o %s %s ",
               paste0("K3A_2nd_quarter_images/merge_aoi_time2.TIF"),
               paste0("K3A_2nd_quarter_images/aoi_*.TIF")
))

# ###################################################################################
# #######          DEM
# ###################################################################################
# for(zip in list.files(dem_dir)){
# system(sprintf("echo A | unzip %s -d %s",
#                paste0(dem_dir,zip),
#                paste0(dem_dir)
# ))
# }
# 
# dem_input <- paste0(dem_dir,"srtm_elev_30m_aoi.tif")
# slp_input <- paste0(dem_dir,"srtm_slope_30m_aoi.tif")
# asp_input <- paste0(dem_dir,"srtm_aspect_30m_aoi.tif")
# 
# 
# system(sprintf("gdal_merge.py -v -o %s %s",
#                paste0(dem_dir,"tmp_dem.tif"),
#                paste0(dem_dir,"*.hgt")
# ))
# 
# 
# 
# 
# ###################################################################################
# #######          Compute slope
# system(sprintf("gdaldem slope -co COMPRESS=LZW %s %s",
#                paste0(dem_dir,"tmp_dem.tif"),
#                paste0(dem_dir,"tmp_slope.tif")
#                ))
# 
# ###################################################################################
# #######          Compute aspect
# system(sprintf("gdaldem aspect -co COMPRESS=LZW %s %s",
#                paste0(dem_dir,"tmp_dem.tif"),
#                paste0(dem_dir,"tmp_aspect.tif")
# ))
# 
# system(sprintf("oft-clip.pl %s %s %s",
#                paste0(training_dir,"pbs_gambella_s2.tif"),
#                paste0(dem_dir,"tmp_dem.tif"),
#                paste0(dem_dir,"tmp_dem_aoi.tif")
# ))
# 
# system(sprintf("oft-clip.pl %s %s %s",
#                paste0(training_dir,"pbs_gambella_s2.tif"),
#                paste0(dem_dir,"tmp_slope.tif"),
#                paste0(dem_dir,"tmp_slope_aoi.tif")
# ))
# 
# system(sprintf("oft-clip.pl %s %s %s",
#                paste0(training_dir,"pbs_gambella_s2.tif"),
#                paste0(dem_dir,"tmp_aspect.tif"),
#                paste0(dem_dir,"tmp_aspect_aoi.tif")
# ))
# 
# 
# system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
#                paste0(dem_dir,"tmp_slope_aoi.tif"),
#                slp_input
# ))
# 
# system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
#                paste0(dem_dir,"tmp_aspect_aoi.tif"),
#                asp_input
# ))
# 
# system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
#                paste0(dem_dir,"tmp_dem_aoi.tif"),
#                dem_input
# ))
# 
# system(sprintf("rm %s",
#                paste0(dem_dir,"tmp*.tif")
# ))
# 
# 
# 
