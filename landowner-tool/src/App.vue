<template>
  <router-view :concernsByCategory="concernsByCategory" :practiceConcernPairs="practiceConcernPairs"
    :practiceDescriptions="practiceDescriptions"></router-view>
</template>

<script>
import Papa from 'papaparse';

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

function strip(practice) {
  return practice.replace(/["]+/g, '').trim();

}

function parseConservationPracticeName(line) {
  console.log(line);
  return line.split(' | ')[1].trim();
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
      let descriptionLines;
      await fetch('data/conservation_practice_descriptions.csv')
        .then(res => res.text())
        .then(csv => {
          Papa.parse(csv, {
            header: true,
            complete: function (results) {
              descriptionLines = results.data;
            }
          });
        });
      let practiceDescriptions = {}
      console.log(descriptionLines)
      for (const line of descriptionLines) {
        practiceDescriptions[parseConservationPracticeName(line['Conservation Practice'])] = line['Description'];
      }
      this.practiceDescriptions = practiceDescriptions;
    },
    async loadPractices() {
      let csvLines;
      await fetch('data/conservation_practice_data.csv')
        .then(res => res.text())
        .then(csv => {
          Papa.parse(csv, {
            header: true,
            complete: function (results) {
              csvLines = results.data;
            }
          });
        });
      let practiceConcernPairs = [];
      for (const line of csvLines) {
        // Each key is a column in the CSV
        for (const colKey in line) {
          // Index column
          if (colKey == 'Conservation Practice') {
            continue;
          }
          practiceConcernPairs.push({
            conservation_practice: parseConservationPracticeName(line['Conservation Practice']),
            concern: strip(colKey),
            value: line[colKey] || 0
          })
        }
      }
      this.practiceConcernPairs = practiceConcernPairs;
    },
    async loadConcerns() {
      const concernDataPath = 'data/concerns_by_category.csv';
      let concernsByCategory;
      await fetch(concernDataPath)
        .then(res => res.text())
        .then(csv => {
          Papa.parse(csv, {
            header: true,
            complete: function (results) {
              concernsByCategory = concernsByCategoryFromCsvObj(results.data);
            }
          });
        })
        .catch((err) => {
          console.log(err);
          throw new Error(`Data at ${concernDataPath} not formatted as expected. `
            + ` Should be a csv file with headers 'concern' and 'category'`)
        });
      this.concernsByCategory = concernsByCategory;

    }
  },
  mounted() {
    this.loadDescriptions();
    this.loadPractices();
    this.loadConcerns();
  },
}
</script>

<style>
#app {
  margin-top: 20px;
  margin-bottom: 20px;
}
</style>
