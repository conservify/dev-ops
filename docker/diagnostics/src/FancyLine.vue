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

::v-deep .jv-diagnostics {
    white-space: nowrap;
    color: #525252;
    font-size: 12px;
    font-family: Consolas, Menlo, Courier, monospace;
    .jv-ellipsis {
        color: #999;
        background-color: #eee;
        display: inline-block;
        line-height: 0.9;
        font-size: 0.9em;
        padding: 0px 4px 2px 4px;
        margin: 0 4px;
        border-radius: 3px;
        vertical-align: 2px;
        cursor: pointer;
        user-select: none;
    }
    .jv-button {
        color: #49b3ff;
    }
    .jv-key {
        color: #efefef;
        margin-right: 4px;
    }
    .jv-item {
        &.jv-array {
            color: #efefef;
        }
        &.jv-boolean {
            color: #fc1e70;
        }
        &.jv-function {
            color: #067bca;
        }
        &.jv-number {
            color: #fc1e70;
        }
        &.jv-object {
            color: #efefef;
        }
        &.jv-undefined {
            color: #e08331;
        }
        &.jv-string {
            color: #42b983;
            word-break: break-word;
            white-space: normal;
        }
    }
    .jv-code {
        .jv-toggle {
            &:before {
                padding: 0px 2px;
                border-radius: 2px;
            }
            &:hover {
                &:before {
                    background: #eee;
                }
            }
        }
    }
}
</style>
