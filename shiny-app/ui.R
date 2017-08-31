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
	tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "icomoon.css"),
    tags$style(HTML(".btn{padding: 2px 12px;
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
"))),
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
						p("• Create a team name and submit your districts to be scored."),
						p("• Click on district to get more information.")
						),

  					column(
  						width = 7,
         				leafletOutput("map",height = "630px")
         			),
         			column(width=3,
					htmlOutput("score"),
					htmlOutput("pop"),
					hr(),
					fluidRow(
						column(width=6,
         				highchartOutput("pres_pie", height = "200px")),column(width=6,
                		highchartOutput("rep_pie", height = "200px"))
                		),hr(),htmlOutput("districtname"),
				htmlOutput("text"),
				htmlOutput("income")
  						

  					)
						
                	
                	
         
  				),conditionalPanel(condition="output.msc=='TRUE'",fluidRow(
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
      			),hr(),
      			HTML("<footer>

      				<font size= '5px'>
      				
      				<a href='https://www.linkedin.com/in/christophvel' target='_blank' class='no-underline'><i class='icon-linkedin'></i></a>
      				<a href='https://github.com/velaraptor' target='_blank' class='no-underline'><i class='icon-github'></i></a>
      				</font>
      					<br>
      				<font size='1px'>
      				  © 2017 Gerry's World All Rights Reserved.<br>
                      * Disclaimer: Congressional Districts are abstract simplified polygons. They are not the exact lines that are used for the House of Representatives.</font>
                    </footer>")
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