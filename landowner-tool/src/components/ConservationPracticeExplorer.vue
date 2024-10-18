<template>
  <div class="container">
    <a href="/" class="btn btn-light"><i class="bi bi-arrow-left me-2"></i>Start Over</a>
  </div>
  <div class="container">
    <h2 class="text-center">NRCS Conservation Practices that Address Your Resource Concerns</h2>
    <p><b>How to Interpret This Graph:</b> This graph visualizes overlap and patterns in the effectiveness of certain
      conservation practices. The vertical left-hand column lists out conservation practices used by NRCS EQIP program and the top
      horizontal row lists resource concerns you selected on the previous page. The numbers in the graph indicate the
      severity of the impact as shown in the effect score key above the graph. This data comes from USDA’s Conservation
      Practice Physical Effects (CPPE) scores.</p>
  </div>
  <div class="container">
    <p><a href="https://www.landscapepartnership.org/networks/working-lands-for-wildlife/landscapes-wildlife/landscapes/aquatics/maps-and-data/aquatic-framework-products/aquacorridors-conservation-encyclopedia" class="btn btn-primary">Learn about these conservation practices and concerns in the AquaCorridors: Conservation Encyclopedia</a></p>
  </div>
  <div class="container">
    <div id="heatmap-legend"></div>
    <div id="heatmap-sidebar"></div>
    <div id="heatmap"></div>
    <!--<button @click="exportToPdf"></button>-->
  </div>
</template>

<script>
import * as d3 from 'd3';
import jsPDF from 'jspdf';
import { sanitizeUrl } from '@braintree/sanitize-url';

// Space for the top labels (concern names)
let TOP_LABEL_OFFSET = 110;
// Space for the side labels (conservation names)
let SIDE_LABEL_OFFSET = 330;
let HEATMAP_COLUMN_WIDTH = 110;
let HEATMAP_ROW_HEIGHT = 30;

function findRelevantConservationPractices(practiceConcernPairs, chosenConcerns) {
  const relevantConservationPractices = new Set();
  for (const pair of practiceConcernPairs) {
    if (chosenConcerns.includes(pair['concern']) && pair['value'] != 0) {
      relevantConservationPractices.add(pair['conservation_practice']);
    }
  }
  return relevantConservationPractices;
}

function filterPracticesByChosenConcerns(practiceConcernPairs, chosenConcerns, relevantConservationPractices) {
  return practiceConcernPairs.filter((pair) =>
  (chosenConcerns.includes(pair['concern']) &&
    relevantConservationPractices.has(pair['conservation_practice'])));
}



function sortByConservationPracticeEffectScores(practiceConcernPairs) {
  let conservationPracticeCumulativeEffectScores = {};
  for (const pair of practiceConcernPairs) {
    if (!(pair['conservation_practice'] in conservationPracticeCumulativeEffectScores)) {
      conservationPracticeCumulativeEffectScores[pair['conservation_practice']] = 0;
    }
    conservationPracticeCumulativeEffectScores[pair['conservation_practice']] += Number(pair['value']);
  }
  console.log(conservationPracticeCumulativeEffectScores);
  // Pairs with conservation practices with a higher cumulative value first
  practiceConcernPairs.sort(practiceConcernPairCompareFn);

  function practiceConcernPairCompareFn(a, b) {
    return conservationPracticeCumulativeEffectScores[b['conservation_practice']]
      - conservationPracticeCumulativeEffectScores[a['conservation_practice']]
  }
}

export default {
  Name: 'ConservationPracticeExplorer',
  props: ['practiceConcernPairs', 'practiceDescriptions'],
  // Prevents all properties from being passed through router-view, only those named above 
  inheritAttrs: false,
  data() {
    return {
      relevantPracticeConcernPairs: [],
    }
  },
  watch: {
    practiceConcernPairs: {
      handler(practiceConcernPairs) {
        // If the data is loaded
        // TODO: handle when no concerns are selected
        if (practiceConcernPairs.length > 0) {
          // Wait until concerns are available from the router
          this.$router.isReady().then(() => {
            const sanitizedQueryConcerns = sanitizeUrl(this.$route.query.concerns);
            const chosenConcerns = sanitizedQueryConcerns.split(':');
            this.loadPage(chosenConcerns);
          });
        }
      },
      // Run on initialization, the component can be initializaed with defined practicesByConcern
      immediate: true,
    },
  },
  methods: {
    loadPage(chosenConcerns) {
      // All conservation practices related to the chosen concerns
      const relevantConservationPractices = findRelevantConservationPractices(this.practiceConcernPairs, chosenConcerns);
      // Paired to the concerns they're related to
      this.relevantPracticeConcernPairs = filterPracticesByChosenConcerns(this.practiceConcernPairs, chosenConcerns, relevantConservationPractices);

      let heatmapWidth = HEATMAP_COLUMN_WIDTH * chosenConcerns.length;
      // Increase width to a minimum if there are a very small number of columns
      if (heatmapWidth < 300) {
        heatmapWidth = 350;
      }
      const heatmapHeight = HEATMAP_ROW_HEIGHT * relevantConservationPractices.size;
      this.createHeatmap(heatmapWidth, heatmapHeight);
    },
    createHeatmap(heatmapWidth, heatmapHeight) {
      let svg = this.initializeHeatmapSVG(heatmapWidth, heatmapHeight);
      // Apparently the best way to sort the y axis is to sort the source data
      sortByConservationPracticeEffectScores(this.relevantPracticeConcernPairs);
      let conservationPractices = d3.map(this.relevantPracticeConcernPairs, function (d) { return d.conservation_practice; })
      let concerns = d3.map(this.relevantPracticeConcernPairs, function (d) { return d.concern; })

      // Add x axis
      let x = d3.scaleBand()
        .range([SIDE_LABEL_OFFSET, heatmapWidth + SIDE_LABEL_OFFSET])
        .domain(concerns)
        .padding(0.05);
      let xAxis = d3.axisTop(x).tickSize(0).scale(x);
      let xAxisObj = svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', 'translate(0,' + TOP_LABEL_OFFSET + ')')
        .style('font-size', 15)
        .call(xAxis);
      xAxisObj.select('.domain').remove();
      xAxisObj.selectAll('.tick text')
        .call(wrapText, x.bandwidth());

      // Add y axis 
      let y = d3.scaleBand()
        .range([0, heatmapHeight])
        .domain(conservationPractices)
        .padding(0.05);
      // The sidebar is inserted into a different div so that it can remain stationary while 
      // the rest of the chart scrolls
      let sidebarSvg = d3.select('#heatmap-sidebar')
        .append('svg')
        .attr('width', SIDE_LABEL_OFFSET)
        .attr('height', heatmapHeight + TOP_LABEL_OFFSET)
      let yAxisObj = sidebarSvg.append('g')
        .style('font-size', 15)
        .attr('transform', 'translate(' + SIDE_LABEL_OFFSET + ',' + TOP_LABEL_OFFSET + ')')
        .call(d3.axisLeft(y).tickSize(0));
      yAxisObj.select('.domain').remove();

      // Strip trailing (IRA) from some rows
      yAxisObj.selectAll('.tick text').text(function(t){
        // Using regex selector, find the string "(IRA)"
        // Replace that with an empty string
        // Trim remaining trailing whitespace
        return t.replace(/\(IRA\)$/, '').trim();
      })

      // TODO: Add hoverover descriptions
      //console.log(yAxisObj.selectAll('.tick text'));
      //.forEach(function (d) {
      //let test = d3.select(d).data();//get the data asociated with y axis
      //console.log(test);
      //  d3.select(d).on("mouseover", () => { console.log("mouseover tick") })
      //    .on("mouseleave", () => { console.log("mouseleave tick") });
      //})

      var colorScale = d3.scaleLinear()
        .domain([-2, 1, 0, 1, 2, 3, 4, 5])
        .range(['#ad1313', '#d65151', '#f2efee', '#cde3ee', '#8fc2dc', '#4b94c4', '#2265a3', '#053061'])
      this.addValues(svg, x, y, colorScale);
      this.addLegend(colorScale);
    },
    initializeHeatmapSVG(heatmapWidth, heatmapHeight) {
      let svg = d3.select('#heatmap')
        .append('svg')
        .attr('width', heatmapWidth + SIDE_LABEL_OFFSET)
        .attr('height', heatmapHeight + TOP_LABEL_OFFSET)
        .append('g')
      return svg;
    },
    addValues(svg, x, y, colorScale) {
      let squares = svg.selectAll()
        .data(this.relevantPracticeConcernPairs, function (d) { return d.concern + ':' + d.conservation_practice; })
        .enter();

      squares.append('rect')
        .attr('x', function (d) { return x(d.concern) })
        .attr('y', function (d) { return y(d.conservation_practice) + TOP_LABEL_OFFSET })
        .attr('rx', 4)
        .attr('ry', 4)
        .attr('width', x.bandwidth())
        .attr('height', y.bandwidth())
        .style('fill', function (d) { return colorScale(d.value || 0) })
        .style('stroke-width', 4)
        .style('stroke', 'none')
        .style('opacity', 0.8)

      squares.insert('text')
        .attr('x', function (d) { return x(d.concern) + x.bandwidth() / 2 })
        .attr('y', function (d) { return y(d.conservation_practice) + TOP_LABEL_OFFSET + y.bandwidth() / 2 })
        // Text looks slightly out of alignment, better when adjusted down by 1 px
        .attr('dy', 1)
        .attr('text-anchor', 'middle')
        .style('alignment-baseline', 'middle')
        .attr('fill', d => valueToTextColor(d.value))
        .attr('font-family', 'sans-serif')
        .text((d) => d.value);
      
    },
    addLegend(colorScale) {
      // All the values that a conservation practice can have aon a concern
      let keys = [-2, -1, 0, 1, 2, 3, 4, 5];

      let legendBoxWidth = 40;
      let legendBoxHeight = 25;
      let legendVerticalOffset = 20;
      let legendHorizontalOffset = 190;
      let legendWidth = 400;
      let legendHeight = 65;

      let svg = d3.select('#heatmap-legend')
        .append('svg')
        .attr('width', legendWidth + keys.length * (legendBoxWidth + 5))
        .attr('height', legendHeight)
        .attr('transform', 'translate(' + legendHorizontalOffset + ', 0)')
        .append('g')

      svg.selectAll('legend-boxes')
        .data(keys)
        .enter()
        .append('rect')
        .attr('x', function (d, i) { return legendHorizontalOffset + i * (legendBoxWidth + 5) })
        .attr('y', legendVerticalOffset)
        .attr('width', legendBoxWidth)
        .attr('height', legendBoxHeight)
        .style('fill', function (d) { return colorScale(d) })

      svg.selectAll('legend-numbers')
        .data(keys)
        .enter()
        .append('text')
        .attr('x', function (d, i) { return + legendHorizontalOffset + i * (legendBoxWidth + 5) + legendBoxWidth / 2 })
        .attr('y', legendVerticalOffset + legendBoxHeight / 2)
        .attr('dy', 1)
        .attr('fill', d => valueToTextColor(d))
        // make into function
        .text(function (d) { return d })
        .attr('text-anchor', 'middle')
        .style('alignment-baseline', 'middle')

      svg.append('text')
        .attr('x', legendHorizontalOffset - 8)
        .attr('y', legendVerticalOffset + legendBoxHeight / 2 - 10)
        .text('Conservation practice')
        .attr('text-anchor', 'end')
        .style('alignment-baseline', 'middle')

      svg.append('text')
        .attr('x', legendHorizontalOffset - 8)
        .attr('y', legendVerticalOffset + legendBoxHeight / 2 + 10)
        .text('has detrimental effect')
        .attr('text-anchor', 'end')
        .style('alignment-baseline', 'middle')

      svg.append('text')
        .attr('x', legendHorizontalOffset + 8 * (legendBoxWidth + 5))
        .attr('y', legendVerticalOffset + legendBoxHeight / 2 - 10)
        .text('Conservation practice')
        .attr('text-anchor', 'start')
        .style('alignment-baseline', 'middle')

      svg.append('text')
        .attr('x', legendHorizontalOffset + 8 * (legendBoxWidth + 5))
        .attr('y', legendVerticalOffset + legendBoxHeight / 2 + 10)
        .text('has protective effect')
        .attr('text-anchor', 'start')
        .style('alignment-baseline', 'middle')
    },
    exportToPdf() {
      const doc = new jsPDF();

      doc.fromHTML(document.body);
      doc.save("test.pdf");
    }
  }
}

// Choosing a text color that gives good contrast with the color associated
// with that value
function valueToTextColor(value) {
  return (value == 1 || value == 0) ? 'black' : 'white'
}

// Copyright 2019–2020 Observable, Inc.
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
// 
// THE SOFTWARE IS PROVIDED 'AS IS' AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
// Adapted from https://gist.github.com/mbostock/7555321
function wrapText(text, width) {
  text.each(function () {
    var text = d3.select(this),
      words = text.text().split(/\s+/).reverse(),
      word,
      line = [],
      lineNumber = 0,
      lineHeight = 1.1, // ems
      y = text.attr('y'),
      dy = parseFloat(text.attr('dy')),
      tspan = text.text(null).append('tspan').attr('x', 0).attr('y', y).attr('dy', dy + 'em');
    word = words.pop();
    while (word) {
      line.push(word);
      tspan.text(line.join(' '));
      if (tspan.node().getComputedTextLength() > width) {
        line.pop();
        tspan.text(line.join(' '));
        line = [word];
        tspan = text.append('tspan').attr('x', 0).attr('y', y).attr('dy', ++lineNumber * lineHeight + dy + 'em').text(word);
      }
      word = words.pop();
    }
    let tspans = text.selectAll('tspan');
    // lineHeightEms
    let h = 1.05;
    tspans.each(function (d, i) {
      // Calculate the y offset (dy) for each tspan so that the vertical centre
      // of the tspans roughly aligns with the text element's y position.
      let dy = i * h;
      dy -= ((tspans.size() - 1) * h);
      d3.select(this)
        .attr('y', y)
        .attr('dy', dy + 'em');
    });
  });
}

</script>

<!-- Add 'scoped' attribute to limit CSS to this component only -->
<style scoped>
#heatmap {
  overflow-x: scroll;
}

#heatmap-sidebar {
  position: absolute;
  background: white;
  padding-right: 10px;
}

#heatmap-legend {
  display: absolute;
  margin-left: auto;
  margin-right: auto;
}
</style>
