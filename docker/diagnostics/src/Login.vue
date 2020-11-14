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
<script lang="ts">
import Vue, { PropType } from 'vue'
import Config from './config'

export default Vue.extend({
    name: 'Login',
    props: {},
    data(): {
        user: string
        password: string
    } {
        return {
            user: '',
            password: '',
        }
    },
    methods: {
        login(): Promise<void> {
            const payload = {
                user: this.user,
                password: this.password,
            }
            console.log('HELLO', Config.BaseUrl)
            return fetch(Config.BaseUrl + 'login', {
                method: 'POST',
                body: JSON.stringify(payload),
            }).then((r) => {
                const token = r.headers.get('Authorization')
                if (token) {
                    localStorage.setItem('token', token)
                    this.$emit('authenticated', token)
                }
            })
        },
    },
})
</script>
