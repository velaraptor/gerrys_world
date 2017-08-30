library(rgdal)    
library(sp)   
library(rgeos)
library(shiny)
library(leaflet)
library(RPostgreSQL)
library(DBI)
library(leaflet.extras)
library(dplyr)
library(data.table)
library(rmapshaper)
library(shinythemes)
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

options(googleAuthR.scopes.selected = c("https://www.googleapis.com/auth/userinfo.email",
                                        "https://www.googleapis.com/auth/userinfo.profile"))
##live version
options("googleAuthR.webapp.client_id" = "109365349953-6isj32t7hjojludfdsv9lgq77kc34sd9.apps.googleusercontent.com")
options("googleAuthR.webapp.client_secret" = "vpuc-GFQckA2JIYopsP7fsNG")

##local version
##options("googleAuthR.webapp.client_id" = "109365349953-6gftkgddne6phcjvvcpg6ktid4425flg.apps.googleusercontent.com")
##options("googleAuthR.webapp.client_secret" = "Y_HmkwFs3UGK8wLWTIQj8-5d")
options("googleAuthR.securitycode" = "gerrysworld3940582393")
