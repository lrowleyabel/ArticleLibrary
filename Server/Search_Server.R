df<- readxl::read_excel("Data/Library/library.xlsx")

df<- df%>%
  mutate(status = paste0(ifelse(is.na(pdf_path), '', '<img src="img/pdf.svg" height="15px">'), ifelse(zotero=="True", '<img src="img/z.svg" height="15px""></img>', ''), ifelse(read_status == "Read", '<img src="img/eye.svg" height="19px""></img>', '')))

search_df<- df%>%
  arrange(desc(year), author)

get_df<- reactiveVal(df)

get_search_df<- reactiveVal(search_df)

observeEvent(input$search_query, {
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  df<- df%>%
    mutate(status = paste0(ifelse(is.na(pdf_path), '', '<img src="img/pdf.svg" height="15px">'), ifelse(zotero=="True", '<img src="img/z.svg" height="15px""></img>', ''), ifelse(read_status == "Read", '<img src="img/eye.svg" height="19px""></img>', '')))
  
  search_query<- input$search_query
  
  if (is.null(search_query) | search_query == ""){
    
    search_df<- df%>%
      arrange(desc(year), author)

    
  } else {
    
    search_df<- df
    
    search_df$search_field<- search_df[[input$search_by_field]]
    
    search_df<- search_df%>%
      filter(str_detect(search_field, search_query))%>%
      select(-search_field)%>%
      arrange(desc(year), author)
    
    
  }
  
  get_search_df(search_df)
  
})

output$search_results<- renderDataTable({
  
  y<- get_df()
  
  search_df<- get_search_df()
  
  search_df<- search_df%>%
    mutate(status = paste0(ifelse(is.na(pdf_path), '', '<img src="img/pdf.svg" height="15px">'), ifelse(zotero=="True", '<img src="img/z.svg" height="15px""></img>', ''), ifelse(read_status == "Read", '<img src="img/eye.svg" height="19px""></img>', '')))
  
  
  search_df<- search_df%>%
    select(author, year, title, status, tags)%>%
    rename_with(.fn = ~str_to_sentence(.x))
  
  selection_option<- ifelse(input$multiselect, "multiple", "single")
  
  x<- datatable(data = search_df,
                style = "bootstrap4",
                class = "hover",
                rownames = FALSE,
                fillContainer = TRUE,
                escape = FALSE,
                selection = selection_option,
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
      )
    
  return(x)
   
})


observeEvent(input$read_selected_item, {
  
  search_df<- get_search_df()
  
  if(is.null(input$search_results_rows_selected) | length(input$search_results_rows_selected)>1){
    showModal(modalDialog("Select an item to read"))
    return(NULL)
  }
  
  pdf_path<- search_df$pdf_path[input$search_results_rows_selected][[1]]%>%
    normalizePath()
  
  if(is.na(pdf_path)){
    
    showModal(modalDialog("No PDF file attached to this item"))
    return(NULL)
    
  }
  
  get_os <- function(){
    sysinf <- Sys.info()
    if (!is.null(sysinf)){
      os <- sysinf['sysname']
      if (os == 'Darwin')
        os <- "osx"
    } else { ## mystery machine
      os <- .Platform$OS.type
      if (grepl("^darwin", R.version$os))
        os <- "osx"
      if (grepl("linux-gnu", R.version$os))
        os <- "linux"
    }
    tolower(os)
  }
  
  os<- get_os()
  
  if(os == "windows"){
    system(paste0('start "', pdf_path, '"'))
  } else {
    system(paste0('open "', pdf_path, '"'))
  }
  
})

observeEvent(input$open_selected_item_online, {
  
  search_df<- get_search_df()
  
  if(is.null(input$search_results_rows_selected) | length(input$search_results_rows_selected)>1){
    showModal(modalDialog("Select an item to open"))
    return(NULL)
  }
  
  url<- search_df$url[input$search_results_rows_selected][[1]]
  
  if(is.na(url)){
    
    showModal(modalDialog("No URL for this item"))
    return(NULL)
    
  }
  
  browseURL(url)
  
})



observeEvent(input$mark_selected_item_as_read, {
  
  search_df<- get_search_df()
  
  if(is.null(input$search_results_rows_selected)){
    showModal(modalDialog("Select an item to mark as read"))
    return(NULL)
  }
  
  selected_item_doi<- search_df$doi[input$search_results_rows_selected]
  
  df<- readxl::read_excel("Data/Library/library.xlsx")

  df$read_status[df$doi %in% selected_item_doi]<- "Read"
  
  writexl::write_xlsx(x = df, path = "Data/Library/library.xlsx")
  
  
  search_query<- input$search_query
  
  if (is.null(search_query) | search_query == ""){
    
    search_df<- df%>%
      arrange(desc(year), author)
    
    
  } else {
    
    search_df<- df
    
    search_df$search_field<- search_df[[input$search_by_field]]
    
    search_df<- search_df%>%
      filter(str_detect(search_field, search_query))%>%
      select(-search_field)%>%
      arrange(desc(year), author)
    
    
  }
  
  get_search_df(search_df)
  
  showModal(modalDialog(title = "Success", "Marked as read", footer = NULL))
  
  Sys.sleep(2)
  
  removeModal()
  
})


observeEvent(input$mark_selected_item_as_unread, {
  
  search_df<- get_search_df()
  
  if(is.null(input$search_results_rows_selected)){
    showModal(modalDialog("Select an item to mark as unread"))
    return(NULL)
  }
  
  selected_item_doi<- search_df$doi[input$search_results_rows_selected]
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  df$read_status[df$doi %in% selected_item_doi]<- "Not read"
  
  writexl::write_xlsx(x = df, path = "Data/Library/library.xlsx")
  
  search_query<- input$search_query
  
  if (is.null(search_query) | search_query == ""){
    
    search_df<- df%>%
      arrange(desc(year), author)
    
    
  } else {
    
    search_df<- df
    
    search_df$search_field<- search_df[[input$search_by_field]]
    
    search_df<- search_df%>%
      filter(str_detect(search_field, search_query))%>%
      select(-search_field)%>%
      arrange(desc(year), author)
    
    
  }
  
  get_search_df(search_df)
  
  showModal(modalDialog(title = "Success", "Marked as unread", footer = NULL))
  
  Sys.sleep(2)
  
  removeModal()
  
})

observeEvent(input$delete_selected_item, {
  
  search_df<- get_search_df()
  
  if(is.null(input$search_results_rows_selected)){
    showModal(modalDialog("Select an item to delete"))
    return(NULL)
  }
  
  selected_item_doi<- search_df$doi[input$search_results_rows_selected]
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  df<- df%>%
    filter(doi != selected_item_doi)
  
  writexl::write_xlsx(x = df, path = "Data/Library/library.xlsx")
  
  search_query<- input$search_query
  
  if (is.null(search_query) | search_query == ""){
    
    search_df<- df%>%
      arrange(desc(year), author)
    
    
  } else {
    
    search_df<- df
    
    search_df$search_field<- search_df[[input$search_by_field]]
    
    search_df<- search_df%>%
      filter(str_detect(search_field, search_query))%>%
      select(-search_field)%>%
      arrange(desc(year), author)
    
    
  }
  
  get_search_df(search_df)
  
  showModal(modalDialog(title = "Success", "Item deleted", footer = NULL))
  
  Sys.sleep(2)
  
  removeModal()
  
})

existing_tags<- paste(df$tags, collapse = "; ")%>%
  str_split("; ")%>%
  unlist()%>%
  unique()

authors<- df$author%>%
  str_split(" and |\\., ")%>%
  unlist()%>%
  unique()


update_autocomplete_input(session = session, id = "search_query", label = "Search for...", options = existing_tags, create = TRUE)


observeEvent(input$search_by_field, {
  
  if(input$search_by_field == "tags"){
   
    update_autocomplete_input(session = session, id = "search_query", label = "", placeholder = "Search...", options = existing_tags, create = TRUE)
    
  }
  
  if(input$search_by_field == "author"){
    
    update_autocomplete_input(session = session, id = "search_query", label = "", placeholder = "Search...", options = authors, create = TRUE)
    
  }
  
  if(input$search_by_field == "title"){
    
    update_autocomplete_input(session = session, id = "search_query", label = "", placeholder = "Search...", options = unique(df$title), create = TRUE)
    
  }
  
  
  
})



observeEvent(input$search_results_cell_edit, {
  
  search_df<- get_search_df()
  
  edited_row<- input$search_results_cell_edit$row
  edited_column<- input$search_results_cell_edit$col + 1
  
  edited_item_doi<- search_df$doi[edited_row]
  edited_variable<- c("author", "year", "title", "status", "tags")[edited_column]
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  df[df$doi==edited_item_doi & !is.na(df$doi),edited_variable]<- input$search_results_cell_edit$value
  
  writexl::write_xlsx(x = df, path = "Data/Library/library.xlsx")
  
})
