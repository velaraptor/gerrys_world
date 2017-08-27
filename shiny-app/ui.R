library(shiny)
library(leaflet)
library(leaflet.extras)
library(shinythemes)
library(highcharter)
library(googleAuthR)
library(googleID)
library(shinyjs)


ui = fluidPage(
	theme = shinytheme("cyborg"),
	tags$head(
    tags$style(HTML(".btn{padding: 2px 12px;
font-size: 15px;}
body{
	font-size: 13px;
}
.img-circle {
    border-radius: 50%;
}"))),
	navbarPage(
		title = div(
				a(
					img(src = "race_tiles_map/logo.png", height = "30", width = "56"),
					href="https://velaraptor.shinyapp.io/gerrys_world"),""
				)
			,
		windowTitle = "Gerrymandering Texas",
           
		tabPanel("Home",
			useShinyjs(),
				div(class = "outer",
                		tags$head(
                  			tags$link(
                    			rel = "icon", 
                    			type = "image/png", 
                    			href = "race_tiles_map/favicon.png")
                  		)
                ),
  				fluidRow( column(
         				width = 2,
         				
         				htmlOutput("user_image"),
         				br(),
         				googleAuthUI("loginButton"),
         				hr(),
         				conditionalPanel(condition="output.n=='TRUE'",
         					htmlOutput("emailerror")
         					),
         				conditionalPanel(condition="output.n=='TRUE'",
         					textInput("teamname", "Email Address", "")
         					),
						downloadButton("btnSave", "Submit Districts", class="btn-info"),
						hr(),
						h6("Tips:"),
						br(),
						p("• Click on the Edit button ", img(src='edit.png')," to edit the districts."),
						p("• The goal is to make the district representation as close to the election results, while maintaining close to equal population representation."),
						p("• Double click on vertex points to edit districts then save to see how it changes demographics/election results."),
						p("• Create a team name and submit your districts to be scored.")
						),

  					column(
  						width = 8,
         				leafletOutput("map",height = "610px")
         			),
         			column(width=2,
					htmlOutput("score"),
					htmlOutput("pop"),
					hr(),
         				highchartOutput("pres_pie", height = "270px"),
                		highchartOutput("rep_pie", height = "260px")
  						)
						
                	
                	
         
  				),
				hr(),
				selectInput("district_num", 
					"District Demographics:",
		            c("District 1" = "01", "District 2" = "02", "District 3" = "03",
		              "District 4" = "04", "District 5" = "05", "District 6" = "06",
		              "District 7" = "07", "District 8" = "08", "District 9" = "09",
		              "District 10" = "10", "District 11" = "11", "District 12" = "12",
		              "District 13" = "13", "District 14" = "14", "District 15" = "15",
		              "District 16" = "16", "District 17" = "17", "District 18" = "18",
		              "District 19" = "19", "District 20" = "20", "District 21" = "21",
		              "District 22" = "22", "District 23" = "23", "District 24" = "24",
		              "District 25" = "25", "District 26" = "26", "District 27" = "27",
		              "District 28" = "28", "District 29" = "29", "District 30" = "30",
		              "District 31" = "31", "District 32" = "32", "District 33" = "33",
		              "District 34" = "34", "District 35" = "35", "District 36" = "36"
             		),
             		selected = "01"
             	),
				htmlOutput("text"),
				htmlOutput("income"),
				fluidRow(
					column(
						width=6,
						highchartOutput("votes_chart", height = "300px")
					),
         			column(
         				width=6,
         				highchartOutput("race_chart", height = "300px")
         			)
      			)
		),
		tabPanel("How to Play",
				fluidRow(
  					column(
  						12, 
  						align = "center",
  						img(src = "race_tiles_map/logo.png")
  					)
  				),
				hr(),
				h5(
					"The goal of the game is to make districts that are closely equal to the results of the 2016 Presidential Election."
				),
				p(
					"Click the edit button to edit the congressional districts to ungerrymander or gerrymander the citizens of Texas.")
				),
		tabPanel("Leaderboard")

	)
)