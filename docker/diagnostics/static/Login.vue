<!-- Login.vue -->

<template>
    <div class="container-fluid">
        <form class="col-md-4">
            <div class="form-group">
                <label for="user">User</label>
                <input type="text" name="user" v-model="user" class="form-control" />
            </div>
            <div class="form-group">
                <label for="password">Password</label>
                <input type="password" name="password" v-model="password" class="form-control" />
            </div>
            <button v-on:click.prevent="login" class="btn btn-default" type="submit">Login</button>
        </form>
    </div>
</template>
<script>
import Config from './config'

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
            return fetch(Config.BaseUrl + 'login', {
                method: 'POST',
                body: JSON.stringify(payload),
            }).then(r => {
                const token = r.headers.get('Authorization')
                if (token) {
                    localStorage.setItem('token', token)
                    this.$emit('authenticated', token)
                }
            })
        },
    },
}
</script>
