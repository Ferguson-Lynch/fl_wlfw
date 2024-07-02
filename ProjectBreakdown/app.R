<<<<<<< HEAD
## demo Fed project data

## READ OPTIONS:
##### there are three options. One is a plotly with pie chart. One is Highcharts pie chart. Last is Highcharts Polar chart.
#choose plotly example or highcharter example
plotop<-"h"  #put "p" or "h" here

## choose piechart or polar chart (only available for highcharts)
piepol<-"pie"  #put "pie" or "polar"
 





#############
#libraries 

library(shiny)
library(leafem)
library(sf)
library(stringr)
library(ggplot2)
library(shinyWidgets)
library(leaflet)
library(shinyBS)
library(data.table)
#library(DT)
library(plyr)
library(jsonlite)
library(lubridate)
library(plotly)
library(highcharter)


## main colors
colo<-c("#248c94","#d8c467", "#262525","#9e5846","#76b2a9")

##############################################
# ui side

ui<- fluidPage(
  #bootstrapPage(div(class="outer",
  #tags$style(type = "text/css", "#map {height: calc(99vh - 80px) !important;} .navbar-default {margin-bottom:0;}"),
  
  # set style for fluidRows to only be 40% of the screen height
  tags$style('.rowforty{height:40vh; overflow-y:false;}'),
  tags$style('h2{font-family: "Lucida Grande", "Lucida Sans Unicode", Arial, Helvetica, sans-serif}'),
  
  HTML("<div style='background:#248c94;color:#d8c467;padding:5px;margin-bottom:7px;'>
       <h4><b>Title - e.g. Conservation Project Type Breakdowns</b></h4></div>"),
  
  
fluidRow(
  div(class="rowforty",
      column(width=3, 
             
             #dateRangeInput(inputId = "daterange", "Filter Dates", start="2024-01-01", end=Sys.Date()+1, min="2024-01-01", max=Sys.Date()+1),
             selectInput(inputId = "state", "Choose State:", choices="ALL", selected = "ALL",multiple=T),
             selectInput(inputId = "measure", "Measure Type:", choices="", selected="")
             #downloadButton("downloadData", "Download Filtered Data")
      ), 
      column(width=6,
             if(plotop == "p"){  
             plotlyOutput("mainplot", height="48vh")
               }else{
                 highchartOutput("mainplothc", height="48vh")
             }
               
               )
  )),
  
  br(),HTML('<hr style="height: 2px; border: none; background-color: black;margin:0;">'),
  br(),
  fluidRow(
    div(class="rowforty", 
        
        if(plotop == "p"){ 
        plotlyOutput("typeBreakdownPlot", height="100%")
        }else{
          highchartOutput("typeBreakdownPlothc", height="100%")
        }
  )),

  
 bsModal(id="mapmodal", trigger = NULL, size="large",
         uiOutput("modalheader"),
          leafletOutput("map")
  )
  
) 
#))




##################################################################################################
## server side


server<-function(input, output, session) {
  
  
  projdata<-read.csv("www/transformed_data.csv")
  
  ## zeros are a legacy of transforming the data, filter them out
  projdata<-projdata[projdata$VALUE > 0,]
  
  projdata$type<-str_match(projdata$CP_NAME, "\\|\\s*(.*?)\\s*\\|")[,2]  ## clean up the project types
  
  ## rename the measures to their full names
  category_mapping <- c("Ac" = "Acres", "Ft" = "Feet", "Num" = "Units", "sq ft"="Square Feet")
  # Replace category names
  projdata$UNIT <- ifelse(projdata$UNIT %in% names(category_mapping),category_mapping[projdata$UNIT],projdata$UNIT)
  
  
  
  updateSelectInput(session=session, inputId = "state", choices=c("ALL", unique(projdata$STATE)[order(unique(projdata$STATE))]) , selected="ALL")
  updateSelectInput(session=session, inputId = "measure", choices=c(unique(projdata$UNIT)[order(unique(projdata$UNIT))]) , selected=category_mapping[1])
  
  

  
  
  
  
  ## run a reactive that processes the data, while incorporating what the user has chosen in dropdowns
  filteredDat<-reactive({
    
    dat<-projdata
    
    if(any(input$state != "ALL")){
      
      dat<-dat[dat$STATE %in% input$state,]
    }
    
    dat<-dat[dat$UNIT == input$measure,]
    
    
    dat
    
  })
  
  
  
  
  ## for now let's just do a normal grouped bar chart and make a polar one later (will have to be done manually)
  ### main plot to pass to the ui
  output$mainplot<-renderPlotly({
    
    dat<-filteredDat() # bring in data from the reactive filter above
    
    dats<-as.data.frame(data.table(dat)[, list(totals=sum(VALUE, na.rm=T)), 
                                        by=list(type, UNIT)])
    
    options(scipen = 999)
    if(1==2){
    datsprop<-as.data.frame(data.table(dats)[,  percents := round(totals / sum( totals, na.rm=T ) * 100, 1)   , 
                                             by=list( UNIT)])
    }else{
      datsprop<-as.data.frame(data.table(dats)[,  percents := round( totals , 1)   , 
                                               by=list( UNIT)])
    }
    
    
    datsprop<-datsprop[order(unique(dat$type)),]
    
    
    fig <- plot_ly(datsprop, labels = ~type, values = ~percents, type = 'pie', source='mainplot',
                   textposition = 'inside',
                   textinfo = 'label+percent',
                   insidetextfont = list(color = '#FFFFFF'),
                   hoverinfo = 'text',
                   text = ~paste0(type,": ", prettyNum(percents, big.mark=","), " ", input$measure),
                   marker = list(#colors = colors,
                     line = list(color = '#FFFFFF', width = 1)),
                   #The 'pull' attribute can also be used to create space between the sectors
                   showlegend = FALSE)
    fig <- fig %>% layout(#title = 'Method Type',
                          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE), 
                          margin = list(l = 0, r = 0, t = 0, b = 0)) #%>% 
      
      event_register("plotly_hover")  
    
    fig
    
  })
  

  
  last_hovered <- reactiveValues()
  
  observeEvent(event_data("plotly_hover", source = "mainplot"), {
  evdat<-event_data("plotly_hover", source = "mainplot") 
    req(evdat)
    print(evdat)
    
    dat<-filteredDat()
    dats<-as.data.frame(data.table(dat)[, list(totals=sum(VALUE, na.rm=T)),by=list(type, UNIT)])
    dattype<-unique(dat$type)[order(unique(dat$type))]
    
    #dattype<-dattype[evdat$curveNumber+1]  #the last hovered data type
    dattype<-dattype[evdat$pointNumber+1]  #the last hovered data type
    
    last_hovered$dattype<-dattype
    #last_hovered$x<-evdat$x
  })
  
  
  
  
  ################################################
  ## make a main plot for a highcharter option
  
  #highcharts callbacks
  #click_js <- JS("function(event) {Shiny.onInputChange('stategraph3_click', event.point.x);}") # to make click event
  canvasClickFunction <- JS("function(event) {Shiny.onInputChange('mainPlot_click', event.xAxis[0].value);}") #get some value that changes so that the input changes
  barClickFunction<-JS("function(event) {Shiny.onInputChange('barPlot_click',  event.point.category);}")
  #legendClickFunction <- JS("function(event) {Shiny.onInputChange('legendClicked', this.name);}")
 mouseOverFunc<-JS("function(event) {Shiny.onInputChange('mainPlot_mouseOver', event.point.name);}")
 sliceClickFunc <- JS("function(event) {Shiny.onInputChange('mainPlot_click', event.point.name);}")
 clickPolarFunc <- JS("function(event) {var category = this.xAxis.categories[event.point.x]; Shiny.onInputChange('mainPlot_mouseOver', category);}") # to make click event
 
  # observe({
  #   print(paste0("click: ", input$mainPlot_click)); print(paste0("mouseover: ", input$mainPlot_mouseOver))
  # })
  
  output$mainplothc<-renderHighchart({
    
    dat<-filteredDat() # bring in data from the reactive filter above
    
    dats<-as.data.frame(data.table(dat)[, list(totals=sum(VALUE, na.rm=T)), 
                                        by=list(type, UNIT)])
    
    options(scipen = 999)
    if(1==2){
      datsprop<-as.data.frame(data.table(dats)[,  percents := round(totals / sum( totals, na.rm=T ) * 100, 1)   , 
                                               by=list( UNIT)])
    }else{
      datsprop<-as.data.frame(data.table(dats)[,  percents := round( totals , 1)   , 
                                               by=list( UNIT)])
    }
    
    
    datsprop<-datsprop[order(unique(dat$type)),]
    
    req(nrow(datsprop)>0)
    
    
    if(piepol=="pie"){

      hc<-highchart() %>% 
        hc_chart(marginBottom = 0, marginLeft = 0, marginRight = 0, marginTop = 0 
                 ) %>% 
        hc_add_series(data=datsprop, 
                      hcaes(x = type, y = percents), type="pie", name="Conservation Type",
                      point=list(events = list( click=mouseOverFunc)),
                      tooltip=list(pointFormat=paste0("<br><b>{point.percentage:.1f} %<br>{point.percents:,.0f} ",input$measure, "</b><br><br>Click for Breakdown") ) ) %>% 
       
        hc_plotOptions(pie = list(dataLabels = list(enabled = TRUE,
                                                    format = '{point.name} ({point.percentage:.1f} %)' ))
        )   #, legendItemClick = legendClickFunction))) %>% 
        
        
    }else{
      hc <- highchart() %>%
        hc_chart(type = "column", polar = TRUE 
                 ) %>% 
        hc_xAxis(categories = datsprop$type) %>% 
        hc_series(list(
          name = "Conservation Type",data = datsprop$percents,
          colorByPoint = TRUE,type = "column",
          #colors = c("#d35400", "#2980b9", "#2ecc71", "#f1c40f", "#2c3e50"),
          events=list(click=clickPolarFunc),
          showInLegend = FALSE
        )
        ) 
    }
 
    hc
    
  })
  
  
  observeEvent(input$mainPlot_mouseOver, {
    evdat<-input$mainPlot_mouseOver
    req(evdat)
    print(evdat)
    
    last_hovered$dattype<-evdat
  })
  
  
  ###################################################
  
  
  output$typeBreakdownPlot<-renderPlotly({
    req(last_hovered$dattype)
   
   daty<-projdata[projdata$type == last_hovered$dattype,]
   daty<-daty[order(daty$VALUE, decreasing=T),]
   daty$STATE<-factor(daty$STATE, levels=unique(daty$STATE))
   
   fig2 <- plot_ly(daty,x = ~STATE, y = ~VALUE, type='bar', 
                   marker=list(color=colo[1]),
                   hoverinfo="text", text=paste0(daty$STATE, ": ", prettyNum(daty$VALUE, big.mark=","), " ", input$measure)) %>% 
     
     layout(categoryorder = 'array', categoryarray = daty$STATE[order(daty$VALUE, decreasing = TRUE)],
            legend=list(font=(list(size=10))), 
            title=paste0("By State: ", last_hovered$dattype),
            xaxis = list(title = "State"),
            #yaxis = list(side = 'left', title = paste0("Value in ", last_hovered$x), zeroline = FALSE))
            yaxis = list(side = 'left', title = paste0("Value in ", input$measure), zeroline = FALSE)
            )
   
   fig2
   
   
  })
  
  
  
  ### create a highchart instead of plotly
  output$typeBreakdownPlothc<-renderHighchart({
    req(last_hovered$dattype)
    
    daty<-projdata[projdata$type == last_hovered$dattype,]
    daty<-daty[order(daty$VALUE, decreasing=T),]
    daty$STATE<-factor(daty$STATE, levels=unique(daty$STATE))
    
    
    hc2 <- highchart() %>%
      hc_add_series( data = daty, hcaes(y = VALUE, x=STATE ), name="Project Type", 
                     type="column", color=colo[1], 
                     tooltip=list(pointFormat=paste0("{point.VALUE:,.0f} ",input$measure) ), 
                     point=list(events = list( click=barClickFunction))
                     ) %>% 
      hc_xAxis(categories = levels(daty$STATE)) %>%
      hc_yAxis(title=list(text=paste0("Value in ", input$measure), useHTML=TRUE) #labels = list(format = " {value}%"), 
              ) %>%
      # hc_tooltip(pointFormat = "<span style=\"color:{series.color}\">Total Bass Sampled: {point.TotalLMB}<br>Total Bass w/ Abnormalities: {point.TotalAb}<br>{point.series.name}: {point.y:,.1f}%<br/></span>",
      #            footerFormat="<br><br>Click for map", 
      #            shared = TRUE) %>% 
      hc_legend(enabled = FALSE) %>% 
      hc_title(text = paste0("By State: ", last_hovered$dattype)) %>%
      #hc_subtitle(text = "....can put subtitle") %>%
      #hc_caption(text = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Can have caption....",useHTML = TRUE) %>%
      #hc_plotOptions(series = list(events = list(click = barClickFunction))) %>%  #, mouseOver=mouseOverFunc, legendItemClick = legendClickFunction))) %>% 
      #hc_chart(events=list(click=canvasClickFunction)) %>% 
      hc_exporting(enabled = TRUE, buttons = list(contextButton = list(menuItems = c("downloadPNG", "downloadJPEG", "downloadPDF", "downloadSVG", "downloadCSV" ))))
    
    
    hc2
    
  })
  
  observe({
    print(input$barPlot_click)
  })
  
  
  
  # ## if they switch unit type, null out bottom plot
  # observeEvent(input$measure, {
  #   
  #   last_hovered$dattype<-NULL
  # })
  
  
  
  
  
  # 
  # ## try to build a custom circular bar chart using a polar chart (need to do math conversions manually)
  # 
  # ### main plot to pass to the ui
  # output$mainplot<-renderPlotly({
  #   
  #   
  #   fig <- plot_ly(
  #     type = 'scatterpolar',
  #     mode = 'lines'
  #   ) 
  # 
  #   fig <- fig %>%
  #     add_trace(
  #       r = c(2, 4, 4, 2),
  #       theta = c(195, 185, 175, 165), fill = 'toself',fillcolor = '#FFDF70',line = list(color = 'black')
  #     ) 
  #   fig <- fig %>%
  #     add_trace(
  #       r = c(0, 3, 3, 0),
  #       theta = c(0, 262.5, 277.5, 0), fill = 'toself',fillcolor = '#B6FFB4',line = list(color = 'black'
  #       )
  #     ) 
  #   fig <- fig %>%
  #     layout(
  #       polar = list(radialaxis = list(visible = T,range = c(0,5))
  #       ),
  #       showlegend = F
  #     )
  #   
  #   fig
  #   
  #   # Create a circular bar plot
# p <- plot_ly()
# # Add rectangular bars
# for (i in 1:num_categories) {
# x <- c(theta[i] - bar_width / 2, theta[i] + bar_width / 2, theta[i] + bar_width / 2, theta[i] - bar_width / 2, theta[i] - bar_width / 2)
# y <- c(0, 0, values[i], values[i], 0)
# p <- add_trace(
# p,
# type = "scatterpolar",
# r = y,
# theta = x,
# fill = "toself",
# mode = "lines",
# line = list(color = "blue"),  # Adjust the color of the bars as needed
# name = categories[i]
# )
# }
# # Adjust layout
# p <- layout(
# p,
# title = "Circular Bar Plot with Rectangular Bars",
# polar = list(
# radialaxis = list(
# visible = TRUE,
# range = c(0, max_value + 5)  # Adjust the range of the radial axis if needed
# )
# )
# )
# # Show plot
# p
  #   
  #   
  # })
  # 
  # 
  
  
  #############################################################
  ## states shapefile for map
  
 ## get state shapefiles streamed from ArcGis open source
  

  requesturl<-"https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/USA_States_Generalized/FeatureServer/0/query?where=1%3D1&outFields=STATE_NAME&f=geojson"
  arcpoly<-tryCatch(st_read(requesturl, quiet=TRUE), error=function(e) {NULL})
  arcpoly<-suppressWarnings(as(arcpoly, "Spatial"))

  
  

  
  
  
  
  observeEvent(input$barPlot_click, {
      req(arcpoly, last_hovered$dattype)
    
    daty<-projdata[projdata$type == last_hovered$dattype,]
    
    statdat<-arcpoly[tolower(arcpoly$STATE_NAME) %in% tolower(unique(daty$STATE)), ]
  statdat$value<-daty$VALUE[match(tolower(statdat$STATE_NAME), tolower(daty$STATE))]

  # pal<-colorRampPalette(rev(c("#990000",'#e93e3a','#ed683c','#f3903f','#fdc70c','#fff33b','#0000ff')))
  # statdat$colo<-pal(20)[as.numeric(cut(statdat$value, breaks=20))]
  # 
  numberofcolors<-1000
  color_palette <-colorRampPalette(rev(c('#e93e3a','#ed683c','#f3903f','#fdc70c','#fff33b','#0000ff')))(numberofcolors)
  # Map the numeric values to colors
  scaled_values <- (statdat$value - min(statdat$value)) / diff(range(statdat$value))
  color_indices <- ceiling(scaled_values * (numberofcolors - 1)) + 1
  statdat$colo <- color_palette[color_indices]
  
  
  output$modalheader<-renderUI({
    HTML(paste0("<h2>", last_hovered$dattype ,"</h2>"))
  })
  
  
output$map<-renderLeaflet({
  
  leaflet() %>% 
    addProviderTiles("CartoDB.Positron", group="Map") %>% 
    
    addMouseCoordinates() %>% 
    addPolygons(data=statdat,
               label=paste0(statdat$STATE_NAME, " - ", statdat$value, " ", input$measure), 
                fillColor=statdat$colo, fillOpacity = 0.7, color="black", weight=0.5,
                group = "States")
  
  
})
    #leafletProxy("map") %>% clearGroup("States") %>%
      
    
    toggleModal(session=session, modalId = "mapmodal", toggle="open")
    
    
  })
  
  
  
  
}





shinyApp(ui, server)













=======
## demo Fed project data

## READ OPTIONS:
##### there are three options. One is a plotly with pie chart. One is Highcharts pie chart. Last is Highcharts Polar chart.
#choose plotly example or highcharter example
plotop<-"h"  #put "p" or "h" here

## choose piechart or polar chart (only available for highcharts)
piepol<-"pie"  #put "pie" or "polar"
 





#############
#libraries 

library(shiny)
library(leaflet)
library(stringr)
library(shinyWidgets)
library(shinyBS)
library(data.table)
#library(DT)
library(plyr)
library(jsonlite)
library(lubridate)
library(plotly)
library(highcharter)


## main colors
colo<-c("#248c94","#d8c467", "#262525","#9e5846","#76b2a9")

##############################################
# ui side

ui<- fluidPage(
  #bootstrapPage(div(class="outer",
  #tags$style(type = "text/css", "#map {height: calc(99vh - 80px) !important;} .navbar-default {margin-bottom:0;}"),
  
  # set style for fluidRows to only be 40% of the screen height
  tags$style('.rowforty{height:40vh; overflow-y:false;}'),
  tags$style('h2{font-family: "Lucida Grande", "Lucida Sans Unicode", Arial, Helvetica, sans-serif}'),
  
  HTML("<div style='background:#248c94;color:#d8c467;padding:5px;margin-bottom:7px;'>
       <h4><b>Title - e.g. Conservation Project Type Breakdowns</b></h4></div>"),
  
  
fluidRow(
  div(class="rowforty",
      column(width=3, 
             
             #dateRangeInput(inputId = "daterange", "Filter Dates", start="2024-01-01", end=Sys.Date()+1, min="2024-01-01", max=Sys.Date()+1),
             selectInput(inputId = "state", "Choose State:", choices="ALL", selected = "ALL",multiple=T),
             selectInput(inputId = "measure", "Measure Type:", choices="", selected="")
             #downloadButton("downloadData", "Download Filtered Data")
      ), 
      column(width=6,
             if(plotop == "p"){  
             plotlyOutput("mainplot", height="48vh")
               }else{
                 highchartOutput("mainplothc", height="48vh")
             }
               
               )
  )),
  
  br(),HTML('<hr style="height: 2px; border: none; background-color: black;margin:0;">'),
  br(),
  fluidRow(
    div(class="rowforty", 
        
        if(plotop == "p"){ 
        plotlyOutput("typeBreakdownPlot", height="100%")
        }else{
          highchartOutput("typeBreakdownPlothc", height="100%")
        }
  )),

  
  bsModal(id="mapmodal", trigger = NULL, size="large",
         uiOutput("modalheader"),
          leafletOutput("map")
  )
  
) 
#))




##################################################################################################
## server side


server<-function(input, output, session) {
  
  
  projdata<-read.csv("www/transformed_data.csv")
  
  ## zeros are a legacy of transforming the data, filter them out
  projdata<-projdata[projdata$VALUE > 0,]
  
  projdata$type<-str_match(projdata$CP_NAME, "\\|\\s*(.*?)\\s*\\|")[,2]  ## clean up the project types
  
  ## rename the measures to their full names
  category_mapping <- c("Ac" = "Acres", "Ft" = "Feet", "Num" = "Units", "sq ft"="Square Feet")
  # Replace category names
  projdata$UNIT <- ifelse(projdata$UNIT %in% names(category_mapping),category_mapping[projdata$UNIT],projdata$UNIT)
  
  
  
  updateSelectInput(session=session, inputId = "state", choices=c("ALL", unique(projdata$STATE)[order(unique(projdata$STATE))]) , selected="ALL")
  updateSelectInput(session=session, inputId = "measure", choices=c(unique(projdata$UNIT)[order(unique(projdata$UNIT))]) , selected=category_mapping[1])
  
  

  
  
  
  
  ## run a reactive that processes the data, while incorporating what the user has chosen in dropdowns
  filteredDat<-reactive({
    
    dat<-projdata
    
    if(any(input$state != "ALL")){
      
      dat<-dat[dat$STATE %in% input$state,]
    }
    
    dat<-dat[dat$UNIT == input$measure,]
    
    
    dat
    
  })
  
  
  
  
  ## for now let's just do a normal grouped bar chart and make a polar one later (will have to be done manually)
  ### main plot to pass to the ui
  output$mainplot<-renderPlotly({
    
    dat<-filteredDat() # bring in data from the reactive filter above
    
    dats<-as.data.frame(data.table(dat)[, list(totals=sum(VALUE, na.rm=T)), 
                                        by=list(type, UNIT)])
    
    options(scipen = 999)
    if(1==2){
    datsprop<-as.data.frame(data.table(dats)[,  percents := round(totals / sum( totals, na.rm=T ) * 100, 1)   , 
                                             by=list( UNIT)])
    }else{
      datsprop<-as.data.frame(data.table(dats)[,  percents := round( totals , 1)   , 
                                               by=list( UNIT)])
    }
    
    
    datsprop<-datsprop[order(unique(dat$type)),]
    
    
    fig <- plot_ly(datsprop, labels = ~type, values = ~percents, type = 'pie', source='mainplot',
                   textposition = 'inside',
                   textinfo = 'label+percent',
                   insidetextfont = list(color = '#FFFFFF'),
                   hoverinfo = 'text',
                   text = ~paste0(type,": ", prettyNum(percents, big.mark=","), " ", input$measure),
                   marker = list(#colors = colors,
                     line = list(color = '#FFFFFF', width = 1)),
                   #The 'pull' attribute can also be used to create space between the sectors
                   showlegend = FALSE)
    fig <- fig %>% layout(#title = 'Method Type',
                          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE), 
                          margin = list(l = 0, r = 0, t = 0, b = 0)) #%>% 
      
      event_register("plotly_hover")  
    
    fig
    
  })
  

  
  last_hovered <- reactiveValues()
  
  observeEvent(event_data("plotly_hover", source = "mainplot"), {
  evdat<-event_data("plotly_hover", source = "mainplot") 
    req(evdat)
    print(evdat)
    
    dat<-filteredDat()
    dats<-as.data.frame(data.table(dat)[, list(totals=sum(VALUE, na.rm=T)),by=list(type, UNIT)])
    dattype<-unique(dat$type)[order(unique(dat$type))]
    
    #dattype<-dattype[evdat$curveNumber+1]  #the last hovered data type
    dattype<-dattype[evdat$pointNumber+1]  #the last hovered data type
    
    last_hovered$dattype<-dattype
    #last_hovered$x<-evdat$x
  })
  
  
  
  
  ################################################
  ## make a main plot for a highcharter option
  
  #highcharts callbacks
  #click_js <- JS("function(event) {Shiny.onInputChange('stategraph3_click', event.point.x);}") # to make click event
  canvasClickFunction <- JS("function(event) {Shiny.onInputChange('mainPlot_click', event.xAxis[0].value);}") #get some value that changes so that the input changes
  barClickFunction<-JS("function(event) {Shiny.onInputChange('barPlot_click',  event.point.category);}")
  #legendClickFunction <- JS("function(event) {Shiny.onInputChange('legendClicked', this.name);}")
 mouseOverFunc<-JS("function(event) {Shiny.onInputChange('mainPlot_mouseOver', event.point.name);}")
 sliceClickFunc <- JS("function(event) {Shiny.onInputChange('mainPlot_click', event.point.name);}")
 clickPolarFunc <- JS("function(event) {var category = this.xAxis.categories[event.point.x]; Shiny.onInputChange('mainPlot_mouseOver', category);}") # to make click event
 
  # observe({
  #   print(paste0("click: ", input$mainPlot_click)); print(paste0("mouseover: ", input$mainPlot_mouseOver))
  # })
  
  output$mainplothc<-renderHighchart({
    
    dat<-filteredDat() # bring in data from the reactive filter above
    
    dats<-as.data.frame(data.table(dat)[, list(totals=sum(VALUE, na.rm=T)), 
                                        by=list(type, UNIT)])
    
    options(scipen = 999)
    if(1==2){
      datsprop<-as.data.frame(data.table(dats)[,  percents := round(totals / sum( totals, na.rm=T ) * 100, 1)   , 
                                               by=list( UNIT)])
    }else{
      datsprop<-as.data.frame(data.table(dats)[,  percents := round( totals , 1)   , 
                                               by=list( UNIT)])
    }
    
    
    datsprop<-datsprop[order(unique(dat$type)),]
    
    req(nrow(datsprop)>0)
    
    
    if(piepol=="pie"){

      hc<-highchart() %>% 
        hc_chart(marginBottom = 0, marginLeft = 0, marginRight = 0, marginTop = 0 
                 ) %>% 
        hc_add_series(data=datsprop, 
                      hcaes(x = type, y = percents), type="pie", name="Conservation Type",
                      point=list(events = list( click=mouseOverFunc)),
                      tooltip=list(pointFormat=paste0("<br><b>{point.percentage:.1f} %<br>{point.percents:,.0f} ",input$measure, "</b><br><br>Click for Breakdown") ) ) %>% 
       
        hc_plotOptions(pie = list(dataLabels = list(enabled = TRUE,
                                                    format = '{point.name} ({point.percentage:.1f} %)' ))
        )   #, legendItemClick = legendClickFunction))) %>% 
        
        
    }else{
      hc <- highchart() %>%
        hc_chart(type = "column", polar = TRUE 
                 ) %>% 
        hc_xAxis(categories = datsprop$type) %>% 
        hc_series(list(
          name = "Conservation Type",data = datsprop$percents,
          colorByPoint = TRUE,type = "column",
          #colors = c("#d35400", "#2980b9", "#2ecc71", "#f1c40f", "#2c3e50"),
          events=list(click=clickPolarFunc),
          showInLegend = FALSE
        )
        ) 
    }
 
    hc
    
  })
  
  
  observeEvent(input$mainPlot_mouseOver, {
    evdat<-input$mainPlot_mouseOver
    req(evdat)
    print(evdat)
    
    last_hovered$dattype<-evdat
  })
  
  
  ###################################################
  
  
  output$typeBreakdownPlot<-renderPlotly({
    req(last_hovered$dattype)
   
   daty<-projdata[projdata$type == last_hovered$dattype,]
   daty<-daty[order(daty$VALUE, decreasing=T),]
   daty$STATE<-factor(daty$STATE, levels=unique(daty$STATE))
   
   fig2 <- plot_ly(daty,x = ~STATE, y = ~VALUE, type='bar', 
                   marker=list(color=colo[1]),
                   hoverinfo="text", text=paste0(daty$STATE, ": ", prettyNum(daty$VALUE, big.mark=","), " ", input$measure)) %>% 
     
     layout(categoryorder = 'array', categoryarray = daty$STATE[order(daty$VALUE, decreasing = TRUE)],
            legend=list(font=(list(size=10))), 
            title=paste0("By State: ", last_hovered$dattype),
            xaxis = list(title = "State"),
            #yaxis = list(side = 'left', title = paste0("Value in ", last_hovered$x), zeroline = FALSE))
            yaxis = list(side = 'left', title = paste0("Value in ", input$measure), zeroline = FALSE)
            )
   
   fig2
   
   
  })
  
  
  
  ### create a highchart instead of plotly
  output$typeBreakdownPlothc<-renderHighchart({
    req(last_hovered$dattype)
    
    daty<-projdata[projdata$type == last_hovered$dattype,]
    daty<-daty[order(daty$VALUE, decreasing=T),]
    daty$STATE<-factor(daty$STATE, levels=unique(daty$STATE))
    
    
    hc2 <- highchart() %>%
      hc_add_series( data = daty, hcaes(y = VALUE, x=STATE ), name="Project Type", 
                     type="column", color=colo[1], 
                     tooltip=list(pointFormat=paste0("{point.VALUE:,.0f} ",input$measure) ), 
                     point=list(events = list( click=barClickFunction))
                     ) %>% 
      hc_xAxis(categories = levels(daty$STATE)) %>%
      hc_yAxis(title=list(text=paste0("Value in ", input$measure), useHTML=TRUE) #labels = list(format = " {value}%"), 
              ) %>%
      # hc_tooltip(pointFormat = "<span style=\"color:{series.color}\">Total Bass Sampled: {point.TotalLMB}<br>Total Bass w/ Abnormalities: {point.TotalAb}<br>{point.series.name}: {point.y:,.1f}%<br/></span>",
      #            footerFormat="<br><br>Click for map", 
      #            shared = TRUE) %>% 
      hc_legend(enabled = FALSE) %>% 
      hc_title(text = paste0("By State: ", last_hovered$dattype)) %>%
      #hc_subtitle(text = "....can put subtitle") %>%
      #hc_caption(text = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Can have caption....",useHTML = TRUE) %>%
      #hc_plotOptions(series = list(events = list(click = barClickFunction))) %>%  #, mouseOver=mouseOverFunc, legendItemClick = legendClickFunction))) %>% 
      #hc_chart(events=list(click=canvasClickFunction)) %>% 
      hc_exporting(enabled = TRUE, buttons = list(contextButton = list(menuItems = c("downloadPNG", "downloadJPEG", "downloadPDF", "downloadSVG", "downloadCSV" ))))
    
    
    hc2
    
  })
  
  observe({
    print(input$barPlot_click)
  })
  
  
  
  # ## if they switch unit type, null out bottom plot
  # observeEvent(input$measure, {
  #   
  #   last_hovered$dattype<-NULL
  # })
  
  
  
  
  
  # 
  # ## try to build a custom circular bar chart using a polar chart (need to do math conversions manually)
  # 
  # ### main plot to pass to the ui
  # output$mainplot<-renderPlotly({
  #   
  #   
  #   fig <- plot_ly(
  #     type = 'scatterpolar',
  #     mode = 'lines'
  #   ) 
  # 
  #   fig <- fig %>%
  #     add_trace(
  #       r = c(2, 4, 4, 2),
  #       theta = c(195, 185, 175, 165), fill = 'toself',fillcolor = '#FFDF70',line = list(color = 'black')
  #     ) 
  #   fig <- fig %>%
  #     add_trace(
  #       r = c(0, 3, 3, 0),
  #       theta = c(0, 262.5, 277.5, 0), fill = 'toself',fillcolor = '#B6FFB4',line = list(color = 'black'
  #       )
  #     ) 
  #   fig <- fig %>%
  #     layout(
  #       polar = list(radialaxis = list(visible = T,range = c(0,5))
  #       ),
  #       showlegend = F
  #     )
  #   
  #   fig
  #   
  #   # Create a circular bar plot
# p <- plot_ly()
# # Add rectangular bars
# for (i in 1:num_categories) {
# x <- c(theta[i] - bar_width / 2, theta[i] + bar_width / 2, theta[i] + bar_width / 2, theta[i] - bar_width / 2, theta[i] - bar_width / 2)
# y <- c(0, 0, values[i], values[i], 0)
# p <- add_trace(
# p,
# type = "scatterpolar",
# r = y,
# theta = x,
# fill = "toself",
# mode = "lines",
# line = list(color = "blue"),  # Adjust the color of the bars as needed
# name = categories[i]
# )
# }
# # Adjust layout
# p <- layout(
# p,
# title = "Circular Bar Plot with Rectangular Bars",
# polar = list(
# radialaxis = list(
# visible = TRUE,
# range = c(0, max_value + 5)  # Adjust the range of the radial axis if needed
# )
# )
# )
# # Show plot
# p
  #   
  #   
  # })
  # 
  # 
  
  
  #############################################################
  ## states shapefile for map
  
 ## get state shapefiles streamed from ArcGis open source
  

  requesturl<-"https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/USA_States_Generalized/FeatureServer/0/query?where=1%3D1&outFields=STATE_NAME&f=geojson"
  arcpoly<-tryCatch(st_read(requesturl, quiet=TRUE), error=function(e) {NULL})
  arcpoly<-suppressWarnings(as(arcpoly, "Spatial"))

  
  

  
  
  
  
  observeEvent(input$barPlot_click, {
      req(arcpoly, last_hovered$dattype)
    
    daty<-projdata[projdata$type == last_hovered$dattype,]
    
    statdat<-arcpoly[tolower(arcpoly$STATE_NAME) %in% tolower(unique(daty$STATE)), ]
  statdat$value<-daty$VALUE[match(tolower(statdat$STATE_NAME), tolower(daty$STATE))]

  # pal<-colorRampPalette(rev(c("#990000",'#e93e3a','#ed683c','#f3903f','#fdc70c','#fff33b','#0000ff')))
  # statdat$colo<-pal(20)[as.numeric(cut(statdat$value, breaks=20))]
  # 
  numberofcolors<-1000
  color_palette <-colorRampPalette(rev(c('#e93e3a','#ed683c','#f3903f','#fdc70c','#fff33b','#0000ff')))(numberofcolors)
  # Map the numeric values to colors
  scaled_values <- (statdat$value - min(statdat$value)) / diff(range(statdat$value))
  color_indices <- ceiling(scaled_values * (numberofcolors - 1)) + 1
  statdat$colo <- color_palette[color_indices]
  
  
  output$modalheader<-renderUI({
    HTML(paste0("<h2>", last_hovered$dattype ,"</h2>"))
  })
  
  
output$map<-renderLeaflet({
  
  leaflet() %>% 
    addProviderTiles("CartoDB.Positron", group="Map") %>% 
    
    addMouseCoordinates() %>% 
    addPolygons(data=statdat,
               label=paste0(statdat$STATE_NAME, " - ", statdat$value, " ", input$measure), 
                fillColor=statdat$colo, fillOpacity = 0.7, color="black", weight=0.5,
                group = "States")
  
  
})
    #leafletProxy("map") %>% clearGroup("States") %>%
      
    
    toggleModal(session=session, modalId = "mapmodal", toggle="open")
    
    
  })
  
  
  
  
}





shinyApp(ui, server)













# >>>>>>> d38055737aac6beebb257ee91be1ff2da4be15f6
