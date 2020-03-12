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
            Mobile App DB
        </div>
		<div class="row" v-if="analysis">
			<div class="col-md-12">
				<table class="table table-condensed stations">
					<thead>
						<tr>
							<th>Station</th>
							<th>Device ID</th>
							<th>Generation ID</th>
						</tr>
					</thead>
					<tbody>
						<tr v-for="station in analysis.stations">
							<td>{{ station.name }}</td>
							<td>{{ station.device_id }}</td>
							<td>{{ station.generation }}</td>
						</tr>
					</tbody>
				</table>
			</div>
		</div>
		<div class="row">
			<div class="col-md-12">
				<a :href="'/diagnostics/archives/' + archive.id + '/fk.db?token=' + token">Download</a>
			</div>
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

        fetch('archives/' + this.query.id, options)
            .then(response => response.json())
            .then(archive => {
                this.archive = archive
            })

        fetch('archives/' + this.query.id + '/app.txt', options)
            .then(response => response.text())
            .then(mobileAppLogs => {
                this.mobileAppLogs = mobileAppLogs
            })

        fetch('archives/' + this.query.id + '/device.json', options)
            .then(response => response.json())
            .then(device => {
                this.device = device
            })

        fetch('archives/' + this.query.id + '/analysis', options)
            .then(response => response.json())
            .then(analysis => {
                this.analysis = analysis
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
html {
	overflow-y: scroll;
}
.device-table {
    font-size: 80%;
    width: 100%;
}
.app-logs {
    font-size: 80%;
}
table.stations th, table.stations td {
	padding-top: 1;
	padding-bottom: 1;
	padding-left: 0;
}
</style>
