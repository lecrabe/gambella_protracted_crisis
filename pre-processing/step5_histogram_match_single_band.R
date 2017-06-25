####################################################################################
####### Object:  Match histogram of 2 images and merge
####### AOI   :  Bangladesh
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/04/03                                        
####################################################################################

for(band in c("B","N","R")){
  
input1 <- paste0("K3A_2nd_quarter_images/20170307/merge_20170307_gd_P",band,".tif")
input2 <- paste0("K3A_2nd_quarter_images/20170204/gd_K3A_20170204110457_10299_00079197_L1G_P",band,".tif")

outdir <- dirname(input2)
base   <- basename(input2)

####### Read rasters and determine common intersection extent
r1 <- raster(paste0(input1))
r2 <- raster(paste0(input2))

e1 <- extent(r1)
e2 <- extent(r2)

####### Polygonize
poly_1 <- Polygons(list(Polygon(cbind(
  c(e1@xmin,e1@xmin,e1@xmax,e1@xmax,e1@xmin),
  c(e1@ymin,e1@ymax,e1@ymax,e1@ymin,e1@ymin))
)),1)

####### Polygonize
poly_2 <- Polygons(list(Polygon(cbind(
  c(e2@xmin,e2@xmin,e2@xmax,e2@xmax,e2@xmin),
  c(e2@ymin,e2@ymax,e2@ymax,e2@ymin,e2@ymin))
)),1)

####### Convert to SpatialPolygon
sp_poly_1 <- SpatialPolygons(list(poly_1))

####### Convert to SpatialPolygon
sp_poly_2 <- SpatialPolygons(list(poly_2))

####### Intersect both zones
sp_poly   <- intersect(sp_poly_1,sp_poly_2)

####### Shoot randomly points on the intersection, extract values from both rasters
pts <- spsample(sp_poly,n=500,"random")

h1 <- data.frame(extract(x = r1,y = pts))
h2 <- data.frame(extract(x = r2,y = pts))

#######  Put datasets together and exclude 10% and 90% quartiles
hh <- data.frame(cbind(h1,h2))
names(hh) <- c("X1","X2")

hh <- hh[!is.na(hh$X1),]
hh <- hh[!is.na(hh$X2),]

hh <- hh[hh$X1 > quantile(hh$X1,probs= seq(0,1,0.1))[2] & hh$X1 < quantile(hh$X1,probs= seq(0,1,0.1))[10],]
hh <- hh[hh$X2 > quantile(hh$X2,probs= seq(0,1,0.1))[2] & hh$X2 < quantile(hh$X2,probs= seq(0,1,0.1))[10],]

#######  GLM of dataset 1 vs dataset 2 and normalized raster 2 as output
glm12 <- glm(hh$X1 ~ hh$X2)

hh$residuals <- residuals(glm12)
hh$score<-scores(hh$residuals,type="z")

outlier <- hh[abs(hh$score)>2,]
plot(X2 ~ X1,hh,col="darkgrey")
points(X2 ~ X1,outlier,col="red")

summary(hh)
hh <- hh[abs(hh$score)<=2,]
glm12 <- glm(hh$X1 ~ hh$X2)

i12 <- glm12$coefficients[1]
c12 <- glm12$coefficients[2]


#######  Apply model to have a normalized input2
system(sprintf("gdal_calc.py -A %s --outfile=%s --NoDataValue=0 --co COMPRESS=LZW --calc=\"%s\"",
               input2,
               paste0(outdir,"/","norm_",base),
               paste0("(A>0)*(A*",c12,"+",i12,")")
               ))

}
