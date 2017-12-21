FROM openanalytics/r-base

MAINTAINER velaraptor

RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libssl1.0.0 \ 
    libv8-dev \
    libprotobuf-dev \ 
    libgdal1-dev \
    libgdal-dev \
    libgeos-c1v5 \ 
    libproj-dev \
    protobuf-compiler \
    libudunits2-dev

# install for geojsonio dependecies
RUN sudo apt-get install -y software-properties-common python-software-properties
RUN sudo add-apt-repository -y ppa:opencpu/jq
RUN sudo apt-get update
RUN sudo apt-get install -y libjq-dev  

# install R packages
RUN R -e "install.packages(c('rgdal', 'rgeos'), type='source')"
RUN R -e "install.packages(c('devtools','sp','leaflet','DT','dplyr','RPostgreSQL','DBI','shinythemes','shiny','highcharter','googleAuthR','data.table','rpostgis','RJSONIO','shinyjs'), repos='http://cran.rstudio.com/')"
RUN R -e "devtools::install_github('velaraptor/leaflet.extras')"
RUN R -e "devtools::install_github('MarkEdmondson1234/googleID')"
RUN R -e "install.packages('geojsonio', repos ='http://cran.rstudio.com/')"

RUN mkdir /root/gerrys_world
COPY shiny-app /root/gerrys_world

COPY Rprofile.site /usr/lib/R/etc/

EXPOSE 3838

CMD ["R","-e shiny::runApp('/root/gerrys_world',port=3838,host='0.0.0.0')"]