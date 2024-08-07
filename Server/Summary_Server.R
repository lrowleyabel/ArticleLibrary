output$most_common_tags_plot<- renderD3({
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }
  
  existing_tags<- paste(df$tags, collapse = "; ")%>%
    str_split("; ")%>%
    unlist()
  

  
  x<- data.frame(tags = existing_tags)%>%
    group_by(tags)%>%
    summarise(n = n())%>%
    arrange(desc(n))%>%
    head(10)
  
  return(r2d3(data = x, script = "www/js/summary_plot.js", d3_version = "3"))
  
})

output$overall_summary_text<- renderUI({
  
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }
  
  existing_tags<- paste(df$tags, collapse = "; ")%>%
    str_split("; ")%>%
    unlist()%>%
    unique()
  
  return(HTML(paste("<p style = 'font-size: 16px;'>There are <strong>", nrow(df), "</strong> items in your library, belonging to <strong>", length(existing_tags), "</strong> tags.</p>")))
  
  
})

output$overall_read_plot<- renderD3({
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }
  
  x<- df%>%
    group_by(read_status)%>%
    summarise(n = n())%>%
    ungroup()%>%
    mutate(n = 100*n/sum(n))%>%
    arrange(desc(read_status))%>%
    rename(category = read_status)%>%
    mutate(category = ifelse(category == "Read", "A", "B"))
  
  
  
  r2d3(data = x, script = "www/js/overall_read_plot.js",  d3_version = "3", options = list(read_proportion = round(x$n[x$category=="A"])))
  
  
})

output$overall_zotero_plot<- renderD3({

  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }

  x<- df%>%
    group_by(zotero)%>%
    summarise(n = n())%>%
    ungroup()%>%
    mutate(n = 100*n/sum(n))%>%
    arrange(desc(zotero))%>%
    rename(category = zotero)%>%
    mutate(category = ifelse(category == "True", "A", "B"))

  r2d3(data = x, script = "www/js/overall_read_plot.js", d3_version = "3", options = list(read_proportion = round(x$n[x$category == "A"])))


})

existing_tags<- paste(df$tags, collapse = "; ")%>%
  str_split("; ")%>%
  unlist()%>%
  unique()

update_autocomplete_input(session = session, id = "summary_tag_search", placeholder = "Search for a tag...", options = existing_tags, create = TRUE)



output$tag_summary_plot<- renderD3({
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }
  
  existing_tags<- paste(df$tags, collapse = "; ")%>%
    str_split("; ")%>%
    unlist()
  
  
  
  x<- data.frame(tags = existing_tags)%>%
    group_by(tags)%>%
    summarise(n = n())%>%
    arrange(desc(n))%>%
    head(10)
  
  return(r2d3(data = x, script = "www/js/summary_plot.js", d3_version = "3"))
  
})

output$individual_tag_read_plot<- renderD3({
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }
  
  x<- df%>%
    filter(str_detect(tags, "frailty"))%>%
    group_by(read_status, .drop = F)%>%
    summarise(n = n())%>%
    ungroup()%>%
    mutate(n = 100*n/sum(n))%>%
    arrange(desc(read_status))%>%
    rename(category = read_status)%>%
    mutate(category = ifelse(category == "Read", "A", "B"))%>%
    mutate(n = round(n))
  
  
  r2d3(data = x, script = "www/js/individual_tag_read_plot.js",  d3_version = "3", options = list(read_proportion = round(x$n[x$category=="A"])))
  
  
})

observeEvent(input$summary_tag_search_submit, {
  
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }
  
  x<- df%>%
    filter(str_detect(tags, input$summary_tag_search))%>%
    group_by(read_status)%>%
    summarise(n = n())%>%
    ungroup()%>%
    mutate(n = 100*n/sum(n))%>%
    arrange(desc(read_status))%>%
    rename(category = read_status)%>%
    mutate(category = ifelse(category == "Read", "A", "B"))%>%
    mutate(n = round(n))
  
  if (nrow(x)==1){
    if(x$category[1] == "A"){
      x<- rbind(x, data.frame(category = "B", n = 0))
    } else {
      x<- rbind(data.frame(category = "A", n = 0), x)
    }
  }
  
  session$sendCustomMessage(type = "update_individual_tag_plot", x)  
  
})


observeEvent(input$summary_tag_search_submit, {
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }
  
  x<- df%>%
    filter(str_detect(tags, input$summary_tag_search))
  
  
  net_df<- readxl::read_excel("Data/Library/library.xlsx")
  
  net_df<- net_df%>%
    filter(!duplicated(doi))%>%
    filter(tags != "" & !is.na(tags))
  
  net<- data.frame(source = c(), target = c())
  
  lapply(net_df$title, FUN = function(title){
    
    tags<- net_df$tags[net_df$title==title]
    
    lapply(str_split(tags,pattern = "; "), FUN = function(tag){
      
      new_net_item<- data.frame(source = title, target = tag)
      net<<- rbind(net, new_net_item)
      return(NULL)
    })
    return(NULL)
  })
  
  tag_items<- net%>%
    filter(target == input$summary_tag_search)
  
  linked_tags<- net%>%
    filter(source %in% tag_items$source)%>%
    filter(target != input$summary_tag_search)%>%
    group_by(target)%>%
    summarise(n = n())%>%
    rename(tag = target)%>%
    arrange(desc(n))%>%
    head(3)
  
  tag<- input$summary_tag_search
  
  output$individual_tag_text<- renderUI(
    if (nrow(x)>1){
      return(HTML(paste0("<p style = 'font-size: 16px;'>There are <strong>", nrow(x), " items</strong> with the tag <strong>", tag, "</strong>. It overlaps most with <strong>", paste(linked_tags$tag, collapse = ", "), "</stong>.</p>")))
    } else {
      return(HTML(paste0("<p style = 'font-size: 16px;'>There is <strong>", nrow(x), " item</strong> with the tag <strong>", tag, "</strong>. It overlaps most with <strong>", paste(linked_tags$tag, collapse = ", "), "</stong>.</p>")))
    }  
  )
  
  
})

output$individual_tag_text<- renderUI({
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  if(nrow(df)==0){
    return(NULL)
  }
  
  x<- df%>%
    filter(str_detect(tags, "frailty"))
  
  
  net_df<- readxl::read_excel("Data/Library/library.xlsx")
  
  net_df<- net_df%>%
    filter(!duplicated(doi))%>%
    filter(tags != "" & !is.na(tags))
  
  net<- data.frame(source = c(), target = c())
  
  lapply(net_df$title, FUN = function(title){
    
    tags<- net_df$tags[net_df$title==title]
    
    lapply(str_split(tags,pattern = "; "), FUN = function(tag){
      
      new_net_item<- data.frame(source = title, target = tag)
      net<<- rbind(net, new_net_item)
      return(NULL)
    })
    return(NULL)
  })
  
  tag_items<- net%>%
    filter(target == "frailty")
  
  linked_tags<- net%>%
    filter(source %in% tag_items$source)%>%
    filter(target != "frailty")%>%
    group_by(target)%>%
    summarise(n = n())%>%
    rename(tag = target)%>%
    arrange(desc(n))%>%
    head(3)
  
  tag<- "frailty"
  
  output$individual_tag_text<- renderUI(
    if (nrow(x)>1){
      return(HTML(paste0("<p style = 'font-size: 16px;'>There are <strong>", nrow(x), " items</strong> with the tag <strong>", tag, "</strong>. It overlaps most with <strong>", paste(linked_tags$tag, collapse = ", "), "</stong>.</p>")))
    } else {
      return(HTML(paste0("<p style = 'font-size: 16px;'>There is <strong>", nrow(x), " item</strong> with the tag <strong>", tag, "</strong>. It overlaps most with <strong>", paste(linked_tags$tag, collapse = ", "), "</stong>.</p>")))
    }  
  )
})
