# map 11
# Look at a Dibblee geologic map:
# Raster rectification, mosaicking / conjoining quadrangles, collar trimming, and AOI cropping

library(terra)

# clean the environment and hidden objects
rm(list = ls())

# set map number
current_sheet <- 11
# set ggplot counter
current_ggplot <- 0

gg_labelmaker <- function(plot_num) {
  gg_title <- c("Map:", current_sheet, " ggplot:", plot_num)
  plot_text <- paste(gg_title, collapse = " ")
  print(plot_text)
  current_ggplot <<- plot_num
  return(plot_text)
}

# every ggtitle() or labs() should be:
# ggtitle(gg_labelmaker(current_ggplot+1))
# end automagic ggtitle           #######

# Ensure output directories exist
dir.create("images", showWarnings = FALSE)
dir.create("final_output", showWarnings = FALSE)

# ---------- 1. Ingest & Rectify Goleta Quadrangle ----------
# Scanned paper maps possess non-orthogonal affine orientation.
# We rectify the rotated raster into standard north-up coordinates:
dibblee_gol <- rast("source_data/07gGoleta/DB0007.tif")
dibblee_gol <- rectify(dibblee_gol, method = "bilinear")
dibblee_gol

# ---------- 2. Ingest Adjacent Quadrangle & Conjoin ----------
# Check for adjacent quadrangle (Solvang/Gaviota DB0016)
gav_file <- "source_data/16gSolvangGaviota/DB0016.tif"
if (file.exists(gav_file)) {
  cat("Loading and rectifying Solvang/Gaviota quadrangle...\n")
  dibblee_gav <- rast(gav_file)
  dibblee_gav <- rectify(dibblee_gav, method = "bilinear")
  # Conjoin (merge) adjacent sheets into a single continuous raster
  dibblee_merged <- merge(dibblee_gol, dibblee_gav)
} else {
  cat("Adjacent quadrangle file not found; proceeding with Goleta quadrangle.\n")
  dibblee_merged <- dibblee_gol
}

# ---------- 3. Crop to Greater Campus AOI ----------
greater_campus <- vect("source_data/greater_UCSB-campus-aoi.geojson")
greater_campus_proj <- project(greater_campus, crs(dibblee_merged))
crop_dibblee_aoi <- crop(dibblee_merged, greater_campus_proj)

# ---------- 4. Also Compute Quad Neatline Crop (Collar Trimming) ----------
# Quadrangle corners in NAD27 / geographic coordinates:
# NW: 34° 30' 00" N / 119° 52' 30" W
# NE: 34° 30' 00" N / 119° 45' 00" W
# SE: 34° 22' 30" N / 119° 45' 00" W
# SW: 34° 22' 30" N / 119° 52' 30" W
ll_ext <- ext(-119.875, -119.750, 34.375, 34.500)
ll_vec <- as.polygons(ll_ext, crs = "EPSG:4326")
utm_ext <- ext(project(ll_vec, crs(dibblee_gol)))
crop_dibblee_gol <- crop(dibblee_gol, utm_ext)

# ---------- 5. Save Output Maps ----------
# Save AOI plate to images and final_output
png("images/map11.png", width = 1600, height = 1200, res = 150)
plotRGB(crop_dibblee_aoi)
plot(greater_campus_proj, border = "red", lwd = 2, add = TRUE)
title(main = "Dibblee Geologic Map - Greater UCSB Campus AOI",
      sub = "Source: Thomas Dibblee Geologic Quadrangle Series (DB0007)")
dev.off()

# Copy to final_output
file.copy("images/map11.png", "final_output/map_11.png", overwrite = TRUE)

# Also save standalone AOI map
png("final_output/dibble_aoi.png", width = 800, height = 800, res = 150)
plotRGB(crop_dibblee_aoi)
plot(greater_campus_proj, border = "red", lwd = 2, add = TRUE)
dev.off()

cat("Map 11 outputs generated:\n")
cat(" - images/map11.png\n")
cat(" - final_output/map_11.png\n")
cat(" - final_output/dibble_aoi.png\n")
