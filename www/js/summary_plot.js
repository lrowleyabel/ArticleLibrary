var barHeight = Math.ceil((height*0.95) / data.length) - 3;

var maxn = d3.max(data, function(d) { return +d.n;} );

function xscale(n){
  
  return width * (n/maxn)
  
} 

var bars = svg.selectAll('.bar')  
  .data(data)
  
bars.enter().append('rect')
  .attr('class', 'bar')
  .merge(bars)
  .attr('width', 0)
  .attr('height', barHeight)
  .attr('y', function(d, i) { return (i * barHeight)+(i*3); })
  .attr('fill', '#18bc9c')
  .attr('stroke', '#2c3e50')
  .attr('tag', function(d){ return d.tags; })
  .transition().duration(1000)
  .attr('width', function(d) { return xscale(d.n); });
    
bars.exit().remove();

function labelx(n){
  
  if (xscale(n) < 150) {
    return xscale(n) + 10;
  } else {
    return 10;
  }
  
}

var labels = svg.selectAll('text')  
  .data(data)
  
labels.enter().append('text')
  .merge(labels)
  .attr('x', function(d) { return (labelx(d.n)); })
  .attr('y', function(d, i) { return (i * barHeight)+(i*3)+(barHeight/2); })
  .attr('alignment-baseline', 'central')
  .attr('fill', 'black')
  .style('font-size', '12px')
  .text(function(d){ return d.tags + " (n = " + d.n + ")"; })
    
labels.exit().remove();