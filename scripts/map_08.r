# map 8 actually
# multi-band imagery

# for the episode about RGBs and multi-band rasters
# episode 5
# https://datacarpentry.github.io/r-raster-vector-geospatial/05-raster-multi-band-in-r.html#create-a-three-band-image

# This map is all terra!

library(terra)
# library(geojsonsf)
# library(sf)
# library(ggpubr)

# clean the environment and hidden objects
rm(list=ls())

# reset your par() before starting
par(mfrow = c(1,1))


# set map number
current_sheet <- 8
# set ggplot counter
current_ggplot <- 0


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
#######



#load an 8-band image: data_prep puts it here:
planet_scene <- rast("source_data/planet/planet/20232024_UCSB_campus_PlanetScope/PSScene/20230912_175450_00_2439_3B_AnalyticMS_SR_8b_clip.tif")
planet_scene

# check it out
class(planet_scene)
res(planet_scene)
dim(planet_scene)
crs(planet_scene)

# won't plot without a stretch
# plotRGB(planet_scene)

plotRGB(planet_scene, stretch = "lin")
plotRGB(planet_scene, stretch = "hist")

# Now plot out some different combinations:
#  natural color
plotRGB(planet_scene, stretch = "hist",
        r = 4, g = 3, b = 2)

#  false-color IR
plotRGB(planet_scene, stretch = "hist",
        r = 8, g = 3, b = 2)

#  something pretty or odd
plotRGB(planet_scene, stretch = "hist",
        r = 1, g = 2, b = 6)

#  yellow = green
plotRGB(planet_scene, stretch = "hist",
        r = 7, g = 5, b = 1)


# Let's format one of those up:
#  yellow = green
plotRGB(planet_scene, stretch = "hist",
        r = 7, g = 5, b = 1,
        axes=TRUE,
        main = "yellow = green")

# set up my frame
par(mfrow = c(2,2))
  
#  natural color
natural <- plotRGB(planet_scene, stretch = "hist",
        r = 4, g = 3, b = 2,
        main = "natural color")


#  false-color IR
false_color_ir <- plotRGB(planet_scene, stretch = "hist",
        r = 8, g = 3, b = 2,
        main = "false color infrared")

#  yellow = green
yellow_green <- plotRGB(planet_scene, stretch = "hist",
        r = 7, g = 5, b = 1,
        main = "yellow = green")

#  pretty 7,4,1
pretty_741 <- plotRGB(planet_scene, stretch = "hist",
        r = 7, g = 4, b = 1,
        main = "pretty")



# save the image
# i realize this is repetitive 
# open device
png("final_output/map_08.png")
par(mfrow = c(2,2))

#  natural color
natural <- plotRGB(planet_scene, stretch = "hist",
                   r = 4, g = 3, b = 2,
                   main = "natural color")


#  false-color IR
false_color_ir <- plotRGB(planet_scene, stretch = "hist",
                          r = 8, g = 3, b = 2,
                          main = "false color infrared")

#  yellow = green
yellow_green <- plotRGB(planet_scene, stretch = "hist",
                        r = 7, g = 5, b = 1,
                        main = "yellow = green")

#  pretty 7,4,1
pretty_741 <- plotRGB(planet_scene, stretch = "hist",
                      r = 7, g = 4, b = 1,
                      main = "pretty")



dev.off()
   

# reset your par() before leaving
par(mfrow = c(1,1))

