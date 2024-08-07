observeEvent(input$save_zotero_settings, {
  
  if(input$use_zotero){
    user_options$use_zotero<- "True"
  } else {
    user_options$use_zotero<- "False"
  }
  
  user_options$zotero_library_id<- input$library_id
  
  user_options$zotero_api_key<- input$api_key
  
  writeLines(text = jsonlite::toJSON(user_options), con = "Data/user_options.json")
  
  showModal(modalDialog("Zotero settings updated. Refresh app for changes to take effect."))
  
})

observeEvent(input$no_zotero_credentials, {
  showModal(modalDialog(title = "Finding Zotero credentials", div("If you do not have these, go to zotero.org and login. Go to Settings > Feeds/API. Here you can see your library ID and you can create an API key by clicking 'Create new private key'. Make sure to give the API key read and write permissions (ie: under 'Personal Library' check 'Allow write access' and 'Allow notes access', then under 'Default Group Permissions' select 'Read/Write').")))
})

observeEvent(input$use_chrome_extension, {
  
  user_options$use_chrome_extension<- ifelse(input$use_chrome_extension, "True", "False")
  
  writeLines(text = jsonlite::toJSON(user_options), con = "Data/user_options.json")
  
})