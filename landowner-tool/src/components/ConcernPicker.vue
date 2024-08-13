<template>
  <div class="container">
    <h1 class="text-center">Tell us about your conservation interests</h1>
  </div>
  <div class="container">
    <form>
      <div class="container-md">
        <div class="mb-3">
          <label for="name" class="form-label">Name</label>
          <input class="form-control" id="name">
        </div>
        <div class="mb-3">
          <label for="location" class="form-label">Location</label>
          <input class="form-control" id="location">
        </div>
        <div class="mb-3">
          <label for="organization" class="form-label">Organization</label>
          <input class="form-control" id="organization">
        </div>
        <div class="mb-3">
          <label class="form-label">Role</label>
          <select class="form-select" aria-label="role">
            <option selected>Select your role</option>
            <option value="landowner">Landowner</option>
            <option value="biologist">Biologist</option>
            <option value="other">Other</option>
          </select>
        </div>
      </div>
      <masonry :cols="3">
        <div v-for="(value, key) in concernsByCategory" :key="key">
          <div class="card">
            <div class="card-body">
              <div class="form-check">
                <input type="checkbox" :id="key + '-checkbox'" class="form-check-input" @click="toggleAll(key)">
                <label class="card-title">
                  <h5>{{ key }}</h5>
                </label>
              </div>
              <div v-for="concern in value" :key="concern" class="form-check">
                <input type="checkbox" class="form-check-input" :value="concern" v-model="checkedConcerns">
                <label class="form-check-label" :for="concern">{{ concern }}</label>
              </div>
            </div>
          </div>
        </div>
      </masonry>
      <RouterLink :to="`/explore?concerns=${getConcernString()}`">
        <button type="submit" class="btn btn-primary">Explore conservation practices</button>
      </RouterLink>
    </form>
  </div>
</template>

<script>
export const ALL_CHECKED = 'all-checked';
export const SOME_CHECKED = 'some-checked';
export const NONE_CHECKED = 'none-checked';

import { intersection } from './util.js';

export default {
  name: 'ConcernPicker',
  props: ['concernsByCategory'],
  // Prevents all properties from being passed through router-view, only those named above 
  inheritAttrs: false,
  data() {
    return {
      checkedConcerns: store.checkedConcerns,
      // The toggle state of categories that include concerns the user
      // has interacted with so far
      categoryToggleStates: {},
    }
  },
  mounted() {
    // Update from store when navigating backwards to this page
    this.updateTopLevelCheckmarks();
  },
  watch: {
    // Indeterminate checkbox state cannot be set via HTML. For consistency, 
    // setting all checkbox state here.
    checkedConcerns() {
      this.updateTopLevelCheckmarks();
    },
  },
  methods: {
    getConcernString() {
      store.checkedConcerns = this.checkedConcerns;
      const concernURLString = this.checkedConcerns.join(':');
      return encodeURIComponent(concernURLString);
    },
    updateTopLevelCheckmarks() {
      for (const category in this.concernsByCategory) {
        const concernsIntersection = intersection(this.checkedConcerns, this.concernsByCategory[category]);
        const checkboxElement = document.getElementById(category + '-checkbox');
        if (concernsIntersection.length == 0) {
          this.categoryToggleStates[category] = NONE_CHECKED;
          checkboxElement.checked = false;
          checkboxElement.indeterminate = false;
        } else if (concernsIntersection.length == this.concernsByCategory[category].length) {
          this.categoryToggleStates[category] = ALL_CHECKED;
          checkboxElement.checked = true;
          checkboxElement.indeterminate = false;
        } else {
          this.categoryToggleStates[category] = SOME_CHECKED;
          checkboxElement.indeterminate = true;
          checkboxElement.checked = false;
        }
      }
    },
    toggleAll(categoryName) {
      if (!this.categoryToggleStates[categoryName]) {
        this.categoryToggleStates[categoryName] = ALL_CHECKED;
        for (const concern of this.concernsByCategory[categoryName]) {
          if (!this.checkedConcerns.includes(concern)) {
            this.checkedConcerns.push(concern);
          }
        }
        return;
      }
      switch (this.categoryToggleStates[categoryName]) {
        case ALL_CHECKED:
          this.categoryToggleStates[categoryName] = NONE_CHECKED;
          for (const concern of this.concernsByCategory[categoryName]) {
            this.checkedConcerns = this.checkedConcerns.filter(val => val != concern);
          }
          break;
        case NONE_CHECKED:
        case SOME_CHECKED:
          this.categoryToggleStates[categoryName] = ALL_CHECKED;
          for (const concern of this.concernsByCategory[categoryName]) {
            if (!this.checkedConcerns.includes(concern)) {
              this.checkedConcerns.push(concern);
            }
          }
          break;
      }
    }
  }
}
</script>
<script setup>
import { store } from '../store.js'
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.card {
  margin: 15px;
}
</style>
