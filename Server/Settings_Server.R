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
    
    drive_auth()
    
    drive_upload(paste0(backup_path, ".zip"))
    
    setProgressAttendant(value = 100, text = "Done")
    
    
  }, id = "backup_progress_bar")
  
})

observeEvent(input$import_zotero_dois, {
  
  showModal(modalDialog(title = "Update memory of Zotero items",
                        p("This checks what DOIs are already in your Zotero library so that the app doesn't duplicate items when you add them."),
                        attendantBar(id = "import_zotero_progress_bar")
                        ))
  
  
  url <- paste0("https://api.zotero.org/users/", user_options$zotero_library_id, "/items?limit=0")
  
  response <- GET(
    url,
    add_headers(Authorization = paste("Bearer", user_options$zotero_api_key))
  )
  
  total_zotero_items<- as.numeric(headers(response)[["Total-Results"]])
  
  end<- 0
  
  zotero_data<- data.frame(key = c(), version = c(), DOI = c())
  zotero_results<- data.frame()

  withProgressAttendant({
    
    setProgressAttendant(value = 10)
    
    while (is.data.frame(zotero_results)) {
      
      start<- end+1
      
      print(paste("Fetching, starting at item", start))
      
      # Construct the API URL to retrieve items
      url <- paste0("https://api.zotero.org/users/", user_options$zotero_library_id, "/items?format=json&limit=100&start=", start)
      
      # Send the GET request to retrieve items
      response <- GET(
        url,
        add_headers(Authorization = paste("Bearer", user_options$zotero_api_key))
       )
      
      zotero_results <- fromJSON(content(response, "text", encoding = "UTF-8"))$data
      
      if (is.null(zotero_results)){
        print("Breaking because is null")
        break
      }
      
      if (all(zotero_results$DOI %in% zotero_data$DOI, na.rm = T)){
        print(paste0("Breaking because all already in list"))
        
        break
      }
      
      new_dois<- zotero_results%>%
        filter(!DOI %in% zotero_data$DOI)%>%
        select(key, version, DOI)
      
      zotero_data<- rbind(zotero_data, new_dois)
      
      end<- end+nrow(zotero_results)
      
      setProgressAttendant(value = 100*(end/total_zotero_items), text = paste("Fetched", end, "items from Zotero..."))
      
    }
    
    write.csv(zotero_data, "Data/Zotero Data.csv", row.names = F)
    
    setProgressAttendant(value = 100, text = "Done")
    
  }, id = "import_zotero_progress_bar")
  

})

proposed_deletions<- reactiveVal(data.frame(key = c(), title = c(), date_added = c()))

observeEvent(input$clear_zotero_pdfs, {
  
  df<- readxl::read_xlsx("Data/Library/library.xlsx")
  
  library_dois<- df$doi
  
  zotero_data<- read.csv("Data/Zotero Data.csv")
  
  showModal(modalDialog(title = "Clear Zotero PDFs",
                        p("This searches for potential items to delete from Zotero. An item will be proposed for deletion if it has a PDF attached in Zotero and is also duplicated."),
                        attendantBar(id = "zotero_clear_progress_bar"),
                        p("The below items are proposed for deletion:"),
                        renderDataTable(datatable(data = proposed_deletions(),
                                                        style = "bootstrap4",
                                                        class = "hover",
                                                        rownames = FALSE,
                                                        selection = "multiple",
                                                        fillContainer = TRUE,
                                                        escape = FALSE,
                                                        editable = T,
                                                        options = list(paging = FALSE,
                                                                       searching = FALSE,
                                                                       columnDefs = list(
                                                                         list(
                                                                           targets = c(0),
                                                                           render = DT::JS(
                                                                             "function(data, type, row, meta) {",
                                                                             "return type === 'display' && data.length > 1 ?",
                                                                             "'<span title=\"' + data + '\">' + data.substr(0, 15) + '...</span>' : data;",
                                                                             "}")
                                                                         )
                                                                       )
                                                        )
                        )),
                        size = "xl",
                        footer = list(actionButton("clear_zotero_pdfs_confirmation", "Delete items"), modalButton("Dismiss"))))
  
  withProgressAttendant({
    
    i<- 0
    
    for(doi in library_dois){
      
      i<- i+1
      
      setProgressAttendant(value = 100*(i/length(library_dois)), text = paste("Checked", i, "item(s)"))
      
      zotero_matches<- zotero_data%>%
        filter(DOI == doi)
      
      if(nrow(zotero_matches)>1){
        
        duplicated_title<- df$title[df$doi==doi]
        
        url <- paste0("https://api.zotero.org/users/", user_options$zotero_library_id, "/items?format=json&q=", URLencode(duplicated_title), "&qmode=titleCreatorYear")
        
        response <- GET(
          url,
          add_headers(Authorization = paste("Bearer", user_options$zotero_api_key))
        )
        
        
        items <- fromJSON(content(response, "text", encoding = "UTF-8"))
        
        duplicates_with_pdfs<- items[items$meta$numChildren>0,]
        
        print(nrow(duplicates_with_pdfs))
        
        new_proposed_deletions<- data.frame(key = duplicates_with_pdfs$key,
                                            title = duplicates_with_pdfs$data$title,
                                            date_added = duplicates_with_pdfs$data$dateAdded)
        
        print(new_proposed_deletions)
        
        proposed_deletions(rbind(proposed_deletions(), new_proposed_deletions))
        
      }
      
    }
    setProgressAttendant(value = 100, text = "Done")
    
  
  }, id = "zotero_clear_progress_bar")
  
})

observeEvent(input$clear_zotero_pdfs_confirmation, {
  
  withProgressAttendant({
    
    setProgressAttendant(value = 0, text = "Deleting...")
    
    Sys.sleep(2)
    
    keys<- proposed_deletions()$key
    
    if(length(keys)==0){
      setProgressAttendant(value = 100, text = "Nothing to delete")
    }
  
    zotero_data<- read.csv("Data/Zotero Data.csv")
    
    i<- 0
    
    for(key in keys){
      
      i<- i + 1
      
      version<- zotero_data$version[zotero_data$key==key]
      
      url <- paste0("https://api.zotero.org/users/", user_options$zotero_library_id, "/items/", key)
      
      response <- DELETE(
        url,
        add_headers(Authorization = paste("Bearer", user_options$zotero_api_key),
                    `If-Unmodified-Since-Version` = version)
      )
      
      setProgressAttendant(value = 100*(i/length(keys)), text = paste("Deleted", key))
      
    }
    
  }, id = "zotero_clear_progress_bar")
  
})

