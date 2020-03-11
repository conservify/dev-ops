<!-- Login.vue -->

<template>
    <div>
        <form>
            <input type="text" name="user" v-model="user" />
            <input type="password" name="password" v-model="password" />
            <button v-on:click.prevent="login">Login</button>
        </form>
    </div>
</template>
<script>
export default {
    name: 'Login',
    props: {},
    data: () => {
        return {
            user: '',
            password: '',
        }
    },
    created() {},
    filters: {},
    methods: {
        login() {
            const payload = {
                user: this.user,
                password: this.password,
            }
            return fetch('/login', {
                method: 'POST',
                body: JSON.stringify(payload),
            }).then(r => {
                console.log(r)
            })
        },
    },
}
</script>
