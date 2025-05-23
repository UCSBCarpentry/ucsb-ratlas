# ep 11
# "Manipulate raster data"
# vector - raster integration

# cropping rasters
getwd()

# library(raster)
library(tidyverse)
library(terra)
library(sf)
library(geojsonsf)
# new!
library(terrainr)
library(tidyterra)

# clean the environment and hidden objects
rm(list=ls())

current_episode <- 11

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




# re-create vector overlay map here
# objects are from episodes 5 and 7
# 
# lesson has a bunch layers
# some polys, 1 points, 1 lines

# ep 5 objects:
ncos_rgb <- rast("source_data/cirgis_1ft/w_campus_1ft.tif")
ncos_rgb <- aggregate(ncos_rgb, fact = 4)

# ep 7 objects
# shapefiles
buildings <- st_read("source_data/Campus_Buildings/Campus_Buildings.shp")
birds <- st_read("source_data/NCOS_Bird_Survey_Data_20190724shp/NCOS_Bird_Survey_Data_20190724_web.shp")
bikes <- st_read("source_data/icm_bikes/bike_paths/bikelanescollapsedv8.shp")
streams <- st_read("source_data/california_streams/streams_crop.shp")


# Crop a raster to a vector extent
# setup diagram
# canonical uses an AOI.shp (aoi_boundary_HARV), 
# the CHM, and a pointfile 
# convex hulls is a nice hack
# names from the canonical:
  # bikes or streams = lines_HARV 
  # birds = plots_HARV 
  # greatercampus = aoi_boundary_HARV

# create campus_DEM as a dataframe:
campus_DEM <- rast("source_data/campus_DEM.tif")

# I know I'll need to reproject it:
crs(birds) == crs(campus_DEM)
birds <- st_transform(birds, crs(campus_DEM))
campus_DEM_df <- as.data.frame(campus_DEM, xy = TRUE, na.rm=FALSE)
names(campus_DEM_df)[names(campus_DEM_df) == 'greatercampusDEM_1_1'] <- 'elevation'

# this turns the DEM into a vector:
campus_DEM_sp <- st_as_sf(campus_DEM_df, coords = c("x", "y"), crs = crs(campus_DEM))
# approximate the boundary box with a random sample of raster points:
DEM_rand_sample <- sample_n(campus_DEM_sp, 10000)
greatercampus <- st_read("source_data/greater_UCSB-campus-aoi.geojson")

# this should look very much like the diagram at the start of the lesson:
ggplot() +
  geom_sf(data = st_convex_hull(st_union(DEM_rand_sample)), fill = "green") +
  geom_sf(data = st_convex_hull(st_union(bikes)),
          fill = "purple", alpha =  0.2) +
  geom_sf(data = bikes, aes(color = LnType), size = 1) +
  geom_sf(data = greatercampus, fill = "blue", alpha =  0.4) +
  geom_sf(data = st_convex_hull(st_union(birds)),
                    fill = "black", alpha = 0.8) +
  geom_sf(data = birds, color = "white", alpha = 0.8) +
  theme(legend.position = "none") +
  ggtitle("Build a diagram: Campus DEM, bikes", subtitle = gg_labelmaker(current_ggplot+1)) +
  coord_sf()
# end of setup diagram           ###############################



# Crop a Raster Using Vector Extent
# ###############################
# We can use the crop() function to crop a raster 
# to the extent of another spatial object. To do this, 
# we need to specify the raster to be cropped and 
# the spatial object that will be used to crop the raster.

plot(bikes)
plot(campus_DEM)

str(campus_DEM_df)

# here's the wide view with the vector:
ggplot() +
  geom_raster(data = campus_DEM_df, aes(x=x, y=y, fill=elevation)) +
  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
  geom_sf(data=bikes, color = "blue", alpha = 0.5) +
  ggtitle(gg_labelmaker(current_ggplot+1), subtitle=" Campus DEM with Birds") +
  coord_sf()

# now crop the DEM to the extent of the bike layer
# <- crop(x= raster_to_crop, y= vector_extent)
campus_bike_DEM <- crop(x=campus_DEM, y=bikes)
campus_bike_DEM_df <- as.data.frame(campus_bike_DEM, xy = TRUE) %>% 
  rename(elevation = greatercampusDEM_1_1) 





# Challenge: Crop to Vector Points Extent
# ##########################
# 
# 1. Crop the Canopy Height Model to the extent of the study plot locations.
# 2. Plot the vegetation plot location points on top of the Canopy Height Model.
# 
# 1. Crop the campus DEM to the extent of the campus buildings layer.
# 2. Plot the building polygons on top of the campus DEM.

# Solution

ggplot() +
  geom_raster(data = campus_DEM_df, aes(x=x, y=y, fill=elevation)) +
  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
#  geom_sf(data=buildings, color = "yellow", alpha = 0.5) +
  ggtitle(gg_labelmaker(current_ggplot+1), subtitle=" Campus DEM, Birds, and Bikes") +
  coord_sf()

plot(buildings)






# recreate a raster with a vector extent overlaid on it
# from ep 5
# why are we using an RGB? (because episode 5 was color)

# geom_spatial_rgb() is from tidyterra
ggplot() +
  geom_spatraster_rgb(data=ncos_rgb) +
  ggtitle(gg_labelmaker(current_ggplot+1)) +
  coord_sf()

# campus Areas of Interest (AOIs) as geojson
# use one of these AOIs as the extent to crop the raster?
# they come into the lesson in ep. 6.
greatercampus <- st_read("source_data/greater_UCSB-campus-aoi.geojson")
greatercampus60km <- st_read("source_data/planet/planet/ucsb_60sqkm_planet_extent.geojson")

ggplot() +
  geom_raster(data=campus_DEM_df, aes(x=x, y=y, fill=elevation)) +
  coord_sf()

# from episode 3 we know:
# greatercampus <- project(greatercampus, from = to = )

crs(greatercampus) == crs(campus_DEM)
crs(greatercampus60km) == crs(campus_DEM)
crs(greatercampus60km) == crs(greatercampus)

campus_DEM <- project(campus_DEM, crs(greatercampus))
# remake dataframe
campus_DEM_df <- as.data.frame(campus_DEM, xy = TRUE, na.rm=FALSE)
names(campus_DEM_df)[names(campus_DEM_df) == 'greatercampusDEM_1_1'] <- 'elevation'

# now overlay
ggplot() +
  geom_sf(data=greatercampus, color = "red") +
  geom_sf(data=greatercampus60km, color = "blue") +
  geom_raster(data=campus_DEM_df, aes(x=x, y=y, fill=elevation)) +
  coord_sf()

# that's still not a very good overlay for cropping. :(
# somewhere below we crop to NCOS

# get a geojson and turn that into a vector
# ncos_aoi <- geojson_sf("source_data/ncos_aoi.geojson", expand_geometries = TRUE )

# plot(ncos_aoi)
# crs(ncos_aoi)
colnames(campus_DEM_df)

# projection error
# ggplot() +
#  geom_raster(data = campus_DEM_df, aes(x = x, y = y, fill = elevation)) +
#  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
#  geom_polygon(data = ncos_aoi, color = "blue", fill = NA) +
#  coord_sf()

crs(ncos_rgb) == crs(campus_DEM)
campus_projection <- crs(campus_DEM)

str(ncos_rgb)

# from episode 3 we know:
campus_DEM <- project(campus_DEM, campus_projection)
crs(campus_DEM) == crs(campus_DEM)

# NCOS over Campus DEM mismatch
ggplot() +
  geom_raster(data = campus_DEM_df, aes(x = x, y = y, fill = elevation)) +
  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
  geom_spatraster_rgb(data=ncos_rgb) +
  ggtitle(gg_labelmaker(current_ggplot+1), subtitle=" NCOS RGB over Campus DEM") +
  coord_sf()

ncos_rgb <- project(ncos_rgb, campus_projection)

ggplot() +
  geom_raster(data = campus_DEM_df, aes(x = x, y = y, fill = elevation)) +
  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
  geom_spatraster_rgb(data=ncos_rgb) +
  ggtitle(gg_labelmaker(current_ggplot+1), subtitle=" NCOS RGB over Campus DEM") +
  coord_sf()


# ####################
# this is cropping one raster to the extent of another raster.
campus_DEM_cropped <- crop(x=campus_DEM, y=ncos_rgb)
plot(campus_DEM_cropped)

# remake our dataframe and reset the attribute name:
campus_DEM_cropped_df <- as.data.frame(campus_DEM_cropped, xy = TRUE, na.rm=FALSE)
str(campus_DEM_cropped_df)
names(campus_DEM_cropped_df)[names(campus_DEM_cropped_df) == 'greatercampusDEM_1_1'] <- 'elevation'
str(campus_DEM_cropped_df)

ggplot() +
  geom_spatraster_rgb(data=ncos_rgb) +
  geom_raster(data = campus_DEM_cropped_df, aes(x = x, y = y, fill = elevation)) +
  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
  ggtitle(gg_labelmaker(current_ggplot+1), subtitle=" NCOS RGB over Campus DEM") +
  coord_sf()

# add some transparency
ggplot() +
  geom_spatraster_rgb(data=ncos_rgb) +
  geom_raster(data = campus_DEM_cropped_df, aes(x = x, y = y, fill = elevation)) +
  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
  aes(alpha = 0.3) +
  ggtitle(gg_labelmaker(current_ggplot+1), subtitle=" NCOS RGB over Campus DEM") +
  coord_sf()


# Crop a Raster Using Vector Extent
# #########################################
# st_as_sfc is new here
# it turns the raster bbox extent of campus_DEM into a vector we can use.
ggplot() +
  geom_sf(data = st_as_sfc(st_bbox(campus_DEM)), fill = "green",
          color = "green", alpha = .2) +
  geom_raster(data = campus_DEM_cropped_df,
              aes(x = x, y = y, fill = elevation)) +
  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
  coord_sf()

# the cropped version of campus_DEM should have the same extents
# but we can see a a tiny strange mismatch that we 
# should be able to explain
ggplot() +
  geom_raster(data = campus_DEM_cropped_df,
              aes(x = x, y = y, fill = elevation)) +
  scale_fill_gradientn(name = "Elevation", colors = terrain.colors(10)) +
  geom_sf(data = st_as_sfc(st_bbox(campus_DEM_cropped)), 
          color = "blue", 
          alpha = .2) +
  coord_sf()


# tuesday reading stopping point ###################################
# the lesson goes on to show the extents of a bunch of our datasets
# but the objects aren't loaded. and the lesson narrative is
# 'which is the biggest?'




# output will be a side-by-side raster of 2 drastically different
# resolutions
# get a box 
sb_channel_extent <- geojson_sf("source_data/socal_aoi.geojson") %>% 
  vect()
plot(sb_channel_extent)


# get the bathymetry data
campus_bath <- rast("source_data/SB_bath.tif")
plot(campus_bath)
campus_bath_df <- as.data.frame(campus_bath, xy=TRUE) %>%
  rename(bathymetry = Bathymetry_2m_OffshoreCoalOilPoint)

# get low-res data
# zoom 1, aka, Map 4 from map_4_5_6.r
west_us <- rast("source_data/dem90_hf/dem90_hf.tif")
# plot(west_us)
polys(sb_channel_extent)

# the above overlays don't work because of different CRSs
sb_channel_extent <- project(sb_channel_extent, west_us)
# this time it does:
# plot(west_us)
polys(sb_channel_extent)

# west_us_df <- as.data.frame(west_us, xy=TRUE)
# colnames(west_us_df)


# make some gg overlays

west_us_cropped <- crop(x=west_us, y=ext(sb_channel_extent))
plot(west_us_cropped)



str(west_us)

# project it to match west_us
# why do we project this into itself?
# crs(west_us) == crs(west_us_cropped)

# west_us_cropped <- project(x=west_us, y=west_us)
crs(west_us_cropped)

# now you can plot them together
# to confirm that's the correct extent
# that you want to crop to
plot(west_us_cropped)
polys(sb_channel_extent, col=NA)


  
# Define an Extent
# ########################

# from scratch!
# what are appropriate local numbers?
new_extent <- ext(1480000, 1560000, -2250000, -2050000)
class(new_extent)

# CHM_HARV_manual_cropped <- crop(x = CHM_HARV, y = new_extent)

# this is a good extent to play with.
plot(sb_channel_extent)

# these don't work
# campus_DEM_cropped <- crop(x=campus_DEM, y=new_extent)
# campus_DEM_cropped <- crop(x=campus_DEM, y=sb_channel_extent)


# get/make some bounding boxes for 3 layers:
bath_extent <- ext(campus_bath)
buildings_extent <- ext(buildings)

bath_extent_shape <- vect(bath_extent)
buildings_extent_shape <- vect(buildings_extent)
campus_extent_shape <- sb_channel_extent

crs(campus_extent_shape)





# Extract Raster Pixels Values Using Vector Polygons
# ########################

# aka: buffering.
# tree_height <- extract(x = CHM_HARV, y = aoi_boundary_HARV, raw = FALSE)
# str(tree_height)

# Summarize Extracted Raster Values
# ########################
# mean_tree_height_AOI <- extract(x = CHM_HARV, y = aoi_boundary_HARV,
#                              fun = mean)


# Extract Data using x,y Locations
# ########################

# Challenge: Extract Raster Height Values For Plot Locations
# ########################



# I dunno what all this stuff is.
# leftover cruft?
################################################################

buildings <- st_read("source_data/Campus_Buildings/Campus_Buildings.shp")




writeVector(campus_extent_shape, "output_data/aoi_campus.shp", filetype= "ESRI shapefile", overwrite=TRUE)
writeVector(bath_extent_shape, "output_data/aoi_bath.shp",  filetype= "ESRI shapefile", overwrite=TRUE)
writeVector(buildings_extent_shape, "output_data/aoi_buildings.shp",  filetype= "ESRI shapefile", overwrite=TRUE)

campus_box <- st_read("output_data/aoi_campus.shp")
bath_box <- st_read("output_data/aoi_bath.shp")
buildings_box <- st_read("output_data/aoi_buildings.shp")

crs(campus_box)
crs(bath_box)
crs(buildings_box)

# neither bath nor buildings have crss
ggplot () +
  geom_sf(data = campus_box, color = "black", fill = NA) +
  #  geom_sf(data = bath_box, color = "red", fill = NA) +
  #  geom_sf(data = buildings_box, color = "purple", fill = NA) +
  coord_sf()


# this tells me I want to use the campus DEM bounding box
# for my overview map.

# Let's crop bathymetry to the extent of campus
# bath_cropped <- crop(x=bath, y=campus_box)
# oops. we need to re-project

project_from <- crs(campus_DEM) 

my_res <- res(campus_DEM)

crs(campus_bath)
crs(campus_DEM)

str(campus_bath_df)
str(campus_DEM_df)

# plot everyone together
# this won't overlay
#ggplot() +
#  geom_sf(data = buildings_extent_shape, color = "black", fill = NA) +
#  geom_raster(data = campus_DEM_df, 
#              aes(x=x, y=y, fill=elevation)) +
#  scale_fill_viridis_c(na.value="NA")+
#      geom_raster(data = campus_bath_df, 
#              aes(x=x, y=y, alpha=bathymetry)) +
#  coord_sf()