#### Options ####

if(!file.exists("Data/user_options.json")){
  
  print("Creating user options file")
  
  user_options<- list("use_zotero" = "True", "zotero_library_id" = "", "zotero_api_key" = "", "use_chrome_extension" = "False", "downloads_path" = "", "first_time" = "True", "existing_zotero_dois" = list())
  
  writeLines(text = jsonlite::toJSON(user_options), con = "Data/user_options.json")
  
}

user_options<- jsonlite::fromJSON(txt = "Data/user_options.json")

zot_set_options(user = user_options$zotero_library_id, credentials = user_options$zotero_api_key)

shinyWidgets::updateMaterialSwitch(session = session, inputId = "use_zotero", value = ifelse(user_options$use_zotero == "True", T, F))

updateTextInput(session = session, inputId = "library_id", value = user_options$zotero_library_id)

updateTextInput(session = session, inputId = "api_key", value = user_options$zotero_api_key)

shinyWidgets::updateMaterialSwitch(session = session, inputId = "use_chrome_exntesion", value = ifelse(user_options$use_chrome_extension == "True", T, F))

updateTextInput(session = session, inputId = "downloads_path", value = user_options$downloads_path)

options(shiny.maxRequestSize=30*1024^2)


#### Zotero sync ####

if (user_options$first_time == "False" & 1 == 2){
  
  zotero_results<- list()
  end<- 0
  
  waiter_show(html = shiny::tagList(h2(style = "margin:30px;", "Loading Article Library"),
                                    spin_solar()), color = "#18bc9c")

 
  while (is.list(zotero_results)) {
    
    zotero_results<- RefManageR::ReadZotero(user = user_options$zotero_library_id, .params = list(key = user_options$zotero_api_key, limit = 100, start = end+1))
    
    if (is.null(zotero_results)){
      break
    }
    
    new_dois<- zotero_results$doi[!zotero_results$doi %in% user_options$existing_zotero_dois]%>%
      unname()%>%
      unlist()
    
    if (is.null(new_dois)){
      break
    }
    
    print(new_dois)
    
    user_options$existing_zotero_dois<- append(user_options$existing_zotero_dois, new_dois)
    
    print(user_options$existing_zotero_dois[length(user_options$existing_zotero_dois)])
    
    end<- end+length(zotero_results)+1
    
    
  }
  
  writeLines(text = jsonlite::toJSON(user_options), con = "Data/user_options.json")
  
  waiter_hide()
  
}

#### Set up ####

source("Server/Setup_Server.R", local = TRUE)$value


#### Functions ####

check_doi_in_library<- function(doi){
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  return(doi %in% df$doi)
  
}

item_from_doi<- function(doi){
  
  json_results<- tryCatch({rcrossref::cr_cn(dois = doi, format = "citeproc-json")},
                              error = function(e){
                                print(e)
                                showModal(modalDialog(title = "Error", paste("Error calling CrossRef API:", e)))
                                req(1 == 0)
                              })
  
  if(is.null(json_results) | is.null(json_results)){
    print("NULL returned by Crossref from DOI lookup")
    return(NULL)
  }
  
  title<- json_results$title
  author<- paste0(json_results$author$family, ", ", json_results$author$given, collapse = " and ")
  journal<- json_results$`container-title`
  year<- json_results$published$`date-parts`[,1]
  
  core_fields<- list(title = title, author = author, journal = journal, year = year)
  
  core_fields<- lapply(core_fields, function(x){
    return(ifelse(!is.null(x), x, NA))
  })
  
  if(any(is.na(core_fields))){
    status<- "Core fields missing"
  } else {
    status<- "Core fields present"
  }
  
  volume<- json_results$volume
  issue<- json_results["issue"][[1]]
  pages<- json_results$page
  doi<- json_results$DOI
  issn<- json_results$ISSN
  url<- json_results$URL
  
  non_core_fields<- list(volume = volume, issue = issue, pages = pages, doi = doi, issn = issn, url = url)
  
  non_core_fields<- lapply(non_core_fields, function(x){
    return(ifelse(!is.null(x), x, NA))
  })
  
  new_items<- data.frame(itemType = "journalArticle",
                         title = core_fields$title,
                         author = core_fields$author,
                         journal = core_fields$journal,
                         volume = non_core_fields$volume,
                         issue = non_core_fields$issue,
                         pages = non_core_fields$pages,
                         year = core_fields$year,
                         doi = non_core_fields$doi,
                         ISSN = non_core_fields$issn,
                         url =  non_core_fields$url,
                         tags = "",
                         read_status = "Not read",
                         pdf_path = NA)%>%
    mutate(across(everything(), ~as.character(.x)))
  
  return(list(new_items = new_items, status = status))
  
}


dois_from_pdf<- reactive({
  
  pdf_file<- input$item_pdf_upload
  
  if (is.null(pdf_file)){
    return(NULL)
  }
  
  pdf_text<- pdftools::pdf_text(pdf_file$datapath)
  
  doi_pattern<- "10.\\d{4,9}/[-._;()/:a-z0-9A-Z]+"
  
  extracted_dois<- str_extract_all(pdf_text, doi_pattern)%>%
    unlist()
  
  if(length(extracted_dois)==0){
    showModal(modalDialog(title = "No DOI found in PDF", "No DOI was found in the PDF file. You can add the DOI manually by entering into the 'DOIs from PDF' box."))
  }
  
  updateSelectizeInput(session = session, inputId = "pdf_dois_add", choices = extracted_dois, options = list(create = TRUE))
  
})

item_from_pdf<- reactive({
  
  doi<- input$pdf_dois_add
  
  response<- item_from_doi(doi)
  
  return(response)
  
})

add_item_to_library<- function(item, with_pdf = FALSE, zotero){
  
  item$zotero<- ifelse(zotero == 1 | zotero == 0, "True", "False")
  
  current_items<- readxl::read_excel("Data/Library/library.xlsx")
  
  duplicated_item_dois<- item$doi[item$doi %in% current_items$doi]
  
  if (item$doi %in% current_items$doi){
    return(0)
  }
  
  current_items<- rbind(current_items, select(item, all_of(colnames(current_items))))
  
  if (with_pdf){
    
    first_author<- str_extract(item$author[1], "[^,]*(?=,)")
    
    if (!dir.exists(paste0("PDFs/", item$year[1]))){
      
      dir.create(paste0("PDFs/", item$year[1]))
      
      next_letter<- ""
      
    }
    
    if (!dir.exists(paste0("PDFs/", item$year[1], "/", first_author))){
      
      dir.create(paste0("PDFs/", item$year[1], "/", first_author))
      
      next_letter<- ""
      
    } else {
      
      current_pdfs<- list.files(paste0("PDFs/", item$year[1], "/", first_author))
      
      if (any(str_detect(current_pdfs, paste0(item$year[1], "[a-z]")))) {
        used_letters<- str_extract(current_pdfs, paste0("(?<=", item$year[1], ")[a-z]"))
        used_letters<- used_letters[!is.na(used_letters)]
        next_letter<- letters[which(used_letters == letters)+1]
        
      } else {
        next_letter<- ""
      }
      
    }
    
    
    
    pdf_file<- input$item_pdf_upload
    
    file.rename(from = pdf_file$datapath, to = paste0("PDFs/", item$year[1], "/", first_author, "/", paste0(first_author, " ", item$year[1], next_letter, ".pdf")))
    
    file.remove(pdf_file$datapath)
    
    current_items$pdf_path[current_items$doi == item$doi]<- paste0("PDFs/", item$year[1], "/", first_author, "/", paste0(first_author, " ", item$year[1], next_letter, ".pdf"))
    
  }
  
  writexl::write_xlsx(current_items, path = "Data/Library/library.xlsx")
  
  get_df(current_items)
  
  return(1)
  
}
add_item_to_zotero<- function(item){
  
  zotero_data<- read.csv("Data/Zotero Data.csv")
  
  # x<- tryCatch({RefManageR::ReadZotero(user = user_options$zotero_library_id, .params = list(key = user_options$zotero_api_key, qmode = "everything", q = item$title))},
  #              error = function(e){
  #                showModal(modalDialog(title = "Error", paste("Error calling Zotero API:", e)))
  #                req(1 == 0)
  #              })
  # 
  
  if (item$doi %in% zotero_data$DOI){
    
    print("Item in Zotero already")
    
    # Find existing zotero key and version for the item
    existing_key<- zotero_data$key[zotero_data$DOI == item$doi & !is.na(zotero_data$DOI)]
    existing_version<- zotero_data$version[zotero_data$DOI == item$doi & !is.na(zotero_data$DOI)]
    
    # Delete the existing item
    
    print("Deleting existing item in Zotero")
    url <- paste0("https://api.zotero.org/users/", user_options$zoter_library_id, "/items/", existing_key)
    
    response <- DELETE(
      url,
      add_headers(Authorization = paste("Bearer", user_options$zotero_api_key),
                  `If-Unmodified-Since-Version` = existing_version)
    )
    
    # Create a new item
    print("Adding new item to Zotero")
    
    zot_item<- item%>%
      mutate(creators = zot_convert_creators_to_df_list(author, separator_multiple_authors = " and "),
             date = year,
             DOI = doi,
             publicationTitle = journal)%>%
      select(itemType, title, creators, publicationTitle, volume, issue, pages, date, DOI, ISSN, url)
    
    # Send new item to Zotero
    url<- paste0("https://api.zotero.org/users/",user_options$zotero_library_id, "/items?key=", user_options$zotero_api_key)
    #url<- paste0("https://api.zotero.org/users/",zotero_user_id, "/items?key=", zotero_api_key)
    
    response <- httr::POST(url = url,
                           config = httr::add_headers("Content-Type : application/json",
                                                      paste0("Zotero-Write-Token: ", paste(sample(c(0:9, letters, LETTERS), 32, replace = TRUE), collapse = ""))), 
                           body = jsonlite::toJSON(x = zot_item, auto_unbox = TRUE))
    
    response_data<- fromJSON(content(response, "text", encoding = "UTF-8"))
    
    # Add new item key and DOI to the locally stored Zotero data
    new_item_key<- response_data$success$`0`
    new_item_version<- response_data$successful$`0`$data$version
    
    zotero_data<- rbind(zotero_data, data.frame(key = new_item_key, version = new_item_version, DOI = item$doi))
    
    write.csv(zotero_data, file = "Data/Zotero Data.csv", row.names = F)
    
    code<- 0
    
  } else {
    
    # Create a new item
    zot_item<- item%>%
      mutate(creators = zot_convert_creators_to_df_list(author, separator_multiple_authors = " and "),
             date = year,
             DOI = doi,
             publicationTitle = journal)%>%
      select(itemType, title, creators, publicationTitle, volume, issue, pages, date, DOI, ISSN, url)
    
    # Send new item to Zotero
    url<- paste0("https://api.zotero.org/users/",user_options$zotero_library_id, "/items?key=", user_options$zotero_api_key)
    #url<- paste0("https://api.zotero.org/users/",zotero_user_id, "/items?key=", zotero_api_key)
    
    response <- httr::POST(url = url,
                           config = httr::add_headers("Content-Type : application/json",
                                                      paste0("Zotero-Write-Token: ", paste(sample(c(0:9, letters, LETTERS), 32, replace = TRUE), collapse = ""))), 
                           body = jsonlite::toJSON(x = zot_item, auto_unbox = TRUE))
    
    response_data<- fromJSON(content(response, "text", encoding = "UTF-8"))
    
    # Add new item key and DOI to the locally stored Zotero data
    new_item_key<- response_data$success$`0`
    
    new_item_version<- response_data$successful$`0`$data$version
    
    zotero_data<- rbind(zotero_data, data.frame(key = new_item_key, version = new_item_version, DOI = item$doi))
    
    write.csv(zotero_data, file = "Data/Zotero Data.csv", row.names = F)
    
    code<- 1
    
  }

  return(code)
  
  
}
