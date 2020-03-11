<!-- Archive.vue -->
<template>
    <div>
		<h1>Archive</h1>
    </div>
</template>
<script>
export default {
    name: 'Archive',
props: {
query: {
required: true
}
},
    data: () => {
        return {
            archive: {},
        }
    },
    created() {
            fetch('/archives/' + this.query.id)
                .then(response => {
                    return response.json()
                })
                .then(archives => {
                    this.archives = archives.archives
                })
    },
    filters: {},
    methods: {
    },
}
</script>
<style></style>
