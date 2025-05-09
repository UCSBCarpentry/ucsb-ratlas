#############################################
# ep. 2

# overlays

# ggtitle starts in this lesson, 
# so we will start labeling our plots
# automagically when we overlay 
# elevation with hillshade

library(tidyverse)
library(terra)


# clean the environment and hidden objects
rm(list=ls())

# set up objects
current_episode <- 2

campus_DEM <- rast("source_data/campus_DEM.tif")
campus_DEM_df <- as.data.frame(campus_DEM, xy = TRUE, na.rm=FALSE)
# make the name logical:
names(campus_DEM_df)[names(campus_DEM_df) == 'greatercampusDEM_1_1'] <- 'elevation'

campus_bath <- rast("source_data/SB_bath.tif")
campus_bath_df <- as.data.frame(campus_bath, xy = TRUE, na.rm=FALSE)
# make the name logical:
names(campus_bath_df)[names(campus_bath_df) == 'Bathymetry_2m_OffshoreCoalOilPoint'] <- 'depth'


# Plotting Data Using Breaks
#################################
# lesson example bins / highlights Harvard Forest pixels > 400m.
# for us, let's highlight our holes.
summary(campus_DEM_df)



#############################
custom_bins <- c(-3, -.01, .01, 2, 3, 4, 5, 10, 40, 200)

campus_DEM_df <- campus_DEM_df %>% 
  mutate(binned_DEM = cut(elevation, breaks = custom_bins))

# there are < 20 pixels under zero
summary(campus_DEM_df$binned_DEM)

# there's sooooo few negative values that you can't see them
# on the histogram
ggplot() +
  geom_bar(data = campus_DEM_df, aes(binned_DEM)) +
  ggtitle("Histogram")


# but think about landscapes. elevation tends to 
# go up on a log scale from the coast
# log scale works better
# this shows that there's nothing at zero.
# and just a few negative pixels
ggplot() +
  geom_bar(data = campus_DEM_df, aes(binned_DEM)) +
  scale_y_continuous(trans='log10') +
  ggtitle("log10 histogram")


# let's go again with what we've learned
custom_bins <- c(-3, 0, 2, 5, 10, 25, 40, 70, 100, 150, 200)

campus_DEM_df <- campus_DEM_df %>% 
  mutate(binned_DEM = cut(elevation, breaks = custom_bins))

# this shows that sea level is at 2-5 ft
# that needs some explanation: in the challenge
ggplot() + 
  geom_raster(data = campus_DEM_df, aes(x=x, y=y, fill = binned_DEM)) +
  coord_quickmap() +
  ggtitle("Why is sea level 2-5 feet?")



# Challenge: Plot Using Custom Breaks
# ##################################

# use custom bins to figure out a good place to put sea level
# what is really 'zero' around here?

custom_bins_1 <- c(-3, 0, 4, 4.8, 5, 10, 25, 40, 70, 100, 150, 200)
custom_bins_2 <- c(-3, 0, 4.9, 5.1, 7.5, 10, 25, 40, 70, 100, 150, 200)

campus_DEM_df <- campus_DEM_df %>% 
  mutate(binned_DEM = cut(elevation, breaks = custom_bins_1))

ggplot() + 
  geom_raster(data = campus_DEM_df, aes(x=x, y=y, fill = binned_DEM)) +
  ggtitle("Where is sea level ?")
# it appears to be around 5 feet on our DEM.




# More Plot Formatting
# ############################# 


# this isn't so nice
ggplot() + 
  geom_raster(data = campus_DEM_df, aes(x=x, y=y, fill = binned_DEM)) +
  scale_fill_manual(values = terrain.colors(11)) +
  ggtitle("Where is sea level ?", 
          subtitle = "greens are too similar")


# let's seize more control of our bins
# like my_col in the lesson
coast_palette <- terrain.colors(11)

# set 4.9-5 ft a nice sea blue
coast_palette[2] <- "#1d95b3"
coast_palette[3] <- "#1c9aed"
coast_palette

# and make the negative numbers "red"
coast_palette[1] <- "red"

# but we can't see any underwaters.

ggplot() + 
  geom_raster(data = campus_DEM_df, aes(x=x, y=y, fill = binned_DEM)) +
  scale_fill_manual(values = coast_palette)+
  ggtitle("Last manual title?", subtitle="Can't see red")+
  coord_quickmap()

summary(campus_DEM_df$elevation)

# Challenge: Plot Using Custom Breaks
# ##################################

# x breaks
# Axis labels
# A plot title



# Layering Rasters
##############
# https://datacarpentry.github.io/r-raster-vector-geospatial/02-raster-plot.html#layering-rasters


# add in the hillshade layer
describe("source_data/campus_hillshade.tif")

campus_hillshade_df <- 
  rast("source_data/campus_hillshade.tif") %>% 
  as.data.frame(xy = TRUE)

campus_hillshade_df
str(campus_hillshade_df)

# plot the hillshade
ggplot() + 
  geom_raster(data = campus_hillshade_df, 
              aes(x=x, y=y, fill = hillshade)) +
  ggtitle("Hillshade")+
  coord_sf()

# ### Layering Rasters
# #############
# now plot the hillshade on top of the DEM:

# here is the first time the lesson uses
# a ggtitle. So here is the first time we will insert our function:

# make our ggtitles automagically #######
# set ggplot counter
current_ggplot <- 0

gg_labelmaker <- function(plot_num){
  gg_title <- c("Episode:", current_episode, " ggplot:", plot_num)
  plot_text <- paste(gg_title, collapse=" " )
  print(plot_text)
  current_ggplot <<- plot_num
  return(plot_text)
}
# every ggtitle should be:
# ggtitle(gg_labelmaker(current_ggplot+1))
# end automagic ggtitle           #######

# Data Tips
###############################

# turn off the legend with guide="none" or
# theme(legend.position = "none")
ggplot() + 
  geom_raster(data=campus_DEM_df, aes(x=x, y=y, fill = elevation)) +
  geom_raster(data = campus_hillshade_df, aes(x=x, y=y, alpha = hillshade)) +
  scale_alpha(range = c(0.05, 0.3), guide="none") +
  scale_fill_viridis_c() + 
  ggtitle(gg_labelmaker(current_ggplot+1)) +
  coord_quickmap()




# challenge:
# how many pixels are below 3.1 feet (1 m)?
below_3 <- apply(campus_DEM_df, 1, function(campus_DEM_df) any(campus_DEM_df < 3.12))
below_0 <- apply(campus_DEM_df, 1, function(campus_DEM_df) any(campus_DEM_df < 0))


# Count all pixels below 0
negatives <- campus_DEM_df %>% filter(elevation < 0)
nrow(negatives)  # this will give you the count

print(negatives)

# Count how many pixels are below 3.12 feet
below_3ft <- campus_DEM_df %>% filter(elevation < 3.12)
nrow(below_3ft)  # this will give you the count


# look at the values in the DEM
# I'm convinced < 3 ft should make an ok binned ggplot.
str(campus_DEM_df)
# when did elevation become so NA?


ggplot() + 
  geom_raster(data=campus_DEM_df, aes(x=x, y=y, fill = binned_DEM)) +
  geom_raster(data = campus_hillshade_df, aes(x=x, y=y, alpha = hillshade)) +
  scale_alpha(range = c(0.05, 0.6), guide="none") +
  ggtitle(gg_labelmaker(current_ggplot+1)) +
  coord_sf()



# that's too many. let's count them up tidily
campus_DEM_df %>% 
  group_by(elevation) %>% 
  count() %>% 
  head(20)

str(campus_DEM_df)

# still can't see them
 ggplot(campus_DEM_df) +
  geom_bar(aes(binned_DEM))


# Challenge: Create DTM & DSM for a 2nd set of rasters
# our challenge: 
# try the next zoom out? 
# that would be something like map 4

# Challenge: Make a 2-layer overlay for a 2nd set of rasters
# try the bathymetry (if we have a hillshade)
