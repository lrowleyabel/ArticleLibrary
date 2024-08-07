df<- readxl::read_excel("Data/Library/library.xlsx")


#### Add item from bib ####

observeEvent(input$add_items_bib, {
  
  item_file<- input$item_upload
  
  if (is.null(item_file)){
    return(NULL)
  }
  
  items<- handlr::bibtex_reader(item_file$datapath)%>%
    handlr::handl_to_df()
  
  item_dois<- items$doi
  
  showModal(modalDialog(title = "Adding item", attendantBar(id = "custom_progress_bar"), easyClose = F, size = "l"))
  
  withProgressAttendant({
    
    lapply(seq_along(item_dois), function(i){
      
      setProgressAttendant(value = 100*(i/length(item_dois)), text = paste0("Adding item ", i, "..."))
      
      # Get item from DOI
      response<- item_from_doi(item_dois[i])
      item<- response$new_items
      
      if (response$status != "Core fields present"){
        setProgressAttendant(value = 100*(i/length(item_dois)), text = paste0("Item ", i, " is missing core fields. Skipping..."))
        Sys.sleep(3)
        return(NULL)
      }
      
      # Attach tags
      item<- item%>%
        mutate(tags = paste(current_tags$tags, collapse = "; "))
      
      
      # Add to zotero
      
      if (user_options$use_zotero == "True"){
      
        zotero_outcome<- add_item_to_zotero(item)
        
        if (zotero_outcome == 1){
          setProgressAttendant(value = 100*(i/length(item_dois)), text = paste0("Added item ", i, " to Zotero..."))
        }
        
        if (zotero_outcome == 0){
          setProgressAttendant(value = 100*(i/length(item_dois)), text = paste0("Item ", i, " already in Zotero..."))
        }
        
      } else {
        zotero_outcome<- -1
      }
      
      
      # Add to library
      
      library_outcome<- add_item_to_library(item, with_pdf = F, zotero = zotero_outcome)
      
      if (library_outcome == 1){
        setProgressAttendant(value = 100*(i/length(item_dois)), text = paste0("Added item ", i,  " to library..."))
      }
      
      if (library_outcome == 0){
        setProgressAttendant(value = 100*(i/length(item_dois)), text = paste0("Item ", i, " already in library..."))
      }
      
      Sys.sleep(1)
      
    })
    
    setProgressAttendant(value = 100, text = "Done")
    
  }, id = "custom_progress_bar")
  
})


#### Add item from PDF ####

observeEvent(input$add_items_pdf, {
  
  # Get item from PDF  
  
  response<- item_from_pdf()
  
  if (response$status != "Core fields present"){
    manual_submission_item<<- response$new_items
    showModal(modalDialog(title = "Core fields missing",
                          textInput("manual_input_title", label = "Title", value = response$new_items$title),
                          textInput("manual_input_author", label = "Author", value = response$new_items$author),
                          textInput("manual_input_journal", label = "Journal", value = response$new_items$journal),
                          textInput("manual_input_year", label = "Year", value = response$new_items$year),
                          actionButton("manual_submit", "Submit"),
                          br(),
                          attendantBar(id = "manual_submission_progress_bar")
    )
    )
    req(response == "Core fields present")
  }
  
  showModal(modalDialog(title = "Adding item", attendantBar(id = "custom_progress_bar")))
  
  withProgressAttendant({
    
    setProgressAttendant(value = 10, text = "Adding...")
  
    new_items<- response$new_items
  
    # Attach tags
    
    new_items<- new_items%>%
      mutate(tags = paste(current_tags$tags, collapse = "; "))
  
    # Add to zotero
    
    setProgressAttendant(value = 40, text = "Adding item to Zotero...")
    
    if (user_options$use_zotero == "True"){
      
      zotero_outcome<- add_item_to_zotero(new_items)
      
      if (zotero_outcome == 1){
        setProgressAttendant(value = 50, text = "Added citation to Zotero...")
      }
      
      if (zotero_outcome == 0){
        setProgressAttendant(value = 50, text = "Item already in Zotero...")
      }
      
    } else {
      
      zotero_outcome<- -1
      
      setProgressAttendant(value = 50, text = "Skipping adding to Zotero...")
      
    }
    
    # Add to library
    
    library_outcome<- add_item_to_library(new_items, with_pdf = T, zotero = zotero_outcome)
    
    if (library_outcome == 1){
      setProgressAttendant(value = 90, text = "Added item to library...")
    }
    
    if (library_outcome == 0){
      setProgressAttendant(value = 90, text = "Item already in library")
    }

    Sys.sleep(1)
    
    
    Sys.sleep(1)
  
    setProgressAttendant(value = 100, text = "Done")
  
  }, id = "custom_progress_bar")
})


#### Add item from DOI ####

observeEvent(input$add_items_text_doi, {
  
  # Get item from PDF  
  
  response<- item_from_doi(doi = input$text_doi_add)
  
  if (response$status != "Core fields present"){
    manual_submission_item<<- response$new_items
    showModal(modalDialog(title = "Core fields missing",
                          textInput("manual_input_title", label = "Title", value = response$new_items$title),
                          textInput("manual_input_author", label = "Author", value = response$new_items$author),
                          textInput("manual_input_journal", label = "Journal", value = response$new_items$journal),
                          textInput("manual_input_year", label = "Year", value = response$new_items$year),
                          actionButton("manual_submit", "Submit"),
                          br(),
                          attendantBar(id = "manual_submission_progress_bar")
    )
    )
    req(response == "Core fields present")
  }
  
  showModal(modalDialog(title = "Adding item", attendantBar(id = "custom_progress_bar")))
  
  withProgressAttendant({
    
    setProgressAttendant(value = 10, text = "Adding...")
    
    new_items<- response$new_items
    
    # Attach tags
    
    new_items<- new_items%>%
      mutate(tags = paste(current_tags$tags, collapse = "; "))
    
    # Add to zotero
    
    setProgressAttendant(value = 40, text = "Adding item to Zotero...")
    
    if (user_options$use_zotero == "True"){
      
      zotero_outcome<- add_item_to_zotero(new_items)
      
      if (zotero_outcome == 1){
        setProgressAttendant(value = 50, text = "Added citation to Zotero...")
      }
      
      if (zotero_outcome == 0){
        setProgressAttendant(value = 50, text = "Item already in Zotero...")
      }
      
    } else {
      
      zotero_outcome<- -1
      
      setProgressAttendant(value = 50, text = "Skipping adding to Zotero...")
      
    }
    
    # Add to library
    
    library_outcome<- add_item_to_library(new_items, with_pdf = F, zotero = zotero_outcome)
    
    if (library_outcome == 1){
      setProgressAttendant(value = 90, text = "Added item to library...")
    }
    
    if (library_outcome == 0){
      setProgressAttendant(value = 90, text = "Item already in library")
    }
    
    Sys.sleep(1)
    
    setProgressAttendant(value = 100, text = "Done")
    
  }, id = "custom_progress_bar")
})



#### Add tags ####

update_autocomplete_input(session = session, id = "input_tag", label = "Add tags to new item:", options = existing_tags, create = TRUE)

current_tags<- reactiveValues(tags = NULL)

observeEvent(input$item_upload, {
  
  current_tags$tags<- NULL
  
})

observeEvent(input$item_pdf_upload, {
  
  current_tags$tags<- NULL
  
})

observeEvent(input$text_doi_add, {
  
  current_tags$tags<- NULL
  
})


observeEvent(input$add_tag, {
  
  new_tag<- input$input_tag
  
  current_tags$tags<- append(current_tags$tags, new_tag)
  
  output$new_item_tags<- renderText({
    return(paste("Tags:", paste(current_tags$tags, collapse = "; ")))
  })
  
  
})


#### Display new items ####


output$new_items_display<- renderDataTable({
  
  waiter_show(id = "new_items_display", html = spin_solar(), color = "#2c3e50")
  
  if (!is.null(input$item_upload)){
    
    item_file<- input$item_upload
    
    bib<- handlr::bibtex_reader(item_file$datapath)
    rawbib<- bibtex::read.bib(item_file$datapath)
    
    if (length(rawbib)==1){
      bib<- list(bib)
    }
    
    if ("list" %in% class(bib) & (!"handl" %in% class(bib))){
      df<- handl_to_df(bib[[1]])
    } else {
      df<- handl_to_df(bib)
    }
    
    
    df$year<- rawbib$Year
    
    zot_journals<- lapply(bib, function(bib_item){
      
      bib_item$is_part_of$title
      
    })
    
    
    new_items<- df%>%
      mutate(doi = doi,
             author = author,
             year = as.character(year),
             title = title,
             journal = as.character(zot_journals),
             url = paste0("https://www.doi.org/", doi),
             tags = paste(current_tags$tags, collapse = "; "),
             read_status = "Not read")%>%
      select(author, year, title, tags)%>%
      mutate(across(everything(), ~as.character(.x)))
    
    x<- datatable(data = new_items,
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
    
  }
  
  if (!is.null(input$item_pdf_upload)){
    
    x<- dois_from_pdf()
    
    response<- item_from_pdf()
    
    new_items<- response$new_items
    
    if(is.null(new_items)){
      return(NULL)
    }
    
    
    new_items<- new_items%>%
      mutate(tags = paste(current_tags$tags, collapse = "; "))
    
    new_items<- new_items%>%
      mutate(across(c(author, year, title, tags), ~ifelse(is.na(.x), "", .x)))
    
    new_items<- new_items%>%
      select(author, year, title, tags)
    
    x<- datatable(data = new_items,
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
    
  }
  
  if (!is.null(input$text_doi_add) & input$text_doi_add != ""){
    
    response<- item_from_doi(input$text_doi_add)
    
    new_items<- response$new_items
    
    if(is.null(new_items)){
      return(NULL)
    }
    
    
    new_items<- new_items%>%
      mutate(tags = paste(current_tags$tags, collapse = "; "))
    
    new_items<- new_items%>%
      mutate(across(c(author, year, title, tags), ~ifelse(is.na(.x), "", .x)))
    
    new_items<- new_items%>%
      select(author, year, title, tags)
    
    x<- datatable(data = new_items,
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
    
  }
  
})

observeEvent(input$manual_submit, {
  
  withProgressAttendant({
    
    setProgressAttendant(value = 10, text = "Adding...")
    
    new_items<- manual_submission_item
    
    new_items$title<- input$manual_input_title
    new_items$author<- input$manual_input_author
    new_items$journal<- input$manual_input_journal
    new_items$year<- input$manual_input_year
    
    # Attach tags
    
    new_items<- new_items%>%
      mutate(tags = paste(current_tags$tags, collapse = "; "))
    
    # Add to zotero
    
    zotero_outcome<- add_item_to_zotero(new_items)
    
    setProgressAttendant(value = 50, text = "Added to Zotero...")
    
    Sys.sleep(1)
    
    
    # Add to library
    
    library_outcome<- add_item_to_library(new_items, with_pdf = F, zotero = zotero_outcome)
    
    setProgressAttendant(value = 50, text = "Added to library...")
    
    Sys.sleep(1)
    
    setProgressAttendant(value = 100, text = "Done")
    
    Sys.sleep(1)
    
  }, id = "manual_submission_progress_bar")
  
})
