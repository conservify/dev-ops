<!-- Archive.vue -->
<template>
    <div class="archive-container" v-if="archive">
        <vue-headful :title="archive.phrase" />

        <h1>
            <a href="#" v-on:click.prevent="back()">Archives</a>
            / {{ archive.phrase }}
        </h1>

        <h4>{{ archive.time | prettyTime }}</h4>

        <div class="download">
            <a :href="'/diagnostics/archives/' + archive.id + '.zip?token=' + token">Download</a>
        </div>

        <div class="alert alert-primary" role="alert">App Database</div>
        <div class="row" v-if="analysis">
            <div class="col-md-12">
                <table class="table table-condensed stations" v-if="analysis.stations">
                    <thead>
                        <tr>
                            <th>Station</th>
                            <th>Device ID</th>
                            <th>Device ID</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="station in analysis.stations" v-bind:key="station.id">
                            <td>{{ station.name }}</td>
                            <td>{{ station.device_id }}</td>
                            <td>
                                <a target="_blank" :href="station.device_id | deviceLogsUrl">{{ station.device_id | hexToBase64 }}</a>
                            </td>
                        </tr>
                    </tbody>
                </table>
                <div v-else>No stations.</div>
            </div>
        </div>
        <div class="row">
            <div class="col-md-12">
                <a target="_blank" :href="'/diagnostics/archives/' + archive.id + '/fk.db?token=' + token" download="fk.db">DB</a>
                <a
                    target="_blank"
                    :href="'/diagnostics/archives/' + archive.id + '/logs.txt?token=' + token"
                    :download="archive.id + '.txt'"
                >
                    Logs
                </a>
                <a target="_blank" :href="'/diagnostics/archives/' + archive.id + '/analysis?token=' + token">Summary</a>
            </div>
        </div>

        <div class="alert alert-primary" role="alert">Device / Configuration</div>
        <div class="row">
            <div class="col-md-6 device-json">
                <vue-json-pretty :data="device" :showDoubleQuotes="false"></vue-json-pretty>
            </div>
            <div class="col-md-6"></div>
        </div>

        <div class="alert alert-primary" role="alert" v-if="mobileAppLogs">Mobile App Logs</div>
        <div class="row" v-if="mobileAppLogs">
            <div class="col-md-12">
                <pre class="app-logs" @mousedown="down" @mousemove="over">{{ mobileAppLogs }}</pre>
            </div>
        </div>
    </div>
</template>
<script lang="ts">
import Vue, { PropType } from 'vue'
import _ from 'lodash'
import moment from 'moment'
import VueJsonPretty from 'vue-json-pretty'
import Config from './config'

import FancyLine from './FancyLine.vue'

interface SimpleBuffer {
    toString(encoding: string): string
}

declare const Buffer: {
    from(value: string, encoding: string): SimpleBuffer
}

export type Archive = any
export type Device = any

export interface StationAnalysis {
    id: number
}
export interface Analysis {
    stations: StationAnalysis[]
}

export default Vue.extend({
    name: 'Archive',
    components: {
        VueJsonPretty,
    },
    props: {
        token: {
            type: String,
            required: true,
        },
        query: {
            type: Object as PropType<{ id: string }>,
            required: true,
        },
    },
    data(): {
        archive: Archive | null
        device: Device | null
        mobileAppLogs: string | null
        analysis: Analysis | null
    } {
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
            .then((response) => response.json())
            .then((archive) => {
                this.archive = archive
            })

        fetch(Config.BaseUrl + 'archives/' + this.query.id + '/logs.txt', options)
            .then((response) => response.text())
            .then((mobileAppLogs) => {
                this.mobileAppLogs = mobileAppLogs
            })

        fetch(Config.BaseUrl + 'archives/' + this.query.id + '/device.json', options)
            .then((response) => response.json())
            .then((device) => {
                this.device = device
            })

        fetch(Config.BaseUrl + 'archives/' + this.query.id + '/analysis', options)
            .then((response) => response.json())
            .then((analysis) => {
                this.analysis = analysis
            })
    },
    filters: {
        prettyTime(value: string): string {
            return moment(value).format('MMM Do YYYY hh:mm:ss')
        },
        hexToBase64(value: string): string {
            return Buffer.from(value, 'hex').toString('base64')
        },
        deviceLogsUrl(value: string): string {
            return (
                'https://code.conservify.org/logs-viewer?range=864000&query=device_id:"' +
                Buffer.from(value, 'hex').toString('base64') +
                '"'
            )
        },
    },
    methods: {
        back(): void {
            this.$emit('navigate', '?')
        },
        getCaret(ev: { clientX: number; clientY: number }) {
            if (document.caretPositionFromPoint) {
                const range = document.caretPositionFromPoint(ev.clientX, ev.clientY)
                if (!range) return null
                return {
                    node: range.offsetNode,
                    offset: range.offset,
                }
            } else if (document.caretRangeFromPoint) {
                const range = document.caretRangeFromPoint(ev.clientX, ev.clientY)
                if (!range) return null
                return {
                    node: range.startContainer,
                    offset: range.startOffset,
                }
            }
            throw new Error(`unsupported browser`)
        },
        findBackwards(haystack: string, offset: number, c: string): number {
            for (let i = offset; i >= 0; --i) {
                if (haystack[i] == c) {
                    return i
                }
            }
            return 0
        },
        findForwards(haystack: string, offset: number, c: string): number {
            for (let i = offset; i < haystack.length; ++i) {
                if (haystack[i] == c) {
                    return i
                }
            }
            return haystack.length - 1
        },
        getLineRange(text: string, offset: number): [number, number] {
            if (text[offset] == '\n') {
                const b = this.findBackwards(text, offset - 1, '\n')
                return [b, offset]
            }
            const b = this.findBackwards(text, offset, '\n')
            const e = this.findForwards(text, offset, '\n')
            return [b, e]
        },
        getLine(text: string, range: [number, number]): string {
            return text.substring(range[0], range[1]).trim()
        },
        down(ev: { clientX: number; clientY: number }): void {
            const cp = this.getCaret(ev)
            if (cp && cp.node.nodeType == 3 && cp.node.textContent) {
                // Yeah yeah yeah this sucks.
                if (!cp.node.parentNode || (cp.node.parentNode as Element).className != 'app-logs') {
                    return
                }
                const range = this.getLineRange(cp.node.textContent, cp.offset)
                const line = this.getLine(cp.node.textContent, range)
                const replacing = (cp.node as Text).splitText(range[0])
                const keeping = replacing.splitText(range[1] - range[0] + 1) // Removes extra new line.
                const fancy = document.createElement('span')
                replacing.replaceWith(fancy)
                console.log(`down`, cp.offset, range)
                const vm = new FancyLine({ propsData: { line: line } }).$mount(fancy)
            }
        },
        over(ev: Event): void {
            // console.log('over', ev)
        },
    },
})
</script>
<style>
html {
    overflow: scroll;
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
pre {
    overflow: inherit;
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
