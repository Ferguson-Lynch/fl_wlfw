<template>
  <RouterView />
</template>

<script>
import Papa from 'papaparse';

export default {
  name: 'App',
  data() {
    return {
      practices: [],
    }
  },
  computed: {
    concernsWithPractices() {

    }
  },
  methods: {
    async loadPractices() {
      let practices;
      await fetch('data/conservation_practice_data.csv')
        .then(res => res.text())
        .then(csv => {
          Papa.parse(csv, {
            header: true,
            complete: function (results) {
              practices = results.data;
            }
          });
        });
      this.practices = practices;
    },
    async loadConcerns() {
      let practices;
      await fetch('data/concerns_by_category.csv')
        .then(res => res.text())
        .then(csv => {
          Papa.parse(csv, {
            header: true,
            complete: function (results) {
              categories = concernsByCategoryFromJson(results.data);
            }
          });
        })
        .catch((err) => {
          console.log("error");
        });
      this.categories = categories;

    }

  },
  mounted() {
    this.loadPractices();
  },

}
</script>

<style>
#app {
  margin-top: 20px;
  margin-bottom: 20px;
}
</style>
