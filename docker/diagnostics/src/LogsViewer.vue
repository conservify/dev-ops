<template>
    <div>
        <pre class="app-logs" @mousedown="down" @mousemove="over">{{ logs }}</pre>
    </div>
</template>
<script lang="ts">
import Vue from 'vue'
import FancyLine from './FancyLine.vue'

class Launch {
    constructor(public readonly logs: string) {}
}

export default Vue.extend({
    components: {},
    props: {
        logs: {
            type: String,
            required: true,
        },
    },
    data() {
        return {}
    },
    methods: {
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
            return haystack.length
        },
        getLineRange(text: string, offset: number): [number, number] {
            if (text[offset] == '\n') {
                const b = this.findBackwards(text, offset - 1, '\n')
                return [b, offset]
            }
            const b = this.findBackwards(text, offset, '\n')
            const e = this.findForwards(text, offset, '\n')
            return [b, Math.min(e, text.length)]
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

                const originalNode = cp.node as Text

                const replacingNode = originalNode.splitText(range[0])
                if (!replacingNode || !replacingNode.textContent) throw new Error(`failure`)

                if (!originalNode.textContent || originalNode.textContent.length == 0) {
                    originalNode.remove()
                }

                const hasNl = replacingNode.textContent[range[1] - range[0]] == '\n'
                const keepingNode = replacingNode.splitText((hasNl ? 1 : 0) + range[1] - range[0])
                if (!keepingNode.textContent || keepingNode.textContent.length == 0) {
                    keepingNode.remove()
                }

                const fancy = document.createElement('span')
                fancy.className = 'fancy-container'
                replacingNode.replaceWith(fancy)
                console.log(`down`, cp.offset, range, hasNl, line)
                const vm = new FancyLine({ propsData: { line: line } }).$mount(fancy)
            }
        },
        over(ev: Event): void {
            // console.log('over', ev)
        },
    },
})
</script>
<style lang="scss" scoped>
pre {
    overflow: inherit;
}

.app-logs {
    font-size: 80%;
}
</style>
