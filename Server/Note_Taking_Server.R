update_autocomplete_input(session = session, id = "manual_attach_item_selection", options = df$title, label = "Select existing item to attach to")

observeEvent(input$pdf_upload, {
  
  pdf_file<- input$pdf_upload
  
  if (is.null(pdf_file)){
    return(NULL)
  }
  
  pdf_text<- pdftools::pdf_text(pdf_file$datapath)
  
  doi_pattern<- "10.\\d{4,9}/[-._;()/:a-z0-9A-Z]+"
  
  extracted_dois<- str_extract_all(pdf_text, doi_pattern)%>%
    unlist()
  
  updateSelectizeInput(session = session, inputId = "pdf_dois", choices = extracted_dois)
  
  
})

output$pdf_item_confirmation<- renderUI({
  
  if (is.null(input$pdf_dois) | input$pdf_dois == ""){
    return(NULL)
  }
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  matched_item<- df%>%
    filter(doi == input$pdf_dois)
  
  first_author<- str_extract(matched_item$author[1], "[^,]*(?=,)")
  
  if (nrow(matched_item) != 0){
    shinyjs::enable("save_pdf")  
    update_autocomplete_input(session = session, id = "manual_attach_item_selection", options = df$title, label = "Select existing item to attach to", value = matched_item$title[1])
    return(list(tags$i(class = "text-success", paste0("Existing item detected: ", first_author, ", ", matched_item$year[1]))))
                
  } else {
    
    return(tags$i(class = "text-danger", "No match found in exsiting items. Type title below or add the PDF as new item in the Add tab."))
    
  }
  
  
})

observeEvent(input$save_pdf, {
  
  if (input$manual_attach_item_selection == "" | is.na(input$manual_attach_item_selection)){
    showModal(modalDialog("No item selected to attach PDF to."))
    req(input$manual_attach_item_selection)
  }
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  matched_item<- df%>%
    filter(title == input$manual_attach_item_selection)
  
  first_author<- str_extract(matched_item$author[1], "[^,]*(?=,)")
  
  if (!dir.exists(paste0("PDFs/", matched_item$year[1]))){
    
    dir.create(paste0("PDFs/", matched_item$year[1]))
    
  }
  
  if (!dir.exists(paste0("PDFs/", matched_item$year[1], "/", first_author))){
    
    dir.create(paste0("PDFs/", matched_item$year[1], "/", first_author))
    
  }
  
  pdf_file<- input$pdf_upload
  
  file.rename(from = pdf_file$datapath, to = paste0("PDFs/", matched_item$year[1], "/", first_author, "/", paste0(first_author, " ", matched_item$year[1], ".pdf")))
  
  df$pdf_path[df$title == input$manual_attach_item_selection]<- paste0("PDFs/", matched_item$year[1], "/", first_author, "/", paste0(first_author, " ", matched_item$year[1], ".pdf"))
  
  writexl::write_xlsx(df, path = "Data/Library/library.xlsx")
  
  showModal(modalDialog(title = "Success", "PDF attached to item."))
  
  get_df(df)
  
})


observeEvent(input$create_item_from_pdf, {
  
  nav_select(id = "index_navbar", selected = "Add")
  
})
