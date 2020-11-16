<template>
    <div>
        <div class="fancy-line">{{ fancy.text }}</div>
        <div v-if="hasExtras" class="extras">
            <div v-for="(o, i) in json" v-bind:key="i">
                <json-viewer theme="jv-diagnostics" :value="o.parsed" :expand-depth="3" copyable sort v-if="o.parsed" />
            </div>
        </div>
    </div>
</template>
<script lang="ts">
import Vue from 'vue'
import JsonViewer from 'vue-json-viewer'

class JSONField {
    public readonly parsed: unknown
    public readonly error: boolean

    constructor(public readonly text: string) {
        try {
            this.parsed = JSON.parse(text)
            this.error = false
        } catch (error) {
            this.error = true
            console.log(`error parsing:`, error)
        }
    }
}

class FancyLogLine {
    constructor(public readonly text: string) {}

    public findJson(): JSONField[] {
        const fields: JSONField[] = []
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
                    fields.push(new JSONField(this.text.substring(mark, i + 1)))
                    mark = -1
                }
            }
        }
        return fields
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
        json(): JSONField[] {
            return this.fancy.findJson()
        },
        hasExtras(): boolean {
            return this.json.length > 0
        },
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
