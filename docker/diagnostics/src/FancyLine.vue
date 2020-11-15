<template>
    <div>
        <div class="fancy-line">{{ fancy.text }}</div>
        <div v-if="hasExtras" class="extras">
            <div v-for="(o, i) in json" v-bind:key="i">
                <json-viewer theme="jv-diagnostics" :value="JSON.parse(o)" :expand-depth="3" copyable sort />
            </div>
        </div>
    </div>
</template>
<script lang="ts">
import Vue from 'vue'
import JsonViewer from 'vue-json-viewer'

class FancyLogLine {
    constructor(public readonly text: string) {}

    public findJson(): string[] {
        const found: string[] = []
        let depth = 0
        let mark = -1
        for (let i = 0; i < this.text.length; ++i) {
            if (this.text[i] == '{') {
                if (depth == 0) {
                    mark = i
                }
                depth++
            }
            if (this.text[i] == '}') {
                depth--
                if (depth == 0) {
                    found.push(this.text.substring(mark, i + 1))
                    mark = -1
                }
            }
        }
        return found
    }
}

export default Vue.extend({
    components: {
        'json-viewer': JsonViewer,
    },
    props: {
        line: {
            type: String,
            required: true,
        },
    },
    data() {
        return {
            fancy: new FancyLogLine(this.line.trim()),
        }
    },
    computed: {
        json(): string[] {
            return this.fancy.findJson()
        },
        hasExtras(): boolean {
            return this.json.length > 0
        },
    },
    created() {
        console.log()
    },
})
</script>
<style lang="scss" scoped>
.fancy-line {
    display: block;
}

.extras {
    margin-top: 1em;
    margin-bottom: 1em;
}
</style>
