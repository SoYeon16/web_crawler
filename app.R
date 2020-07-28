library(shiny)
library(shinydashboard)
library(ggplot2)
library(RMySQL)

ui = dashboardPage(
  dashboardHeader(title = "Airline Ticket Price Fluctuation"),
  dashboardSidebar(sidebarSearchForm(textId="searchText", 
                                     buttonId="searchButton", label="Search..."),
                   sidebarMenu(
                     menuItem("Dashboard", tabName = "dashboard",
                              icon = icon("dashboard")),
                     menuItem("Widgets", tabName = "widgets",
                              icon = icon("th"),
                              badgeLabel = "New", badgeColor = "green"),
                     menuItem("Charts", icon = icon("bar-chart-o"),
                              menuSubItem("Sub-item 1", tabName = "subitem1"),
                              menuSubItem("Sub-item 2", tabName = "subitem2")),
                     #textInput(inputId="slider", label="Slider"),
                     radioButtons(inputId="radio", label="Button:",
                                  choices=list("Paris", "Shanghai"), selected="Paris"))
  ),
  dashboardBody(
    tabBox(
      tabPanel("Time series Graph",
               "Time series Graph: ", plotOutput("tsg")),
      tabPanel("Ticket Data", "Ticket Raw data: ", tableOutput("ttb")),
      tabPanel("Price Data", "Price Raw data: ", tableOutput("ptb")))
  )
)

server = function(input, output) {
  tpdf = reactive({
    con = dbConnect(MySQL(), host='203.252.196.68',
                    dbname='sql1611164', user='db1611164', pass='stat1234')
    if ( input$radio == "Paris" ) {
      query1 = sprintf("SELECT * FROM Paris_Price_v1 ;") 
      res = dbGetQuery(con, query1) 
      
      price.num = substr(res$PRICE, 4, 10000)
      price.num = gsub(",", "", price.num, ignore.case = FALSE, fixed = FALSE)
      price.num = as.factor(price.num)
      price.num = as.numeric(as.character(price.num))
      res2= cbind(res, price.num)
      
      time = substr(res$TIME_OF_CRAWL, 1, 16)
      res2= cbind(res2, time)
      
      myID = names(table(res2$FLIGHT_ID))[ table(res2$FLIGHT_ID) > max(table(res2$FLIGHT_ID))*0.9 ]
      res_plot = res2[ res$FLIGHT_ID %in%  myID,  ]
      dbDisconnect(con)
      return(res_plot)
    }
    if ( input$radio == "Shanghai" ) {
      query1 = sprintf("SELECT * FROM Shanghai_Price_v1 ;")
      res = dbGetQuery(con, query1) 
      
      
      price.num = substr(res$PRICE, 4, 10000)
      price.num = gsub(",", "", price.num, ignore.case = FALSE, fixed = FALSE)
      price.num = as.factor(price.num)
      price.num = as.numeric(as.character(price.num))
      res2= cbind(res, price.num)
      
      time = substr(res$TIME_OF_CRAWL, 1, 16)
      res2= cbind(res2, time)
      
      myID = names(table(res2$FLIGHT_ID))[ table(res2$FLIGHT_ID) > max(table(res2$FLIGHT_ID))*0.9 ]
      res_plot = res2[ res$FLIGHT_ID %in%  myID,  ]
      dbDisconnect(con)
      return(res_plot)
    }
  })
  df = reactive({
    con = dbConnect(MySQL(), host='203.252.196.68',
                    dbname='sql1611164', user='db1611164', pass='stat1234')
    if (input$radio == "Paris") {
      query2 = sprintf("SELECT * FROM Paris_MetaData_v1 ;")
      res = dbGetQuery(con, query2)        
    }
    if (input$radio == "Shanghai"){
      query2 = sprintf("SELECT * FROM Shanghai_MetaData_v1 ;")
      res = dbGetQuery(con, query2)        
    }
    dbDisconnect(con)
    return(res)
  })
  df2 = reactive({
    con = dbConnect(MySQL(), host='203.252.196.68',
                    dbname='sql1611164', user='db1611164', pass='stat1234')
    if (input$radio == "Paris") {
      query2 = sprintf("SELECT * FROM Paris_Price_v1 ;")
      res = dbGetQuery(con, query2)        
    }
    if (input$radio == "Shanghai"){
      query2 = sprintf("SELECT * FROM Shanghai_Price_v1 ;")
      res = dbGetQuery(con, query2)        
    }
    dbDisconnect(con)
    return(res)
  })
  output$tsg = renderPlot({
    res_plot = tpdf()
    res_plot$FLIGHT_ID = as.factor(res_plot$FLIGHT_ID)
    if (input$radio == 'Paris') {
      return(ggplot(res_plot) + geom_line(aes(x=time, y=price.num, group=FLIGHT_ID, color = FLIGHT_ID))+
        theme_minimal() + ggtitle("Airline Ticket Price Fluctuation") + 
        theme(axis.title = element_text(face = "bold", size = 9, color = "darkblue")) +
        labs(x="Time", y="Ticket Price") + theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5 )) + 
        lims(y=c(700000,3500000)) + 
        scale_y_continuous(labels = scales::comma))
    }
    if (input$radio == 'Shanghai') {
    return(ggplot(res_plot) + geom_line(aes(x=time, y=price.num, group=FLIGHT_ID, color = FLIGHT_ID))+
      theme_minimal() + ggtitle("Airline Ticket Price Fluctuation") +
      theme(axis.title = element_text(face = "bold", size = 9, color = "darkblue")) +
      labs(x="Time", y="Ticket Price") + theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5 )) +
      lims(y=c(100000,500000)) +
      scale_y_continuous(labels = scales::comma))
    }
  })
  output$ttb = renderTable({
    df()
  })
  output$ptb = renderTable({
    df2()
  })
  output$temp = renderTable({
    tpdf()
  })
}

shinyApp(ui = ui, server = server)
