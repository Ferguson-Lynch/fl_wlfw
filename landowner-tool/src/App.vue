<template>
  <router-view :concernsByCategory="concernsByCategory" :practicesByConcern="practicesByConcern"></router-view>
</template>

<script>
import Papa from 'papaparse';

function concernsByCategoryFromCsvObj(jsonObj) {
  const concernsByCategory = {};
  for (const line of jsonObj) {
    if (concernsByCategory[line.category]) {
      concernsByCategory[line.category].push(line.concern);
    } else {
      concernsByCategory[line.category] = [line.concern];
    }
  }
  return concernsByCategory;
}

function strip(practice) {
  return practice.replace(/["]+/g, '').trim();

}

export default {
  name: 'App',
  data() {
    return {
      practicesByConcern: [],
      concernsByCategory: [],
      dataLoaded: false,
    }
  },
  computed: {
    concernsWithPractices() {
      return [];
    }
  },
  methods: {
    async loadPractices() {
      let practicesByConcern;
      await fetch('data/conservation_practice_data.csv')
        .then(res => res.text())
        .then(csv => {
          Papa.parse(csv, {
            header: true,
            complete: function (results) {
              practicesByConcern = results.data;
            }
          });
        });
      for (const practice of practicesByConcern) {
        for (const key in practice) {
          const strippedKey = strip(key);
          if (key != strippedKey) {
            Object.defineProperty(practice, strippedKey,
              Object.getOwnPropertyDescriptor(practice, key));
            delete practice[key];
          }
        }
      }
      this.practicesByConcern = practicesByConcern;
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
