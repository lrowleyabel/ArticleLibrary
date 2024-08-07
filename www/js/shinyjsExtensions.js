// SET UP WINDOW //

shinyjs.first_setup_button = function(){
  document.getElementById("setup_card_1").style.opacity = 0;
  document.getElementById("setup_card_1").style.display = "none";
  document.getElementById("setup_card_2").style.opacity = 1;
};

shinyjs.second_setup_button_yes = function(){
  document.getElementById("setup_card_2").style.opacity = 0;
  document.getElementById("setup_card_2").style.display = "none";
  document.getElementById("setup_card_3").style.opacity = 1;
  
}

shinyjs.second_setup_button_no = function(){
  document.getElementById("setup_card_2").style.opacity = 0;
  document.getElementById("setup_card_2").style.display = "none";
  document.getElementById("setup_card_3").style.opacity = 0;
  document.getElementById("setup_card_3").style.display = "none";
  document.getElementById("setup_card_4").style.opacity = 1;
  
}


shinyjs.zotero_credential_help = function(){
  document.getElementById("zotero_credentials_help_text").textContent = "If you do not have these, go to zotero.org and login. Under Settings > Feeds/API you can see your library ID. You can also create an API key here by clicking Create new private key. Make sure to give the API key read and write permissions (ie: under Personal Library check Allow write access and Allow notes access, then under Default Group Permissions select Read/Write).";
  
}

shinyjs.setup_save_zotero_settings = function(){
  document.getElementById("setup_card_2").style.opacity = 0;
  document.getElementById("setup_card_2").style.display = "none";
  document.getElementById("setup_card_3").style.opacity = 0;
  document.getElementById("setup_card_3").style.display = "none";
  document.getElementById("setup_card_4").style.opacity = 1;
  
}

shinyjs.save_downloads_path = function(){
  document.getElementById("setup_card_4").style.opacity = 0;
  document.getElementById("setup_card_4").style.display = "none";
  document.getElementById("setup_card_5").style.opacity = 1;
  
}


// COLLAPSABLE CARDS //


document.addEventListener("DOMContentLoaded", function(){
  console.log("Content loaded")
  
  var collapsable_card_headers = document.getElementsByClassName("collapsable_header")
  
  Array.from(collapsable_card_headers).forEach(function (element) {
    element.addEventListener("click", collapse)            
  })
  
  
  var collapsable_cards = document.getElementsByClassName("collapsable")
  
  Array.from(collapsable_cards).forEach(function (element) {
    element.setAttribute("collapsable_state", "closed")
    element.style.overflow = "hidden"
  });
  
});

function collapse(){
  
  var card = this.parentElement
  
  var state = card.getAttribute("collapsable_state")
  
  if (state === "closed"){
    
    card.style.minHeight = "350px"
    card.style.maxHeight = "350px"
    
    card.setAttribute("collapsable_state", "open")
    
    var this_content = Array.from(card.getElementsByClassName("collapsable_content")).forEach(function(element){
      element.style.opacity = 1
    })
    
    this.querySelector("img").style.transform = "rotate(180deg)";
    
    
  }
  
  if (state === "open"){
    
    card.style.minHeight = "40px"
    card.style.maxHeight = "40px"
    
    var this_content = Array.from(card.getElementsByClassName("collapsable_content")).forEach(function(element){
      element.style.opacity = 0
    })
    
    this.querySelector("img").style.transform = "rotate(0deg)";
    
    card.setAttribute("collapsable_state", "closed")
    
    
  }
  
  
}
