# map 6
# an alternate to map 1
# for the bottom of the page on map 7


library(terra)
library(ggplot2)
library(dplyr)
# library(raster)
library(sf)

# clean the environment and hidden objects
rm(list = ls())

# set map number
current_sheet <- 6
# set ggplot counter
current_ggplot <- 0

# make our ggtitles automagically #######
gg_labelmaker <- function(plot_num) {
  gg_title <- c("Map:", current_sheet, " ggplot:", plot_num)
  plot_text <- paste(gg_title, collapse = " ")
  print(plot_text)
  current_ggplot <<- plot_num
  return(plot_text)
}
# every ggtitle should be:
# ggtitle(gg_labelmaker(current_ggplot+1))
# end automagic ggtitle           #######

# vector layers
buildings <- st_read("source_data/campus_buildings/Campus_Buildings.shp")
bikeways <- st_read("source_data/icm_bikes/bike_paths/bikelanescollapsedv8.shp")
habitat <- st_read("source_data/NCOS_Shorebird_Foraging_Habitat/NCOS_Shorebird_Foraging_Habitat.shp")
iv_buildings <- st_read("source_data/iv_buildings/iv_buildings/CA_Structures_ExportFeatures.shp")

# rasters
# the background setup is bathymetry and topography mashed together
# this is worked through in map_01.r
# but we need to crop them tighter

campus_DEM <- rast("source_data/campus_DEM.tif")
campus_bath <- rast("source_data/SB_bath.tif")
campus_hillshade <- rast("source_data/campus_hillshade.tif")
# and/or user bathotopo from map 1:
campus_bathotopo <- rast("output_data/campus_bathotopo.tif")


# we will use the original projection of
#    campus_DEM
# for whatever needs it to overlay:
campus_projection <- crs(campus_DEM)
campus_bath <- project(campus_bath, campus_projection)
campus_hillshade <- project(campus_hillshade, campus_projection)
buildings <- st_transform(buildings, campus_projection)
bikeways <- st_transform(bikeways, campus_projection)
habitat <- st_transform(habitat, campus_projection)

# ###################
# crop the 4 rasters to the extent of the batho-topo:
plot(campus_bathotopo)

# Get extent:
campus_bathotopo_extent <- ext(campus_bathotopo)

# Crop rasters:
campus_DEM_crop <- crop(campus_DEM, campus_bathotopo_extent)
campus_bath_crop <- crop(campus_bath, campus_bathotopo_extent)
campus_hillshade_crop <- crop(campus_hillshade, campus_bathotopo_extent)

# make dataframes
campus_DEM_df <- as.data.frame(campus_DEM_crop, xy = TRUE) %>%
  rename(elevation = greatercampusDEM_1_1)

campus_bath_df <- as.data.frame(campus_bath_crop, xy = TRUE) %>%
  rename(bathymetry = Bathymetry_2m_OffshoreCoalOilPoint)

campus_hillshade_df <- as.data.frame(campus_hillshade_crop, xy = TRUE)

## test vector overlays
#
# this is our first ggplot, so
# let's make reuse our
# our theme for the first time:
rAtlas_theme <- theme(
  axis.title.x = element_blank(),
  axis.title.y = element_blank(),
  legend.position = "none",
  panel.ontop = TRUE,
  panel.grid.major = element_line(color = "#FFFFFF33"),
  panel.background = element_blank()
)


ggplot() +
  geom_sf(data = habitat) +
  geom_sf(data = buildings) +
  geom_sf(data = iv_buildings) +
  geom_sf(data = bikeways) +
  theme(rAtlas_theme) +
  ggtitle(gg_labelmaker(current_ggplot + 1)) +
  coord_sf()


############################
# now do what's necessary to plot the new
# closest-in #6 rasters together with the 4 vector layers

# let's apply our named theme from map_05


# these '6' versions should map when they are ready:
# the graticule is getting blown out.
ggplot() +
  geom_raster(data = campus_DEM_df, aes(x = x, y = y, fill = elevation)) +
  geom_sf(data = buildings, color = "hotpink") +
  geom_sf(data = bikeways, color = "yellow") +
  geom_raster(data = campus_hillshade_df, aes(x = x, y = y, alpha = hillshade), show.legend = FALSE) +
  geom_raster(data = campus_bath_df, aes(x = x, y = y, fill = bathymetry)) +
  scale_fill_viridis_c(na.value = "NA") +
  theme(rAtlas_theme) +
  ggtitle("Map 6 = Map 1: Batho-topo Extent", subtitle = (gg_labelmaker(current_ggplot + 1))) +
  coord_sf()


ggsave("images/map6.1.png", width = 12, height = 4, plot = last_plot(), bg = "white")
ggsave("final_output/map_06.png", width = 12, height = 4, plot = last_plot(), bg = "white")
