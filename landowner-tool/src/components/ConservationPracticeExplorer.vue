<template>
  <div class='container'>
    <h3 class='text-center'>Which conservation practices help resource concerns that you are interested in?</h3>
    <p><b>How to Interpret This Graph:</b> This graph visualizes overlap and patterns in the effectiveness of certain
      conservation practices. The vertical left-hand column lists out conservation practices used by NRCS and the top
      horizontal row lists resource concerns you selected on the previous page. The numbers in the graph indicate the
      severity of the impact as shown in the effect score key above the graph. This data comes from USDA’s Conservation
      Practice Physical Effects (CPPE) scores.</p>
  </div>
  <div id='heatmap'></div>
</template>

<script>
import * as d3 from 'd3';

const CHART_MARGIN = { top: 80, right: 25, bottom: 30, left: 330 };
const CHART_HEIGHT = 850;
// Space for the x-axis labels (concern names)
let X_LABEL_OFFSET = 100;

export default {
  Name: 'ConservationPracticeExplorer',
  props: ['practiceConcernPairs', 'practiceDescriptions'],
  data() {
    return {
      relevantPracticeConcernPairs: [],
      chartWidth: 1100,
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
            this.loadHeatmap();
          });
        }
      },
      // Run on initialization, the component can be initializaed with defined practicesByConcern
      immediate: true,
    },
  },
  methods: {
    loadHeatmap() {
      console.log(this.$route.query.concerns);
      const chosenConcerns = this.$route.query.concerns.split(':');
      console.log(chosenConcerns);
      this.filterPracticesByChosenConcerns(this.practiceConcernPairs, chosenConcerns);
      this.createHeatmap();
    },
    filterPracticesByChosenConcerns(practiceConcernPairs, chosenConcerns) {
      const allRelevantConservationPractices = new Set();
      for (const pair of this.practiceConcernPairs) {
        if (chosenConcerns.includes(pair['concern']) && pair['value'] != 0) {
          allRelevantConservationPractices.add(pair['conservation_practice']);
        }
      }
      this.relevantPracticeConcernPairs =
        practiceConcernPairs.filter((pair) =>
        (chosenConcerns.includes(pair['concern']) &&
          allRelevantConservationPractices.has(pair['conservation_practice'])));
    },
    createHeatmap() {
      this.chartWidth = window.innerWidth;
      let svg = this.initializeHeatmap();
      let conservationPractices = d3.map(this.relevantPracticeConcernPairs, function (d) { return d.conservation_practice; })
      let concerns = d3.map(this.relevantPracticeConcernPairs, function (d) { return d.concern; })

      // Add x axis
      let x = d3.scaleBand()
        .range([0, this.chartWidth])
        .domain(concerns)
        .padding(0.05);

      let xAxis = d3.axisTop(x).tickSize(0).scale(x);
      let axisObj = svg.append('g')
        .attr('y', X_LABEL_OFFSET)
        .attr('class', 'x axis')
        .style('font-size', 15)
        .call(xAxis);
      axisObj.select('.domain').remove();
      axisObj.selectAll('.tick text')
        .call(wrapText, x.bandwidth());

      // Add y axis 
      let y = d3.scaleBand()
        .range([CHART_HEIGHT, 0])
        .domain(conservationPractices)
        .padding(0.05);
      svg.append('g')
        .style('font-size', 15)
        .call(d3.axisLeft(y).tickSize(0))
        .select('.domain').remove()

      var colorScale = d3.scaleLinear()
        .domain([-2, 1, 0, 1, 2, 3, 4, 5])
        .range(['#ad1313', '#d65151', '#f2efee', '#cde3ee', '#8fc2dc', '#4b94c4', '#2265a3', '#053061'])

      this.addValues(svg, x, y, colorScale);
      this.addLegend(svg, colorScale);

    },
    initializeHeatmap() {
      // set the dimensions and margins of the graph
      // append the svg object to the body of the page
      let svg = d3.select('#heatmap')
        .append('svg')
        .attr('width', this.chartWidth + CHART_MARGIN.left + CHART_MARGIN.right)
        .attr('height', CHART_HEIGHT + CHART_MARGIN.top + CHART_MARGIN.bottom)
        .append('g')
        .attr('transform',
          'translate(' + CHART_MARGIN.left + ',' + CHART_MARGIN.top + ')');
      return svg;
    },
    addValues(svg, x, y, colorScale) {
      let squares = svg.selectAll()
        .data(this.relevantPracticeConcernPairs, function (d) { return d.concern + ':' + d.conservation_practice; })
        .enter();

      squares.append('rect')
        .attr('x', function (d) { return x(d.concern) })
        .attr('y', function (d) { return y(d.conservation_practice) })
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
        .attr('y', function (d) { return y(d.conservation_practice) + y.bandwidth() / 2 })
        // Text looks slightly out of alignment, better when adjusted down by 1 px
        .attr('dy', 1)
        .attr('text-anchor', 'middle')
        .style('alignment-baseline', 'middle')
        .attr('fill', d => d.value > 1 ? 'white' : 'black')
        .attr('font-family', 'sans-serif')
        .text((d) => d.value);
    },
    addLegend(svg, colorScale) {
      let keys = [-2, -1, 0, 1, 2, 3, 4, 5]

      let legendBoxWidth = 40
      let legendBoxHeight = 25
      let legendVerticalOffset = 70

      svg.selectAll('legend-boxes')
        .data(keys)
        .enter()
        .append('rect')
        .attr('x', function (d, i) { return i * (legendBoxWidth + 5) })
        .attr('y', -legendVerticalOffset)
        .attr('width', legendBoxWidth)
        .attr('height', legendBoxHeight)
        .style('fill', function (d) { return colorScale(d) })

      svg.selectAll('legend-numbers')
        .data(keys)
        .enter()
        .append('text')
        .attr('x', function (d, i) { return + i * (legendBoxWidth + 5) + legendBoxWidth / 2 })
        .attr('y', -legendVerticalOffset + legendBoxHeight / 2)
        .attr('dy', 1)
        .attr('fill', d => d > 1 ? 'white' : 'black')
        // make into function
        .text(function (d) { return d })
        .attr('text-anchor', 'middle')
        .style('alignment-baseline', 'middle')

      svg.append('text')
        .attr('x', -8)
        .attr('y', -legendVerticalOffset + legendBoxHeight / 2 - 10)
        .text('Conservation practice')
        .attr('text-anchor', 'end')
        .style('alignment-baseline', 'middle')

      svg.append('text')
        .attr('x', -8)
        .attr('y', -legendVerticalOffset + legendBoxHeight / 2 + 10)
        .text('has detrimental effect')
        .attr('text-anchor', 'end')
        .style('alignment-baseline', 'middle')

      svg.append('text')
        .attr('x', 8 * (legendBoxWidth + 5))
        .attr('y', -legendVerticalOffset + legendBoxHeight / 2 - 10)
        .text('Conservation practice')
        .attr('text-anchor', 'start')
        .style('alignment-baseline', 'middle')

      svg.append('text')
        .attr('x', 8 * (legendBoxWidth + 5))
        .attr('y', -legendVerticalOffset + legendBoxHeight / 2 + 10)
        .text('has protective effect')
        .attr('text-anchor', 'start')
        .style('alignment-baseline', 'middle')
    }
  }
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
<style scoped></style>
