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

<script lang="ts">
import Vue, { Component, PropType } from 'vue'
import Login from './Login.vue'
import Home from './Home.vue'
import Archive from './Archive.vue'

import './bootstrap.min.css'

type Query = Record<string, unknown>

function parseQuery(queryString: string): Query {
    const query: Query = {}
    const pairs = (queryString[0] === '?' ? queryString.substr(1) : queryString).split('&')
    for (let i = 0; i < pairs.length; i++) {
        const pair = pairs[i].split('=')
        query[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1] || '')
    }
    return query
}

export default Vue.extend({
    data(): {
        path: string
        rawQuery: string
        token: string | null
    } {
        return {
            path: window.location.pathname,
            rawQuery: window.location.search,
            token: null,
        }
    },
    methods: {
        handleNavigate(url: string): void {
            console.log('navigate', url)
            history.pushState({}, '', url)
            this.rawQuery = url
        },
        handleAuthenticated(token: string): void {
            console.log('authenticated')
            this.token = token
        },
        handleLogout(): void {
            console.log('logout')
            history.pushState({}, '', '')
            this.token = null
        },
    },
    computed: {
        visible(): Component {
            if (!this.token) {
                return Login
            }

            const query = parseQuery(this.rawQuery)
            if (query.id) {
                return Archive
            }
            return Home
        },
        query(): Query {
            return parseQuery(this.rawQuery)
        },
    },
    created(): void {
        this.token = localStorage.getItem('token')

        window.onpopstate = (ev: Event) => {
            console.log(`location: ${window.location} state: ${JSON.stringify((ev as PopStateEvent).state)}`)
            this.handleNavigate(window.location.search)
        }
    },
})
</script>
