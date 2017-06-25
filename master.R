####################################################################################
####### Object:  Processing chain                
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/06/05                                       
####################################################################################

####### SET WHERE YOUR SCRIPTS ARE CLONED
clonedir <- "/home/dannunzio/Documents/scripts/scripts_k3/"

scriptdir <- paste0(clonedir,"process/")
p_procdir <- paste0(clonedir,"/pre-processing/")

####### SET WHERE YOUR PROCESSING DATA WILL BE CREATED AND STORED
rootdir <- "/home/dannunzio/Documents/k3_safe/"  

####### SET WHERE YOUR IMAGE DIRECTORY IS
rawimgdir <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/k3_safe/"

####################################################################################
#######          PACKAGES
####################################################################################
source(paste0(scriptdir,"load_packages.R"),echo=TRUE)


####################################################################################
#######          SET PARAMETERS
####################################################################################
source(paste0(scriptdir,"set_parameters_master.R"),echo=TRUE)


####################################################################################
##              RUN PRE-PROCESSING STEPS
####################################################################################
source(paste0(p_procdir,"step1_unpack imagery.R"),echo=TRUE)
source(paste0(p_procdir,"step2_shift_imagery.R"),echo=TRUE)
source(paste0(p_procdir,"step3_rasterize_cloud_mask_merge_in_data.R"),echo=TRUE)
source(paste0(p_procdir,"step4_prepare_DEM.R"),echo=TRUE)
source(paste0(p_procdir,"step5_histogram_match_single_band.R"),echo=TRUE)


####################################################################################
#######          CHANGE ACCORDINGLY TO PERIOD OF INTEREST
####################################################################################
time1       <- "q1"
time2       <- "q2"


t1_bands <- c(3,4,2) # NIR, RED, GREEN for Kompsat 3 data
t2_bands <- c(3,4,2) # because of alphabetical order in merge
 
source(paste0(scriptdir,"set_parameters_imad.R"),echo=TRUE)
source(paste0(scriptdir,"set_parameters_merge.R"),echo=TRUE)

setwd(rootdir)

################################################################################
## Run the change detection
source(paste0(scriptdir,"change_detection_OTB.R"),echo=TRUE)


################################################################################
## Run the classification for time 1
outdir  <- paste0(tiledir,"/time1/")
dir.create(outdir)
im_input <- t1_input

        source(paste0(scriptdir,"set_parameters_classif.R"),echo=TRUE)

        source(paste0(scriptdir,"prepare_training_data.R"),echo=TRUE)
        source(paste0(scriptdir,"supervised_classification.R"),echo=TRUE)

################################################################################
## Run the classification for time 2
outdir  <- paste0(tiledir,"/time2/")
dir.create(outdir)
im_input <- t2_input

        source(paste0(scriptdir,"set_parameters_classif.R"),echo=TRUE)

        source(paste0(scriptdir,"prepare_training_data.R"),echo=TRUE)
        source(paste0(scriptdir,"supervised_classification.R"),echo=TRUE)


################################################################################
## Merge date 1 and date 2 (uncomment necessary script)
# source(paste0(scriptdir,"merge_datasets_9403.R"),echo=TRUE)
# source(paste0(scriptdir,"merge_datasets_0316.R"),echo=TRUE)

################################################################################
## After running for 2 periods, combine periods
# source(paste0(scriptdir,"combine_3_dates.R"),echo=TRUE)

################################################################################
## Call field data and inject into LCC map to generate statistics and biomass maps
# source(paste0(scriptdir,"inject_field_data.R"),echo=TRUE)





