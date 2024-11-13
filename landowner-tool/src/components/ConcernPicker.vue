<template>
  <div class="container">
    <h1 class="text-center">Tell us about your conservation interests</h1>
  </div>
  <div class="container">
    <form>
      <div class="container-md">
        <div class="mb-3">
          <label for="name" class="form-label">Name</label>
          <input v-model="name" class="form-control" id="name">
        </div>
        <div class="mb-3">
          <label for="state" class="form-label">State</label>
          <select v-model="state" class="form-select" id="state" required>
            <option selected disabled>Select your state</option>
            <option value="AL">Alabama</option>
            <option value="AK">Alaska</option>
            <option value="AZ">Arizona</option>
            <option value="AR">Arkansas</option>
            <option value="CA">California</option>
            <option value="CO">Colorado</option>
            <option value="CT">Connecticut</option>
            <option value="DE">Delaware</option>
            <option value="DC">District Of Columbia</option>
            <option value="FL">Florida</option>
            <option value="GA">Georgia</option>
            <option value="HI">Hawaii</option>
            <option value="ID">Idaho</option>
            <option value="IL">Illinois</option>
            <option value="IN">Indiana</option>
            <option value="IA">Iowa</option>
            <option value="KS">Kansas</option>
            <option value="KY">Kentucky</option>
            <option value="LA">Louisiana</option>
            <option value="ME">Maine</option>
            <option value="MD">Maryland</option>
            <option value="MA">Massachusetts</option>
            <option value="MI">Michigan</option>
            <option value="MN">Minnesota</option>
            <option value="MS">Mississippi</option>
            <option value="MO">Missouri</option>
            <option value="MT">Montana</option>
            <option value="NE">Nebraska</option>
            <option value="NV">Nevada</option>
            <option value="NH">New Hampshire</option>
            <option value="NJ">New Jersey</option>
            <option value="NM">New Mexico</option>
            <option value="NY">New York</option>
            <option value="NC">North Carolina</option>
            <option value="ND">North Dakota</option>
            <option value="OH">Ohio</option>
            <option value="OK">Oklahoma</option>
            <option value="OR">Oregon</option>
            <option value="PA">Pennsylvania</option>
            <option value="RI">Rhode Island</option>
            <option value="SC">South Carolina</option>
            <option value="SD">South Dakota</option>
            <option value="TN">Tennessee</option>
            <option value="TX">Texas</option>
            <option value="UT">Utah</option>
            <option value="VT">Vermont</option>
            <option value="VA">Virginia</option>
            <option value="WA">Washington</option>
            <option value="WV">West Virginia</option>
            <option value="WI">Wisconsin</option>
            <option value="WY">Wyoming</option>
            <option value="NONE">None</option>
          </select>
        </div>
        <div class="mb-3">
          <label for="county" class="form-label">County</label>
          <input v-model="county" class="form-control" id="county" required>
        </div>
        <div class="mb-3">
          <label for="organization" class="form-label">Organization</label>
          <input v-model="organization" class="form-control" id="organization" required>
        </div>
        <div class="mb-3">
          <label class="form-label">Role</label>
          <select v-model="role" class="form-select" aria-label="role">
            <option selected disabled>Select your role</option>
            <option value="landowner">Landowner</option>
            <option value="biologist">Biologist</option>
            <option value="other">Other</option>
          </select>
        </div>
      </div>
      <masonry :cols="{ default: 3, 700: 2, 400: 1 }">
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
                <label class="form-check-label" :for="concern" :title="concernDescriptions[concern] || ''">{{ concern }}</label>
              </div>
            </div>
          </div>
        </div>
      </masonry>
      <RouterLink :to="`/explore?name=${encodeURIComponent(name)}&state=${encodeURIComponent(state)}&county=${encodeURIComponent(county)}&organization=${encodeURIComponent(organization)}&role=${encodeURIComponent(role)}&concerns=${getConcernString()}`">
        <button type="submit" class="btn btn-primary">Explore conservation practices</button>
      </RouterLink>
    </form>
  </div>
</template>

<script>
export const ALL_CHECKED = 'all-checked';
export const SOME_CHECKED = 'some-checked';
export const NONE_CHECKED = 'none-checked';

// eslint-disable-next-line
import * as bootstrap from 'bootstrap'
import { intersection } from './util.js';
import analyticsInstance from '../analyticsInstance.js';
import concernDescriptions from '../../public/data/concern_descriptions_map.json'

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
      name: '',
      state: '',
      county: '',
      organization: '',
      role: '',
      concernDescriptions
    }
  },
  mounted() {
    // Update from store when navigating backwards to this page
    this.updateTopLevelCheckmarks();
    analyticsInstance.track('ConcernPickerDidLoad');

    // Unfortunately the elements are within a vue-next-masonry component
    // which does not emit a layout-complete event, and requires us to
    // repeat initializing the tooltips regularly. This code is WIP
    // window.bootstrap = bootstrap
    // const tooltipList = document.querySelectorAll('[data-bs-title]');
    // tooltipList.forEach(el => {
    //   if (el.getAttribute('data-bs-title')) {
    //     // console.log(el)
    //     new bootstrap.Tooltip(el);
    //   }
    // });

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
