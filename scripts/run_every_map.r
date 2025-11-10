# a script to run each map.

# start fresh
rm(list=ls())

map_list <- list.files("scripts", pattern='^ma', full.names=TRUE)
map_list

# this runs all the scripts:
# source(map_list[1])


# time for a for loop:
for (map_sheet in map_list) {
  cat("\n******** Running map: ", map_sheet, " *********\n\n")
  tt <- system.time(source(map_sheet))
  cat("\n******** Map sheet ran in ", tt[3], " s *********\n\n")
}



