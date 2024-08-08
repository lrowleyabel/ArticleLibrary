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


observeEvent(input$update_app, {
  
  showModal(modalDialog(title = "Update app", p("Updating the app will replace the server files and app.R file with those from the latest version on GitHub. It will not change your library data or PDFs. To update, click Continue and when the update is complete, refresh the app in your browser."),
                        attendantBar(id = "app_update_progress_bar"),
                        br(),
                        footer = list(actionButton(class = "btn-success", inputId = "update_app_confirmation", label = "Continue"), modalButton("Dismiss"))
  ))
  
})  

observeEvent(input$update_app_confirmation, {
  withProgressAttendant({
    
    setProgressAttendant(value = 50, text = "Updating...")
    
    
    if("NewArticleLibrary.zip" %in% dir("../")){
      file.remove("../NewArticleLibrary.zip")
    }
    
    download.file(url = "https://github.com/lrowleyabel/ArticleLibrary/archive/refs/heads/main.zip",
                  destfile = "../NewArticleLibrary.zip")
    
    
    if("NewArticleLibrary" %in% dir("../")){
      unlink("../NewArticleLibrary", recursive = T)
    }
    
    unzip(zipfile = "../NewArticleLibrary.zip", exdir = "../NewArticleLibrary")
    
    file.remove("../NewArticleLibrary.zip")
    
    existing_server_files<- dir("Server")
    new_server_files<- dir("../NewArticleLibrary/ArticleLibrary-main/Server")
    
    sapply(existing_server_files, function(f){
      file.remove(paste0("Server/",f))
    })
    
    sapply(new_server_files, function(f){
      file.rename(from = paste0("../NewArticleLibrary/ArticleLibrary-main/Server/", f), to = paste0("Server/", f))
    })
    
    file.rename("../NewArticleLibrary/ArticleLibrary-main/app.R", "app.R")
    
    unlink("../NewArticleLibrary", recursive = T)
    
    setProgressAttendant(value = 100, text = "Done")
    
  }, id = "app_update_progress_bar")
  
  
  
})

observeEvent(input$backup_data, {
  
  showModal(modalDialog(title = "Backup data to Google Drive",
             p("This uploads a snapshot of your current Article Library data and PDFs to your Google Drive. You will be prompted to give the app permission to read/write/edit your files on Drive. The app will then store the data/PDFs in a ZIP file on Drive named with the current time stamp."),
             attendantBar(id = "backup_progress_bar"),
             footer = list(actionButton(inputId = "backup_data_confirmation", label = "Continue", class = "btn-success"), modalButton("Dismiss"))
  ))
  
})

observeEvent(input$backup_data_confirmation, {
  
  withProgressAttendant({
    
    setProgressAttendant(value = 30, text = "Copying PDFs...")
    
    backup_name<- paste("Article Library Backup", Sys.time())%>%
      str_replace_all("[:punct:]", "_")
    
    backup_path<- paste0("Data/Backups/", backup_name) 
    
    dir.create(backup_path)
    
    dir.create(paste0(backup_path, "/PDFs"))
    
    fs::dir_copy("PDFs", paste0(backup_path, "/PDFs"), overwrite = T)
    
    setProgressAttendant(value = 35, text = "Copying data...")
    
    fs::file_copy("Data/Library/library.xlsx", backup_path)
    
    fs::file_copy("Data/user_options.json", backup_path)
    
    setProgressAttendant(value = 50, text = "Packaging backup...")
    
    zip(backup_path, files = backup_path)
    
    fs::dir_delete(backup_path)
    
    setProgressAttendant(value = 70, text = "Uploading to Drive...")
    
    drive_upload(paste0(backup_path, ".zip"))
    
    setProgressAttendant(value = 100, text = "Done")
    
    
  }, id = "backup_progress_bar")
  
})