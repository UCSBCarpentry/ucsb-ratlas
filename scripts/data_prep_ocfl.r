library(jsonlite)
library(curl)


#' Download files for an object in an OCFL storage root over http(s). 
#' This assumes the storage root uses a flat-direct layout. It helps to be 
#' familiar with the OCFL spec, especially the inventory.json structure: 
#' https://ocfl.io/1.1/spec/#inventory
#' 
#' @param ocfl_base_url URL for the OCFL storage root, served over http(s)
#' @param object_id The ID for an existing object in the OCFL storage root
#' @param version the object version to download (defaults to most recent version)
#' @param download_dir local folder where files are downloaded
#' 
ocfl_download <- function(ocfl_base_url, object_id, version="", download_dir="."){
  
  # base url for the object (assumes the OCFL root uses flat-direct layout).
  object_base_url <-paste(ocfl_base_url, object_id, sep="/")
  
  # url to object's root inventory.json
  inventory_url <- paste(object_base_url, "inventory.json", sep="/")
  
  # Download and parse the object inventory
  inventory <- fromJSON(inventory_url)
  manifest <- inventory$manifest
  if (version == "") {
    version <- inventory$head
  }
  state <- inventory$versions[[version]]$state
  # TODO: check that state is not null
  
  # we will build vectors of URLs to download and files to copy so we can use 
  # multi_download
  download_sources <- c() # URLs to download
  download_dests <- c()   # local paths for downloads
  copy_sources <- c()     # local source of a downloaded file
  copy_dests <- list()    # local dest for copy of download
  
  # build vectors
  for (digest in names(state)){
    
    # logical_names is a list paths in the object version state with the digest
    logical_names <- state[[digest]] 
    # FIXME: paths in logical_names always use '/' as the path separator (it's 
    # defined in the OCFL spec). As a result local_file may not work on Windows: 
    # Need to convert logical_names[1] to use platform path separator.
    local_file <- file.path(download_dir, logical_names[1])
    
    # remote_name is the path to the content with the given digest 
    # relative to the object: use it to build download URL.
    remote_name <- manifest[[digest]][1]
    src_uri <- paste(object_base_url, remote_name, sep="/")
    download_sources <- c(download_sources, src_uri)
    download_dests <- c(download_dests, local_file)

    # build all directories we need before we download
    local_dir <- dirname(local_file)
    if (!dir.exists(local_dir)) {
      dir.create(local_dir, recursive = TRUE)
    }
    
    # build copy source/dest vectors if logical_names has
    # more than one entry
    if(length(logical_names) > 1) {
      copy_sources <- c(copy_sources, local_file)
      names <- state[[digest]][2:length(state[[digest]])]
      names <- file.path(download_dir, names)
      copy_dests <- c(copy_dests, names)
    }
  }
  
  # do downloads
  multi_download(download_sources, destfiles = download_dests, progress=TRUE)
  
  # do copies
  i <- 1
  for(local_source in copy_sources) {
    for(local_dest in copy_dests[[i]]){
      local_dir <- dirname(local_dest)
      if (!dir.exists(local_dir)) {
        write(paste("mkdir", local_dir), stderr())
        dir.create(local_dir, recursive = TRUE)
      }
      write(paste("copy", local_source, "->", local_dest), stderr())
      file.copy(local_source, local_dest)
    }
    i <- i+1
  } # copy loop
  
}

ocfl_root <- "https://dreamlab-public.s3.us-west-2.amazonaws.com/ocfl"
object_id <- "geospatialRUCSBAtlas-data"
ocfl_download(ocfl_root, object_id, download_dir="source_data")


## Work in progress
download_if_changed <- function(uri, localfile) {
  head_handle <- new_handle()
  handle_setopt(head_handle, customrequest = "HEAD", nobody = TRUE)
  resp <- curl_fetch_memory(uri, handle = head_handle)
  headers <- parse_headers_list(resp$headers)
  size <- as.numeric(headers[['content-length']])
  mtime <- curl::parse_date(headers$`last-modified`)
  f_info <- file.info(localfile)
  if(is.na(f_info$size) || size != f_info$size || mtime != f_info$mtime){
    write(paste("downloading to", localfile), stderr())
    curl_download(uri, dstfile)
    Sys.setFileTime(dstfile, modtime)
    return(TRUE)
  }
  write(paste(localfile, "is unchanged"), stderr())
  return(FALSE)
}

