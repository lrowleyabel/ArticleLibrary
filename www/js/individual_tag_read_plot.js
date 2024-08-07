r2d3.onResize(function (width, height) {

});

var radius = (Math.min(width, height) / 2)-1;

var donutWidth = 30; //This is the size of the hole in the middle

var color = d3.scaleOrdinal()
.range(["#18bc9c", "#ecf0f1"]);

svg.attr('width', width)
.attr('height', height)
//.attr('transform', 'translate('+ width/2 +','+ height/2 + ')')

var arc = d3.arc()
.innerRadius(radius - donutWidth)
.outerRadius(radius);

var pie = d3.pie()
.value(function (d) {
  return d.n;
})
.sort(null);

var null_data = [{'category' : 'A','n':0.1}, {'category' : 'B', 'n' : 99.9}]

var path = svg.selectAll('path')
.data(pie(null_data))
.enter()
.append('path')
.attr('d', arc)
.attr('fill', function (d, i) {
  return color(d.data.category);
})
.attr('stroke', '#2c3e50')
.attr('transform', 'translate('+ width/2 +','+ height/2 +')')
.each(function(d) { this._current = d; });

path.exit().remove();     

var label = svg.append('text')
.text(options.read_proportion + '%')
.attr('transform', 'translate('+ width/2 +','+ (height/2) +')')
.style('text-anchor', 'middle')
.style('font-size', '20px')
.style('dominant-baseline', 'middle')

function change(newdata){
  path.data(pie(newdata));
  path.transition().duration(750).attrTween("d", arcTween);
    
  label.text(JSON.stringify(newdata[0].n)+"%");
  
}

function arcTween(a) {
  var i = d3.interpolate(this._current, a);
  this._current = i(0);
  return function(t) {
    return arc(i(t));
  };
}

const myTimeout = setTimeout(change(data), 100);

Shiny.addCustomMessageHandler('update_individual_tag_plot', function(message) {
  //console.log(JSON.stringify(message));

  
  const transformedJson = message.category.map((category, index) => {
      return { category: category, n: message.n[index] };
  });
  
  //console.log(JSON.stringify(transformedJson));
  
  change(transformedJson)
  

  
})