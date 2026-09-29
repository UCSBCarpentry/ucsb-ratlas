# datasets retrieved from public, canonical sources
# for the rAtlas of UCSB
# this is more for record keeping than running.
# we have everything in a google drive triggered by data_prep.r

# bathymetry data #############################
curl_download("https://pubs.usgs.gov/ds/781/OffshoreCoalOilPoint/data/Bathymetry_OffshoreCoalOilPoint.zip", 
              "downloaded_data/Bathymetry_OffshoreCoalOilPoint.zip", quiet=FALSE)

# Unzip the archive
unzip("downloaded_data/Bathymetry_OffshoreCoalOilPoint.zip", 
      exdir = "downloaded_data/bathymetry",
      overwrite = TRUE) 

# copy the file needed for episode 3
file.copy(from='downloaded_data/bathymetry/Bathymetry_2m_OffshoreCoalOilPoint.tif', 
          to='source_data/SB_bath_2m.tif')

# Delete the zip archive
file.remove("downloaded_data/Bathymetry_OffshoreCoalOilPoint.zip")

# Our largest extent raster
# global shaded relief from NaturalEarth
curl_download("https://naciscdn.org/naturalearth/10m/raster/GRAY_HR_SR_OB.zip",
              "downloaded_data/global_raster.zip")
unzip("downloaded_data/global_raster.zip", exdir="source_data/global_raster", overwrite = TRUE)


# california populated places
curl_download("https://www2.census.gov/geo/tiger/TIGER2023/PLACE/tl_2023_06_place.zip", "downloaded_data/tl_2023_06_place.zip")
unzip("downloaded_data/tl_2023_06_place.zip", exdir="source_data/cal_pop_places", overwrite = TRUE)




# Water data for map 2
# * California Streams https://data.cnra.ca.gov/dataset/california-streams
curl_download("https://data-cdfw.opendata.arcgis.com/api/download/v1/items/92b18d9e091d469fa69d256fb395b946/shapefile?layers=0",
              "downloaded_data/california_streams.zip")
unzip("downloaded_data/california_streams.zip", exdir="source_data/california_streams", overwrite = TRUE)
file.remove("downloaded_data/california_streams.zip")

# It's very large, so let's crop it here in data prep
# so map 2 makes itself faster later on:

streams <- vect("source_data/california_streams/California_Streams.shp")

# crop California streams
# to the extent of
# UCSB trees:
crs(streams, describe=TRUE)
ext(streams)
trees <- vect("source_data/trees/DTK_012116.shp")
streams_crop <- crop(streams, trees)
plot(trees)
crs(trees, describe=TRUE)
ext(trees)

streams_crop <- crop(streams, trees) %>% 
  writeVector("source_data/california_streams/streams_crop.shp", overwrite = TRUE)
