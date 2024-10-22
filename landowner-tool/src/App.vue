<template>
  <router-view :concernsByCategory="concernsByCategory" :practiceConcernPairs="practiceConcernPairs"
    :practiceDescriptions="practiceDescriptions"></router-view>
</template>

<script>
import Papa from 'papaparse';
import analyticsInstance from './analyticsInstance.js'

// Creates a dictionary from the CSV associating concerns and category
//
// Format of input object:
// {category: "Soil & Land", concern: "Wind Erosion"}, 
// {category: "Soil & Land", concern: "Classic Gully Erosion"} 
//
// Return value:
// {"Soil & Land": ["Wind Erosion", "Classic Gully Erosion"]}
function concernsByCategoryFromCsvObj(jsonObj) {
  const concernsByCategory = {};
  for (const line of jsonObj) {
    if (concernsByCategory[line.category]) {
      concernsByCategory[line.category].push(strip(line.concern));
    } else {
      concernsByCategory[line.category] = [strip(line.concern)];
    }
  }
  return concernsByCategory;
}

function strip(str) {
  return str.replace(/["]+/g, '').trim();
}

async function loadCsvWithHeader(filePath) {
  let csvLines;
  await fetch(filePath)
    .then(res => res.text())
    .then(csv => {
      Papa.parse(csv, {
        header: true,
        complete: function (results) {
          csvLines = results.data;
        }
      });
    });
  return csvLines;
}

export default {
  name: 'App',
  data() {
    return {
      /**
       * How effective a certain conservation practice is for a certain resource 
       * concern. In long format, so every line contains a practice, a concern, and
       * the effectiveness value. Zero values are omitted.
       */
      practiceConcernPairs: [],
      concernsByCategory: [],
      practiceDescriptions: [],
      dataLoaded: false,
    }
  },
  computed: {
    concernsWithPractices() {
      return [];
    }
  },
  methods: {
    async loadDescriptions() {
      let practiceDescriptions = {};
      let descriptionLines = await loadCsvWithHeader('data/conservation_practice_descriptions.csv');
      // TODO: may not need this line once data is cleaned up
      for (const line of descriptionLines) {
        practiceDescriptions[line['Conservation Practice']] = line['Description'];
      }
      this.practiceDescriptions = practiceDescriptions;
    },
    async loadPractices() {
      this.practiceConcernPairs = await loadCsvWithHeader('data/conservation_practices_long.csv');
    },
    async loadConcerns() {
      let concernsByCategoryLines = await loadCsvWithHeader('data/concerns_by_category.csv');
      this.concernsByCategory = concernsByCategoryFromCsvObj(concernsByCategoryLines);
    }
  },
  mounted() {
    // Loading the data at the app-level to avoid extra loading if the user goes back
    // and forth between the concern picker and explorer, which is an expected use.
    this.loadDescriptions();
    this.loadPractices();
    this.loadConcerns();

    // Track a page view
    analyticsInstance.page();
  },
}
</script>

<style>
#app {
  margin-top: 20px;
  margin-bottom: 20px;
}
</style>
