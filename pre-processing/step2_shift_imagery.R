####################################################################################
####### Object:  Processing chain                
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/06/05                                      
####################################################################################

##########################################################################################
#### Shift imagery when necessary. Shift is VISUALLY ASSESSED (v1 and v2 in QGIS)

list_to_shift <- list.files(paste0(rawimgdir,paths[1]),pattern=glob2rx("K3*.TIF"))

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


