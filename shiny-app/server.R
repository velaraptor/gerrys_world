##leaflet spatial data libs requirements
library(rgdal)    
library(sp)   
library(rgeos)
library(rmapshaper)
library(leaflet)
library(leaflet.extras)

##database & json libs
library(RPostgreSQL)
library(DBI)
library(rpostgis)

##data manipulation tables
library(dplyr)
library(data.table)
library(DT)

##shiny & graphs
library(shinythemes)
library(shiny)
library(shinyjs)
library(highcharter)
library(googleAuthR)
library(googleID)

source("helper.R")
source("postgres_creds.R")
aws_server = 'http://ec2-34-212-119-75.us-west-2.compute.amazonaws.com'

server = function(input, output, session) {
	##authentication events
	rv = reactiveValues(
        login = FALSE
    )

	access_token = callModule(googleAuth, "loginButton")
	##our reactive spdf polygon initiated 
	fixed_spdf = reactiveValues()
	userDetails = reactive({
        validate(
            need(access_token(), "")
        )

        rv$login <- TRUE
        with_shiny(get_user_info, shiny_access_token = access_token())
    })

    output$user_image = renderUI({
		validate(
			need(userDetails(), HTML(""))
		)
		HTML(
			paste0("<div class='row'><div class='col-sm-2'><img class='img-circle' src='",
  					userDetails()$image$url,
  					"' height='30px'></div><div class='col-sm-10'>",
  					p(userDetails()$displayName),
  					"</div></div>"
  			)
  		)
    })

    observe({
    	if(rv$login){
    		output$n=reactive({
	 			return("FALSE")
	 		})
    	}
    	else{
    	    	output$n=reactive({
	 				return("TRUE")
	 			})
    	}
    	outputOptions(output, 'n', suspendWhenHidden=FALSE)
    })

    observe({
    	if(is.null(input$map_shape_click)){
    		output$msc=reactive({
	 			return("FALSE")
	 		})
    		}else{
    			output$msc=reactive({
	 				return("TRUE")
	 				})
    		}
    	outputOptions(output, 'msc', suspendWhenHidden=FALSE)
    })

    observe({
    	validate(
            need(userDetails(), ""))
    		if(is.null(userDetails()$gender)){
    			gender = "NA"
    			}else{
    				gender = userDetails()$gender
    			}
            user_info=data.frame(userDetails()$displayName,gender,userDetails()$emails$value)
            names(user_info)=c("displayname","gender","email")
            connection = connection_creds()
            count=dbGetQuery(connection,paste0("SELECT COUNT(*) FROM usr_info WHERE email ='",userDetails()$emails$value,"'"))
            dbDisconnect(connection)
            if(count$count==0){
            	connection = connection_creds()
            	dbWriteTable(connection, c("public","usr_info"), value=user_info,append=TRUE, row.names=FALSE)
            	dbDisconnect(connection)
            }
        
    })

    ## code beginning getting district polygons from db 
	fixed_spdf$df <- NULL
	connection = connection_creds()
    congressional_geoms = dbGetQuery(connection,
    	"SELECT __gid AS gid,cd115fp, d,r,winner,st_astext(geom) AS geom FROM small_tracts_clean "
    	)
     total_amount = dbGetQuery(connection,
    	"SELECT SUM(d)/(SUM(r)+SUM(d)) AS d_percent, SUM(r)/(SUM(r)+SUM(d)) AS r_percent FROM president_race"
    	)

    summary_stats = dbGetQuery(connection,"SELECT * FROM house_district_summ_stats")
    
    ##read WKT of POSTGIS query for congressional districts
    for(i in seq(nrow(congressional_geoms))){
		if(i == 1){
			p <- readWKT(congressional_geoms$geom[i], id = congressional_geoms$gid[i])
		}
		else{
			p=rbind(p,readWKT(congressional_geoms$geom[i], id = congressional_geoms$gid[i]))
			}
	}
    
    t = data.frame(congressional_geoms,row.names = congressional_geoms$gid)
    congress_geom_sppdf = SpatialPolygonsDataFrame(p,t[-6])
    crs.geo = CRS("+proj=longlat +datum=WGS84 +ellps=WGS84")
    proj4string(congress_geom_sppdf) = crs.geo

    district_spdf = congress_geom_sppdf
        
    ##make district_spdf reactive, be able to edit winner, and population totals, and geoms 

    district_summary=read.csv("district_summary.csv")
    income_by_district=read.csv("income_by_district.csv")
    race_numbers=read.csv("race_by_district.csv")

    static_race_numbers=read.csv("race_by_district.csv")
    static_votes_numbers = district_spdf@data
    district_spdf=merge(district_spdf,race_numbers,by="gid")

    dbDisconnect(connection)
    
    factpal = colorFactor(c("#3E66F3","#ff6750"), district_spdf$winner)
    popup = paste0("<h6><font color='#000000'>District Number:</font><b><font color='#2a9fd6'> ",
    			district_spdf@data$cd115fp,
    			"</h5></font></b><b><font color='#ff6750'>Republican Votes:</font></b> ",
    			prettyNum(
    				round(
    					district_spdf@data$r
    				),
    				big.mark = ","
    			),
    			"<br><b><font color='#3E66F3'>Democrat Votes: </font></b> ",
				prettyNum(
					round(
						district_spdf@data$d
					),
					big.mark=",")
			)

	output$map = renderLeaflet({
		leaflet() %>% 
		
		enableTileCaching() %>%
		addProviderTiles(
			providers$CartoDB.DarkMatter,
			options = providerTileOptions(minZoom = 6, maxZoom = 10),
			group = "Default") %>%
        setView(
        	lng = -99.2, 
        	lat = 31.2643298807937, 
        	zoom = 6) %>% 
        addTiles(
        	urlTemplate = paste0(aws_server,"/map_tiles/race/{z}/{x}/{y}.png"),
        	group = "Hispanic",
        	options = providerTileOptions(minZoom = 6, maxZoom = 10, errorTileUrl='http://openlayers.org/api/img/blank.gif')) %>% 
        addTiles(
        	urlTemplate = paste0(aws_server,"/map_tiles/white/{z}/{x}/{y}.png"),
        	group = "White",
        	options = providerTileOptions(minZoom = 6, maxZoom = 10, errorTileUrl='http://openlayers.org/api/img/blank.gif')) %>%
        addTiles(
        	urlTemplate=paste0(aws_server,"/map_tiles/black/{z}/{x}/{y}.png"),
        	group = "Black",
        	options = providerTileOptions(minZoom = 6, maxZoom = 10, errorTileUrl='http://openlayers.org/api/img/blank.gif')) %>%
        addTiles(
        	urlTemplate = paste0(aws_server,"/map_tiles/asian/{z}/{x}/{y}.png"),
        	group = "Asian",
        	options = providerTileOptions(minZoom = 6, maxZoom = 10, errorTileUrl='http://openlayers.org/api/img/blank.gif')) %>%
        addTiles(
        	urlTemplate = paste0(aws_server,"/map_tiles/native/{z}/{x}/{y}.png"),
        	group = "Native",
        	options = providerTileOptions(minZoom = 6, maxZoom = 10, errorTileUrl='http://openlayers.org/api/img/blank.gif')) %>%
        addTiles(
        	urlTemplate = paste0(aws_server,"/map_tiles/repubs/{z}/{x}/{y}.png"),
        	group = "Republicans",
        	options = providerTileOptions(minZoom = 6, maxZoom = 10, errorTileUrl='http://openlayers.org/api/img/blank.gif')) %>%
        addTiles(
        	urlTemplate = paste0(aws_server,"/map_tiles/dems/{z}/{x}/{y}.png"),
        	group = "Democrats",
        	options = providerTileOptions(minZoom = 6, maxZoom = 10, errorTileUrl='')) %>%
       
  		addMiniMap(tiles=providers$CartoDB.DarkMatter,toggleDisplay = TRUE,
    				position = "bottomleft") %>%
        addPolygons( 
			data = district_spdf,
			fillOpacity = 0.15,
			color = 'white',
			fillColor = ~factpal(winner),
			weight = 1.5,
			layerId = district_spdf@data$gid,
			label = paste0("District ",district_spdf@data$cd115fp),
			smoothFactor = 0.2,
			stroke = TRUE, 
			opacity = 1,
			group='Congressional Districts',
			highlightOptions = highlightOptions(
                color='#A8A8A8', opacity = 1, weight = 3, fillOpacity = .25,
                bringToFront = TRUE, sendToBack = TRUE)) %>%
        addDrawToolbar(
        	polylineOptions = F,
        	polygonOptions = F,
			circleOptions = F,
			rectangleOptions = F,
			markerOptions = F,
			targetGroup = 'Congressional Districts',
			editOptions = editToolbarOptions(
				selectedPathOptions = selectedPathOptions(maintainColor=TRUE),remove=F
			)
		) %>%
		addFullscreenControl() %>% 
        addLayersControl(
        	overlayGroups = c(
        		'Congressional Districts',
        		"Default",
        		"Hispanic",
        		"White",
        		"Black",
        		"Asian",
        		"Native",
        		"Republicans",
        		"Democrats"), 
        	options = layersControlOptions(collapsed=TRUE)) %>% 
        hideGroup("Hispanic") %>% 
        hideGroup("White") %>% 
        hideGroup("Black") %>% 
        hideGroup("Asian") %>% 
        hideGroup("Native") %>% 
        addLegend("bottomright", 
        	colors =
        		c("#ff2124", "#f3f019","#00e121", "#ff7f00", "#a6cee3"),
        	labels = 
        		c("White","Black","Hispanic","Asian","Native"),
        	title = "Racial Dot Legend",
        	opacity = 1) 
      
    })
    
    ##probably the only thing that stays static
    output$pres_pie = renderHighchart({
    	highchart() %>% 
      	hc_add_series_labels_values(
      		c("Democrats","Republicans"),
			c(round(total_amount$d_percent,2),round(total_amount$r_percent,2)),
			type = "pie",
			colors = c("#3E66F3","#ff6750"),
			name = "Percent of Votes",
			dataLabels = list(enabled = FALSE)) %>%
      	hc_tooltip(style = list(fontSize='10px')) %>%
		hc_title(
			text = "Presidential Results",
			style = list(color="#ffffff",fontSize='10px'))
    })

    ##event from click feature to show graphs and text from district
    observe({
    	click<-input$map_shape_click
    	if(is.null(click))
            return()
    	dist_data = fixed_spdf$df@data
    	dist_data$total = rowSums(dist_data[,c(6:10)])
    	dis_numbers = dist_data[dist_data$gid==click$id,]
    	ic = income_by_district[income_by_district$gid==dis_numbers$gid,]

		ss = static_race_numbers[static_race_numbers$gid==dis_numbers$gid,]
		st = static_votes_numbers[static_votes_numbers$gid==dis_numbers$gid,]
		
		summary = district_summary[district_summary$district==as.numeric(dis_numbers$cd115fp),2]
		
		output$votes_chart=renderHighchart({
			highchart() %>% 
			hc_add_series_labels_values(
				c("Republican","Democrat"), 
				c(round(dis_numbers$r),round(dis_numbers$d)), 
				name = "Votes",
				colorByPoint = TRUE, 
				type = "column",
				colors = c("#FF4C4C","#3E66F3")) %>% 
          hc_xAxis(
				categories = 
				c("Republican","Democrat")) %>% 
          hc_add_series(
				data=c(round(st$r),round(st$d)), 
				name = "Actual Votes",
				type = "column",
				color = "#c081e0")
		})

		output$districtname=renderUI({
			HTML(paste(h5("District ",as.numeric(dis_numbers$cd115fp))))
			})

		output$districtname_header=renderUI({
			HTML(paste(h3("District ",as.numeric(dis_numbers$cd115fp), "Demographics")))
			})

		output$text = renderUI({
			HTML(
				paste(
					p(summary),
					h6(
						paste0(
							"Total Population: ", 
							prettyNum(round(dis_numbers$total),big.mark = ",")
						)
					)
				)
			)
		})

		output$race_chart=renderHighchart({
			highchart() %>% 
				hc_add_series_labels_values(
					c("White","Black","Hispanic","Asian","Native"), 
					c(round(dis_numbers$white),round(dis_numbers$black),round(dis_numbers$hispanic),round(dis_numbers$asian),round(dis_numbers$native)), 
					name = "Population",
					colorByPoint = TRUE, 
					type = "column",
					colors = c("#ff2124",'#f3f019',"#44ca4a",'#ff7f00','#a6cee3')) %>% 
				hc_xAxis(
					categories = 
						c("White","Black","Hispanic","Asian","Native")
				) %>% 
				hc_add_series(
					data=
					c(round(ss$white),round(ss$black),round(ss$hispanic),round(ss$asian),round(ss$native)), 
					name = "Actual Population",
					type = "column",
					color = "#c081e0")
		})

		output$income=renderUI({
			HTML(
				paste(
					h6(
						paste0(
							"Median Income: $", 
							prettyNum(ic$round,big.mark = ",")
						)
					)
				)
			)
		})
	})

	fixed_spdf$df = district_spdf

	total_districts_by_party = reactive({
    		fixed_spdf$df@data %>% group_by(winner) %>% summarise(count=n())
    })

	population = reactive({
		total = as.data.frame(
			cbind(
				cd115fp=fixed_spdf$df@data$cd115fp,
				total=fixed_spdf$df@data$hispanic+
						fixed_spdf$df@data$white+
						fixed_spdf$df@data$black+
						fixed_spdf$df@data$asian+
						fixed_spdf$df@data$native)
			)
		total$total = as.numeric(as.character(total$total))
		total$rmse = abs(summary_stats$mean-total$total)
		for(i in 1:nrow(total)){
			if(total$rmse[i] <= summary_stats$std*3){
				total$check[i] = "good"
			}else if(total$rmse[i] > summary_stats$std*3){
				total$check[i] = "fix"
			}
		
		}
		counts_pop = total %>% group_by(check) %>% summarise(count=n())
		if(counts_pop[counts_pop$check=='good',2]<10){
			fixes=total[total$check=='fix',]
			paste0("Population districts are not even!", br(),"Districts to fix: ",   paste(fixes$cd115fp,collapse = ", "))
		}else{
			"Population is even across districts."
		}
		
	})

	population_score = reactive({
				total = as.data.frame(
			cbind(
				cd115fp=fixed_spdf$df@data$cd115fp,
				total=fixed_spdf$df@data$hispanic+
						fixed_spdf$df@data$white+
						fixed_spdf$df@data$black+
						fixed_spdf$df@data$asian+
						fixed_spdf$df@data$native)
			)
		total$total=as.numeric(as.character(total$total))
		total$rmse=abs(summary_stats$mean-total$total)
		sum(total$rmse)
	})

	observe({
		output$pop = renderUI({
			HTML(
				paste(
					"<center><h6><font color='#2a9fd6'>",
					population(),
					"</font></h6></center>"
				)
			)
		})
	})

	observe({
		ddd = as.data.frame(total_districts_by_party()$count/sum(total_districts_by_party()$count))
		# only use this line cause we are doing a subset, if not clear the next line
		total_amount$r_percent = .5
		leaning = ddd[2,]-total_amount$r_percent
		if(abs(leaning)>=0 & abs(leaning)<=.04){
			output$score=renderUI({HTML(paste("<center>",h6("Good Districts!"),"</center>"))})
		}else if(leaning>.04 & leaning<=.1){
			output$score=renderUI({HTML(paste("<center>",h6("Districts are Leaning Right!"),"</center>"))})
		}else if(leaning>.1 & leaning<=.2){
			output$score=renderUI({HTML(paste("<center>",h6("Districts are Leaning More Right!"),"</center>"))})
		}else if(leaning>.2 & leaning<=.3){
			output$score=renderUI({HTML(paste("<center>",h6("Districts are Leaning Extremely Right!"),"</center>"))})
		}else if(leaning>.3 & leaning<=1){
			output$score=renderUI({HTML(paste("<center>",h6("Are you trying to eliminate Democrat Representation?"),"</center>"))})
		}else if(leaning<(-.03) & leaning>=(-.1)){
			output$score=renderUI({HTML(paste("<center>",h6("Districts are Leaning Left!"),"</center>"))})
		}else if(leaning<(-.1) & leaning>=(-.2)){
			output$score=renderUI({HTML(paste("<center>",h6("Districts are Leaning More Left!"),"</center>"))})
		}else if(leaning< (-.2) & leaning>=(-.3)){
			output$score=renderUI({HTML(paste("<center>",h6("Districts are Leaning Extremely Left!"),"</center>"))})
		}else if(leaning<(-.3)){
			output$score=renderUI({HTML(paste("<center>",h6("Are you trying to eliminate Republican Representation?"),"</center>"))})
		}
		})

	leaning_score = reactive({
		ddd = as.data.frame(total_districts_by_party()$count/sum(total_districts_by_party()$count))
		leaning = ddd[2,]-total_amount$r_percent
		leaning
		})

	 output$rep_pie = renderHighchart({
		highchart() %>% 
		hc_add_series_labels_values(
			c("Democrats","Republicans"),
			total_districts_by_party()$count,
			type = "pie",
			colors = c("#3E66F3","#ff6750"),
			name = "US Representatives",
			dataLabels = list(enabled = FALSE)) %>%
		hc_tooltip(style = list(fontSize='10px')) %>%
      hc_title(
      	text = "Representatives by Party",
      	style = list(color="#ffffff",fontSize='10px'))
    })

	##the good ole edited map features event 
	observeEvent(input$map_draw_edited_features,{
		withProgress(message = 'Getting Population Numbers', value = 0, {
		if(typeof(input$map_draw_edited_features)=="list"){
			ix = input$map_draw_edited_features
			connection = connection_creds()
			date = Sys.Date()
			random_number = sample(1:100, 1)
			write(RJSONIO::toJSON(ix),paste0("temp/test_",random_number,"_",date,".json"))
			incProgress(.25, detail = paste("Almost done."))
			new_data_race = dbGetQuery(connection,
				paste0(
					"WITH DATA AS (SELECT '",
					RJSONIO::toJSON(ix), 
					"'::json AS fc)
					SELECT
					m.gid,SUM(m.proportion*m.hispanic) AS hispanic, SUM(m.proportion*m.white) AS white,
					SUM(m.proportion*m.black) AS black,SUM(m.proportion*m.asian) AS asian,SUM(m.proportion*m.native) AS native
					FROM
					(SELECT (feat->'properties'->>'layerId')::int AS gid,
					    b.gid AS gid_2, n.hispanic,
					n.white,
					n.black,
					n.native,
					n.asian,
					St_setsrid(St_geomfromgeojson(feat->>'geometry'),4326) AS geom,
					(St_area(St_intersection(b.geom, ST_MAKEVALID(St_setsrid(St_geomfromgeojson(feat->>'geometry'),4326)))) / St_area(b.geom)) AS proportion
					FROM tx_tracts b,
					(SELECT Json_array_elements(fc->'features') AS feat
					 FROM DATA) AS f,
					(SELECT geoid2,
					hd01_vd12 AS hispanic,
					hd01_vd03 AS white,
					hd01_vd04 AS black,
					hd01_vd05 AS native,
					hd01_vd06 AS asian
					FROM race)n 
					WHERE 
					St_intersects(b.geom, ST_MAKEVALID(St_setsrid(St_geomfromgeojson(feat->>'geometry'),4326)))
					AND n.geoid2=CONCAT(b.statefp,b.countyfp,b.tractce)
					AND (St_area(St_intersection(b.geom, ST_MAKEVALID(St_setsrid(St_geomfromgeojson(feat->>'geometry'),4326)))) / St_area(b.geom)) >.6)m
					GROUP BY m.gid;"))
			new_votes_data = dbGetQuery(
				connection,
				paste0(
					"WITH DATA AS (SELECT '",
					RJSONIO::toJSON(ix), 
					"'::json AS fc)                   
					SELECT
					m.gid,SUM(m.proportion*m.d) AS d,SUM(m.proportion*m.r) AS r
					FROM
					(SELECT (feat->'properties'->>'layerId')::int AS gid,
					    b.cntyvtd AS cntyvtd,
					n.r,
					n.d,
					(St_area(St_intersection(b.geom_1, ST_MAKEVALID(St_setsrid(St_geomfromgeojson(feat->>'geometry'),4326)))) / St_area(b.geom_1)) AS proportion
					FROM voting_districts_1 b,
					(SELECT Json_array_elements(fc->'features') AS feat
					 FROM DATA) AS f,
					(SELECT * FROM president_race)n
					WHERE 
					St_intersects(b.geom_1, ST_MAKEVALID(St_setsrid(St_geomfromgeojson(feat->>'geometry'),4326)))
					AND 
					  n.cntyvtd=b.cntyvtd
					AND 
					(St_area(St_intersection(b.geom_1, ST_MAKEVALID(St_setsrid(St_geomfromgeojson(feat->>'geometry'),4326)))) / St_area(b.geom_1)) >.1)m
					GROUP BY m.gid;"))
			dbDisconnect(connection)
			incProgress(.5, detail = paste("Almost done.."))

			g = geojsonio::geojson_read(paste0("temp/test_",random_number,"_",date,".json"),what = "sp")

			g = merge(g,new_votes_data,by.x="layerId",by.y="gid")

			g$winner = ifelse(g$d >= g$r, "D", "R")

			for(i in 1:nrow(g)){
			  g$cd115fp[i] = fixed_spdf$df@data[fixed_spdf$df$gid == g$layerId[i],2]
			}

			names(g)[1] = "gid"
			g = merge(g,new_data_race,by="gid")
			g = g[,-2]
			g = g[c(1,5,2,3,4,6:10)]

			for(i in 1:nrow(g)){
			  fixed_spdf$df@data[fixed_spdf$df$gid == g$gid[i],] = g@data[i,]
			  fixed_spdf$df@polygons[fixed_spdf$df$gid == g$gid[i]] = g@polygons[i]
			}
			incProgress(.25, detail = paste("Almost done..."))
   			popup = paste0("<h6><font color='#000000'>District Number:</font><b><font color='#2a9fd6'> ",
    			fixed_spdf$df@data$cd115fp,
    			"</h5></font></b><b><font color='#ff6750'>Republican Votes:</font></b> ",
    			prettyNum(
    				round(
    					fixed_spdf$df@data$r
    				),
    				big.mark = ","
    			),
    			"<br><b><font color='#3E66F3'>Democrat Votes: </font></b> ",
				prettyNum(
					round(
						fixed_spdf$df@data$d
					),
					big.mark=",")
			)
			observe({
    	  		validate(
            		need(userDetails(), HTML(""))
        		)
    			fixed_spdf$df$user_name = userDetails()$emails$value

    		})

			##need to fix coordinates and popup 
			leafletProxy("map") %>% 
			clearShapes() %>%
			addPolygons( 
			data = fixed_spdf$df,
			fillOpacity = 0.15,
			color = 'white',
			fillColor = ~factpal(winner),
			weight = 1.5,
			layerId = fixed_spdf$df@data$gid,
			label = paste0("District ",fixed_spdf$df@data$cd115fp),
			smoothFactor = 0.2,
			stroke = TRUE, 
			opacity = 1,
			group='Congressional Districts',
			highlightOptions = highlightOptions(
                color='#A8A8A8', opacity = 1, weight = 3, fillOpacity = .25,
                bringToFront = TRUE, sendToBack = TRUE))
			

		}
		}) ##with progress ender 
	})

	
	output$emailerror = renderUI({
		validate(need(isValidEmail(input$teamname),
       			HTML(
       				paste("Please type a valid e-mail address")
       			)
       		)
		)
	})

	##let's download the data for the user and insert it into our database
	observe({
	if(rv$login){
			output$btnSave <- downloadHandler(
			function() 
				{
		
					paste0("gerrymander_districts",
							"_",
							userDetails()$displayName , 
							".zip")

				}, 
			function(file) {
				connection = connection_creds()
				datetime = Sys.time()
				fixed_spdf$df$date = datetime
				pgInsert(connection, name = c("public", "user_data"), data.obj = fixed_spdf$df,overwrite = F,new.id = "id")
				scores_to_insert = as.data.frame(cbind(population_score(),leaning_score(),userDetails()$emails$value,as.character(datetime)))
				names(scores_to_insert) = c("pop","leaning","email","date")
				dbWriteTable(connection, c("public","scores"), value=scores_to_insert,append=TRUE, row.names=FALSE)
				dbDisconnect(connection)
				shp = writeRasterZip(
						fixed_spdf$df, 
						file, 
						userDetails()$displayName,
						format="ESRI Shapefile")

				})
		}else{
				output$btnSave <- downloadHandler(

			function() 
			{
		
				validate(need(isValidEmail(input$teamname),
      			 paste("Please Input a valid E-mail address")))
				paste0("gerrymander_districts",
						"_",
						input$teamname , 
						".zip")

			}, 
			function(file) {
				connection = connection_creds()
				fixed_spdf$df$user_name = input$teamname
				datetime = Sys.time()
				fixed_spdf$df$date = datetime
				pgInsert(connection, name = c("public", "user_data"), data.obj = fixed_spdf$df,overwrite = F,new.id = "id")
				scores_to_insert = as.data.frame(cbind(population_score(),leaning_score(),input$teamname,as.character(datetime)))
				names(scores_to_insert) = c("pop","leaning","email","date")
				dbWriteTable(connection, c("public","scores"), value=scores_to_insert,append=TRUE, row.names=FALSE)
				dbDisconnect(connection)
				shp = writeRasterZip(
						fixed_spdf$df, 
						file,
						input$teamname,
						format="ESRI Shapefile")

			}
			)

		}
	})

	##sign out page to redirect
	observe({
    	if (rv$login) {
        	shinyjs::onclick("loginButton-googleAuthUi",
            	shinyjs::runjs("window.location.href = 'http://localhost:8001/www/login.html';"))
    	}
	})

	##leaderboards FTW 
	connection = connection_creds()
	usr_table = dbGetQuery(connection,"
		SELECT 
			RANK() OVER (ORDER BY score) AS rank,
			email,
			date,
			leaning,
			pop,
			score 
		FROM
			(SELECT 
				email,
				date,
				leaning,
				pop,
				((leaning*5)+(pop/std)/100) AS score
			FROM 
				scores, 
				house_district_summ_stats
			)m 
		ORDER BY score DESC")

	usr_table$date = as.POSIXct(strptime(usr_table$date, "%Y-%m-%d %H:%M:%S"))

	clean_leaderboard = datatable(usr_table,
							style = 'bootstrap',
							options = 
								list(
									order = list(0,"asc"),
									
                                    pageLength = 25, 
                                    autoWidth = TRUE
                                ), 
                            class = 'hover',
                			escape = FALSE,
                			rownames = F,
                			colnames = 
	                			c('Rank',
	                				'E-Mail',
	                			 'Submission Date', 
	                			 'Political Score', 
	                			 'Population Equality Score', 
	                			 'Overall Score')
                		) %>% 
						formatPercentage('leaning', 2) %>% 
						formatRound('score', 3) %>%
						formatRound('pop', 0) %>% 
						formatDate('date', 'toLocaleString') %>% 
                 		formatStyle("email",fontWeight="bold")

	output$tbl = DT::renderDataTable(clean_leaderboard)
	dbDisconnect(connection)
	hide(id = "loading-content", anim = TRUE, animType = "fade")    
  	shinyjs::show(id="app-content")
  	#session$allowReconnect("force")

}
