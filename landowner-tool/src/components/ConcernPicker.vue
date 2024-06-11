<template>
  <div class="container">
    <h1 class="text-center">Tell us about your conservation interests</h1>
  </div>
  <div class="container">
    <form>
      <div class="mb-3">
        <label for="exampleInputEmail1" class="form-label">Location</label>
        <input type="email" class="form-control" id="exampleInputEmail1">
      </div>
      <div class="mb-3">
        <label for="exampleInputPassword1" class="form-label">Your Role</label>
        <input type="password" class="form-control" id="exampleInputPassword1">
      </div>
      <masonry :cols="3">
        <div v-for="category in categories" :key="category.category">
          <div class="card">
            <div class="card-body">
              <div class="card-title">
                {{category.category}}
              </div>
              <div v-for="concern in category.concerns" :key="concern" class="form-check">
                <input type="checkbox" class="form-check-input" id="{{concern.concern}}">
                <label class="form-check-label" for="{{concern.concern}}">{{concern.concern}}</label>
              </div>
            </div>
          </div>
        </div>
      </masonry>
      <RouterLink to="/explore">
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
      if (line.category == entry.category) {
         entry.concerns.push({'concern': line.concern});
         found = true;
      } 
    }
    if (!found) {
      concernsByCategory.push({'category': line.category, concerns: [{'concern':line.concern}]})
    }
  }
  return concernsByCategory;
}

export default {
  name: 'ConcernPicker',
  data() {
    return {
      categories: [],
    }
  },
  async created() {
    let categories;
    await fetch('data.csv')
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
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.card{
  margin: 15px;
}
</style>
