<!-- Archive.vue -->
<template>
    <div class="container" v-if="archive">
        <h1>
            <a href="#" v-on:click.prevent="back()">Archives</a>
            / {{ archive.phrase }}
        </h1>

        <h4>{{ archive.time | prettyTime }}</h4>

        <div class="alert alert-primary" role="alert">
            Device
        </div>
        <div class="row">
            <div class="col-md-6">
                <table class="device-table">
                    <tbody>
                        <tr v-for="(value, key) in device">
                            <th>{{ key }}</th>
                            <td>{{ value }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>
            <div class="col-md-6"></div>
        </div>

        <div class="alert alert-primary" role="alert">
            Application Logs
        </div>
        <div>
            <pre class="app-logs">{{ appLogs }}</pre>
        </div>
    </div>
</template>
<script>
import moment from 'moment'

export default {
    name: 'Archive',
    props: {
        token: {
            required: true,
        },
        query: {
            required: true,
        },
    },
    data: () => {
        return {
            archive: null,
            device: null,
            appLogs: null,
        }
    },
    created() {
        this.archive = null

        const options = {
            headers: {
                Authorization: this.token,
            },
        }

        fetch('archives/' + this.query.id, options)
            .then(response => response.json())
            .then(archive => {
                this.archive = archive
            })

        fetch('archives/' + this.query.id + '/device.json', options)
            .then(response => response.json())
            .then(device => {
                this.device = device
            })

        fetch('archives/' + this.query.id + '/app.txt', options)
            .then(response => response.text())
            .then(appLogs => {
                this.appLogs = appLogs
            })
    },
    filters: {
        prettyTime(value) {
            return moment(value).format('MMM Do YYYY hh:mm:ss')
        },
    },
    methods: {
        back() {
            this.$emit('navigate', '?')
        },
    },
}
</script>
<style>
.device-table {
    font-size: 80%;
    width: 100%;
}
.app-logs {
    font-size: 80%;
}
</style>
