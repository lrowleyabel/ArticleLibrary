if (user_options$use_chrome_extension == "True"){
  
  synced_item_log<- reactiveValues(log = NULL)
  
  sync<- reactiveTimer(intervalMs = 10000, session = session)
  
  observe({
    
    sync()
    
    downloads_path<- user_options$downloads_path
    
    req(downloads_path)
    
    download_files<- list.files(downloads_path)
    
    pending_item_files<- download_files[str_detect(download_files, "Article Library Item Download")]
    
    lapply(pending_item_files, function(pending_item_file){
      
      pending_item<- jsonlite::fromJSON(readLines(paste0(downloads_path, "/", pending_item_file)))
      
      doi_pattern<- "10.\\d{4,9}/[-._;()/:a-z0-9A-Z]+"
      
      if (!str_detect(pending_item$doi, doi_pattern)){
        print(paste0("DOI '", pending_item$doi, "' from file '", pending_item_file, "' does not contain a recognised DOI pattern."))
        showModal(modalDialog(title = "Warning", "Invalid DOI(s) found in downloaded file while syncing"))
        return(NULL)
      }
      
      pending_item$doi<- str_extract(pending_item$doi, doi_pattern)
      
      if (check_doi_in_library(pending_item$doi)){
        print(paste0("DOI '", pending_item$doi,  "' from file '", pending_item_file, "' already in library. Deleting file."))
        file.remove(paste0(downloads_path, "/", pending_item_file))
        return(NULL)
      }
  
      # Get item from DOI
      
      response<- tryCatch({
          item_from_doi(pending_item$doi)
        },
        error = function(e){
          return(NULL)
        }
      )  
                      
      
      if (is.null(response) | response$status != "Core fields present"){
        print(paste0("DOI '", pending_item$doi,  "' from file '", pending_item_file, "' returned an error."))
        showModal(modalDialog(title = "Warning", "Error while processing downloaded file"))
        return(NULL)
      }
      
      item<- response$new_items
      
      
      # Attach tags
      
      item<- item%>%
        mutate(tags = pending_item$tags)
      
      # Add item to zotero
      if (user_options$use_zotero == "True"){
        
        zotero_outcome<- add_item_to_zotero(item)
        
      } else {
        zotero_outcome<- -1
      }
      
      
      # Add item to library
      
      add_item_to_library(item = item, with_pdf = F, zotero = zotero_outcome)
      
      # Add item to log of synced items
      
      current_log<- synced_item_log$log
      
      if (!is.null(current_log)){
        new_log<- rbind(current_log, item)
      } else {
        new_log<- item
      }
      
      synced_item_log$log<- new_log
      
      # Delete pending item file from Downloads
      
      file.remove(paste0(downloads_path, "/", pending_item_file))
      
    })
      
  })
  
  # Update synced item log
  
  output$synced_item_log_display<- renderDataTable({
    
    log<- synced_item_log$log
    
    if (is.null(log)){
      return(NULL)
    }
    
    x<- datatable(data = log%>%
                    select(author, year, title, tags),
                  style = "bootstrap4",
                  class = "hover",
                  rownames = FALSE,
                  fillContainer = TRUE,
                  escape = TRUE,
                  editable = TRUE,
                  options = list(pageLength = 50,
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
    )
    
    return(x)
    
  })

}


