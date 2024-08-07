
net_df<- readxl::read_excel("Data/Library/library.xlsx")

if (nrow(net_df)!=0){

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
  
  
  nodes<- data.frame(name = c(unique(net$source), unique(net$target)),
                     group = c(rep("Paper", length(unique(net$source))), rep("Tag", length(unique(net$target)))),
                     size = c(rep(0.1, length(unique(net$source))), rep(100, length(unique(net$target)))),
                     author = c(net_df$author[net_df$title == unique(net$source)], rep(NA, length(unique(net$target)))))
  
  
  
  force_net<- data.frame(source = lapply(net$source, function(s){which(nodes$name == s)})%>%
                           unlist()-1,
                         target = lapply(net$target, function(s){which(nodes$name == s)})%>%
                           unlist()-1)

}

output$force_network<- renderForceNetwork({
  
  if (!exists("force_net")){
    return(NULL)
  }
    
  x<- forceNetwork(Links = force_net,
               Nodes = nodes,
               Source = "source",
               Target = "target",
               NodeID = "name",
               Nodesize = "size",
               opacity = 1,
               Group = "group",
               colourScale = JS(" d3.scaleOrdinal(['#2c3e50', '#18bc9c']);"),
               zoom = TRUE,
               fontSize = 30,
               fontFamily = "Sans-Serif",
               opacityNoHover = 0,
               bounded = TRUE)
  
  x<- x%>%
    onRender(x = ., jsCode = "
                            function(el, x, data) {
                            
                              var links = HTMLWidgets.dataframeToD3(x.links);
                              var nodes = HTMLWidgets.dataframeToD3(x.nodes);
                              var urldata = HTMLWidgets.dataframeToD3(x.urldata);

                              
                              var linkedByIndex = {};
                                links.forEach(function(d) {
                                  linkedByIndex[d.source + ',' + d.target] = 1;
                                  linkedByIndex[d.target + ',' + d.source] = 1;
                                });
                                function neighboring(a, b) {
                                  return linkedByIndex[a.index + ',' + b.index];
                              }

                              d3.selectAll('circle')
                                .on('mouseover', function(d){
                                  
                                  if (d.group == 'Tag'){
                                    Shiny.setInputValue('hovered_tag', d.name);
                                    Shiny.setInputValue('hovered_tag_2', d.name);
                                    d3.select('#linked_tag_plot_title')
                                      .style('opacity', 1)
                                  }
                                  
                                  //var associatednodes = d3.selectAll('.node').filter(function(myd){
                                  //  return neighboring(d, myd);
                                  //})
                                  //
                                  //d3.select(this).raise()
                                  //
                                  //d3.select('.my_svg_text')
                                  //  .text(d.group + ': ' + d.name);
                                  //  
                                  //associatednodes.select('text')
                                  //  .style('stroke-width', '.5px')
                                  //  .style('font-size', '10px')
                                  //  .style('opacity', 1);
                                  //  
                                  //associatednodes.each(function(d,i){
                                  //
                                  //d3.select('.my_info_svg').append('text')
                                  //  .attr('class', 'my_svg_text')
                                  //  .attr('x', 20)
                                  //  .attr('y', i*20)
                                  //  .text(d.name)
                                  //  .style('fill', 'black')
                                  //  .style('stroke-width', '.5px')
                                  //  .style('font-size', '16px')
                                  //  .style('opacity', 1)
                                  //  .raise();
                                  //
                                  //})
                                })
                                .on('mouseout', function(d){
                                
                                  var associatednodes = d3.selectAll('.node').filter(function(myd){
                                    return neighboring(d, myd);
                                  })
                                  
                              
                                  associatednodes.select('text')
                                    .style('stroke-width', '.5px')
                                    .style('font-size', '30px')
                                    .style('opacity', 0);
                                
                                });
                                
                                Shiny.addCustomMessageHandler('highlight_item', function(message) {
                                  d3.selectAll('circle')
                                    .style('stroke', 'white')
                                    .style('stroke-width', '1.5px')
                                    
                                  d3.selectAll('circle')
                                    .filter(function(d){
                                      var f = d.name === message;
                                      console.log(f);
                                      return f;
                                    })
                                    .raise()
                                    .transition().duration(100)
                                    .style('stroke', '#f39c12')
                                    .style('stroke-width', '6px')
                                    
                                  
                                });
                                
                                Shiny.addCustomMessageHandler('highlight_tag', function(message){
                                  
                                  d3.selectAll('circle')
                                    .style('stroke', 'white')
                                    .style('stroke-width', '1.5px');
                                    
                                  var highlighted_tag = d3.selectAll('circle')
                                    .filter(function(myd){
                                      return myd.name == message;
                                    })
                                  
                                  highlighted_tag.style('stroke', '#f39c12')
                                    .style('stroke-width', '6px')
                                    .raise();
                                })
                            }
                           ", data = force_net)
  
  return(x)
      
  
})

output$hovered_tag_display<- renderUI({
  
  if(is.null(input$hovered_tag)){
    return(tags$h5("Hover over tags (green circles) to see linked items..."))
  }
  
  return(tags$h3(input$hovered_tag, class = "bs-primary"))
  
})

output$hovered_tag_items_display<- renderDataTable({
  
  if(is.null(input$hovered_tag)){
    return(NULL)
  }
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  df<- df%>%
    filter(str_detect(tags, input$hovered_tag))%>%
    select(author, title)
  
  x<- datatable(data = df,
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


output$hovered_tag_links_plot<- renderD3({
  
  tag<- input$hovered_tag_2
  
  if (is.null(tag)){
    return(NULL)
  }
  
  tag_items<- net%>%
    filter(target == tag)
  
  linked_tags<- net%>%
    filter(source %in% tag_items$source)%>%
    filter(target != tag)%>%
    group_by(target)%>%
    summarise(n = n())%>%
    rename(tag = target)%>%
    arrange(desc(n))%>%
    head(10)
  
  r2d3(data = linked_tags, script = "www/js/hovered_tag_links_plot.js", height = 900, d3_version = "3")
  
})


observeEvent(input$hovered_tag_items_display_rows_selected, {
  
  if(is.null(input$hovered_tag)){
    return(NULL)
  }
  
  df<- readxl::read_excel("Data/Library/library.xlsx")
  
  df<- df%>%
    filter(str_detect(tags, input$hovered_tag))%>%
    select(author, title)
  
  highlighted_title<- df$title[input$hovered_tag_items_display_rows_selected]
  
  session$sendCustomMessage(type = "highlight_item", highlighted_title)
  
})

observeEvent(input$visual_tag_search, {
  
  session$sendCustomMessage(type = "highlight_tag", message = input$visual_tag_search)
  
  
})

existing_tags<- paste(df$tags, collapse = "; ")%>%
  str_split("; ")%>%
  unlist()%>%
  unique()


update_autocomplete_input(session = session, id = "visual_tag_search", placeholder = "Search for a tag...", options = existing_tags, create = TRUE)
