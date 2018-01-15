library(shiny)
library(leaflet)
library(leaflet.extras)
library(shinythemes)
library(highcharter)
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
					img(src = "race_tiles_map/logo.png", height = "30", width = "56")
					),""
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
         				
         				conditionalPanel(condition="output.n=='TRUE'",
         					htmlOutput("emailerror")
         					),
         				conditionalPanel(condition="output.us=='TRUE'",
         				textInput("teamname", "Email Address", "")),
						    downloadButton("btnSave", "Submit Districts", class="btn-info"),
                hr(),
                uiOutput("previousmaps"),
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
					"Welcome to Gerrymandering Game Night!"
				),
        h5("This game was designed to simplify the redistricting process to show the impacts gerrymandering can have on electoral politics."),
				p(
					"As we get closer to the national census count in 2020, the influence of gerrymandering on the redistricting process has become a growing topic of interest. The Constitution mandates that the census be conducted every 10 years in order to count the number of people in the country and collect demographic data. This information is key in determining the number of seats each state gets in the US House of Representatives and is used to distribute federal funding to communities across the nation.  Once this data is collected, our state legislature is then tasked with redrawing and reapportioning district lines so that all districts in Texas have approximately the same population – fulfilling the one person, one vote legal requirement."),
				p("Following the 2010 census, Texas was apportioned 36 congressional seats. During this game you will only focus on moving the existing boundaries of the following ten districts: 10, 15, 17, 20, 21, 23, 25, 28, 31, 35.  These districts are all located in Central Texas and reflect 5 Republican and 5 Democratic districts."
          ),
        p(
          "Your team will try to manipulate district populations in a way that strengthens or weakens the representation of your assigned political party – this process is called gerrymandering.  For this game we’ve attempted to balance the variables legislators account for when divvying up districts, such as: population density, median income, voting history, ethnic background, and party preference to create an experience that reflects the political factors legislators interact with when redistricting."
        ),
				hr(),
        h5("What is Gerrymandering?"),
        p("Have you ever looked at a map of Texas’ congressional districts and wondered how San Antonio and El Paso are in the same district? This district spans over 500 miles and takes over 7 hours to drive, yet this entire area is represented by one Congress member. Compared with Texas’ 18th district that almost exclusively serves downtown Houston, we see how different the scope and shape of these districts can be."
          ),
        p("During the redistricting process, legislators can gerrymander the state by including or excluding certain populations when drawing district lines to gain a political advantage. The manipulation of these populations often leave districts in odd, inconsistent shapes and can mean completely different areas of the state can be included in the same district, while neighboring areas of the state can be split up."
          ),
        p("In order to gerrymander, legislators use the technique of “packing” and “cracking” populations in order to influence the ways districts are represented."
          ),
        tags$ul(h6("• Packing - this is when a political party concentrates the opposition party’s voters into a few districts in order to reduce the opposition’s voting power. This creates districts that are heavily in favor of the opposition’s party, reducing that party’s representation in other districts.")),
        tags$ul(h6("• Cracking - this is when a party dilutes supporters of the opposing party by spreading them across many districts. This denies the opposition’s supporters a chance to have group representation in their district.")),

        hr(),
        h5('Rules & Hints'),
        tags$ul("• Ideally each district would have a census population of 698,488. For the purposes of the game, your goal is to aim for a population of 650,000 to 850,000 for each district."),
        tags$ul("• According to the Voting Rights Act, racial and ethnic minority groups may not be intentionally discriminated against. While playing this game, try to preserve existing minority voting strength by keeping “majority - minority” districts."),
        tags$ul("• Although the Texas Constitution does not provide specific requirements for federal districts, your team should try to keep the  following criteria in mind:"),
        tags$ul(tags$ul("• Compactness - Federal law does not require compact districts, but failure to draw reasonably compact districts may be viewed as evidence that the districts have been illegally gerrymandered, as per the Texas Legislative Council.")),
        tags$ul(tags$ul("• Contiguous - The area contained within a district should be in continuous, direct contact.")),
        tags$ul("• Be sure to save your changes as you make them to see how it changes the demographics of the districts."),
        tags$ul("• Get creative when it comes to drawing these districts (legislators definitely do) -- take at look at District 35, represented by Lloyd Doggett to see how small and specific this district was drawn to pack in democratic voters."),
        hr(),
        h5("Gerry's World in the News"),

        HTML("<center><iframe src='https://www.facebook.com/plugins/video.php?href=https%3A%2F%2Fwww.facebook.com%2FKLRUAustinPBS%2Fvideos%2F900138163474614%2F&show_text=0&width=476' width='476' height='476' style='border:none;overflow:hidden' scrolling='no' frameborder='0' allowTransparency='true' allowFullScreen='true'></iframe></center>"),
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