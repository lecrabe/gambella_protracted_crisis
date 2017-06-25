####################################################################################
####### Object:  Processing chain                
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/06/05                                      
####################################################################################


##########################################################################################
#### Delineate clouds for each archive, manually. cloud and shadow is 1, rest is 0

#list_to_shift <- list.files(paste0(rawimgdir,paths[1]),pattern=glob2rx("K3*.TIF"))
list_no_shift <- list.files(paste0(rawimgdir,paths),pattern=glob2rx("K3*.TIF"))

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
