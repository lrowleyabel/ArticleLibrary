if(!require("pacman")) install.packages("pacman")
cran_packages<- c("dplyr", "stringr", "htmlwidgets", "htmltools", "jsonlite", "bslib", "waiter", "DT", "r2d3", "networkD3", "handlr", "bibtex", "rcrossref", "RefManageR", "pdftools", "readlxl", "writexl")
github_packages<- c("daqana/dqshiny", "giocomai/zoteror")
pacman::p_load(char = cran_packages)
pacman::p_load_gh(char = github_packages)


ui<- page_navbar(
  
  tags$head(tags$link(rel = "icon", type = "image/x-icon", href = "img/icon.ico")),
  
  shinyjs::useShinyjs(),
  
  
  
  theme = bs_theme(bootswatch = "flatly",
                   "progress-height" = "1.5rem")%>%
    bs_add_rules(sass::sass_file("www/css/custom.scss")),
  
  title = "Article Library",
  
  id = "index_navbar",
  
  nav_panel(
    waiter::useAttendant(),
    waiter::useWaiter(),
    title = "Search",
    card(
      card_header("Library Search"),
      card_body(
        fillable = F,
        fill = F,
        span(
          
        layout_column_wrap(
          style = "background-color: #ECF0F1;",
          width = 1/4,
          autocomplete_input(id = "search_query", label =  "" , options = c(), create = TRUE, placeholder = "Search..."),
          radioButtons(inputId = "search_by_field", choices = c("tags", "author", "title"), label = "", selected = "tags", inline = T),
          div(),
          div(id = "multiselect_container", checkboxInput(inputId = "multiselect", label = "Multiselect"))
        )
        )
      ),
      
      card_body(
          dataTableOutput(outputId = "search_results")  
      ),
      
      card_body(
        fillable = F,
        fill = F,
        layout_column_wrap(
            width = 1/5,
            actionButton("read_selected_item", label = "Read selected item", class = "btn-success"),
            actionButton("open_selected_item_online", label = "Open selected item online", class = "btn-success"),
            actionButton("mark_selected_item_as_read", label = "Mark selected item as read", class = "btn-success"),
            actionButton("mark_selected_item_as_unread", label = "Mark selected item as unread", class = "btn-success"),
            actionButton("delete_selected_item", label = "Delete selected item", class = "btn-success")
          )
        
      )
    )
    
  ),
  
  nav_panel(
    title = "Add",
    layout_column_wrap(width = NULL,
                       style = htmltools::css(grid_template_columns = "1fr 2fr"),
                       card(
                          card_header("Add items to library"),
                          card_body(
                                  fillable = T,
                                  
                                  card(
                                    min_height = "40px",
                                    max_height = "40px",
                                    fill = T,
                                    class = "collapsable",
                                    card_header(class = "collapsable_header", "Add new item from pdf", tags$img(class = "collapsable_icon", style = "height: 10px; margin-top: 8px; float: right; transition: transform 1s;",  src = "img/down.png")),
                                    
                                    div(
                                      class = "collapsable_content",
                                      fileInput("item_pdf_upload", label = "Add new item from pdf file:"),
                                      selectizeInput("pdf_dois_add", label = "Dois from PDF", choices = c(), options = list(create = TRUE)),
                                      actionButton("add_items_pdf", class = "btn-success", label = "Add items", width = "300px")
                                    )
                                    
                                  ),
                                  
                                  card(
                                    min_height = "40px",
                                    max_height = "40px",
                                    fill = T,
                                    class = "collapsable",
                                    card_header(class = "collapsable_header", "Add new item from doi", tags$img(class = "collapsable_icon", style = "height: 10px; margin-top: 8px; float: right; transition: transform 1s;",  src = "img/down.png")),
                                    
                                    div(
                                      class = "collapsable_content",
                                      textInput("text_doi_add", label = "Add new item from doi:"),
                                      actionButton("add_items_text_doi", class = "btn-success", label = "Add items", width = "300px")
                                    )
                                    
                                  ),
                                  
                                  card(
                                    min_height = "40px",
                                    max_height = "40px",
                                    fill = T,
                                    class = "collapsable",
                                    card_header(class = "collapsable_header", "Add new item from bib file", tags$img(class = "collapsable_icon", style = "height: 10px; margin-top: 8px; float: right; transition: transform 1s;",  src = "img/down.png")),
                                    
                                    div(
                                      class = "collapsable_content",
                                      fileInput("item_upload", label = "Add new item(s) from bib file:"),
                                      actionButton("add_items_bib", class = "btn-success", label = "Add items", width = "300px")
                                    )
                                    
                                  ),
                            
                                card(fill = T,
                                     min_height = "500px",
                                     card_header("Add tags"),
                                     div(
                                       autocomplete_input(id = "input_tag", label = "Add tags to new item:", options = c("frailty", "biomarkers"), create = TRUE),
                                       actionButton("add_tag", label = "Add tag to items", width = "300px"),
                                       textOutput("new_item_tags")  
                                     )
                                     
                                )
                                  
                            )
                       ),
                       card(card_header("New items"),
                            card_body(dataTableOutput("new_items_display")))
    )
  ),
  
  nav_panel(
    title = "Attach",
    layout_column_wrap(
      width = 1/3,
      card(card_header("Attach PDF to existing item"),
           card_body(div("Use this to attach PDFs to items that are already in your library. For adding a PDF that is not yet at item, use the Add tab."),
                     fileInput("pdf_upload", label = "Upload PDF"),
                     selectizeInput("pdf_dois", label = "DOIs from PDF", choices = c()),
                     htmlOutput("pdf_item_confirmation"),
                     autocomplete_input(id = "manual_attach_item_selection", options =c(), placeholder = "Type title...", label = "Item to attach to:"),
                     actionButton("save_pdf", label = "Save PDF", class = "btn-success", width = "300px")
           )
      )
    )
    
  ),
  
  nav_panel(
    title = "Summary",
    layout_column_wrap(width = NULL,
                         style = htmltools::css(grid_template_columns = "1fr 2fr"),
                         card(
                           card_header("Overall summary"),
                           card_body(
                             htmlOutput("overall_summary_text"),
                             card(div(style = "margin:0px auto; width: 75%; height: 250px;",
                                 h5(style = 'text-align: center;', "Proportion read:"),
                                 d3Output("overall_read_plot", height = 130)
                             )),
                             card(div(style = "margin:0px auto; width: 75%; height:250px;",
                                 h5(style = 'text-align: center;', "Proportion in Zotero:"),
                                 d3Output("overall_zotero_plot", height = 130)
                             ))
                           )
                         ),
                       
                         card(
                           card_header("Tag summary"),
                           layout_column_wrap(width = 1/2,
                                              
                           card(
                             p("Most common tags:"),
                             d3Output("tag_summary_plot")
                           ),
                           
                           card(
                             p("Individual tags:"),
                             autocomplete_input(id = "summary_tag_search", label =  "" , options = c(), create = TRUE, placeholder = "Search for a tag...", value = "frailty", width = "100%"),
                             actionButton(inputId = "summary_tag_search_submit", label = "Search", height = 20),
                             htmlOutput("individual_tag_text"),
                             div(style = "margin:0px auto; width: 75%; height:250px;",
                                      h5(style = 'text-align: center;', "Proportion read:"),
                                      d3Output("individual_tag_read_plot", height = 130)
                             )
                           )
                           )
                         )
    )
  ),
  
  nav_panel(
    title = "Visualise",
    layout_column_wrap(width = NULL,
        style = htmltools::css(grid_template_columns = "1fr 3fr"),
        layout_column_wrap(
          width = 1,
          heights_equal = "row",
          card(
            full_screen = T,
            uiOutput("hovered_tag_display"),
            h5(style = "opacity: 0;", id = "linked_tag_plot_title", "Commly overlapping tags (number of shared items):"),
            d3Output("hovered_tag_links_plot", height = 700),
            autocomplete_input(id = "visual_tag_search", label =  "" , options = c(), create = TRUE, placeholder = "Search for a tag..."),
            
          )
        ),
        card(
          forceNetworkOutput("force_network")
        )
    )
    
  ),
  
  nav_panel(
    title = "Chrome",
    card(
      card_header("Items synced from Chrome"),
      card_body(
        div("This will display items downloaded from the Chrome extension, as they are periodically added."),
        dataTableOutput("synced_item_log_display")
      )
    )
  ),
  
  nav_panel(
    title = "Settings",
    layout_column_wrap(
      width = 1/3,
      card(card_header("Zotero settings"),
           card_body(
             shinyWidgets::materialSwitch("use_zotero", HTML("Sync library to Zotero:<br>"), value = TRUE),
             div("Input your Zotero library ID and API key below."),
             actionLink(input = "no_zotero_credentials", label = "Don't have these?"),
             textInput("library_id", "Zotero library ID:"),
             textInput("api_key", "Zotero API key:"),
             actionButton("save_zotero_settings", "Save")
           )
      ),
      card(card_header("Chrome extensions settings"),
           card_body(
             shinyWidgets::materialSwitch("use_chrome_extension", HTML("Use chrome extension:<br>"), value = TRUE),
             div("Input your the path to your downloads folder below. This is so the app knows where to look for items downloaded using the Chrome extension."),
             textInput("downloads_path", "Downloads path:"),
             actionButton("save_downloads_path", "Save")
           )
      ),
      card(card_header("General settings"),
           card_body(
             actionButton("update_app", "Update App")
           )
      )
    )
  ),
  
  shinyjs::extendShinyjs(script = "js/shinyjsExtensions.js", functions = c("first_setup_button", "second_setup_button_yes", "zotero_credential_help", "second_setup_button_no", "setup_save_zotero_settings", "save_downloads_path")),
  
  
)

server<- function(input, output, session){
  
  #### General ####
  
  source("Server/General_Server.R", local = TRUE)$value
  
  #### Search ####
  
  source("Server/Search_Server.R", local = TRUE)$value
  
  #### Add ####
  
  source("Server/Add_Server.R", local = TRUE)$value
  
  #### Note-taking ####
  
  source("Server/Note_Taking_Server.R", local = TRUE)$value
  
  #### Summary ####
  
  source("Server/Summary_Server.R", local = TRUE)$value
  
  
  #### Visualise ####
  
  source("Server/Visualise_Server.R", local = TRUE)$value
  
  #### Syncing ####
  
  source("Server/Syncing_Server.R", local = TRUE)$value
  
  #### Settings ####
  
  source("Server/Settings_Server.R", local = TRUE)$value
  
}


shinyApp(ui, server)