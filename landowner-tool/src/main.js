import { createApp } from 'vue'
import App from './App.vue'
import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap/dist/js/bootstrap.min.js'

import { createMemoryHistory, createRouter } from 'vue-router'

import masonry from 'vue-next-masonry'

import ConcernPicker from './components/ConcernPicker.vue'
import ConservationPracticeExplorer from './components/ConservationPracticeExplorer.vue'

const routes = [
  { path: '/', component: ConcernPicker },
  { path: '/explore', component: ConservationPracticeExplorer },
]

const router = createRouter({
  history: createMemoryHistory(),
  routes,
})

createApp(App).use(router).use(masonry).mount('#app')
