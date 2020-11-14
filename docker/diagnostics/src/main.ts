import Vue from 'vue'
import Router from './Router.vue'
import vueHeadful from 'vue-headful'

Vue.component('vue-headful', vueHeadful)

new Vue({
    render: h => h(Router),
}).$mount('#app')
