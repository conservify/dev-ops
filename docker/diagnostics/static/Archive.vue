<!-- Archive.vue -->
<template>
    <div class="archive-container" v-if="archive">
        <h1>
            <a href="#" v-on:click.prevent="back()">Archives</a>
            / {{ archive.phrase }}
        </h1>

        <h4>{{ archive.time | prettyTime }}</h4>

        <div class="alert alert-primary" role="alert">
            Mobile App DB
        </div>
        <div class="row" v-if="analysis">
            <div class="col-md-12">
                <table class="table table-condensed stations">
                    <thead>
                        <tr>
                            <th>Station</th>
                            <th>Device ID</th>
                            <th>Device ID</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="station in analysis.stations">
                            <td>{{ station.name }}</td>
                            <td>{{ station.device_id }}</td>
                            <td>
                                <a target="_blank" :href="station.device_id | deviceLogsUrl">{{ station.device_id | hexToBase64 }}</a>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="row">
            <div class="col-md-12">
                <a target="_blank" :href="'/diagnostics/archives/' + archive.id + '/fk.db?token=' + token">Download</a>
            </div>
        </div>

        <div class="alert alert-primary" role="alert">
            Device / Configuration
        </div>
        <div class="row">
            <div class="col-md-6 device-json">
                <vue-json-pretty :data="device" :showDoubleQuotes="false"></vue-json-pretty>
            </div>
            <div class="col-md-6"></div>
        </div>

        <div class="alert alert-primary" role="alert" v-if="mobileAppLogs">
            Mobile App Logs
        </div>
        <div class="row" v-if="mobileAppLogs">
            <div class="col-md-12">
                <pre class="app-logs">{{ mobileAppLogs }}</pre>
            </div>
        </div>
    </div>
</template>
<script>
import _ from 'lodash'
import moment from 'moment'
import VueJsonPretty from 'vue-json-pretty'
import Config from './config'

export default {
    name: 'Archive',
    components: {
        VueJsonPretty,
    },
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
            mobileAppLogs: null,
            analysis: null,
        }
    },
    created() {
        this.archive = null

        const options = {
            headers: {
                Authorization: this.token,
            },
        }

        fetch(Config.BaseUrl + 'archives/' + this.query.id, options)
            .then(response => response.json())
            .then(archive => {
                this.archive = archive
            })

        fetch(Config.BaseUrl + 'archives/' + this.query.id + '/app.txt', options)
            .then(response => response.text())
            .then(mobileAppLogs => {
                this.mobileAppLogs = mobileAppLogs
            })

        fetch(Config.BaseUrl + 'archives/' + this.query.id + '/device.json', options)
            .then(response => response.json())
            .then(device => {
                this.device = device
            })

        fetch(Config.BaseUrl + 'archives/' + this.query.id + '/analysis', options)
            .then(response => response.json())
            .then(analysis => {
                this.analysis = analysis
            })
    },
    filters: {
        prettyTime(value) {
            return moment(value).format('MMM Do YYYY hh:mm:ss')
        },
        hexToBase64(value) {
            return Buffer.from(value, 'hex').toString('base64')
        },
        deviceLogsUrl(value) {
            return (
                'https://code.conservify.org/logs-viewer?range=864000&query=device_id:"' +
                Buffer.from(value, 'hex').toString('base64') +
                '"'
            )
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
html {
    overflow-y: scroll;
}
.archive-container {
	padding: 1em;
}
.device-table {
    font-size: 80%;
    width: 100%;
}
.alert {
    margin-top: 20px;
}
.app-logs {
    font-size: 80%;
}
.device-json .vjs-tree {
    font-size: 90%;
}
table.stations {
    font-size: 90%;
}
table.stations th,
table.stations td {
    padding-top: 4px;
    padding-bottom: 4px;
    padding-left: 0;
}
</style>
