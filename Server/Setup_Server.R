if(user_options$first_time == "True"){
  
  showModal(modalDialog(size = "xl",
                        footer = NULL,
                        title = "Looks like its your first time",
                        
                        div(
                          style = "height: 400px !important;",
                          
                          div(
                            id = "setup_card_5",
                            div(style = "width: 100px; margin: auto;", img(src = "img/icon.ico", height = "100px", style = "margin: auto;")),
                            div("Everything is setup. You can change these preferences in the Settings tab", style = "text-align: center; padding-top: 30px;"),
                            div(style = "text-align: center; margin: auto; width: 200px; padding-top: 20px;", actionButton("setup_close", "Done", width = 200, class = "btn-success"))
                            
                          ),
                          
                          div(
                            id = "setup_card_4",
                            div(style = "width: 100px; margin: auto;", img(src = "img/icon.ico", height = "100px", style = "margin: auto;")),
                            div("Enter the path to your Download folder below", style = "text-align: center; padding-top: 30px;"),
                            div(style = "text-align: center; margin: auto; width: 200px;", textInput("setup_downloads_path", "")),
                            div(style = "text-align: center; margin: auto; width: 200px;", actionButton("setup_save_downloads_path", "Save", width = 200, class = "btn-success"))
                            
                          ),
                          
                          div(
                            id = "setup_card_3",
                            div("Input your Zotero library ID and API key below"),
                            actionLink(input = "setup_no_zotero_credentials", label = "Don't have these?"),
                            div(id = "zotero_credentials_help_text"),
                            textInput("setup_library_id", "Zotero library ID:"),
                            textInput("setup_api_key", "Zotero API key:"),
                            attendantBar(id = "zotero_fetch_progress"),
                            br(),
                            br(),
                            actionButton("setup_save_zotero_settings", "Save")
                          ),
                          
                          div(
                            id = "setup_card_2",
                            #h4(style = "text-align: center; margin: auto; padding: 20px;", "Step 1"),
                            div(style = "width: 100px; margin: auto;", img(src = "img/icon.ico", height = "100px", style = "margin: auto;")),
                            div("Do you want to link Article Library to Zotero?", style = "text-align: center; padding-top: 30px;"),
                            div(style = "text-align: center; margin: auto; padding: 20px;", actionButton("second_setup_button_no", "No", width = 100, class = "btn-success"), actionButton("second_setup_button_yes", "Yes", width = 100, class = "btn-success"))
                            
                          ),
                          
                          div(
                            id = "setup_card_1",
                            h4(style = "text-align: center; margin: auto; padding: 20px;", "Welcome to Article Library"),
                            div(style = "width: 100px; margin: auto;", img(src = "img/icon.ico", height = "100px", style = "margin: auto;")),
                            div(style = "text-align: center; margin: auto; padding: 20px;", actionButton("setup", "Before you start, a few things to set up..."))
                          )
                        )
  )
  )
  
}
observeEvent(input$setup, {
  
  shinyjs::js$first_setup_button()
  
})

observeEvent(input$second_setup_button_yes, {
  
  user_options$use_zotero<<- "True"
  
  shinyWidgets::updateMaterialSwitch(session = session, inputId = "use_zotero", value = ifelse(user_options$use_zotero == "True", T, F))
  
  writeLines(text = jsonlite::toJSON(user_options), con = "Data/user_options.json")
  
  updateTextInput(session = session, inputId = "setup_library_id", value = user_options$zotero_library_id)
  
  updateTextInput(session = session, inputId = "setup_api_key", value = user_options$zotero_api_key)
  
  shinyjs::js$second_setup_button_yes()
  
})

observeEvent(input$setup_save_zotero_settings, {
  
  
  #updateTextInput(session = session, inputId = "downloads_path", value = user_options$downloads_path)
  
  user_options$zotero_library_id<<- input$setup_library_id
  
  user_options$zotero_api_key<<- input$setup_api_key
  
  updateTextInput(session = session, inputId = "library_id", value = user_options$zotero_library_id)
  
  updateTextInput(session = session, inputId = "api_key", value = user_options$zotero_api_key)
  
  
  zotero_results<- list()
  end<- 0
  
  withProgressAttendant({
    
    setProgressAttendant(value = 10, text = "Fetching...")
    
    while (is.list(zotero_results)) {
      
      print(paste("Fetching, starting at", end+1))
    
      zotero_results<- RefManageR::ReadZotero(user = user_options$zotero_library_id, .params = list(key = user_options$zotero_api_key, limit = 100, start = end+1, sort = "dateAdded"))
      
      
      if (is.null(zotero_results)){
        print("Breaking because is null")
        break
      }
      
      if (all(zotero_results$doi %in% user_options$existing_zotero_dois, na.rm = T)){
        print(paste0("Breaking because all already in list"))
        
        break
      }
      
      new_dois<- zotero_results$doi[!zotero_results$doi %in% user_options$existing_zotero_dois]%>%
        unname()%>%
        unlist()
      
      user_options$existing_zotero_dois<<- append(user_options$existing_zotero_dois, new_dois)
      
      end<- end+length(zotero_results)
      
      setProgressAttendant(value = end/10, text = "Fetching...")
      
    }
    
  }, id = "zotero_fetch_progress")
  
  
  writeLines(text = jsonlite::toJSON(user_options), con = "Data/user_options.json")
  
  updateTextInput(session = session, inputId = "setup_downloads_path", value = user_options$downloads_path)
  
  shinyjs::js$setup_save_zotero_settings()
  

  
})


observeEvent(input$setup_no_zotero_credentials, {
  
  shinyjs::js$zotero_credential_help()
  
})

observeEvent(input$second_setup_button_no, {
  
  user_options$use_zotero<<- "False"
  
  shinyWidgets::updateMaterialSwitch(session = session, inputId = "use_zotero", value = ifelse(user_options$use_zotero == "True", T, F))
  
  writeLines(text = jsonlite::toJSON(user_options), con = "Data/user_options.json")
  
  shinyjs::js$second_setup_button_no()
  
})

observeEvent(input$setup_save_downloads_path, {
  
  user_options$downloads_path<<- normalizePath(input$setup_downloads_path)
  
  updateTextInput(session = session, inputId = "downloads_path", value = user_options$downloads_path, label = "Downloads path:")
  
  shinyjs::js$save_downloads_path()
  
})


observeEvent(input$setup_close, {
  
  user_options$first_time<- "False"
  
  writeLines(text = jsonlite::toJSON(user_options), con = "Data/user_options.json")
  
  removeModal(session = session)
  
})
