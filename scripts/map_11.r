# map 11
# Look at a Dibblee geologic map:
# Splicing two adjacent 7.5-minute quadrangles:
# West: Dos Pueblos Canyon (09gDosPueblos / DB0009.tif)
# East: Goleta (07gGoleta / DB0007.tif)

library(terra)

# Clean the environment and hidden objects
rm(list = ls())

# Set map number
current_sheet <- 11
# Set ggplot counter
current_ggplot <- 0

gg_labelmaker <- function(plot_num) {
  gg_title <- c("Map:", current_sheet, " ggplot:", plot_num)
  plot_text <- paste(gg_title, collapse = " ")
  print(plot_text)
  current_ggplot <<- plot_num
  return(plot_text)
}

# Ensure output directories exist
dir.create("images", showWarnings = FALSE)
dir.create("final_output", showWarnings = FALSE)
dir.create("output_data", showWarnings = FALSE)

crs_nad27 <- "+proj=utm +zone=11 +datum=NAD27 +units=m +no_defs"

# ---------- 1. Ingest & Rectify Both Dibblee Quadrangles ----------
# Goleta Quadrangle (DF-07 / DB0007.tif) - East side of campus
if (file.exists("output_data/DB0007_rectified.tif")) {
  cat("Loading cached rectified Goleta quadrangle (DB0007)...\n")
  gol_rect <- rast("output_data/DB0007_rectified.tif")
} else {
  cat("Rectifying Goleta quadrangle (DB0007)...\n")
  gol <- rast("source_data/07gGoleta/DB0007.tif")
  gol_rect <- rectify(gol, method = "bilinear")
  names(gol_rect) <- c("red", "green", "blue")
  writeRaster(gol_rect, "output_data/DB0007_rectified.tif", overwrite = TRUE, gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
}

# Dos Pueblos Canyon Quadrangle (DF-09 / DB0009.tif) - West side of campus
dp_file <- "source_data/09gDosPueblos/DB0009.tif"
if (!file.exists(dp_file)) {
  # Check alternate location if applicable
  dp_file <- "source_data/16gSolvangGaviota/DB0016.tif"
}

if (file.exists("output_data/DB0009_rectified.tif")) {
  cat("Loading cached rectified Dos Pueblos Canyon quadrangle (DB0009)...\n")
  dp_rect <- rast("output_data/DB0009_rectified.tif")
} else if (file.exists(dp_file)) {
  cat("Rectifying Dos Pueblos Canyon quadrangle (DB0009)...\n")
  dp <- rast(dp_file)
  dp_rect <- rectify(dp, method = "bilinear")
  names(dp_rect) <- c("red", "green", "blue")
  writeRaster(dp_rect, "output_data/DB0009_rectified.tif", overwrite = TRUE, gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
} else {
  stop("Western Dibblee quadrangle not found! Please place DB0009.tif in source_data/09gDosPueblos/")
}

# ---------- 2. Campus AOI and Quadrangle Neatlines ----------
aoi <- vect("source_data/greater_UCSB-campus-aoi.geojson")
aoi_nad27 <- project(aoi, crs_nad27)

# Goleta 7.5' neatline: -119.875° to -119.750° W, 34.375° to 34.500° N
poly_gol <- project(as.polygons(ext(-119.875, -119.750, 34.375, 34.500), crs = "EPSG:4326"), crs_nad27)

# Dos Pueblos Canyon 7.5' neatline: -120.000° to -119.875° W, 34.375° to 34.500° N
poly_dp <- project(as.polygons(ext(-120.000, -119.875, 34.375, 34.500), crs = "EPSG:4326"), crs_nad27)

# ---------- 3. Output Intermediate GeoTIFF of Both Full Sheets with AOI ----------
interm_tif <- "output_data/dibblee_both_tiffs_full_extent_with_aoi.tif"
if (!file.exists(interm_tif)) {
  cat("Generating intermediate GeoTIFF showing full extent of both sheets with AOI...\n")
  dp_half <- aggregate(dp_rect, fact = 2)
  gol_half <- aggregate(gol_rect, fact = 2)
  both_full <- merge(dp_half, gol_half)

  aoi_buf <- buffer(as.lines(aoi_nad27), width = 60)
  both_with_aoi <- rasterize(aoi_buf, both_full, update = TRUE)

  writeRaster(both_with_aoi, interm_tif, overwrite = TRUE, gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
}

# Diagnostic overview PNG showing full extent of both sheets + neatlines + AOI:
png("final_output/map11_both_tiffs_full_extent_aoi.png", width = 2400, height = 1500, res = 150)
plotRGB(merge(aggregate(dp_rect, fact = 4), aggregate(gol_rect, fact = 4)))
plot(poly_dp, border = "#2E7D32", lwd = 2.5, lty = 2, add = TRUE)
plot(poly_gol, border = "#1565C0", lwd = 2.5, lty = 2, add = TRUE)
plot(aoi_nad27, border = "#D50000", lwd = 4, add = TRUE)
title(
  main = "Both Dibblee Geologic Sheets (Dos Pueblos DF-09 & Goleta DF-07) with Campus AOI",
  sub = "Green = Dos Pueblos neatline | Blue = Goleta neatline | Red = Greater Campus AOI",
  adj = 0
)
dev.off()
file.copy("final_output/map11_both_tiffs_full_extent_aoi.png", "images/map11_both_tiffs_full_extent_aoi.png", overwrite = TRUE)

# ---------- 4. Splicing the 2 Maps Together (Neatline Collar-Trimmed) ----------
cat("Trimming collars to neatlines and splicing adjacent sheets...\n")
# Bounding extent covering the AOI latitude range:
aoi_ext <- ext(aoi_nad27) + c(-200, 200, -200, 200)

poly_dp_aoi <- ext(222896, 235715.5, ymin(aoi_ext), ymax(aoi_ext))
poly_gol_aoi <- ext(235715.5, 252013, ymin(aoi_ext), ymax(aoi_ext))

dp_sub <- crop(dp_rect, poly_dp_aoi)
gol_sub <- crop(gol_rect, poly_gol_aoi)

spliced_campus <- merge(dp_sub, gol_sub)

# Crop spliced mosaic to the Greater Campus AOI:
campus_geology <- crop(spliced_campus, aoi_nad27)

# ---------- 5. Save Final Spliced Map Outputs ----------
png("images/map11.png", width = 1600, height = 1200, res = 150)
plotRGB(campus_geology)
plot(aoi_nad27, border = "#D50000", lwd = 2.5, add = TRUE)
title(
  main = "Spliced Dibblee Geologic Map - Greater UCSB Campus AOI",
  sub = "Seamless mosaic of Dos Pueblos Canyon (DB0009) & Goleta (DB0007) Quadrangles",
  adj = 0
)
dev.off()
file.copy("images/map11.png", "final_output/map_11.png", overwrite = TRUE)

# Also save standalone AOI clip
png("final_output/dibble_aoi.png", width = 800, height = 800, res = 150)
plotRGB(campus_geology)
plot(aoi_nad27, border = "#D50000", lwd = 2, add = TRUE)
dev.off()

cat("\nMap 11 successfully generated:\n")
cat(" - Intermediate GeoTIFF: output_data/dibblee_both_tiffs_full_extent_with_aoi.tif\n")
cat(" - Diagnostic Full Map:  final_output/map11_both_tiffs_full_extent_aoi.png\n")
cat(" - Final Spliced Plate:  final_output/map_11.png\n")
cat(" - Square AOI Clip:      final_output/dibble_aoi.png\n")
