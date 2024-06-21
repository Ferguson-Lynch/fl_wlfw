<template>
  <div class="container">
    <h1 class="text-center">Tell us about your conservation interests</h1>
  </div>
  <div class="container">
    <form>
      <div class="mb-3">
        <label for="location" class="form-label">Location</label>
        <input class="form-control" id="location">
      </div>
      <div class="mb-3">
        <label for="role" class="form-label">Your Role</label>
        <input class="form-control" id="role">
      </div>
      <masonry :cols="3">
        <div v-for="category in categories" :key="category.categoryName">
          <div class="card">
            <div class="card-body">
              <h5 class="card-title">{{ category.categoryName }}</h5>
              <div class="card-title">
                {{ category.category }}
              </div>
              <div v-for="concern in category.concerns" :key="concern" class="form-check">
                <input type="checkbox" class="form-check-input" :value="concern" v-model="checkedConcerns">
                <label class="form-check-label" :for="concern">{{ concern }}</label>
              </div>
            </div>
          </div>
        </div>
      </masonry>
      <RouterLink :to="`/explore?concerns=${ getConcernString() }`">
        <button type="submit" class="btn btn-primary">Explore conservation practices</button>
      </RouterLink>
    </form>
  </div>
</template>

<script>
import Papa from 'papaparse';

function concernsByCategoryFromJson(jsonObj) {
  const concernsByCategory = [];
  for (const line of jsonObj) {
    let found = false;
    for (const entry of concernsByCategory) {
      if (line.category == entry.categoryName) {
         entry.concerns.push(line.concern.trim());
         found = true;
      } 
    }
    if (!found) {
      concernsByCategory.push({'categoryName': line.category, concerns: [line.concern.trim()]})
    }
  }
  return concernsByCategory;
}

export default {
  name: 'ConcernPicker',
  data() {
    return {
      categories: [],
      checkedConcerns: store.checkedConcerns,
    }
  },
  async created() {
    let categories;
    await fetch('data/concerns_by_category.csv')
        .then( res => res.text() )
        .then( csv => {
            Papa.parse( csv, {
                header: true,
                complete: function(results) {
                     categories = concernsByCategoryFromJson(results.data);
                }
            });
        })
        .catch(function() {
         console.log("error"); 
        });
        this.categories = categories;
  },
  methods: {
    getConcernString() {
      store.checkedConcerns = this.checkedConcerns;
      return encodeURIComponent(this.checkedConcerns);
    }
  }
}
</script>
<script setup>
import { store } from '../store.js'
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.card{
  margin: 15px;
}
</style>
