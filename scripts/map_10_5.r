# Map 10.5: Data Provenance & The Missing NCOS Bike Trail
# Demonstrating the temporal and institutional limitations of spatial data:
# Why the major bike path and bridge crossing through North Campus Open Space (NCOS)
# is absent from the legacy campus bikeways dataset.

library(terra)
library(tidyverse)
library(tidyterra)
library(sf)
library(geojsonsf)

# Clean the environment and hidden objects
rm(list = ls())

# Set map number
current_sheet <- "10.5"
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

# ---------- 1. Ingest Spatial Data ----------
# NCOS study area bounding box
ncos_box <- vect(geojson_sf("scripts/ncos.geojson"))

# Full California streams network
streams_full <- vect("source_data/california_streams/California_Streams.shp")
streams_full_proj <- project(streams_full, crs(ncos_box))
streams_ncos <- crop(streams_full_proj, ncos_box)

# Restored saltmarsh & shorebird foraging habitat
habitat <- vect("source_data/NCOS_Shorebird_Foraging_Habitat/NCOS_Shorebird_Foraging_Habitat.shp")
habitat <- project(habitat, crs(ncos_box))

# Legacy campus bike paths (circa 2016-2017 ICM harvest)
bike_paths <- vect("source_data/icm_bikes/bike_paths/bikelanescollapsedv8.shp")
bike_paths_proj <- project(bike_paths, crs(ncos_box))
bike_paths_ncos <- crop(bike_paths_proj, ncos_box)

# ---------- 2. Delineate Modern NCOS Multi-Use Trail Network ----------
# Constructed by CCBER between 2018 and 2021 as part of the Ocean Meadows restoration:
trail_main <- matrix(c(
  -119.8696, 34.4226,  # Whittier Drive eastern trailhead
  -119.8722, 34.4218,  # Northern marsh boardwalk
  -119.8745, 34.4212,  # Marsh path
  -119.8770, 34.4204,  # Main Devereux Creek timber bridge
  -119.8800, 34.4210,  # Western mesa trail
  -119.8835, 34.4208,  # Ellwood Mesa / Coronado Drive connection
  -119.8852, 34.4205
), ncol = 2, byrow = TRUE)

trail_south <- matrix(c(
  -119.8770, 34.4204,  # Bridge junction
  -119.8775, 34.4170,  # West bluff trail
  -119.8785, 34.4135,
  -119.8790, 34.4105   # Sands Beach / Coal Oil Point Reserve connection
), ncol = 2, byrow = TRUE)

trail_east <- matrix(c(
  -119.8696, 34.4226,  # Whittier Drive trailhead
  -119.8705, 34.4180,  # East bluff trail
  -119.8715, 34.4150,
  -119.8725, 34.4120   # Sierra Madre / West Campus student housing connection
), ncol = 2, byrow = TRUE)

ncos_trails <- rbind(
  vect(trail_main, type = "lines", crs = crs(ncos_box)),
  vect(trail_south, type = "lines", crs = crs(ncos_box)),
  vect(trail_east, type = "lines", crs = crs(ncos_box))
)

# ---------- 3. Compare Intersection Analyses ----------
# Intersection with modern trails: detects the real-world Devereux Creek bridge crossing
actual_crossings <- terra::intersect(streams_ncos, ncos_trails)
actual_crossings_disagg <- disagg(actual_crossings)

# Intersection with legacy dataset: 0 crossings found in NCOS!
legacy_crossings <- terra::intersect(streams_ncos, bike_paths_ncos)

cat("Actual modern crossings in NCOS:", length(actual_crossings_disagg), "\n")
cat("Legacy dataset crossings in NCOS:", length(legacy_crossings), "\n")

# Save actual crossing point to output_data
writeVector(actual_crossings_disagg, "output_data/ncos_creek_crossing_actual.shp", overwrite = TRUE)

# ---------- 4. Construct Cartographic Visualization ----------
map10_5_plot <- ggplot() +
  geom_spatvector(data = habitat, aes(fill = "Restored Wetland Habitat"), color = "#81C784", alpha = 0.55, linewidth = 0.3) +
  geom_spatvector(data = streams_ncos, aes(color = "Devereux Creek & Channels"), linewidth = 1.6) +
  geom_spatvector(data = bike_paths_ncos, aes(color = "Legacy Bikeways (2016 ICM)"), linewidth = 1.1, linetype = "dashed") +
  geom_spatvector(data = ncos_trails, aes(color = "Modern NCOS Trails (2018-2022)"), linewidth = 1.3) +
  geom_spatvector(data = actual_crossings_disagg, aes(shape = "Unrecorded Bridge Crossing"), fill = "#FF1744", color = "black", size = 6, stroke = 1.5) +
  scale_color_manual(
    name = "Linear Infrastructure & Hydrology",
    values = c(
      "Devereux Creek & Channels" = "#0288D1",
      "Modern NCOS Trails (2018-2022)" = "#2E7D32",
      "Legacy Bikeways (2016 ICM)" = "#37474F"
    ),
    guide = guide_legend(override.aes = list(linewidth = c(1.6, 1.3, 1.1), linetype = c("solid", "solid", "dashed")), order = 1)
  ) +
  scale_fill_manual(
    name = "Ecological Restoration",
    values = c("Restored Wetland Habitat" = "#C8E6C9"),
    guide = guide_legend(order = 2)
  ) +
  scale_shape_manual(
    name = "Data Omission / Reality",
    values = c("Unrecorded Bridge Crossing" = 21),
    guide = guide_legend(override.aes = list(fill = "#FF1744", size = 6, color = "black"), order = 3)
  ) +
  annotate(
    "text", x = -119.8770, y = 34.4214,
    label = "Missing Devereux Creek Crossing\n(Bridge constructed ~2020 by CCBER)",
    fontface = "bold", size = 4.2, color = "#B71C1C", hjust = 0.5
  ) +
  annotate(
    "text", x = -119.8710, y = 34.4235,
    label = "<- Legacy 2016 Data Terminates Here",
    fontface = "italic", size = 3.8, color = "#37474F", hjust = 0
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 20, hjust = 0.5),
    plot.subtitle = element_text(size = 13.5, hjust = 0.5, color = "gray25"),
    plot.caption = element_text(size = 10, color = "gray50"),
    axis.title = element_blank(),
    axis.text = element_text(size = 9, color = "gray30"),
    panel.grid = element_line(color = "#E0E0E080", linetype = "dotted"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 0.6),
    legend.position = "bottom",
    legend.box = "horizontal",
    legend.title = element_text(face = "bold", size = 12),
    legend.text = element_text(size = 11),
    legend.key.size = unit(0.8, "cm"),
    legend.spacing.x = unit(0.4, "cm")
  ) +
  coord_sf(expand = FALSE) +
  labs(
    title = "Map 10.5: Data Provenance & The Missing NCOS Bike Trail",
    subtitle = "Comparing legacy 2016 ICM bikeways against post-2018 North Campus Open Space restoration trails",
    caption = "rAtlas Map 10.5 | UCSB Carpentry"
  )

# ---------- 5. Save Publication Figures ----------
ggsave("images/map10_5.png", plot = map10_5_plot, width = 12, height = 9, dpi = 300, bg = "white")
ggsave("final_output/map_10_5.png", plot = map10_5_plot, width = 12, height = 9, dpi = 300, bg = "white")

cat("Map 10.5 saved successfully:\n")
cat(" - images/map10_5.png\n")
cat(" - final_output/map_10_5.png\n")
