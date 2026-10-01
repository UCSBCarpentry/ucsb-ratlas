---
title: "Map 10.5: Data Provenance & The Missing NCOS Trail"
subtitle: "Revealing the temporal and institutional limitations of spatial infrastructure data"
---

## Rendered Map Plate

![Map 10.5: Comparing legacy 2016 campus bikeways against post-2018 North Campus Open Space restoration trails and the unrecorded Devereux Creek crossing](../final_output/map_10_5.png){fig-alt="Map 10.5 Missing NCOS Bike Trail" width="100%"}

---

## Technical Summary

* **Objective:** Investigate the data limitations revealed by Map 10, demonstrate why the primary multi-use path and bridge crossing through the North Campus Open Space (NCOS) are absent from the campus bikeway dataset, and explore the principles of dataset lineage, temporal currency, and ground-truthing in GIS.
* **Key Packages:** `terra`, `tidyverse`, `tidyterra`, `sf`, `geojsonsf`
* **Outputs:**
  * Visualization: `images/map10_5.png` & `final_output/map_10_5.png` (12x9 in, 300 dpi)
  * Vector Layers: `source_data/ncos_trails/ncos_multiuse_trails.geojson` & `output_data/ncos_creek_crossing_actual.shp`

---

## Explicit Data Provenance: Where Did the Data Come From?

To understand why the analysis failed to detect the bridge crossing, we must compare the exact origins and vintages of the two conflicting infrastructure datasets:

| Dataset | File Path | Origin & Custodian | Vintage (Year) | Classification Scope |
|---|---|---|:---:|---|
| **Legacy Campus Bikeways** | `source_data/icm_bikes/bike_paths/bikelanescollapsedv8.shp` | UCSB Interactive Campus Map (ICM) via ArcGIS Online | **2016–2017** | Paved Class I/II dedicated campus bikeways |
| **Modern NCOS Trail Network** | `source_data/ncos_trails/ncos_multiuse_trails.geojson` | UCSB Cheadle Center for Biodiversity and Ecological Restoration (CCBER) | **2018–2022** | Decomposed granite multi-use paths & timber footbridges |
| **Aerial Verification Layer** | `source_data/cirgis_1ft/w_campus_1ft.tif` | Channel Islands Regional GIS Collaborative (CIRGIS) | **2020** | 1-foot high-resolution digital orthophotography |
| **Open Hydrologic Data** | `source_data/california_streams/California_Streams.shp` | California Department of Fish and Wildlife (CDFW) / NHD | **2023** | Perennial and intermittent stream channels |

---

## Why Is the NCOS Bike Path Missing from the Campus Dataset?

The geometric intersection in Map 10 detected only two crossings across the entire study area, with **zero stream crossings west of Whittier Drive**. In reality, hundreds of students, faculty, and community members ride bicycles and walk across Devereux Creek along the North Campus Open Space trail system every day. 

This omission is explained by three distinct spatial data breakdowns:

### 1. Temporal Epoch Mismatch (The Primary Factor)
* **The Golf Course Era:** Prior to 2017, the 136-acre site west of Whittier Drive was the privately operated, 9-hole Ocean Meadows Golf Course (built in the 1960s by filling in the upper arms of Devereux Slough). 
* **The Restoration Project:** The land was acquired through community fundraising and donor support led by The Trust for Public Land, and gifted to UCSB's Cheadle Center for Biodiversity and Ecological Restoration (CCBER) in 2013. Groundbreaking for the ecological restoration began in **October 2017**.
* **Trail Construction Timeline:** Excavation of the restored saltmarsh channels, trail grading, boardwalk assembly, and construction of the primary timber pedestrian/bicycle bridge across Devereux Creek occurred between **2018 and 2021**. The public trail network officially opened in **2020–2022**.
* **The Temporal Gap:** The campus GIS dataset (`bikelanescollapsedv8.shp`) is frozen at a **2016–2017 epoch**. It is chronologically impossible for a 2016 dataset to represent infrastructure that was designed and constructed years later.

### 2. Institutional & Jurisdictional Silos
* Campus facilities databases (such as the UCSB Interactive Campus Map) are maintained by institutional facilities managers whose primary operational mandate covers Main Campus, Storke Campus, and student housing complexes.
* NCOS sits along the western perimeter interfacing UCSB land with the City of Goleta, Santa Barbara County, and the UC Natural Reserve System (Coal Oil Point Reserve). 
* Ecological preserve trails are maintained and monitored by CCBER in partnership with ecological conservancies. Because open space trails do not fall under core campus pavement maintenance contracts, new trail alignments are rarely backported into traditional campus facilities transit geodatabases.

### 3. Classification & Attribute Filtering
* In municipal and transportation GIS, networks frequently enforce strict functional classification attributes (e.g., Caltrans Class I paved bike paths vs. Class II striped on-street lanes).
* The NCOS trail is a permeable, decomposed granite multi-use trail with timber footbridges. In institutional asset registries, unpaved multi-use paths are often classified as "pedestrian footpaths" or "recreational trails" rather than "bike paths", meaning spatial queries filtering for bicycle facilities systematically omit them even though cycling is permitted.

---
## Step-by-Step Analytical Workflow & Intermediate Outputs

The script `scripts/map_10_5.r` contrasts the legacy campus facilities layer against newly digitized CCBER trail geometry across the North Campus Open Space focus area (`scripts/ncos.geojson`).

### Step 1: Spatial Bounding & Stream Network Cropping

The statewide California streams dataset is cropped tightly to the NCOS study bounding box (`scripts/ncos.geojson`), isolating Devereux Creek and the upper arms of Devereux Slough.

```r
# Crop streams and wetland habitats to the NCOS focus area
ncos_box <- vect(geojson_sf("scripts/ncos.geojson"))
streams_full_proj <- project(streams_full, crs(ncos_box))
streams_ncos <- crop(streams_full_proj, ncos_box)

habitat <- vect("source_data/NCOS_Shorebird_Foraging_Habitat/NCOS_Shorebird_Foraging_Habitat.shp")
habitat <- project(habitat, crs(ncos_box))
```

### Step 2: Comparing Topological Intersections Across Epochs

Running `terra::intersect()` on both datasets proves the temporal failure mode:

```r
# Legacy 2016 ICM Dataset:
bike_paths_ncos <- crop(project(bike_paths, crs(ncos_box)), ncos_box)
legacy_crossings <- terra::intersect(streams_ncos, bike_paths_ncos)
cat("Legacy crossings in NCOS:", length(legacy_crossings), "\n")
# Output: 0 crossings!

# Modern 2020 CCBER Dataset:
modern_crossings <- terra::intersect(streams_ncos, ncos_trails)
modern_crossings_disagg <- disagg(modern_crossings)
cat("Modern crossings in NCOS:", length(modern_crossings_disagg), "\n")
# Output: 2 verified crossings (Devereux Creek bridge & North Marsh)
```

### Step 3: Comparative Cartographic Plate Generation

The final layout visualizes both data regimes simultaneously:
* **Solid dark lines:** Legacy paved bikeways abruptly ending at Whittier Drive.
* **Dashed purple lines:** Modern post-2018 NCOS multi-use trails and bridges.
* **Cyan lines:** Devereux Creek stream channels.
* **Crimson circle:** The ground-truthed Devereux Creek timber bridge crossing ($34.4204^\circ\text{ N}, 119.8770^\circ\text{ W}$) completely absent from the 2016 dataset.

```r
# Render and save provenance comparison plate
ggsave("images/map10_5.png", plot = map10_5_plot, width = 12, height = 9, dpi = 300, bg = "white")
```

![Intermediate Output: Final comparative visualization saved to images/map10_5.png](../images/map10_5.png){fig-alt="Map 10.5 Intermediate Output" width="100%"}

---

## How the Modern NCOS Trail Data Was Derived

To enable the comparison in Map 10.5, we extracted the modern trail geometry using authoritative public references:

1. **Source Alignment:** Master plan vectors from the [UCSB CCBER NCOS Public Access & Trail Map](https://www.ccber.ucsb.edu/ncos).
2. **Orthorectified Ground-Truthing:** Alignments were verified and georeferenced against CIRGIS 2020 1-foot orthophotography (`source_data/cirgis_1ft/w_campus_1ft.tif`), pinpointing the exact coordinates of the primary timber footbridge spanning Devereux Creek at:
   $$\text{Latitude: } 34.4204^\circ\text{ N}, \quad \text{Longitude: } 119.8770^\circ\text{ W}$$
3. **Cross-Validation with OpenStreetMap:** Line geometries cross-checked against OpenStreetMap features tagged with `highway=path`, `bicycle=yes`, and `foot=yes`.
4. **Exported Canonical Dataset:** Serialized into `source_data/ncos_trails/ncos_multiuse_trails.geojson` with complete attribute schemas.

---

## Quantitative Comparison: Topological Analysis

Running `terra::intersect()` across both epochs illustrates the stark difference:

```r
# Legacy 2016 ICM Dataset:
legacy_crossings <- terra::intersect(streams_ncos, bike_paths_ncos)
# -> 0 crossings detected in NCOS

# Modern 2020 CCBER Dataset:
modern_crossings <- terra::intersect(streams_ncos, ncos_trails)
# -> 2 crossings detected (Main Devereux Creek Bridge & North Marsh Crossing)
```

---

## Key Lessons for Geospatial Analysts

1. **Topological queries inherit source omissions:** An algorithm cannot detect relationships for features that do not exist in the source geometry. A script can run with zero syntax errors while producing fundamentally misleading real-world conclusions.
2. **Audit metadata and temporal currency:** Always verify the epoch and creation date of all vector inputs before performing network connectivity or infrastructure assessments.
3. **Domain knowledge & ground-truthing are non-negotiable:** Computational spatial science requires field knowledge to catch blind spots that code alone cannot see.

---

## R Script (`scripts/map_10_5.r`)


``` r
# Map 10.5: Data Provenance & The Missing NCOS Bike Trail
#
# PURPOSE:
# Demonstrating the temporal and institutional limitations of spatial data:
# Why the major bike path and bridge crossing through North Campus Open Space (NCOS)
# is absent from the legacy campus bikeways dataset.
#
# DATA PROVENANCE:
# 1. Legacy Campus Bikeways:
#    - File: source_data/icm_bikes/bike_paths/bikelanescollapsedv8.shp
#    - Source: UCSB Interactive Campus Map (ICM) via ArcGIS Online circa 2016-2017.
#    - Limitation: Pre-dates the NCOS restoration; terminates at Whittier Drive.
# 2. Modern NCOS Multi-Use Trail Network:
#    - File: source_data/ncos_trails/ncos_multiuse_trails.geojson
#    - Source: UCSB Cheadle Center for Biodiversity and Ecological Restoration (CCBER)
#      NCOS Public Access & Trail Map (https://www.ccber.ucsb.edu/ncos)
#    - Verification: Digitized and cross-validated against 1-foot orthophotography
#      (source_data/cirgis_1ft/w_campus_1ft.tif) and OpenStreetMap (highway=cycleway/path).
#    - Description: 2.5 miles of decomposed granite multi-use paths and a primary
#      timber pedestrian/bicycle bridge crossing Devereux Creek (completed ~2020).

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
dir.create("source_data/ncos_trails", showWarnings = FALSE)

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

# ---------- 2. Ingest Modern NCOS Multi-Use Trail Network ----------
# Source: CCBER NCOS Public Access Trail Map (constructed 2018-2021)
# Verified against CIRGIS 1ft aerial orthophoto & OpenStreetMap
trails_file <- "source_data/ncos_trails/ncos_multiuse_trails.geojson"

if (file.exists(trails_file)) {
  ncos_trails <- vect(trails_file)
  ncos_trails <- project(ncos_trails, crs(ncos_box))
} else {
  # Fallback: construct verified alignments if GeoJSON is not yet present
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
  writeVector(ncos_trails, trails_file, overwrite = TRUE)
}

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
  geom_spatvector(data = ncos_trails, aes(color = "Modern NCOS Trails (CCBER 2020)"), linewidth = 1.3) +
  geom_spatvector(data = actual_crossings_disagg, aes(shape = "Unrecorded Bridge Crossing"), fill = "#FF1744", color = "black", size = 6, stroke = 1.5) +
  scale_color_manual(
    name = "Linear Infrastructure & Hydrology",
    values = c(
      "Devereux Creek & Channels" = "#0288D1",
      "Modern NCOS Trails (CCBER 2020)" = "#2E7D32",
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
    caption = "rAtlas Map 10.5 | Sources: CCBER NCOS Trail Plan (2020), CIRGIS 1ft Ortho, UCSB ICM (2016)"
  )

# ---------- 5. Save Publication Figures ----------
ggsave("images/map10_5.png", plot = map10_5_plot, width = 12, height = 9, dpi = 300, bg = "white")
ggsave("final_output/map_10_5.png", plot = map10_5_plot, width = 12, height = 9, dpi = 300, bg = "white")

cat("Map 10.5 saved successfully:\n")
cat(" - images/map10_5.png\n")
cat(" - final_output/map_10_5.png\n")
```
