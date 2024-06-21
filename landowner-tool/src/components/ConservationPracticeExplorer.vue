<template>
  <div class="container">
    <h3 class="text-center">Which conservation practices help resource concerns that you are interested in?</h3>
    <p><b>How to Interpret This Graph:</b> This graph visualizes overlap and patterns in the effectiveness of certain conservation practices.  The vertical left-hand column lists out conservation practices used by NRCS and the top horizontal row lists resource concerns you selected on the previous page. The numbers in the graph indicate the severity of the impact as shown in the effect score key above the graph. This data comes from USDA’s Conservation Practice Physical Effects (CPPE) scores.</p>
  </div>
  <div id="heatmap"></div>
</template>

<script>
import * as d3 from 'd3';
import Papa from 'papaparse';

function lineHasValueForChosenBenefit(line, chosenBenefit) {
  for (const key of Object.keys(line)) {
    for (const benefit of chosenBenefit) {
      if (benefit == key && line[key] && line[key] > 0) {
        return true;
      }
    }
  }
  return false;
}

function wrap(text, width) {
  text.each(function() {
    var text = d3.select(this),
        words = text.text().split(/\s+/).reverse(),
        word,
        line = [],
        lineNumber = 0,
        lineHeight = 1.1, // ems
        y = text.attr("y"),
        dy = parseFloat(text.attr("dy")),
        tspan = text.text(null).append("tspan").attr("x", 0).attr("y", y).attr("dy", dy + "em");
    word = words.pop();
    while (word) {
      line.push(word);
      tspan.text(line.join(" "));
      if (tspan.node().getComputedTextLength() > width) {
        line.pop();
        tspan.text(line.join(" "));
        line = [word];
        tspan = text.append("tspan").attr("x", 0).attr("y", y).attr("dy", ++lineNumber * lineHeight + dy + "em").text(word);
      }
      word = words.pop();
    }
    var tspans = text.selectAll("tspan");
    // lineHeightEms
    var h = 1.05;
    tspans.each(function (d, i) {
      // Calculate the y offset (dy) for each tspan so that the vertical centre
      // of the tspans roughly aligns with the text element's y position.
      var dy = i * h;
      dy -= ((tspans.size() - 1) * h);
      d3.select(this)
        .attr("y", y)
        .attr("dy", dy + "em");
    });
  });
}

function parseConservationPracticeName(line) {
  return line.split(' | ')[1];
}

export default {
  data() {
    return {
      practices: [],
      err: undefined,
    }
  },
  created() {
    let practices;
      fetch('conservation_practice_data.csv')
        .then( res => res.text() )
        .then( csv => {
            Papa.parse( csv, {
                header: true,
                complete: function(results) {
                     practices = results.data;
                }
            });
          const concerns = this.$route.query.concerns.split(',');
          // await??
          this.setPractices(practices, concerns);
          this.createHeatmap();

        });
 
      // `setPost` is a method defined below
  },
  // when route changes and this component is already rendered,
  // the logic will be slightly different.
  //beforeRouteUpdate(to, from) {
  //  this.post = null
  //  getPost(to.params.id).then(this.setPost).catch(this.setError)
  //},

  methods: {
    setPractices(practices, chosenConcerns) {
      const longForm = []
      for (const line of practices) {
        if(lineHasValueForChosenBenefit(line, chosenConcerns)) {
          for (const key of Object.keys(line)) {
            if (key == "Conservation Practice" || !chosenConcerns.includes(key)) {
              continue;
            }
            longForm.push({conservation_practice: parseConservationPracticeName(line['Conservation Practice']), concern: key, value: line[key]})
          }
        } 
     }
      this.practices = longForm;
    },
    setError(err) {
      this.error = err.toString()
    },
    createHeatmap() {

      // set the dimensions and margins of the graph
      var margin = {top: 80, right: 25, bottom: 30, left: 330},
        width = 1100 - margin.left - margin.right,
        height = 850 - margin.top - margin.bottom;
      
      // append the svg object to the body of the page
      var svg = d3.select("#heatmap")
      .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
      .append("g")
        .attr("transform",
              "translate(" + margin.left + "," + margin.top + ")");
      var data = this.practices;
      
      //Read the data
      //d3.csv("./heat_map_for_demo.csv", function(data) {
      
        // Labels of row and columns -> unique identifier of the column called 'group' and 'variable'
        var conservationPractices = d3.map(data, function(d){return d.conservation_practice;})
        var concerns = d3.map(data, function(d){return d.concern;})
      
        // Build X scales and axis:
        var x = d3.scaleBand()
          .range([ 0, width ])
          .domain(concerns)
          .padding(0.05);
      
        var xAxis = d3.axisTop(x).tickSize(0).scale(x);
        var axisObj = svg.append("g")
          .attr("class", "x axis")
          .style("font-size", 15)
          .call(xAxis);
        axisObj.select(".domain").remove();
        axisObj.selectAll(".tick text")
          .call(wrap, x.bandwidth());
      
        // Build Y scales and axis:
        var y = d3.scaleBand()
          .range([ height, 0 ])
          .domain(conservationPractices)
          .padding(0.05);
        svg.append("g")
          .style("font-size", 15)
          .call(d3.axisLeft(y).tickSize(0))
          .select(".domain").remove()
      
        // Build color scale
        var colorScale = d3.scaleLinear()
          .domain([-2, 1, 0, 1, 2, 3, 4, 5])
          .range(["#ad1313", "#d65151", "#f2efee", "#cde3ee", "#8fc2dc", "#4b94c4", "#2265a3", "#053061"])
      
        // create a tooltip
       // var Tooltip = d3.select("#heatmap")
       //   .append("div")
       //   .style("opacity", 0)
       //   .attr("class", "tooltip")
       //   .style("background-color", "white")
       //   .style("border", "solid")
       //   .style("border-width", "1px")
       //   .style("border-radius", "5px")
       //   .style("padding", "5px")
      
       //    // Three function that change the tooltip when user hover / move / leave a cell
       //  var mouseover = function() {
       //     Tooltip
       //       .style("opacity", 1)
       //  }
       // var mousemove = function(d) {
       //   Tooltip
       //     .html(getTooltipText(d))
       //     // getBoundingClientRect solves inconsistent mouse problem w/ scrolling
       //     .style('left', (d3.mouse(this)[0] + d3.select('svg').node().getBoundingClientRect().x + 350) + 'px')
       //     .style('top', (d3.mouse(this)[1] + d3.select('svg').node().getBoundingClientRect().y + 80) + 'px')
       //   }
       // var mouseleave = function() {
       //   Tooltip
       //     .style("opacity", 0)
       // }
      
       // function getTooltipText(d) {
       //   var text = d.conservation_practice + " has ";
       //   switch (d.value) {
       //     case "-2":
       //     case "-1":
       //       text += "a detrimental";
       //       break;  
       //     case "0":
       //       text += "no";
       //       break;
       //     case "1":
       //     case "2":
       //       text += "a slightly positive";  
       //       break;
       //     case "3":
       //       text += "a positive";  
       //       break;
       //     case "4":
       //     case "5":
       //       text += "a strongly positive";  
       //       break;
       //     default:
       //       text += "an unknown";  
       //   }
       //   text += " effect on ";
       //   text += d.concern;
       //   return text;
       // }
      
        // add the squares
        var squares = svg.selectAll()
          .data(data, function(d) {return d.concern+':'+d.conservation_practice;})
          .enter();
      
          squares.append("rect")
            .attr("x", function(d) { return x(d.concern) })
            .attr("y", function(d) { return y(d.conservation_practice) })
            .attr("rx", 4)
            .attr("ry", 4)
            .attr("width", x.bandwidth() )
            .attr("height", y.bandwidth() )
            .style("fill", function(d) { return colorScale(d.value)} )
            .style("stroke-width", 4)
            .style("stroke", "none")
            .style("opacity", 0.8)
          //.on("mouseover", mouseover)
          //.on("mousemove", mousemove)
          //.on("mouseleave", mouseleave)
      
          // TODO: https://jonathansoma.com/lede/storytelling/d3/text-elements/
          squares.insert("text")
          .attr("x", function (d) { return x(d.concern) + x.bandwidth() / 2 })
          .attr("y", function (d) { return y(d.conservation_practice) + y.bandwidth() / 2 })
          .attr("text-anchor", "middle")
          .attr("dy", "0.5em")
          .attr("fill", d => d.value > 1 ? "white" : "black")
          .attr("font-family", "sans-serif")
          .text((d) => d.value);

      
      // Add title to graph
      svg.append("text")
              .attr("x", 0)
              //TODO fix
              .attr("y", -150)
              .attr("text-anchor", "left")
              .style("font-size", "22px")
              .text("Conservation Practice Effectiveness");
      
      // Add subtitle to graph
      svg.append("text")
              .attr("x", 0)
              .attr("y", -20)
              .attr("text-anchor", "left")
              .style("font-size", "14px")
              .style("fill", "grey")
              .style("max-width", 400);


let keys = [-2, -1, 0, 1, 2, 3, 4, 5]
// Usually you have a color scale in your chart already

let legendBoxWidth = 40
let legendBoxHeight = 25
let legendVerticalOffset = 70 
// Add one dot in the legend for each name.
svg.selectAll("legend-boxes")
  .data(keys)
  .enter()
  .append("rect")
    .attr("x", function(d,i){ return  i*(legendBoxWidth+5)}) // 100 is where the first dot appears. 25 is the distance between dots
    .attr("y", -legendVerticalOffset)
    .attr("width", legendBoxWidth)
    .attr("height", legendBoxHeight)
    .style("fill", function(d){ return colorScale(d)})

// Add one dot in the legend for each name.
svg.selectAll("legend-numbers")
  .data(keys)
  .enter()
  .append("text")
    .attr("x", function(d,i){ return + i*(legendBoxWidth+5) + legendBoxWidth/2}) // 100 is where the first dot appears. 25 is the distance between dots
    .attr("y", -legendVerticalOffset + legendBoxHeight / 2)
    .attr("fill", d => d > 1 ? "white" : "black")
    // make into function
    .text(function(d){ return d})
    .attr("text-anchor", "middle")
    .style("alignment-baseline", "middle")

svg.append("text")
    .attr("x",  -8 ) // 100 is where the first dot appears. 25 is the distance between dots
    .attr("y", -legendVerticalOffset + legendBoxHeight / 2 - 10)
    .text("Conservation practice")
    .attr("text-anchor", "end")
    .style("alignment-baseline", "middle")

svg.append("text")
    .attr("x",  -8 ) // 100 is where the first dot appears. 25 is the distance between dots
    .attr("y", -legendVerticalOffset + legendBoxHeight / 2 + 10)
    .text("has detrimental effect")
    .attr("text-anchor", "end")
    .style("alignment-baseline", "middle")

svg.append("text")
    .attr("x",  8 * (legendBoxWidth + 5) ) // 100 is where the first dot appears. 25 is the distance between dots
    .attr("y", -legendVerticalOffset + legendBoxHeight / 2 - 10)
    .text("Conservation practice")
    .attr("text-anchor", "start")
    .style("alignment-baseline", "middle")

svg.append("text")
    .attr("x",  8 * (legendBoxWidth + 5) ) // 100 is where the first dot appears. 25 is the distance between dots
    .attr("y", -legendVerticalOffset + legendBoxHeight / 2 + 10)
    .text("has protective effect")
    .attr("text-anchor", "start")
    .style("alignment-baseline", "middle")
     }
   }
  }





</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
