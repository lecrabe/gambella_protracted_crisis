####################################################################################
####### Object:  Prepare names of all intermediate products                 
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/06/05                                           
####################################################################################

####################################################################################
#######          GLOBAL ENVIRONMENT VARIABLES
####################################################################################
options(stringsAsFactors=FALSE)

rootdir <- "/home/dannunzio/Documents/k3_safe/"

rawimgdir <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/k3_safe/"

t1_dir    <- paste0(rootdir,"input_images/")
t2_dir    <- paste0(rootdir,"input_images/")

tile <- "aoi"

training_dir <- paste0(rootdir,"pbs_aoi/")
trainmanual_dir <- paste0(rootdir,"training_manual/")
dem_dir      <- paste0(rootdir,"dem_aoi/")
result_dir   <- paste0(rootdir,"results/")
cloud_dir    <- paste0(rootdir,"cloud_mask/")
field_dir    <- paste0(rootdir,"field_data/")
comb_dir     <- paste0(result_dir,"")

dem_input    <- paste0(dem_dir,"srtm_elev_30m_aoi.tif")
slp_input    <- paste0(dem_dir,"srtm_slope_30m_aoi.tif")
asp_input    <- paste0(dem_dir,"srtm_aspect_30m_aoi.tif")

train_input  <- paste0(training_dir,"pbs_gambella_s2.tif")

plot_shp     <- paste0(field_dir,"")
agb_data     <- paste0(field_dir,"")

####################################################################################
#######          PARAMETERS
####################################################################################
spacing_km  <- 50   # UTM in meters, Point spacing in grid for unsupervised classification
th_shd      <- 30   # in degrees (higher than threshold and dark is mountain shadow)
th_wat      <- 15   # in degrees (lower than threshold is water)
rate        <- 100  # Define the sampling rate (how many objects per cluster)
minsg_size  <- 10   # Minimum segment size in numbers of pixels

thresh_imad <-10000 # acceptable threshold for no_change mask from IMAD
thresh_gfc  <- 70   # tree cover threshold from GFC to define forests

nb_chdet_bands <- 3 # Number of common bands between imagery for change detection

nb_clusters <- 50   # Number of clusters in the KMEANS classification

train_wat_class <- 5  # class for water
train_shd_class <- 0  # class for shadows

####################################################################################
#######          TRAINING DATA LEGEND
####################################################################################
legend <- read.table(paste0(training_dir,"legend.txt"))
names(legend) <- c("item","alpha","value","class","color")

legend$class <- gsub("label=","",x = legend$class)
legend$class <- gsub("\"","",x = legend$class)

legend$value <- gsub("value=","",x = legend$value)
legend$value <- gsub("\"","",x = legend$value)

legend <- legend[,3:4]

nbclass <- nrow(legend)

legend$value <- as.numeric(legend$value)
