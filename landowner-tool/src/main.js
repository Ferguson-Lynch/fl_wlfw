import { createApp } from 'vue'
import App from './App.vue'
import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap/dist/js/bootstrap.min.js'

import { createMemoryHistory, createRouter } from 'vue-router'

import ConcernPicker from './components/ConcernPicker.vue'

const routes = [
  { path: '/', component: ConcernPicker },
  //{ path: '/about', component: AboutView },
]

const router = createRouter({
  history: createMemoryHistory(),
  routes,
})

createApp(App).use(router).mount('#app')
