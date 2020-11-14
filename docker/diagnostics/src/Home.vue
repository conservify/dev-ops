<!-- Home.vue -->
<template>
    <div class="container">
        <div class="col-md-12">&nbsp;</div>
        <div class="col-md-12">
            <form class="form-inline">
                <label class="sr-only" for="search">Search</label>
                <input type="text" name="search" v-model="search" class="form-control mb-2 mr-sm-2" />
                <button v-on:click.prevent="refresh" class="btn btn-primary mb-2" type="submit">Search</button>
            </form>
        </div>
        <div class="col-md-12">
            <table class="archives">
                <thead>
                    <tr>
                        <th class="track" style="">Time</th>
                        <th class="artist" style="">Phrase</th>
                        <th class="download" style=""></th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="archive in archives" class="archive" v-bind:key="archive.id">
                        <td class="time">{{ archive.time | prettyTime }}</td>
                        <td class="phrase">
                            <a :href="'?id=' + archive.id" v-on:click.prevent="view(archive)">{{ archive.phrase }}</a>
                        </td>
                        <td class="download">
                            <a :href="'/diagnostics/archives/' + archive.id + '.zip?token=' + token">Download</a>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>
<script lang="ts">
import Vue, { PropType } from 'vue'
import moment from 'moment'
import Config from './config'

export default Vue.extend({
    name: 'Home',
    props: {
        query: {
            type: Object,
            required: true,
        },
        token: {
            type: String,
            required: true,
        },
    },
    data(): {
        search: string | null
        archives: { id: string }[]
    } {
        return {
            archives: [],
            search: null,
        }
    },
    created(): void {
        this.refresh()
    },
    filters: {
        prettyTime(value: string | Date): string {
            return moment(value).format('MMM Do YYYY hh:mm:ss')
        },
    },
    methods: {
        view(archive: { id: string }): void {
            this.$emit('navigate', '?id=' + archive.id)
        },
        refresh(): void {
            const filter = this.search || this.query.q || ''
            const url = Config.BaseUrl + 'archives?q=' + filter
            const options = {
                headers: {
                    Authorization: this.token,
                },
            }
            fetch(url, options)
                .then((response) => {
                    if (response.status == 401) {
                        this.$emit('logout')
                        return Promise.reject('unauthorized')
                    }
                    return response.json()
                })
                .then((archives) => {
                    if (archives.archives.length == 1) {
                        this.$emit('navigate', '?id=' + archives.archives[0].id)
                    } else {
                        this.archives = archives.archives
                    }
                })
        },
    },
})
</script>
<style>
html {
    overflow-y: scroll;
}
table.archives {
    width: 100%;
}
</style>
