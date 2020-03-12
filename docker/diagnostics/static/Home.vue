<!-- Home.vue -->
<template>
    <div>
        <table>
            <thead>
                <tr>
                    <th class="track" style="width: 50;">Time</th>
                    <th class="artist" style="width: 50;">Phrase</th>
                    <th class="download" style="">Download</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="archive in archives" class="archive">
                    <td class="time">{{ archive.time }}</td>
                    <td class="phrase">
                        <a :href="'?id=' + archive.id" v-on:click.prevent="view(archive)">{{ archive.phrase }}</a>
                    </td>
                    <td class="download">
                        <a :href="'/archives/' + archive.id + '.zip?token=' + token">Download</a>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>
<script>
export default {
    name: 'Home',
    props: {
		token: {
			required: true
		}
	},
    data: () => {
        return {
            archives: [],
        }
    },
    created() {
        this.refresh()
    },
    filters: {},
    methods: {
        view(archive) {
            this.$emit('navigate', '?id=' + archive.id)
        },
        refresh() {
            fetch('/archives', {
				headers: {
					"Authorization": this.token
				}
			}) .then(response => {
                    return response.json()
                }) .then(archives => {
                    this.archives = archives.archives
                })
        },
    },
}
</script>
<style></style>
