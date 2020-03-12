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
            required: true,
        },
    },
    data: () => {
        return {
            archive: {},
        }
    },
    created() {
        const options = {
            headers: {
                Authorization: this.token,
            },
        }
        fetch('archives/' + this.query.id, options)
            .then(response => {
                return response.json()
            })
            .then(archives => {
                this.archives = archives.archives
            })
    },
    filters: {},
    methods: {},
}
</script>
<style></style>
