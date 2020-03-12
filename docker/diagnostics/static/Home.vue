<!-- Home.vue -->
<template>
    <div class="container">
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
                    <tr v-for="archive in archives" class="archive">
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
<script>
import moment from 'moment'

export default {
    name: 'Home',
    props: {
        query: {
            required: true,
        },
        token: {
            required: true,
        },
    },
    data: () => {
        return {
            archives: [],
        }
    },
    created() {
        const options = {
            headers: {
                Authorization: this.token,
            },
        }

        fetch('archives?q=' + (this.query.q || ''), options)
            .then(response => response.json())
            .then(archives => {
                if (archives.archives.length == 1) {
                    this.$emit('navigate', '?id=' + archives.archives[0].id)
                } else {
                    this.archives = archives.archives
                }
            })
    },
    filters: {
        prettyTime(value) {
            return moment(value).format('MMM Do YYYY hh:mm:ss')
        },
    },
    methods: {
        view(archive) {
            this.$emit('navigate', '?id=' + archive.id)
        },
    },
}
</script>
<style>
html {
    overflow-y: scroll;
}
table.archives {
    width: 100%;
}
</style>
