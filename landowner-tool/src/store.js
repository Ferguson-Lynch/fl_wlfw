import { reactive } from 'vue'

export const store = reactive({
  checkedConcerns: [],
  name: '',
  state: '',
  county: '',
  organization: '',
  role: ''
})