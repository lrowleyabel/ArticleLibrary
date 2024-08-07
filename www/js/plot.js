// !preview r2d3 data=x
//
// r2d3: https://rstudio.github.io/r2d3
//



var width = 100;
var height = 100;

var radius = Math.min(width, height) / 2;

var donutWidth = 20; //This is the size of the hole in the middle

var color = d3.scaleOrdinal()
.range(["#5A39AC", "#DD98D6", "#E7C820", "#08B2B2"]);

svg.attr('width', width)
   .attr('height', height)
   .attr('transform', 'translate(0,0)')
   
var arc = d3.arc()
     .innerRadius(radius - donutWidth)
     .outerRadius(radius);
     
var pie = d3.pie()
     .value(function (d) {
          return d.n;
     })
     .sort(null);


var null_data = [{'read_status' : 'Not read', 'n' : 90}, {'read_status' : 'Read','n':10},]
     
var path = svg.selectAll('path')
     .data(pie(null_data))
     .enter()
     .append('path')
     .attr('d', arc)
     .attr('fill', function (d, i) {
          return color(d.data.read_status);
     })
     .attr('transform', 'translate(50,50)')
     .on('mouseover', function(){
       change()
     })

function change(data) {
    console.log("Changing")
     var pie = d3.pie()
     .value(function (d) {
          return d.n;
     }).sort(null)(data);
     var width = 100;
     var height = 100;
     var radius = Math.min(width, height) / 2;
     var donutWidth = 75;
     path = svg.selectAll("path")
          .data(pie); // Compute the new angles
     var arc = d3.arc()
          .innerRadius(radius - donutWidth)
          .outerRadius(radius);
     path.transition().duration(500).attr("d", arc); // redrawing the path with a smooth transition
}