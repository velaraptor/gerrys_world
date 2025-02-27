library(rgdal)    
library(sp)   
library(rgeos)
library(highcharter)

##highcharter tooltip percentage
hcoptslang <- getOption("highcharter.lang")
hcoptslang$thousandsSep <- ","
options(highcharter.lang = hcoptslang)

##to write polygons as shapefile
writeRasterZip <- function(x, file, filename, format, ...) {

  if (format=="ESRI Shapefile") {
    writeOGR(x, "./", filename, format, overwrite_layer=T, check_exists=T)
  } else {
    writeRaster(x, filename, format, bylayer=F, overwrite=T, ...)
  }

  f <- list.files(pattern=paste0(strsplit(filename, ".", fixed=T)[[1]][1], ".*"))
  zip(paste0(filename, ".zip"), f, flags="-9Xjm", zip="zip")
  file.copy(paste0(filename, ".zip"), file)
  file.remove(paste0(filename, ".zip"))
}

isValidEmail <- function(x) {
	if(x==""){
		TRUE
		}else{
		grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", as.character(x), ignore.case=TRUE)
	}
}
