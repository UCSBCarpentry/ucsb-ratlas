# R geospatial
# episodes 1

#############################################
# setup for each episode

library(tidyverse)
library(terra)

# setwd("C:/users/your_file_path")

# start fresh
rm(list=ls())

# set episode counter
# when we run lots of files, this will help us keep track
current_episode <- 1
#
############################################


#############################################
# ep. 1 narrative starts

# View Raster File Attributes
############

# get info about your first raster dataset
describe("source_data/campus_DEM.tif")

# Open a Raster in R
############

# make it into an object you can manipulate
campus_DEM <- rast("source_data/campus_DEM.tif")

# run the object, units are in feet
# 20 feet x 20 feet pixels
campus_DEM

# get summary of object, min and max make sense for UCSB
summary(campus_DEM)

# we know there's a bigger negative value
# than whatever shows here.
# so...

# we can force it to calculate on all pixels
summary(values(campus_DEM))


# or do that the tidy way with pipes
campus_DEM %>%  
  values() %>% 
  summary()

# to show the deepest pixel to be 2.3 deep.
# we're not sure 2.3 what

# ggplots require dataframes
# (if we remove the NA's that screws up the narrative later)
campus_DEM_df <- as.data.frame(campus_DEM, xy = TRUE, na.rm=FALSE)

# both summaries and str of the dataframe
# show you the name of the layer you'll need to 
# refer to. which is a long drag of a string to type:
str(campus_DEM_df)
summary(campus_DEM_df)

# for convenienve, we will always 
# change the elevation field named greatercampusdem_1_1 
# to elevation 
# we will stick to this naming convention throughout the lesson
names(campus_DEM_df)[names(campus_DEM_df) == 'greatercampusDEM_1_1'] <- 'elevation'

# the legend shows our name change
ggplot() + geom_raster(data = campus_DEM_df, 
              aes(x=x, y=y, fill = elevation)) +
  scale_fill_viridis_c() +
  coord_sf()



# Plotting Tip
############

# faster terra plot (terra::plot masks base::plot)
# and also doesn't force you to remember the name of
# the data layer
plot(campus_DEM)


# View Raster Coordinate Reference System (CRS) in R
############

# https://epsg.io/2874
crs(campus_DEM, proj = TRUE)
crs(campus_DEM)


# Calculate Raster Min and Max Values
############

# min and max values
minmax(campus_DEM)
# these are showing NaN now:
max(values(campus_DEM))

# Data Tip - Set min and max values
############

campus_DEM <- setMinMax(campus_DEM)

# Raster Bands
############
nlyr(campus_DEM)

str(campus_DEM)

# ### Dealing with Missing Data ###
############
# https://datacarpentry.github.io/r-raster-vector-geospatial/01-raster-structure.html

# NAs often wind up being the data
# around the edges but they don't have to be.

ggplot() +
  geom_raster(data = campus_DEM_df, aes(x=x, y=y, fill = elevation)) +
  scale_fill_viridis_c(na.value = "deeppink") 

# exactly how many NAs?
sum(is.na(campus_DEM_df$elevation))

# the lesson has a rgb illustration at this point:

######################

############
# challenge: look at a different raster's nodata values?
############

campus_bath <- rast("source_data/SB_bath.tif")
crs(campus_bath)
str(campus_bath)
colnames(campus_bath)
crs(campus_bath, proj = TRUE)
plot(campus_bath)


campus_bath_df <- as.data.frame(campus_bath, xy=TRUE, na.rm=FALSE)
str(campus_bath_df)

# does this one have NA's?
sum(is.na(campus_bath_df$Bathymetry_2m_OffshoreCoalOilPoint))
summary(campus_bath)

# you betcha.
# 69366 of them

# CHANGE THE bath name for convenience:
names(campus_bath_df)[names(campus_bath_df) == 'Bathymetry_2m_OffshoreCoalOilPoint'] <- 'depth'
str(campus_bath_df)


# Bad Data Values in Rasters
############

# Find Bad Data Values
###################

# the episode doesn't do this very well. It highlights
# values above 400m at Harvard.
# does our Batymetry have positive values?

# So for example: why would bathymetry have a max value of 1?
summary(campus_bath_df)

# histogram to look at the elevation distribution
ggplot()+
  geom_histogram(data=campus_bath_df, aes(depth))

# bin width warning so make some more bins
ggplot()+
  geom_histogram(data=campus_bath_df, aes(depth), bins = 40)

### bad data example goes here.

# both these warning messages tells us there's more going on.
# ie: values out of scale range

ggplot() +
  geom_histogram(data = campus_DEM_df, aes(elevation)) 
ggplot() +
  geom_histogram(data = campus_bath_df, aes(depth))

# crs() and str() don't tell us what bad data values are.

describe("source_data/SB_bath.tif")
# [61] "  NoData Value=nan" 
describe("source_data/campus_DEM.tif")
# [64] "  NoData Value=nan"


# Challenge:
# Explore metadata of the hillshade raster (campus_hillshade.tif)
describe("source_data/campus_hillshade.tif")

campus_hillshade <- rast("source_data/campus_hillshade.tif")
campus_hillshade_df <- as.data.frame(campus_hillshade)

str(campus_hillshade)
str(campus_hillshade_df)

# Create A Histogram of Raster Values
###################
str(campus_bath_df)

ggplot() +
  geom_histogram(data = campus_bath_df, aes(depth))+
  ggtitle("Histogram default bins")

ggplot() +
  geom_histogram(data = campus_bath_df, aes(depth), bins = 5)+
  ggtitle("Histogram 5 bins")

ggplot() +
  geom_histogram(data = campus_bath_df, aes(depth), bins = 20)+
  ggtitle("Histogram 20 bins")

# at some point, the positive values disappear from the visualization
# that's not helpful.

# Challenge: Explore Raster Metadata
###################