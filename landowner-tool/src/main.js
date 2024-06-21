import { createApp } from 'vue'
import App from './App.vue'
import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap/dist/js/bootstrap.min.js'

import { createRouter, createWebHistory } from 'vue-router'

import masonry from 'vue-next-masonry'

import ConcernPicker from './components/ConcernPicker.vue'
import ConservationPracticeExplorer from './components/ConservationPracticeExplorer.vue'

const routes = [
  { path: '/', component: ConcernPicker },
  { path: '/explore', component: ConservationPracticeExplorer },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

createApp(App).use(masonry).use(router).mount('#app')
