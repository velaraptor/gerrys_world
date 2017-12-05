library(shiny)
library(leaflet)
library(leaflet.extras)
library(shinythemes)
library(highcharter)
library(googleAuthR)
library(googleID)
library(shinyjs)

# for loading
appCSS <- "
  #loading-content {
    position: absolute;
    background: #060606;
    opacity: 0.9;
    position: fixed;
    top: 50%;
    left: 50%;
    -webkit-transform: translate(-50%, -50%);
    transform: translate(-50%, -50%);
    text-align: center;
    color: #FFFFFF;
  }"

ui = fluidPage(
	theme = shinytheme("cyborg"),
	tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "icomoon.css"),
    includeScript("www/google_analytics.js"),
    tags$style(
      HTML("
      .btn{
        padding: 2px 12px;
        font-size: 15px;}
      body{
        font-size: 13px;
      }
      .img-circle {
        border-radius: 50%;
      }
      .no-underline:hover {
        text-decoration: none;
        opacity: 0.5;
      }


      ")
    )
  ),
  useShinyjs(),
    inlineCSS(appCSS),

	navbarPage(
		title = div(
				a(
					img(src = "race_tiles_map/logo.png", height = "30", width = "56"),
					href="https://glasshousepolicy.shinyapp.io/gerrys_world"),""
				)
			,
		windowTitle = "Gerrymandering Texas",

    
		tabPanel("Home",
      div(
        id = "loading-content",
        img(src='loader.gif' ,height='60px'),
        h5("loading map...")
        ),
      hidden(
      div(
      id = "app-content",
				div(class = "outer",
                		tags$head(
                  			tags$link(
                    			rel = "icon", 
                    			type = "image/png", 
                    			href = "race_tiles_map/favicon.png")
                  		)
                ),
  				fluidRow( 
            column(
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
                 p("• Click on district to get more information."),
						    p("• Double click on vertex points to edit districts then save to see how it changes demographics/election results."),
						    p("• Create a team name and submit your districts to be scored.")
						   
						),

  					column(
  						width = 7,
         			leafletOutput("map",height = "630px")
         		),
         		column(
              width=3,
					    htmlOutput("score"),
					    htmlOutput("pop"),
					    hr(),
					   fluidRow(
						    column(
                  width=6,
         				  highchartOutput("pres_pie", height = "200px")
                ),
                column(
                  width=6,
                	highchartOutput("rep_pie", height = "200px")
                )
              ),
              hr(),
              htmlOutput("districtname"),
				      htmlOutput("text"),
				      htmlOutput("income")
  						
  					)
         
  			),
        conditionalPanel(condition="output.msc=='TRUE'",
          fluidRow(
  				  hr(),
  				  htmlOutput('districtname_header'),
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
        hr(),
      	HTML("<footer>
      				<font size='1px'>
              <img src ='https://glasshousepolicy.org/wp-content/themes/glasshousepolicy/images/global/glasshouse_logo_wt.svg' height='20'></img><br>
              * Disclaimer: Congressional Districts are abstract simplified polygons. They are not the exact lines that are used for the House of Representatives.</font>
              </footer>")
		))),
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
					"Welcome to Gerrymandering Game Night! This game was designed to simplify the redistricting process to show the impacts gerrymandering can have on electoral politics."
				),
				p(
					"Click the edit button to edit the congressional districts to ungerrymander or gerrymander the citizens of Texas."),
				p(
          "Our hope is that we can not only teach people how gerrymandering works at a state level, but potentially allow users to crowd source the lines to help legislators and the courts get a better idea of what the citizens of Texas believe are just and fair district lines."
        ),
				hr(),
      	HTML("<footer>
      				<font size='1px'>
              <img src ='https://glasshousepolicy.org/wp-content/themes/glasshousepolicy/images/global/glasshouse_logo_wt.svg' height='20'></img><br>
              * Disclaimer: Congressional Districts are abstract simplified polygons. They are not the exact lines that are used for the House of Representatives.</font>
              </footer>")
				),
		tabPanel("Leaderboard",
        DT::dataTableOutput('tbl'),hr(),
      	HTML("<footer>
      				<font size='1px'>
              <img src ='https://glasshousepolicy.org/wp-content/themes/glasshousepolicy/images/global/glasshouse_logo_wt.svg' height='20'></img><br>
              * Disclaimer: Congressional Districts are abstract simplified polygons. They are not the exact lines that are used for the House of Representatives.</font>
              </footer>"))

	)

)