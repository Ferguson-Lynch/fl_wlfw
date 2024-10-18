import { createApp } from 'vue'
import App from './App.vue'
import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap-icons/font/bootstrap-icons.css'
import 'bootstrap/dist/js/bootstrap.min.js'

import { createRouter, createWebHistory } from 'vue-router'

import masonry from 'vue-next-masonry'

import ConcernPicker from './components/ConcernPicker.vue'
import ConservationPracticeExplorer from './components/ConservationPracticeExplorer.vue'

const routes = [
  { path: '/', component: ConcernPicker, props: true },
  { path: '/explore', component: ConservationPracticeExplorer, props: true },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

createApp(App).use(masonry).use(router).mount('#app')
