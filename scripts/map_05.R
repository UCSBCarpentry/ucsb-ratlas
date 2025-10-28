#################################################
# zoom3
# Map 5 ########################################
# 

# clean the environment and hidden objects

rm(list=ls())

library(sf)
library(terra)
library(tidyterra)
library(geojsonsf)
library(ggplot2)
library(dplyr)

# set map number
current_sheet <- 5
# set ggplot counter
current_ggplot <- 0

# our auto ggtitle maker
gg_labelmaker <- function(plot_num){
  gg_title <- c("Map:", current_sheet, " ggplot:", plot_num)
  plot_text <- paste(gg_title, collapse=" " )
  print(plot_text)
  current_ggplot <<- plot_num
  return(plot_text)
}
# every ggtitle should be:
# ggtitle(gg_labelmaker(current_ggplot+1))
# end automagic ggtitle 



# ###########################
# Map 5
# Zoom 3: UCSB & Environs
# these come pre-made

campus_DEM <- rast("source_data/campus_DEM.tif")
plot(campus_DEM)
zoom_3_hillshade <- rast("source_data/campus_hillshade.tif")
plot(zoom_3_hillshade)


#################################################
# zoom3 as ggplot
campus_hillshade <- rast("source_data/campus_hillshade.tif")
str(campus_hillshade)
zoom_3_hillshade_df <- as.data.frame(campus_hillshade, xy=TRUE)
colnames(zoom_3_hillshade_df)

# let's make our ggplots shorter by saving
# our theme:
rAtlas_theme <- theme_minimal() +
  theme(axis.title.x=element_blank(), 
        axis.title.y=element_blank(), 
        axis.text.x=element_blank(), 
        axis.text.y=element_blank(), 
        legend.position="none", 
        panel.ontop=TRUE,
        panel.grid.major = element_line(color = "#FFFFFF33"),
        panel.grid.minor = element_line(color = "#FFFFFF66"),
        panel.background = element_blank())



# ggplot the hillshade
zoom_3_plot <- ggplot() +
  geom_raster(data = zoom_3_hillshade_df,
              aes(x=x, y=y, alpha=hillshade)) +
  scale_alpha(range = c(0.05, 0.5), guide="none") +
  theme(rAtlas_theme) +
  coord_sf() + 
  ggtitle(gg_labelmaker(current_ggplot+1), subtitle = "Campus hillshade")

zoom_3_plot

# ggplot the DEM
zoom_3_DEM_df <- as.data.frame(campus_DEM, xy=TRUE)
str(zoom_3_DEM_df)

zoom_3_plot <- ggplot() +
  geom_raster(data = zoom_3_DEM_df,
              aes(x=x, y=y, fill=greatercampusDEM_1_1)) +
  scale_fill_viridis_c(guide="none") +
  theme(rAtlas_theme) +
  coord_sf() + 
  ggtitle(gg_labelmaker(current_ggplot+1), subtitle = "UCSB DEM")

zoom_3_plot

# now overlay
zoom_3_plot <- ggplot() +
  geom_raster(data = zoom_3_DEM_df,
              aes(x=x, y=y, fill=greatercampusDEM_1_1)) +
  scale_fill_viridis_c() +
  geom_raster(data = zoom_3_hillshade_df,
              aes(x=x, y=y, alpha=hillshade)) +
  scale_alpha(range = c(0.05, 0.5), guide="none") +
  theme(rAtlas_theme) +
  coord_sf() + 
  ggtitle("Map 5: zm 3: UCSB & Surroundings", subtitle = gg_labelmaker(current_ggplot+1))

zoom_3_plot

# back out of the shortened theme and use what works
zoom_3_plot <- ggplot() +
  geom_raster(data = zoom_3_DEM_df,
              aes(x=x, y=y, fill=greatercampusDEM_1_1)) +
  scale_fill_viridis_c() +
  geom_raster(data = zoom_3_hillshade_df,
              aes(x=x, y=y, alpha=hillshade)) +
  scale_alpha(range = c(0.05, 0.5), guide="none") +
  theme_minimal() +
  theme(axis.title.x=element_blank(), 
        axis.title.y=element_blank(), 
        axis.text.x=element_blank(), 
        axis.text.y=element_blank(), 
        legend.position="none", 
        panel.ontop=TRUE,
        panel.grid.major = element_line(color = "#FFFFFF33"),
        panel.background = element_blank()) +
  coord_sf() + 
  ggtitle("Map 5: zm 3: no axis labels", subtitle = gg_labelmaker(current_ggplot+1))

zoom_3_plot

# back out of the shortened theme and use what works
zoom_3_plot <- ggplot() +
  geom_raster(data = zoom_3_DEM_df,
              aes(x=x, y=y, fill=greatercampusDEM_1_1)) +
  scale_fill_viridis_c() +
  geom_raster(data = zoom_3_hillshade_df,
              aes(x=x, y=y, alpha=hillshade)) +
  scale_alpha(range = c(0.05, 0.5), guide="none") +
  theme_minimal() +
  theme(axis.title.x=element_blank(), 
        axis.title.y=element_blank(), 
        axis.text.x=element_blank(), 
        axis.text.y=element_blank(), 
        legend.position="none", 
        panel.ontop=TRUE,
        panel.grid.major = element_line(color = "#FFFFFF33"),
        panel.background = element_blank()) +
  coord_sf() + 
  ggtitle("UCSB Surroundings", subtitle = "on unceded land of the Chumash")

zoom_3_plot



# zoom 3 needs water, 
# add in topo_batho
campus_bathotopo <- rast("output_data/campus_bathotopo.tif")
campus_bathotopo_df <- as.data.frame(campus_bathotopo, xy=TRUE)


# there's an overlay problem here.




# now add campus_bathotopo_df to the ggplot:
zoom_3_plot <- ggplot() +
  geom_raster(data = campus_bathotopo_df, aes(x=x, y=y)) +
  geom_raster(data = zoom_3_DEM_df,
              aes(x=x, y=y, fill=greatercampusDEM_1_1)) +
  scale_fill_viridis_c() +
  geom_raster(data = zoom_3_hillshade_df,
              aes(x=x, y=y, alpha=hillshade)) +
  scale_alpha(range = c(0.05, 0.5), guide="none") +
  theme_minimal() +
  theme(axis.title.x=element_blank(), 
        axis.title.y=element_blank(), 
        axis.text.x=element_blank(), 
        axis.text.y=element_blank(), 
        legend.position="none", 
        panel.ontop=TRUE,
        panel.grid.major = element_line(color = "#FFFFFF33"),
        panel.background = element_blank()) +
  coord_sf() + 
  ggtitle("UCSB Surroundings", subtitle = "on unceded land of the Chumash")

zoom_3_plot


zoom_3_plot <-ggplot() +
  geom_raster(data = campus_bathotopo, aes(x=x, y=y)) +
  geom_raster(data = zoom_3_DEM_df,
              aes(x=x, y=y, fill=greatercampusDEM_1_1)) +
  scale_fill_viridis_c() +
  geom_raster(data = zoom_3_hillshade_df,
              aes(x=x, y=y, alpha=hillshade)) +
  scale_alpha(range = c(0.05, 0.5), guide="none") +
  theme_minimal() +
  theme(my_theme) +
  coord_sf() + 
  ggtitle("UCSB Surroundings", subtitle = "on unceded land of the Chumash")


zoom_3_plot

ggsave("images/map5.png", width = 4, height = 3, plot=last_plot())
ggsave("final_output/map_05.png", width = 4, height = 3, plot=zoom_3_plot)
