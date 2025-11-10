# map 10
library(terra)
library(tidyverse)
library(tidyterra)
# clean the environment and hidden objects
rm(list=ls())

# set map number
current_sheet <- 10
# set ggplot counter
current_ggplot <- 0

gg_labelmaker <- function(plot_num){
  gg_title <- c("Map:", current_sheet, " ggplot:", plot_num)
  plot_text <- paste(gg_title, collapse=" " )
  print(plot_text)
  current_ggplot <<- plot_num
  return(plot_text)
}

# every ggtitle() or labs() should be:
# ggtitle(gg_labelmaker(current_ggplot+1))
# end automagic ggtitle           #######

# ---------- 1. read layers ----------
# bike_paths <- vect("") # replace with updated bike-path file
bike_paths <- vect("source_data/icm_bikes/bike_paths/bikelanescollapsedv8.shp")
creeks     <- vect("source_data/california_streams/streams_crop.shp")

# ---------- 2. common CRS ----------
creeks      <- project(creeks, bike_paths)

# plot creeks and paths together here to prove it

# ---------- 3. intersection points ----------
creek_bike_pts <- intersect(creeks, bike_paths)
str(creek_bike_pts)

creek_bike_pts <- vect(creek_bike_pts)

# let's put in another plot here to prove it
plot(creek_bike_pts)


# ---------- 4. write shapefile ----------
#  Do we output a new point shapefile as a result?
out_file <- "output_data/creek_bike_intersections.shp"
writeVector(creek_bike_pts, out_file, overwrite=TRUE)
