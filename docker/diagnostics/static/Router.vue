<!-- Router.vue -->

<template>
    <div>
        <component
            :is="visible"
            :token="token"
            :query="query"
            @navigate="handleNavigate"
            @authenticated="handleAuthenticated"
            @logout="handleLogout"
        ></component>
    </div>
</template>

<script>
import Login from './Login'
import Home from './Home'
import Archive from './Archive'

function parseQuery(queryString) {
    const query = {}
    const pairs = (queryString[0] === '?' ? queryString.substr(1) : queryString).split('&')
    for (let i = 0; i < pairs.length; i++) {
        const pair = pairs[i].split('=')
        query[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1] || '')
    }
    return query
}

export default {
    data() {
        console.log('data', navigator)

        return {
            path: window.location.pathname,
            rawQuery: window.location.search,
            token: null,
        }
    },
    methods: {
        handleNavigate(url) {
            console.log('navigate', url)
            history.pushState({}, '', url)
            this.rawQuery = url
        },
        handleAuthenticated(token) {
            console.log('authenticated')
            this.token = token
        },
        handleLogout() {
            console.log('logout')
            history.pushState({}, '', '')
            this.token = null
        },
    },
    computed: {
        visible() {
            if (!this.token) {
                return Login
            }

            const query = parseQuery(this.rawQuery)
            if (query.id) {
                return Archive
            }
            return Home
        },
        query() {
            return parseQuery(this.rawQuery)
        },
    },
    created() {
        this.token = localStorage.getItem('token')

        window.onpopstate = ev => {
            console.log('location: ' + window.location + ', state: ' + JSON.stringify(event.state))
            this.handleNavigate(window.location.search)
        }
    },
}
</script>
