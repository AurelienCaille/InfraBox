import Vue from 'vue'
import VueSocketio from 'vue-socket.io'

let protocol = 'ws:'
if (window.location.protocol === 'https:') {
    protocol = 'wss:'
}

const host = protocol + "//" + window.location.host
let path = window.location.pathname.substr(0, window.location.pathname.search("/dashboard"))
path += '/socket.io/'

Vue.use(VueSocketio, 'ws://localhost:3000', {
    path: path
})

function getCookie (cname) {
    const name = cname + '='
    const ca = document.cookie.split(';')

    for (let c of ca) {
        while (c.charAt(0) === ' ') {
            c = c.substring(1)
        }

        if (c.indexOf(name) === 0) {
            return c.substring(name.length, c.length)
        }
    }
    return ''
}

export function getToken () {
    return getCookie('token')
}

export default new Vue({
    sockets: {
        connect () {
            console.log('socket connected')
            this.$socket.emit('auth', getToken())
        },
        'notify:jobs' (val) {
            this.$emit('NOTIFY_JOBS', val)
        }
    },
    methods: {
        listenJobs (project) {
            this.$socket.emit('listen:jobs', project.id)
        }
    }
})
