<template>
    <div class="fancy-line">{{ line.trim() }}</div>
</template>
<script lang="ts">
import Vue from 'vue'
export default Vue.extend({
    props: {
        line: {
            type: String,
            required: true,
        },
    },
    data() {
        return {}
    },
})
</script>
<style>
.fancy-line {
    display: block;
}
</style>
